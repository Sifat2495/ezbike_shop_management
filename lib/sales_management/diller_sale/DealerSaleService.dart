import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class DealerSaleService {
  
  Future<bool> checkUserPermission() async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;

      final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
      await FirebaseFirestore.instance.collection('collection name').doc(userId).get();

      final bool permission = userSnapshot.data()?['permission'] as bool? ?? false;
      return permission;
    } catch (e) {
      debugPrint("Error checking user permission: $e");
      return false;
    }
  }

  
  Future<String?> saveDealerData({
    required String name,
    required String fatherName,
    required String motherName,
    required String phone,
    required String nid,
    required String presentAddress,
    required String permanentAddress,
    XFile? image,
    required double dealerDue,
    required bool smsDealer,
    required List<String> chassis,
    required List<String> phones,
    required DateTime birthDate,
    required DateTime time,
  }) async {
    try {
      final String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return null;

      final CollectionReference<Map<String, dynamic>> userDealersRef =
      FirebaseFirestore.instance.collection('collection name').doc(userId).collection('dealers');

      
      final String normalizedPhone = phone.trim().replaceAll(' ', '');
      final String normalizedName = name.trim().toLowerCase();
      final List<String> filteredChassis = chassis.where((item) => item.trim().isNotEmpty).toList();

      
      final QuerySnapshot existingDealerQuery = await userDealersRef
          .where('phone', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      if (existingDealerQuery.docs.isNotEmpty) {
        
        final DocumentReference<Map<String, dynamic>> existingDealerRef =
        existingDealerQuery.docs.first.reference as DocumentReference<Map<String, dynamic>>;

        final Map<String, dynamic> existingData =
        existingDealerQuery.docs.first.data() as Map<String, dynamic>;

        await existingDealerRef.update({
          'dealers_due': dealerDue,
          'time': time, 
        });

        debugPrint("Dealer updated: $normalizedPhone, New Due: $dealerDue");
        return existingDealerRef.id;
      }

      
      final Map<String, dynamic> dealerData = {
        'name': normalizedName,
        'father_name': fatherName.trim().toLowerCase(),
        'mother_name': motherName.trim().toLowerCase(),
        'birthDate': birthDate,
        'phone': normalizedPhone,
        'nid': nid.trim(),
        'present_address': presentAddress.trim(),
        'permanent_address': permanentAddress.trim(),
        'chassis': filteredChassis,
        'phones': phones,
        'image': image != null ? image.path : "",
        'sms_dealers': smsDealer,
        'dealers_due': dealerDue,
        'time': time,
      };

      final DocumentReference<Map<String, dynamic>> newDealerRef =
      await userDealersRef.add(dealerData);

      debugPrint("New dealer created: $normalizedPhone");
      return newDealerRef.id;
    } catch (e) {
      debugPrint("Error saving dealer data: $e");
      return null;
    }
  }

  Future<void> reduceUserStock(List<Map<String, dynamic>> products, DateTime time) async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final CollectionReference stockRef = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('collection name');

    final CollectionReference lossProfitCollection = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('collection name');

    final CollectionReference dailyTotalsCollection = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('collection name');

    final CollectionReference monthlyTotalsCollection = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('collection name');

    final CollectionReference yearlyTotalsCollection = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('collection name');

    final DocumentReference allTimeDocRef = yearlyTotalsCollection.doc('doc id/name');

    WriteBatch batch = FirebaseFirestore.instance.batch();

    for (var product in products) {
      final String productName = product['name'];
      final int quantitySold = product['quantity'];
      final double saleStock = quantitySold.toDouble();
      final double salePrice = product['sale_price'].toDouble();
      final double purchasePrice = product['purchase_price'].toDouble();
      final double netPurchasePrice = purchasePrice * saleStock;
      final double totalprice = product['total_price'].toDouble();
      final double profitPerProduct = totalprice - netPurchasePrice;

      
      final QuerySnapshot stockQuery = await stockRef.where('name', isEqualTo: productName).limit(1).get();

      if (stockQuery.docs.isEmpty) {
        debugPrint("Stock document not found for: $productName");
        continue; 
      }

      
      final DocumentReference productRef = stockQuery.docs.first.reference;

      batch.update(productRef, {
        'collection name': FieldValue.increment(-quantitySold),
      });

      final QuerySnapshot existingDocs = await lossProfitCollection
          .where('name', isEqualTo: productName)
          .limit(1)
          .get();

      if (existingDocs.docs.isNotEmpty) {
        final DocumentReference docRef = existingDocs.docs.first.reference;
        final Map<String, dynamic> existingData = existingDocs.docs.first.data() as Map<String, dynamic>;

        batch.update(docRef, {
          'sale_stock': (existingData['sale_stock'] ?? 0.0) + saleStock,
          'sale_netTotal': (existingData['sale_netTotal'] ?? 0.0) + totalprice,
          'field name': (existingData['field name'] ?? 0.0) + profitPerProduct,
        });
      } else {
        batch.set(lossProfitCollection.doc(), {
          'name': productName,
          'sale_stock': saleStock,
          'sale_netTotal': totalprice,
          'field name': profitPerProduct,
        });
      }

      final String dailyDocId = '${time.year}-${time.month}-${time.day}';
      final String monthlyDocId = '${time.year}-${time.month}';
      final String yearlyDocId = '${time.year}';

      batch.set(dailyTotalsCollection.doc(dailyDocId), {
        'field name': FieldValue.increment(profitPerProduct),
      }, SetOptions(merge: true));

      batch.set(monthlyTotalsCollection.doc(monthlyDocId), {
        'field name': FieldValue.increment(profitPerProduct),
        'month': time.month,
        'year': time.year,
      }, SetOptions(merge: true));

      batch.set(yearlyTotalsCollection.doc(yearlyDocId), {
        'field name': FieldValue.increment(profitPerProduct),
        'year': time.year,
      }, SetOptions(merge: true));

      batch.set(allTimeDocRef, {
        'field name': FieldValue.increment(profitPerProduct),
      }, SetOptions(merge: true));

      debugPrint("Stock updated successfully for: $productName");
    }

    await batch.commit();
  }


  Future<void> saveSaleData({
    required String name,
    required String license,
    required String description,
    required String collector,
    required String fatherName,
    required String motherName,
    required String phone,
    required String presentAddress,
    required String permanentAddress,
    required String nid,
    required List<String> chassis,
    required List<String> phones,
    required DateTime birthDate,
    required DateTime time,
    XFile? image,
    required List<Map<String, String>> guarantors,
    required List<Map<String, dynamic>> products,
    required double totalPrice,
    required double payment,
    required double due,
    required List<Map<String, dynamic>> installments,
  }) async {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    String? imageUrl;
    if (image != null) {
      imageUrl = image.path;
    }

    
    Future<String?> dealerFuture = saveDealerData(
      name: name,
      fatherName: fatherName,
      motherName: motherName,
      birthDate: birthDate,
      time: time,
      phone: phone,
      nid: nid,
      presentAddress: presentAddress,
      permanentAddress: permanentAddress,
      image: image,
      chassis: chassis,
      phones: phones,
      dealerDue: due,
      smsDealer: true,
    );

    
    Future<void> stockFuture = reduceUserStock(products, time);

    
    String? dealerDocId = await dealerFuture;
    if (dealerDocId == null) return;

    Map<String, dynamic> saleData = {
      'name': name,
      'license': license,
      'phone': phone,
      'present_address': presentAddress,
      'permanent_address': permanentAddress,
      'nid': nid,
      'birthDate': birthDate,
      'chassis': chassis,
      'phones': phones,
      'hasChassis': chassis.isNotEmpty,
      'time': time,
      'image': imageUrl,
      'guarantors': guarantors,
      'products': products,
      'totalPrice': totalPrice,
      'payment': payment,
      'due': due,
      'installments': installments,
    };

    
    final DocumentReference saleRef = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('sales')
        .doc(dealerDocId);

    
    final batch = FirebaseFirestore.instance.batch();
    batch.set(saleRef, saleData);

    
    DateTime now = time;
    batch.set(
        FirebaseFirestore.instance.collection('collection name').doc(userId).collection('collection name').doc('${now.year}-${now.month}-${now.day}'),
        {
          'sale_total': FieldValue.increment(totalPrice),
          'sale_paid': FieldValue.increment(payment),
          'total_due': FieldValue.increment(due),
        },
        SetOptions(merge: true));

    batch.set(
        FirebaseFirestore.instance.collection('collection name').doc(userId).collection('collection name').doc('${now.year}-${now.month}'),
        {
          'sale_total': FieldValue.increment(totalPrice),
        },
        SetOptions(merge: true));

    batch.set(
        FirebaseFirestore.instance.collection('collection name').doc(userId).collection('collection name').doc('${now.year}'),
        {
          'sale_total': FieldValue.increment(totalPrice),
        },
        SetOptions(merge: true));

    batch.set(
        FirebaseFirestore.instance.collection('collection name').doc(userId).collection('collection name').doc('doc id/name'),
        {
          'total_due': FieldValue.increment(due),
        },
        SetOptions(merge: true));


    
    final DocumentReference cashboxRef = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('cashbox')
        .doc(dealerDocId);

    batch.set(cashboxRef, {
      'amount': payment,
      'reason': 'ডিলার সেল ${totalPrice.toStringAsFixed(0)} টাকা, নগদ পরিশোধ ${payment.toStringAsFixed(0)} টাকা, বর্তমান বাকি: ${due.toStringAsFixed(0)} টাকা।',
      'time': now,
    });

    
    final CollectionReference historyRef = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('dealers')
        .doc(dealerDocId)
        .collection('history');

    
    batch.set(historyRef.doc(), {
      'amount': totalPrice,
      'collector': collector,
      'description': description,
      'due': due,
      'payment': payment,
      'time': time,
    });

    
    await Future.wait([batch.commit(), stockFuture]);
  }
}