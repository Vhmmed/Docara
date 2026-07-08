import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks the current user's online presence via Supabase Realtime Presence
/// and maintains a set of currently-online user IDs.
///
/// Privacy note: currently any user sharing a conversation with the tracked
/// user can see their online status. A future "who can see my last seen"
/// setting could be added by filtering visibility at the query level.
class PresenceService {
  final SupabaseClient _client;
  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authSubscription;
  final Set<String> _onlineUsers = {};
  final StreamController<Set<String>> _controller =
      StreamController<Set<String>>.broadcast();
  String? _currentUserId;

  PresenceService(this._client);

  /// Broadcasts the current set of online user IDs whenever it changes.
  Stream<Set<String>> get onlineUsers => _controller.stream;

  /// Returns whether a given user_id is currently tracked as online.
  bool isOnline(String userId) => _onlineUsers.contains(userId);

  /// Initializes presence tracking for the currently authenticated user.
  /// Called on app start and on resume from background.
  Future<void> init() async {
    final prevId = _currentUserId;
    _currentUserId = _client.auth.currentUser?.id;
    developer.log(
      'init() called — supabase currentUser.id=$_currentUserId '
      'previousId=$prevId channel=${_channel != null}',
      name: 'PresenceService',
    );

    if (_currentUserId == null) {
      developer.log(
        'init() — no user yet, setting up auth listener (exists=${_authSubscription != null})',
        name: 'PresenceService',
      );
      _authSubscription ??= _client.auth.onAuthStateChange.listen((event) {
        final newId = event.session?.user.id;
        developer.log(
          'init() authListener fired — event=${event.event} newId=$newId '
          'currentId=$_currentUserId',
          name: 'PresenceService',
        );
        if (newId != null && newId != _currentUserId) {
          _currentUserId = newId;
          developer.log(
            'init() authListener — calling _setup() for user=$_currentUserId',
            name: 'PresenceService',
          );
          _setup();
        }
      });
      return;
    }
    developer.log(
      'init() — user=$_currentUserId already authenticated, calling _setup()',
      name: 'PresenceService',
    );
    _setup();
    unawaited(updateLastSeen());
  }

  void _setup() {
    developer.log(
      '_setup() — currentUserId=$_currentUserId '
      'old channel exists=${_channel != null} '
      'channel name will be "presence:online-users"',
      name: 'PresenceService',
    );

    _channel?.unsubscribe();
    _channel = _client.channel('presence:online-users');

    developer.log(
      '_setup() — new RealtimeChannel created, obj=${_channel.hashCode}',
      name: 'PresenceService',
    );

    _channel!.onPresenceSync((_) {
      developer.log(
        '_setup() — onPresenceSync FIRED — calling _onPresenceChanged()',
        name: 'PresenceService',
      );
      _onPresenceChanged();
    });
    _channel!.onPresenceJoin((payload) {
      final ids = payload.newPresences
          .map((p) => p.payload['user_id'])
          .join(',');
      developer.log(
        '_setup() — onPresenceJoin: key=${payload.key} newPresences=$ids',
        name: 'PresenceService',
      );
    });
    _channel!.onPresenceLeave((payload) {
      final ids = payload.leftPresences
          .map((p) => p.payload['user_id'])
          .join(',');
      developer.log(
        '_setup() — onPresenceLeave: key=${payload.key} leftPresences=$ids',
        name: 'PresenceService',
      );
    });

    _channel!.subscribe((status, err) {
      developer.log(
        '_setup() — subscribe callback FIRED: status=$status err=$err '
        'currentUserId=$_currentUserId channel=${_channel.hashCode}',
        name: 'PresenceService',
      );
      if (status == RealtimeSubscribeStatus.subscribed) {
        developer.log(
          '_setup() — subscribe SUCCESS, now calling _trackPresence()',
          name: 'PresenceService',
        );
        _trackPresence();
      } else if (status == RealtimeSubscribeStatus.timedOut) {
        developer.log(
          '_setup() — subscribe TIMED OUT',
          name: 'PresenceService',
        );
      } else if (status == RealtimeSubscribeStatus.channelError) {
        developer.log(
          '_setup() — subscribe CHANNEL ERROR: err=$err',
          name: 'PresenceService',
          error: err,
        );
      } else if (status == RealtimeSubscribeStatus.closed) {
        developer.log(
          '_setup() — subscribe CLOSED',
          name: 'PresenceService',
        );
      }
    });
  }

