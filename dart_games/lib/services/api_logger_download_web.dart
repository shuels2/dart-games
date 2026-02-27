import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<String> downloadLogFile(String filename, String jsonString) async {
  final bytes = utf8.encode(jsonString);
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  anchor.style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  web.document.body!.removeChild(anchor);
  web.URL.revokeObjectURL(url);
  return 'Downloads/$filename';
}
