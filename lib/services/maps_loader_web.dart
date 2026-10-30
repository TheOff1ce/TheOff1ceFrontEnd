import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<bool>? _loading;

const _readyCallback = '__farmagoMapsReady';
const _loadTimeout = Duration(seconds: 15);

@JS(_readyCallback)
external set _onMapsReady(JSFunction? callback);

/// Injects the Maps JavaScript API once, with the client key passed as `--dart-define=MAPS_API_KEY`.
/// That key must be a browser key restricted by HTTP referrer (never the server key).
Future<bool> ensureGoogleMapsLoaded(String apiKey) {
  if (apiKey.isEmpty) return Future.value(false);
  return _loading ??= _load(apiKey);
}

/// Resolves only when `google.maps.Map`, `Marker`, `Polyline`… exist, which is what
/// google_maps_flutter_web needs. Google calls `callback` once the classic namespace is ready;
/// with `loading=async` the script's `onload` fires before those classes exist and the map
/// widget crashes.
Future<bool> _load(String apiKey) {
  final done = Completer<bool>();
  void finish(bool ok) {
    if (done.isCompleted) return;
    _onMapsReady = null;
    done.complete(ok);
  }

  _onMapsReady = (() => finish(true)).toJS;
  final script = web.HTMLScriptElement()
    ..src = 'https://maps.googleapis.com/maps/api/js?key=${Uri.encodeQueryComponent(apiKey)}'
        '&language=es&region=CO&callback=$_readyCallback'
    ..async = true;
  script.onerror = ((web.Event _) => finish(false)).toJS;
  web.document.head!.appendChild(script);
  Timer(_loadTimeout, () => finish(false));
  return done.future.then((ok) {
    if (!ok) _loading = null; // allow a later retry (e.g. after a network blip)
    return ok;
  });
}
