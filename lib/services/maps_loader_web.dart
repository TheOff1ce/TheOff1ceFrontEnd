import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<bool>? _loading;

/// Injects the Maps JavaScript API once, with the client key passed as `--dart-define=MAPS_API_KEY`.
/// That key must be a browser key restricted by HTTP referrer (never the server key).
Future<bool> ensureGoogleMapsLoaded(String apiKey) {
  if (apiKey.isEmpty) return Future.value(false);
  return _loading ??= _load(apiKey);
}

Future<bool> _load(String apiKey) {
  final done = Completer<bool>();
  final script = web.HTMLScriptElement()
    ..src = 'https://maps.googleapis.com/maps/api/js?key=${Uri.encodeQueryComponent(apiKey)}&language=es&region=CO&loading=async'
    ..async = true;
  script.onload = ((web.Event _) => done.complete(true)).toJS;
  script.onerror = ((web.Event _) => done.complete(false)).toJS;
  web.document.head!.appendChild(script);
  return done.future;
}
