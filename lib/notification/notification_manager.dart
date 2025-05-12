import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationManager {
  static final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  
  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    
    await createNotificationChannel();
  }

  Future<void> createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'main_channel',
      'Main Channel',
      description: 'This channel is used for general notifications.',
      importance: Importance.high,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  
  Future<void> scheduleNotification(int id, String title, String description, DateTime scheduledDate) async {
    
    await _flutterLocalNotificationsPlugin.cancel(id);

    
    if (scheduledDate.isBefore(DateTime.now())) {
      print('Scheduled date must be in the future');
      return;
    }

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      description,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'main_channel',
          'Main Channel',
          channelDescription: 'This channel is used for general notifications.',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    print('Notification scheduled for: $scheduledDate');
  }

  
  Future<void> processUserNotifications(String userId) async {
    final CollectionReference userNotificationsRef = FirebaseFirestore.instance
        .collection('collection name')
        .doc(userId)
        .collection('user_notifications');

    
    final QuerySnapshot querySnapshot = await userNotificationsRef.get();

    List<QueryDocumentSnapshot> documents = querySnapshot.docs;

    for (var doc in documents) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      
      String title = data['title'] ?? 'Default Title'; 
      String description = data['description'] ?? 'Default description'; 
      Timestamp timestamp = data['time'] ?? Timestamp.fromDate(DateTime.now()); 
      DateTime notificationTime = timestamp.toDate();

      
      final DateTime twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      if (notificationTime.isBefore(twoDaysAgo)) {
        
        await doc.reference.delete();
        continue;
      }

      
      await scheduleNotification(
        doc.hashCode, 
        title,
        description,
        notificationTime,
      );
    }
  }
}
