import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Opens the browser's file picker (optionally hinting at the device camera)
/// and returns the raw bytes of the chosen image, or `null` if the user
/// cancels. Replaces the deprecated `dart:html` upload flow with
/// `package:web` + `dart:js_interop`.
Future<Uint8List?> pickImageBytes({bool useCamera = false}) async {
  final input = (web.document.createElement('input') as web.HTMLInputElement)
    ..type = 'file'
    ..accept = 'image/*';
  if (useCamera) input.setAttribute('capture', 'environment');

  final filePicked = Completer<web.File?>();
  input.addEventListener('change', (web.Event _) {
    final files = input.files;
    filePicked.complete((files != null && files.length > 0) ? files.item(0) : null);
  }.toJS);
  input.click();
  final file = await filePicked.future;
  if (file == null) return null;

  final reader  = web.FileReader();
  final loaded  = Completer<Uint8List>();
  reader.addEventListener('load', (web.Event _) {
    loaded.complete((reader.result as JSArrayBuffer).toDart.asUint8List());
  }.toJS);
  reader.addEventListener('error', (web.Event _) {
    loaded.completeError(StateError('Failed to read the selected file'));
  }.toJS);
  reader.readAsArrayBuffer(file);
  return loaded.future;
}
