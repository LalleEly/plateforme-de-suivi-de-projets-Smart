import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveAndShareBytes(List<int> bytes, String fileName, {String mimeType = 'application/octet-stream'}) async {
  final blob = html.Blob([Uint8List.fromList(bytes)], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
