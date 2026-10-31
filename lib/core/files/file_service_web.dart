import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Szöveges fájl mentése.
/// Telefonon a megosztás menüt nyitja meg (ott választható a "Mentés a
/// Fájlokba"), számítógépen egyszerűen letölti a fájlt.
///
/// Fontos: közvetlenül egy gombnyomásból kell meghívni, mert az iPhone
/// csak felhasználói művelet után engedi megnyitni a megosztás menüt.
Future<void> shareOrDownloadTextFile({
  required String fileName,
  required String content,
}) async {
  final bytes = utf8.encode(content);
  final navigator = web.window.navigator;
  final isMobile =
      RegExp('iPhone|iPad|iPod|Android').hasMatch(navigator.userAgent);

  if (isMobile) {
    final file = web.File(
      [bytes.toJS].toJS,
      fileName,
      web.FilePropertyBag(type: 'application/json'),
    );
    final shareData = web.ShareData(files: [file].toJS);

    var canShare = false;
    try {
      canShare = navigator.canShare(shareData);
    } catch (_) {
      canShare = false;
    }

    if (canShare) {
      try {
        await navigator.share(shareData).toDart;
        return;
      } catch (error) {
        // Ha a felhasználó bezárta a menüt, nincs teendő.
        if (error.toString().contains('AbortError')) return;
        // Bármilyen más hiba esetén letöltéssel próbálkozunk.
      }
    }
  }

  _download(bytes, fileName);
}

void _download(Uint8List bytes, String fileName) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  final body = web.document.body;
  if (body != null) {
    body.appendChild(anchor);
    anchor.click();
    body.removeChild(anchor);
  } else {
    anchor.click();
  }
  web.URL.revokeObjectURL(url);
}

/// Megnyit egy fájlválasztót, és visszaadja a kiválasztott fájl szövegét.
/// Null, ha a felhasználó nem választott semmit.
///
/// Ezt is közvetlenül egy gombnyomásból kell meghívni.
Future<String?> pickTextFile() {
  final completer = Completer<String?>();
  final input = web.HTMLInputElement()..type = 'file';

  void finish(String? value) {
    if (!completer.isCompleted) completer.complete(value);
  }

  input.addEventListener(
    'change',
    ((web.Event _) {
      final files = input.files;
      final file =
          (files == null || files.length == 0) ? null : files.item(0);
      if (file == null) {
        finish(null);
        return;
      }
      file.text().toDart.then(
        (text) => finish(text.toDart),
        onError: (Object error) {
          if (!completer.isCompleted) completer.completeError(error);
        },
      );
    }).toJS,
  );
  input.addEventListener(
    'cancel',
    ((web.Event _) => finish(null)).toJS,
  );

  input.click();
  return completer.future;
}
