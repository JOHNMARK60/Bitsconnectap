import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

Future<String> saveQrCodePng(
  String value, {
  String filePrefix = 'student-qr-code',
}) async {
  final painter = QrPainter(
    data: value,
    version: QrVersions.auto,
    gapless: true,
    eyeStyle: const QrEyeStyle(
      eyeShape: QrEyeShape.square,
      color: Colors.black,
    ),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: Colors.black,
    ),
  );
  const canvasSize = Size(1200, 1400);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(Offset.zero & canvasSize, Paint()..color = Colors.white);
  final title =
      ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
        ..pushStyle(
          ui.TextStyle(
            color: Colors.black,
            fontSize: 64,
            fontWeight: FontWeight.w700,
          ),
        )
        ..addText('BITSConnect');
  final paragraph = title.build()
    ..layout(const ui.ParagraphConstraints(width: 1200));
  canvas.drawParagraph(paragraph, const Offset(0, 55));
  canvas.save();
  canvas.translate(88, 190);
  painter.paint(canvas, const Size(1024, 1024));
  canvas.restore();
  final subtitle =
      ui.ParagraphBuilder(ui.ParagraphStyle(textAlign: TextAlign.center))
        ..pushStyle(ui.TextStyle(color: const Color(0xFF334155), fontSize: 34))
        ..addText('Student QR Code');
  final subtitleParagraph = subtitle.build()
    ..layout(const ui.ParagraphConstraints(width: 1200));
  canvas.drawParagraph(subtitleParagraph, const Offset(0, 1260));
  final image = await recorder.endRecording().toImage(1200, 1400);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData?.buffer.asUint8List();
  if (bytes == null) {
    throw Exception('Unable to create QR image.');
  }

  final directory = await _qrDirectory();
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final file = File(
    '${directory.path}${Platform.pathSeparator}${filePrefix}_$timestamp.png',
  );
  await file.writeAsBytes(bytes, flush: true);

  return file.path;
}

Future<void> showQrCodePreview(BuildContext context, String value) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final size = MediaQuery.sizeOf(context);
      final qrSize = (size.shortestSide * .72).clamp(260.0, 420.0).toDouble();

      return Dialog(
        insetPadding: const EdgeInsets.all(24),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(18),
                child: QrImageView(
                  data: value,
                  version: QrVersions.auto,
                  size: qrSize,
                  backgroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<Directory> _qrDirectory() async {
  final baseDirectory =
      await getExternalStorageDirectory() ??
      await getApplicationDocumentsDirectory();
  final directory = Directory(
    '${baseDirectory.path}${Platform.pathSeparator}qr-codes',
  );
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  return directory;
}
