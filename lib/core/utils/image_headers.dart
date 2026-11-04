/// Only recognized raster receipts are accepted; extensions are not trusted.
String? receiptMime(List<int> bytes) {
  bool starts(List<int> prefix) =>
      bytes.length >= prefix.length &&
      Iterable<int>.generate(prefix.length).every((i) => bytes[i] == prefix[i]);
  if (bytes.length >= 24 && starts([137, 80, 78, 71, 13, 10, 26, 10])) {
    return 'image/png';
  }
  if (bytes.length >= 4 && starts([255, 216, 255])) return 'image/jpeg';
  if (bytes.length >= 16 &&
      starts([82, 73, 70, 70]) &&
      String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
    return 'image/webp';
  }
  return null;
}
