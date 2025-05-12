import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
  Future<void> markAttendance(
      String userId, String employeeId, DateTime date, bool isPresent) async {
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);

    await _firestore
        .collection('collection name')
        .doc(userId)
        .collection('collection name')
        .doc(employeeId)
        .collection('attendance')
        .doc(formattedDate)
        .set({
      'date':
          date, 
      'status': isPresent ? 'present' : 'absent',
    });
  }

  
  Future<Map<String, String>> fetchMonthlyAttendance(
      String userId, String employeeId, DateTime month) async {
    DateTime startOfMonth = DateTime(month.year, month.month, 1);
    DateTime endOfMonth = DateTime(month.year, month.month + 1, 0);

    QuerySnapshot snapshot = await _firestore
        .collection('collection name')
        .doc(userId)
        .collection('collection name')
        .doc(employeeId)
        .collection('attendance')
        .where('date', isGreaterThanOrEqualTo: startOfMonth)
        .where('date', isLessThanOrEqualTo: endOfMonth)
        .get();

    
    return {
      for (var doc in snapshot.docs)
        DateFormat('yyyy-MM-dd').format((doc['date'] as Timestamp).toDate()):
            doc['status']
    };
  }
}
