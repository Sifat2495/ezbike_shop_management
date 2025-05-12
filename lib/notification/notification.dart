import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  
  Stream<List<DocumentSnapshot>> getRecentNotifications(String userId) async* {
    DateTime now = DateTime.now();
    DateTime twoDaysAgo = now.subtract(Duration(days: 2));

    
    Stream<QuerySnapshot> globalNotificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(twoDaysAgo))
        .orderBy('time', descending: true)
        .snapshots();

    
    Stream<QuerySnapshot> userNotificationsStream = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('user_notifications')
        .where('time', isGreaterThanOrEqualTo: Timestamp.fromDate(twoDaysAgo))
        .orderBy('time', descending: true)
        .snapshots();

    
    await for (var globalNotifications in globalNotificationsStream) {
      await for (var userNotifications in userNotificationsStream) {
        List<DocumentSnapshot> allNotifications = [
          ...globalNotifications.docs,
          ...userNotifications.docs,
        ];

        
        allNotifications.sort((a, b) {
          Timestamp timeA = a['time'];
          Timestamp timeB = b['time'];
          return timeB.compareTo(timeA);
        });

        yield allNotifications;
      }
    }
  }

  
  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Notifications'),
          backgroundColor: Colors.teal,
          automaticallyImplyLeading: false,
          centerTitle: true,
        ),
        body: Center(
          child: Text("User not logged in"),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(20),
        bottom: Radius.circular(30),
      ),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: AppBar(
            backgroundColor: Colors.teal,
            elevation: 0,
            title: Text('Notifications'),
            automaticallyImplyLeading: false,
            centerTitle: true,
          ),
        ),
        body: StreamBuilder<List<DocumentSnapshot>>(
          stream: getRecentNotifications(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Text(
                  'No recent notifications found.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return ListView(
              children: snapshot.data!.map((doc) {
                String title = doc.data().toString().contains('title')
                    ? doc['title']
                    : 'No Title';
                String description =
                doc.data().toString().contains('description')
                    ? doc['description']
                    : 'No Description';
                String? imageUrl = doc.data().toString().contains('image')
                    ? doc['image']
                    : null;
                Timestamp timestamp = doc['time'];
                String formattedTime = formatTimestamp(timestamp);
                bool isExpanded = false;

                Widget leadingIcon;
                bool isGlobalNotification =
                    doc.reference.parent.id == 'notifications';
                leadingIcon = isGlobalNotification
                    ? Icon(Icons.notifications, color: Colors.teal, size: 40)
                    : Icon(Icons.dangerous, color: Colors.red, size: 40);

                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return Card(
                      color: imageUrl != null
                          ? Colors.lightBlue.shade50
                          : Colors.lightGreen.shade50,
                      margin:
                      EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: Column(
                        children: [
                          ListTile(
                            leading: GestureDetector(
                              onTap: () {
                                if (imageUrl != null && imageUrl.isNotEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Image.network(imageUrl),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text('Close'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: imageUrl != null && imageUrl.isNotEmpty
                                  ? Image.network(
                                imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                                  : leadingIcon,
                            ),
                            title: Text(
                              title,
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isGlobalNotification)
                                  Text(formattedTime,
                                      style: TextStyle(color: Colors.grey)),
                                SizedBox(height: 5),
                                isExpanded
                                    ? Text(description)
                                    : Text(
                                  '${description.split(' ').take(7).join(' ')}...',
                                ),
                              ],
                            ),
                            trailing: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isExpanded = !isExpanded;
                                });
                              },
                              child: Icon(
                                isExpanded
                                    ? Icons.arrow_drop_up
                                    : Icons.arrow_forward_ios,
                                color: Colors.teal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
