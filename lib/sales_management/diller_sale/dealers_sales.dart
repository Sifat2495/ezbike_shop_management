import 'package:bebshar_poristhiti_stock/widgets/all_common_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/ownership_data.dart';
import '../due/guarantor_edit.dart';
import 'edit_dealer_popup.dart';
import 'edit_dealers_product.dart';

class DealersSales extends StatelessWidget {
  final String userId;
  final String dealerDocId;
  final String fatherName;
  final String motherName;
  final VoidCallback onGuarantorUpdated;
  final Function(Map<String, dynamic>) onDealerInfoUpdated;

  const DealersSales({
    super.key,
    required this.userId,
    required this.dealerDocId,
    required this.fatherName,
    required this.motherName,
    required this.onGuarantorUpdated,
    required this.onDealerInfoUpdated,
  });

  Future<Map<String, dynamic>?> fetchSalesData() async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('sales')
        .doc(dealerDocId)
        .get();

    return docSnapshot.data();
  }

  void showEnlargedImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(), 
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.broken_image, size: 100, color: Colors.grey),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> updateGuarantor(Map<String, dynamic> updatedGuarantor, int index) async {
    final salesDocRef = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('sales')
        .doc(dealerDocId);

    final salesData = await salesDocRef.get();
    if (!salesData.exists) return;

    final List<dynamic> guarantors = List.from(salesData.data()?['guarantors'] ?? []);

    if (index >= 0 && index < guarantors.length) {
      
      final Map<String, dynamic> existingGuarantor = guarantors[index];

      final mergedGuarantor = {
        'name': updatedGuarantor['name'] ?? existingGuarantor['name'],
        'fatherName': updatedGuarantor['fatherName'] ?? existingGuarantor['fatherName'],
        'motherName': updatedGuarantor['motherName'] ?? existingGuarantor['motherName'],
        'nid': updatedGuarantor['nid'] ?? existingGuarantor['nid'],
        'phone': updatedGuarantor['phone'] ?? existingGuarantor['phone'],
        'dob': updatedGuarantor['dob'] ?? existingGuarantor['dob'],
        'presentAddress': updatedGuarantor['presentAddress'] ?? existingGuarantor['presentAddress'],
        'permanentAddress': updatedGuarantor['permanentAddress'] ?? existingGuarantor['permanentAddress'],
        'selectedImage': updatedGuarantor['selectedImage'] ?? existingGuarantor['selectedImage'],
      };

      guarantors[index] = mergedGuarantor; 
      await salesDocRef.update({'guarantors': guarantors});
    }
  }


  String wrapText(String text, int maxLength) {
    
    final buffer = StringBuffer();
    int length = 0;
    for (var word in text.split(' ')) {
      if (length + word.length + 1 > maxLength) {
        buffer.writeln(); 
        length = 0; 
      }
      buffer.write('$word '); 
      length += word.length + 1; 
    }
    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: fetchSalesData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('বিক্রয় তথ্য লোড করতে সমস্যা হচ্ছে।'));
        }

        final salesData = snapshot.data;

        if (salesData == null) {
          return Center(
            child: Text(
              'কোনো বিক্রয় তথ্য পাওয়া যায়নি।',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          );
        }

        final products = salesData['products'] as List<dynamic>;
        final guarantors = salesData['guarantors'] as List<dynamic>;
        final chassis = salesData['chassis'] as List<dynamic>;
        final imagePath = salesData['image'] ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              margin: EdgeInsets.only(bottom: 6),
              elevation: 4,
              shadowColor: Colors.black26,
              color: Colors.yellow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'বিক্রয়ের তারিখ: ${DateFormat('dd MMM yyyy, hh:mm a').format(salesData['time'].toDate())}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'জন্মতারিখ: ${salesData['birthDate'] != null ? DateFormat('dd MMM yyyy').format(salesData['birthDate'].toDate()) : 'প্রযোজ্য নয়'}',
                              style: TextStyle(fontSize: 14, color: Colors.black),
                            ),
                            Text(
                              'পিতার নাম: $fatherName',
                              style: TextStyle(fontSize: 15, color: Colors.black),
                            ),
                            Text(
                              'মাতার নাম: $motherName',
                              style: TextStyle(fontSize: 15, color: Colors.black),
                            ),
                            Text(
                              'বর্তমান ঠিকানা: ${wrapText(salesData['present_address'] ?? 'প্রযোজ্য নয়', 20)}',
                              style: TextStyle(fontSize: 15, color: Colors.black),
                            ),
                            Text(
                              'স্থায়ী ঠিকানা: ${wrapText(salesData['permanent_address'] ?? 'প্রযোজ্য নয়', 20)}',
                              style: TextStyle(fontSize: 15, color: Colors.black),
                            ),
                            Text(
                              'এনআইডি: ${salesData['nid'] ?? 'প্রযোজ্য নয়'}',
                              style: TextStyle(fontSize: 15, color: Colors.black),
                            ),
                            Text(
                              'লাইসেন্স: ${wrapText(salesData['license'] ?? 'প্রযোজ্য নয়', 20)}',
                              style: TextStyle(fontSize: 15, color: Colors.black),
                            ),
                            Text(
                              'অটোর চেছিসঃ\n ${chassis.join(", ")}',
                              style: TextStyle(fontSize: 15, color: Colors.black),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            
                            if (chassis.isNotEmpty)
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OwnershipTransferFormPage(
                                        customerName: salesData['name'],
                                        fatherName: fatherName,
                                        motherName: motherName,
                                        presentAddress: salesData['present_address'],
                                        permanentAddress: salesData['permanent_address'],
                                        phone: salesData['phone'],
                                        saleDate: salesData['time'].toDate(),
                                        totalPrice: salesData['totalPrice'],
                                        advance: salesData['payment'],
                                        due: salesData['due'],
                                        nid: salesData['nid'],
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(color: Colors.green, width: 2),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  padding: EdgeInsets.all(12),
                                  backgroundColor: Colors.deepOrange,
                                ),
                                child: Icon(
                                  Icons.print,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                            SizedBox(height: 8), 
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue, size: 28),
                              onPressed: () async {
                                bool ePermission = await checkPermission(context, permissionField: 'isEdit');
                                if (ePermission) {
                                  bool pinVerified = await checkPinPermission(
                                      context,
                                      isDelete: false,
                                      isEdit: true);
                                  if (pinVerified) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return EditDealerInfoPopup(
                                          salesData: salesData,
                                          
                                          userId: userId,
                                          
                                          saleId: dealerDocId,
                                          
                                          dealerId: dealerDocId,
                                          
                                          fatherName: fatherName,
                                          motherName: motherName,
                                          time: salesData['time'],
                                          birthDate: salesData['birthDate'],
                                          onDealerUpdated: (updatedData) {
                                            
                                            onDealerInfoUpdated(updatedData);
                                          },
                                        );
                                      },
                                    );
                                  }
                                } else{
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return EditDealerInfoPopup(
                                        salesData: salesData,
                                        
                                        userId: userId,
                                        
                                        saleId: dealerDocId,
                                        
                                        dealerId: dealerDocId,
                                        
                                        fatherName: fatherName,
                                        motherName: motherName,
                                        time: salesData['time'],
                                        birthDate: salesData['birthDate'],
                                        onDealerUpdated: (updatedData) {
                                          onDealerInfoUpdated(updatedData);
                                        },
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            if (guarantors.isNotEmpty)
              Card(
                margin: EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                elevation: 4,
                color: Colors.blue[400],
                shadowColor: Colors.black26,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'জামিনদার:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ...guarantors.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> guarantor = entry.value;

                        return Card(
                          margin: EdgeInsets.only(bottom: 2),
                          color: Colors.yellow[200],
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        guarantor['name'] ?? 'লিখা হয় নাই',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'পিতার নাম: ${guarantor['fatherName'] ?? 'লিখা হয় নাই'}',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.grey[800]),
                                      ),
                                      Text(
                                        'মাতার নাম: ${guarantor['motherName'] ?? 'লিখা হয় নাই'}',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.grey[800]),
                                      ),
                                      Text(
                                        'এনআইডি: ${guarantor['nid'] ?? 'লিখা হয় নাই'}',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.grey[800]),
                                      ),
                                      Text(
                                        'ফোন: ${guarantor['phone'] ?? 'লিখা হয় নাই'}',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.grey[800]),
                                      ),
                                      Text(
                                        'জন্মতারিখ: ${guarantor['dob'] != null && guarantor['dob'].toString().isNotEmpty && guarantor['dob'] != "Not Set" ? DateFormat('dd MMM yyyy').format(DateTime.parse(guarantor['dob'])) : 'প্রযোজ্য নয়'}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      Text(
                                        'বর্তমান ঠিকানা: ${guarantor['presentAddress'] ?? 'লিখা হয় নাই'}',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.grey[800]),
                                      ),
                                      Text(
                                        'স্থায়ী ঠিকানা: ${guarantor['permanentAddress'] ?? 'লিখা হয় নাই'}',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.grey[800]),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => showEnlargedImage(
                                      context, guarantor['selectedImage'] ?? ''),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      guarantor['selectedImage'] ?? '',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                            width: 40,
                                            height: 40,
                                            color: Colors.grey[200],
                                            child: Icon(Icons.person,
                                                size: 40, color: Colors.grey),
                                          ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () async {
                                    bool ePermission = await checkPermission(context, permissionField: 'isEdit');
                                    if (ePermission) {
                                      bool pinVerified = await checkPinPermission(
                                          context,
                                          isDelete: false,
                                          isEdit: true);
                                      if (pinVerified) {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('এডিট জামিনদার'),
                                            content: GuarantorEdit(
                                              guarantor: guarantor,
                                              userId: userId,
                                              onSave: (updatedGuarantor) {
                                                updateGuarantor(
                                                    updatedGuarantor, index);
                                                Navigator.pop(context);
                                                onGuarantorUpdated();
                                              },
                                            ),
                                          ),
                                        );
                                      }
                                    } else {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('এডিট জামিনদার'),
                                          content: GuarantorEdit(
                                            guarantor: guarantor,
                                            userId: userId,
                                            onSave: (updatedGuarantor) {
                                              updateGuarantor(
                                                  updatedGuarantor, index);
                                              Navigator.pop(context);
                                              onGuarantorUpdated();
                                            },
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
          ],
        );
      },
    );
  }
}
