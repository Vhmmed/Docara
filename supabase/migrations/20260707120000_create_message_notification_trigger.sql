-- ---------------------------------------------------------------------------
-- Trigger: new chat message → notify the other conversation participant
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  v_recipient_id UUID;
  v_sender_name TEXT;
  v_sender_avatar_url TEXT;
  v_sender_role TEXT;
BEGIN
  -- Determine the recipient (the participant who did NOT send the message)
  SELECT
    CASE
      WHEN c.patient_id = NEW.sender_id THEN c.doctor_id
      ELSE c.patient_id
    END INTO v_recipient_id
  FROM public.conversations c
  WHERE c.id = NEW.conversation_id;

  IF v_recipient_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Get sender's profile info
  SELECT full_name, avatar_url, role INTO v_sender_name, v_sender_avatar_url, v_sender_role
  FROM public.profiles
  WHERE id = NEW.sender_id;

  INSERT INTO public.notifications (user_id, type, title, body, data)
  VALUES (
    v_recipient_id,
    'message',
    'New message from ' || COALESCE(v_sender_name, 'Someone'),
    NEW.content,
    jsonb_build_object(
      'conversation_id', NEW.conversation_id,
      'message_id', NEW.id,
      'sender_id', NEW.sender_id,
      'sender_name', v_sender_name,
      'sender_avatar_url', v_sender_avatar_url,
      'sender_role', v_sender_role
    )
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_new_message ON public.messages;
CREATE TRIGGER on_new_message
  AFTER INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_message();
