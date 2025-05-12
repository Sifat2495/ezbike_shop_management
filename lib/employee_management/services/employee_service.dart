import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/employee_model.dart';

class EmployeeService {
  
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  
  CollectionReference get employeeCollection {
    return FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('collection name');
  }

  
  Future<void> updateSalaryTransaction(String employeeId, String transactionId, double newAmount) async {
    final transactionDoc = employeeCollection
        .doc(employeeId)
        .collection('salary_transactions')
        .doc(transactionId);

    final transactionSnapshot = await transactionDoc.get();
    if (transactionSnapshot.exists) {
      final oldAmount = transactionSnapshot.data()?['amount'] ?? 0.0;
      final difference = newAmount - oldAmount;

      await transactionDoc.update({'amount': newAmount});

      final employeeDoc = employeeCollection.doc(employeeId);
      await employeeDoc.update({
        'amountToPay': FieldValue.increment(-difference),
      });
    }
  }
  
  Future<void> deleteSalaryTransaction(String employeeId, String transactionId) async {
    final transactionDoc = getSalaryTransactionCollection(employeeId).doc(transactionId);
    final transactionSnapshot = await transactionDoc.get();

    if (transactionSnapshot.exists) {
      final data = transactionSnapshot.data() as Map<String, dynamic>;
      final amount = data['amount'] ?? 0.0;

      await transactionDoc.delete();

      final employeeDoc = employeeCollection.doc(employeeId);
      await employeeDoc.update({
        'amountToPay': FieldValue.increment(amount),
      });
    }
  }
  
  CollectionReference getSalaryTransactionCollection(String employeeId) {
    return employeeCollection.doc(employeeId).collection('salary_transactions');
  }

  
  Future<void> addEmployee(Employee employee) async {
    await employeeCollection.doc(employee.id).set(employee.toMap());
  }

  
  Future<void> updateEmployee(Employee employee) async {
    await employeeCollection.doc(employee.id).update(employee.toMap());
  }

  

  Future<void> deleteEmployee(String id) async {
    
    final employeeDoc = await employeeCollection.doc(id).get();

    if (employeeDoc.exists) {
      final data = employeeDoc.data() as Map<String, dynamic>;
      final imageUrl = data['imageUrl'];

      
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          
          Reference imageRef = FirebaseStorage.instance.refFromURL(imageUrl);

          
          await imageRef.delete();
        } catch (e) {
          
          print("Error deleting image: $e");
        }
      }

      
      await employeeCollection.doc(id).delete();
    }
  }

  
  Future<void> updateEmployeeImageUrl(
      String employeeId, String imageUrl) async {
    await employeeCollection.doc(employeeId).update({
      'imageUrl': imageUrl,
    });
  }

  
  Future<void> initializeMonthlyAmountToPay(
      String employeeId, double salary) async {
    final employeeDoc = await employeeCollection.doc(employeeId).get();

    if (employeeDoc.exists) {
      final data = employeeDoc.data() as Map<String, dynamic>;
      final lastTransactionDate =
      (data['lastTransactionDate'] as Timestamp?)?.toDate();
      final amountToPay = (data['amountToPay'] ?? 0.0) as double;
      final now = DateTime.now();

      
      if (lastTransactionDate == null ||
          lastTransactionDate.year != now.year ||
          lastTransactionDate.month != now.month) {
        final updatedAmountToPay = amountToPay + salary;

        await employeeCollection.doc(employeeId).update({
          'amountToPay': updatedAmountToPay,
          'lastTransactionDate': Timestamp.fromDate(now),
        });
      }
    }
  }

  
  Future<void> addSalaryTransaction(String employeeId, double amount, _sendToCashbox) async {
    final transactionRef = getSalaryTransactionCollection(employeeId).doc();

    
    await transactionRef.set({
      'amount': amount,
      'time': DateTime.now(),
      'reason': 'Salary payment',
      'includeInCashbox': _sendToCashbox, 
    });

    
    final employeeDoc = await employeeCollection.doc(employeeId).get();
    final currentAmountToPay = (employeeDoc['amountToPay'] ?? 0.0) as double;

    
    final updatedAmountToPay = currentAmountToPay - amount;
    await employeeCollection.doc(employeeId).update({
      'amountToPay': updatedAmountToPay,
    });
  }

  

  Future<List<Map<String, dynamic>>> getPaginatedSalaryTransactions(
      String employeeId, int limit,
      {DocumentSnapshot? startAfter}) async {
    Query query = getSalaryTransactionCollection(employeeId)
        .orderBy('date', descending: true)
        .limit(5);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final querySnapshot = await query.get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; 
      data['documentSnapshot'] = doc; 
      return data;
    }).toList();
  }

  
  Stream<List<Employee>> getEmployees() {
    return employeeCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Employee.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }
}
