import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../notification/notification.dart'; 

class NotificationButton extends StatelessWidget {
  final double iconSize;

  NotificationButton({required this.iconSize});

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;

    
    if (_auth.currentUser == null) {
      return Icon(Icons.notifications, color: Colors.black, size: iconSize);
    }

    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('collection name')
          .doc(_auth.currentUser!.uid)
          .collection('user_notifications')
          .where('isRead', isEqualTo: false) 
          .snapshots(), 
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Icon(Icons.notifications,
              color: Colors.black, size: iconSize); 
        }

        
        bool hasUnreadNotifications =
            snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return IconButton(
          icon: Icon(
            hasUnreadNotifications
                ? Icons.notifications_active
                : Icons.notifications_active_outlined,
            color: hasUnreadNotifications ? Colors.yellowAccent : Colors.black,
            size: iconSize,
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                var screenHeight = MediaQuery.of(context).size.height;
                var screenWidth = MediaQuery.of(context).size.width;

                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: screenHeight * 0.01),
                      child: Container(
                        width: screenWidth * 0.9,
                        height: screenHeight * 0.87,
                        child:
                            NotificationsPage(), 
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
