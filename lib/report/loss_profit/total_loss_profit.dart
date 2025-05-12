import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/all_common_functions.dart';

class LossProfitSummaryWidget extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> _fetchLossProfitSummary() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'daily': 0.0,
        'monthly': 0.0,
        'yearlyTotal': 0.0,
        'grandTotal': 0.0,
      };
    }

    final userId = user.uid;
    final now = DateTime.now();

    
    final dailyDocId = '${now.year}-${now.month}-${now.day}';
    final monthlyDocId = '${now.year}-${now.month}';
    final yearlyDocId = '${now.year}';
    const grandTotalDocId = 'doc id/name';

    try {
      
      final dailySnapshot = await _firestore
          .doc('/collection name/$userId/daily_totals/$dailyDocId')
          .get();
      final monthlySnapshot = await _firestore
          .doc('/collection name/$userId/monthly_totals/$monthlyDocId')
          .get();
      final yearlySnapshot =
      await _firestore.doc('/collection name/$userId/yearly_totals/$yearlyDocId').get();
      final grandTotalSnapshot =
      await _firestore.doc('/collection name/$userId/yearly_totals/$grandTotalDocId').get();

      return {
        'daily': dailySnapshot.data()?['field name'] ?? 0.0,
        'monthly': monthlySnapshot.data()?['field name'] ?? 0.0,
        'yearlyTotal': yearlySnapshot.data()?['field name'] ?? 0.0,
        'grandTotal': grandTotalSnapshot.data()?['field name'] ?? 0.0,
      };
    } catch (e) {
      debugPrint('Error fetching loss/profit summary: $e');
      return {
        'daily': 0.0,
        'monthly': 0.0,
        'yearlyTotal': 0.0,
        'grandTotal': 0.0,
      };
    }
  }

  Widget _buildSummaryRow(String label, double value) {
    String formattedValue;

    if (value % 1 == 0) {
      formattedValue = value.toStringAsFixed(0);
    } else {
      formattedValue = value.toStringAsFixed(2);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            '৳ ${convertToBengaliNumbers(value.toStringAsFixed(0))}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: value >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  double _convertToDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    } else if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else {
      return 0.0; 
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchLossProfitSummary(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!;
        final daily = _convertToDouble(data['daily']);
        final monthly = _convertToDouble(data['monthly']);
        final yearlyTotal = _convertToDouble(data['yearlyTotal']);
        final grandTotal = _convertToDouble(data['grandTotal']);

        return Card(
          elevation: 5,
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'এক নজরে লাভ-লস',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                _buildSummaryRow('দৈনিক লাভ-লস:', daily),
                _buildSummaryRow('মাসিক লাভ-লস:', monthly),
                _buildSummaryRow('বাৎসরিক লাভ-লস:', yearlyTotal),
                if (yearlyTotal != grandTotal)
                  _buildSummaryRow('সর্বকালীন লাভ-লস:', grandTotal),
              ],
            ),
          ),
        );
      },
    );
  }
}
