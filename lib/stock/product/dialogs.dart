import 'package:bebshar_poristhiti_stock/stock/product/product_model.dart';
import 'package:flutter/material.dart';

void showErrorDialog(BuildContext context, String message, Function onClose) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          'দুঃখিত...',
          style: TextStyle(color: Colors.red),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              FocusScope.of(context).unfocus();
              onClose();
            },
            child: const Text('ফিরে যান'),
          ),
        ],
      );
    },
  );
}

void showProductDetailsDialog(
    BuildContext context, Product product, Function onClose) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFFF3F4F6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.teal),
            const SizedBox(width: 8),
            const Text(
              'প্রোডাক্টের বিস্তারিত',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.teal,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               if (product.photoUrls.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: product.photoUrls.map((url) {
                    return Container(
                      margin: const EdgeInsets.only(
                          right: 10),
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(2, 2),
                          ),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(url),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
               _buildDetailRow('নাম', product.name),
              _buildDetailRow('barcode', '${product.barcode}'),
              _buildDetailRow(
                  'ক্রয়মূল্য', '৳${product.purchasePrice.toStringAsFixed(2)}'),
              _buildDetailRow(
                  'বিক্রয়মূল্য', '৳${product.salePrice.toStringAsFixed(2)}'),
              _buildDetailRow('মোট স্টক', '${product.stock}'),
              _buildDetailRow('মোট মূল্য',
                  '৳${(product.purchasePrice * product.stock).toStringAsFixed(2)}'),
            ],
          ),
        ),
        actions: [
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                FocusScope.of(context).unfocus();
                onClose();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'ঠিক আছে',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildDetailRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    ),
  );
}

void showProductExistsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          'Product Already Exists',
          style: TextStyle(color: Colors.red),
        ),
        content:
        const Text('A product with the same name/barcode already exists.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              FocusScope.of(context).unfocus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('OK',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}
