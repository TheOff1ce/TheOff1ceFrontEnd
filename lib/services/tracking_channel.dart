import 'dart:async';

import 'package:socket_io_client/socket_io_client.dart' as io;

import '../types/delivery.dart';
import 'access_token_source.dart';

/// Something that happened to the watched delivery, pushed by TheOff1ceGeolocation.
sealed class TrackingEvent {
  const TrackingEvent();
}

/// Full state: answer to `subscribe` and every `delivery.status`.
class DeliverySnapshot extends TrackingEvent {
  const DeliverySnapshot(this.delivery);
  final Delivery delivery;
}

/// `delivery.location` (driver position, ETA and remaining distance).
class LocationChanged extends TrackingEvent {
  const LocationChanged(this.payload);
  final Map<String, dynamic> payload;
}

/// `delivery.route` (route recalculated after a deviation or periodically).
class RouteChanged extends TrackingEvent {
  const RouteChanged(this.payload);
  final Map<String, dynamic> payload;
}

/// `delivery.ended`: the delivery finished and the location is no longer shared.
class TrackingEnded extends TrackingEvent {
  const TrackingEnded(this.status);
  final DeliveryStatus status;
}

/// Connection state changes, so the UI can say "reconnecting…".
class ConnectionChanged extends TrackingEvent {
  const ConnectionChanged({required this.connected, this.errorCode});
  final bool connected;

  /// `FORBIDDEN`, `DELIVERY_NOT_FOUND`… when the subscription was refused.
  final String? errorCode;
}

/// Realtime channel for one delivery (abstracted for tests).
abstract interface class TrackingChannel {
  Stream<TrackingEvent> get events;

  void watch(String deliveryId);

  void close();
}

typedef TrackingChannelFactory = TrackingChannel Function();

/// Socket.IO client for the `/tracking` namespace.
///
/// The access token goes in the handshake (`auth.token`), never in the URL. When the server
/// closes the socket because the token expired (`session_expired`), or the connection drops,
/// it gets a fresh token from [AccessTokenSource] and reconnects, then subscribes again.
class SocketTrackingChannel implements TrackingChannel {
  SocketTrackingChannel(this.baseUrl, this._tokens);

  static const _reconnectDelay = Duration(seconds: 3);
  static const _maxAuthRetries = 2;

  final String baseUrl;
  final AccessTokenSource _tokens;
  final _events = StreamController<TrackingEvent>.broadcast();
  io.Socket? _socket;
  String? _deliveryId;
  bool _closed = false;
  bool _forceRefresh = false;
  int _authRetries = 0;
  Timer? _retryTimer;

  @override
  Stream<TrackingEvent> get events => _events.stream;

  @override
  void watch(String deliveryId) {
    _deliveryId = deliveryId;
    unawaited(_connect());
  }

  Future<void> _connect() async {
    if (_closed) return;
    final token = await _tokens.currentAccessToken(forceRefresh: _forceRefresh);
    _forceRefresh = false;
    if (_closed) return;
    if (token == null) {
      _emit(const ConnectionChanged(connected: false, errorCode: 'TOKEN_REQUIRED'));
      return;
    }
    _disposeSocket();
    final socket = io.io(
      '$baseUrl/tracking',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .disableReconnection()
          .enableForceNew()
          .setAuth({'token': token})
          .build(),
    );
    _socket = socket;
    _listen(socket);
    socket.connect();
  }

  void _listen(io.Socket socket) {
    socket.onConnect((_) {
      _authRetries = 0;
      _emit(const ConnectionChanged(connected: true));
      socket.emitWithAck('subscribe', {'deliveryId': _deliveryId}, ack: _onSubscribed);
    });
    socket.onConnectError((error) => _onConnectError(error));
    socket.onDisconnect((_) {
      _emit(const ConnectionChanged(connected: false));
      _scheduleReconnect();
    });
    socket.on('session_expired', (_) => _forceRefresh = true);
    socket.on('delivery.location', (data) => _emit(LocationChanged(_map(data))));
    socket.on('delivery.route', (data) => _emit(RouteChanged(_map(data))));
    socket.on('delivery.status', (data) => _emit(DeliverySnapshot(Delivery.fromJson(_map(data)))));
    socket.on('delivery.ended', (data) => _emit(TrackingEnded(DeliveryStatus.fromCode(_map(data)['status']))));
  }

  void _onSubscribed(dynamic data) {
    final answer = _map(data);
    if (answer['success'] == true && answer['delivery'] is Map) {
      _emit(DeliverySnapshot(Delivery.fromJson(_map(answer['delivery']))));
      return;
    }
    final code = _map(answer['error'])['code']?.toString() ?? 'SUBSCRIBE_FAILED';
    _emit(ConnectionChanged(connected: true, errorCode: code));
  }

  /// Expired/invalid tokens are refreshed and retried a couple of times; other errors wait and retry.
  void _onConnectError(dynamic error) {
    final code = _map(_map(error)['data'])['code']?.toString();
    final authProblem = code == 'TOKEN_EXPIRED' || code == 'TOKEN_INVALID';
    if (authProblem && _authRetries >= _maxAuthRetries) {
      _emit(ConnectionChanged(connected: false, errorCode: code));
      return;
    }
    if (authProblem) {
      _authRetries++;
      _forceRefresh = true;
    }
    _emit(ConnectionChanged(connected: false, errorCode: code));
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_closed) return;
    _retryTimer?.cancel();
    _retryTimer = Timer(_reconnectDelay, () => unawaited(_connect()));
  }

  void _emit(TrackingEvent event) {
    if (!_closed) _events.add(event);
  }

  void _disposeSocket() {
    final socket = _socket;
    _socket = null;
    if (socket == null) return;
    socket.clearListeners();
    socket.dispose();
  }

  @override
  void close() {
    _closed = true;
    _retryTimer?.cancel();
    _disposeSocket();
    unawaited(_events.close());
  }
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? value.map((key, v) => MapEntry(key.toString(), v)) : <String, dynamic>{};
