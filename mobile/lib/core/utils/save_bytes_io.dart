import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveAndShareBytes(List<int> bytes, String fileName, {String mimeType = 'application/octet-stream'}) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(Uint8List.fromList(bytes));
  await Share.shareXFiles([XFile(file.path)]);
}
