import { serve } from "https://deno.land/std@0.208.0/http/server.ts";
import { importPKCS8, SignJWT } from "https://deno.land/x/jose@v5.2.0/index.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

interface WebhookPayload {
  type: "INSERT";
  table: string;
  record: {
    id: string;
    conversation_id: string;
    sender_id: string;
    content: string;
    created_at: string;
  };
  schema: "public";
}

interface ServiceAccount {
  type: string;
  project_id: string;
  private_key_id: string;
  private_key: string;
  client_email: string;
  client_id: string;
  auth_uri: string;
  token_uri: string;
}

serve(async (req) => {
  const payload: WebhookPayload = await req.json();

  if (payload.type !== "INSERT" || payload.table !== "messages") {
    return new Response("Not handled", { status: 200 });
  }

  const { conversation_id, sender_id, content } = payload.record;

  const serviceAccountRaw = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!serviceAccountRaw) {
    console.error("FIREBASE_SERVICE_ACCOUNT secret not set");
    return new Response("Server config error", { status: 500 });
  }

  let serviceAccount: ServiceAccount;
  try {
    serviceAccount = JSON.parse(serviceAccountRaw);
  } catch {
    console.error("FIREBASE_SERVICE_ACCOUNT is not valid JSON");
    return new Response("Server config error", { status: 500 });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // Look up conversation to find the OTHER participant
  const { data: conversation, error: convError } = await supabase
    .from("conversations")
    .select("patient_id, doctor_id")
    .eq("id", conversation_id)
    .single();

  if (convError || !conversation) {
    console.error("Conversation lookup error:", convError);
    return new Response("Conversation not found", { status: 200 });
  }

  const otherUserId = conversation.patient_id === sender_id
    ? conversation.doctor_id
    : conversation.patient_id;

  // Fetch recipient's FCM token + sender's name in parallel
  const [recipientResult, senderResult] = await Promise.all([
    supabase
      .from("profiles")
      .select("fcm_token")
      .eq("id", otherUserId)
      .single(),
    supabase
      .from("profiles")
      .select("full_name")
      .eq("id", sender_id)
      .single(),
  ]);

  const fcmToken = recipientResult.data?.fcm_token as string | null;
  const senderName = (senderResult.data?.full_name as string) ?? "Someone";

  if (!fcmToken) {
    console.log(`No FCM token for user ${otherUserId} — skipping notification`);
    return new Response("No FCM token", { status: 200 });
  }

  const truncatedContent = content.length > 50
    ? content.substring(0, 47) + "..."
    : content;

  // Get a short-lived OAuth 2.0 access token from the service account
  const accessToken = await getFcmAccessToken(serviceAccount);

  // Send notification via FCM HTTP v1 API
  const fcmResponse = await fetch(
    `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${accessToken}`,
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: {
            title: `New message from ${senderName}`,
            body: truncatedContent,
          },
          data: {
            conversation_id,
            sender_id,
          },
        },
      }),
    },
  );

  if (!fcmResponse.ok) {
    const errorBody = await fcmResponse.text();
    console.error("FCM API error:", fcmResponse.status, errorBody);
    return new Response("FCM send failed", { status: 200 });
  }

  console.log("Push notification sent successfully");
  return new Response("OK", { status: 200 });
});

// --------------------------------------------------------------------------
// Generates an OAuth 2.0 access token using a Google service account.
// Steps: 1) Create a signed JWT assertion, 2) Exchange it for an access token
//         at the token endpoint.
// --------------------------------------------------------------------------
async function getFcmAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  const privateKey = await importPKCS8(serviceAccount.private_key, "RS256");

  const jwt = await new SignJWT({
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: serviceAccount.token_uri,
    exp: now + 3600,
    iat: now,
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .sign(privateKey);

  const tokenResponse = await fetch(serviceAccount.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const tokenData = await tokenResponse.json();
  return tokenData.access_token as string;
}
