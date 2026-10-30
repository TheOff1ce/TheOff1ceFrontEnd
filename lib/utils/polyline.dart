import '../types/delivery.dart';

/// Decodes a Google Encoded Polyline (precision 1e5), as returned by TheOff1ceGeolocation.
List<GeoPoint> decodePolyline(String encoded) {
  final points = <GeoPoint>[];
  var index = 0;
  var lat = 0;
  var lng = 0;
  while (index < encoded.length) {
    final dLat = _readValue(encoded, index);
    final dLng = _readValue(encoded, dLat.next);
    index = dLng.next;
    lat += dLat.value;
    lng += dLng.value;
    points.add(GeoPoint(lat / 1e5, lng / 1e5));
  }
  return points;
}

({int value, int next}) _readValue(String encoded, int start) {
  var result = 0;
  var shift = 0;
  var index = start;
  int byte;
  do {
    byte = encoded.codeUnitAt(index++) - 63;
    result |= (byte & 0x1f) << shift;
    shift += 5;
  } while (byte >= 0x20 && index < encoded.length);
  final value = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
  return (value: value, next: index);
}
