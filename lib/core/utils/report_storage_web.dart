import 'dart:js_interop';
import 'dart:typed_data';

@JS('fintrackDownload')
external void _download(
  JSUint8Array bytes,
  JSString filename,
  JSString mimeType,
);

Future<String> saveReport(
  Uint8List bytes,
  String filename,
  String mimeType,
) async {
  _download(bytes.toJS, filename.toJS, mimeType.toJS);
  return filename;
}
