import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeService {
  static Future<String?> scanBarcode(BuildContext context) async {
    String? barcodeValue;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Scan Barcode'),
          content: SizedBox(
            height: 300,
            width: 300,
            child: MobileScanner(
              onDetect: (BarcodeCapture capture) {
                if (capture.barcodes.isNotEmpty) {
                  barcodeValue = capture.barcodes.first.rawValue;
                  Navigator.of(context)
                      .pop();
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    return barcodeValue;
  }
}