  void _onPresenceChanged() {
    if (_channel == null) {
      developer.log(
        '_onPresenceChanged() — _channel is NULL, returning',
        name: 'PresenceService',
      );
      return;
    }
    final presence = _channel!.presenceState();
    developer.log(
      '_onPresenceChanged() — raw presenceState has ${presence.length} entries',
      name: 'PresenceService',
    );
    if (presence.isEmpty) {
      developer.log(
        '_onPresenceChanged() — presenceState is EMPTY (no online users)',
        name: 'PresenceService',
      );
    }
    for (final entry in presence) {
      for (final p in entry.presences) {
        final uid = p.payload['user_id'];
        final oat = p.payload['online_at'];
        developer.log(
          '_onPresenceChanged() — entry key="${entry.key}" '
          'userId=$uid onlineAt=$oat',
          name: 'PresenceService',
        );
      }
    }

    final updated = <String>{};
    for (final state in presence) {
      for (final p in state.presences) {
        final userId = p.payload['user_id'] as String?;
        if (userId != null) updated.add(userId);
      }
    }

    final added = updated.difference(_onlineUsers);
    final removed = _onlineUsers.difference(updated);
    developer.log(
      '_onPresenceChanged() — computed set: online=[${updated.join(",")}] '
      'added=[${added.join(",")}] removed=[${removed.join(",")}] '
      'me=$_currentUserId',
      name: 'PresenceService',
    );

    _onlineUsers
      ..clear()
      ..addAll(updated);
    _controller.add(Set.from(_onlineUsers));
    developer.log(
      '_onPresenceChanged() — emitted ${_onlineUsers.length} users '
      'to stream, listeners will update UI',
      name: 'PresenceService',
    );
  }

  Future<void> _trackPresence() async {
    developer.log(
      '_trackPresence() ENTERED — _channel=${_channel.hashCode} '
      'channelAlive=${_channel != null} '
      '_currentUserId=$_currentUserId',
      name: 'PresenceService',
    );
    if (_channel == null || _currentUserId == null) {
      developer.log(
        '_trackPresence() — SKIPPING: _channel==${_channel == null} '
        '_currentUserId==$_currentUserId',
        name: 'PresenceService',
      );
      return;
    }
    try {
      final payload = <String, dynamic>{
        'user_id': _currentUserId,
        'online_at': DateTime.now().toUtc().toIso8601String(),
      };
      developer.log(
        '_trackPresence() — calling channel.track() with payload=$payload',
        name: 'PresenceService',
      );
      await _channel!.track(payload);
      developer.log(
        '_trackPresence() — channel.track() RETURNED SUCCESS',
        name: 'PresenceService',
      );
    } catch (e) {
      developer.log(
        '_trackPresence() ERROR: $e',
        name: 'PresenceService',
        error: e,
      );
    }
  }

  /// Untracks the current user's presence (called on app pause/close).
  Future<void> untrack() async {
    developer.log(
      'untrack() called — _channel=${_channel.hashCode} '
      'channelAlive=${_channel != null} _currentUserId=$_currentUserId',
      name: 'PresenceService',
    );
    if (_channel == null) return;
    try {
      await _channel!.untrack();
      developer.log('untrack() completed OK', name: 'PresenceService');
    } catch (e) {
      developer.log('untrack() error: $e', name: 'PresenceService', error: e);
    }
  }

  /// Updates the last_seen_at column in the profiles table (called on pause).
  Future<void> updateLastSeen() async {
    if (_currentUserId == null) {
      developer.log(
        'updateLastSeen() — SKIPPING: _currentUserId is null',
        name: 'PresenceService',
      );
      return;
    }
    try {
      await _client
          .from('profiles')
          .update({'last_seen_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', _currentUserId!);
      developer.log(
        'updateLastSeen() — updated profile $_currentUserId',
        name: 'PresenceService',
      );
    } catch (e) {
      developer.log(
        'PresenceService.updateLastSeen error: $e',
        name: 'PresenceService',
      );
    }
  }

  void _cleanup() {
    developer.log(
      '_cleanup() — clearing channel and _onlineUsers',
      name: 'PresenceService',
    );
    _channel?.unsubscribe();
    _channel = null;
    _onlineUsers.clear();
  }

  /// Full cleanup — untracks presence, unsubscribes channel, closes stream.
  Future<void> dispose() async {
    developer.log('dispose() called', name: 'PresenceService');
    await updateLastSeen();
    await untrack();
    _cleanup();
    await _authSubscription?.cancel();
    await _controller.close();
    developer.log('dispose() completed', name: 'PresenceService');
  }
}
