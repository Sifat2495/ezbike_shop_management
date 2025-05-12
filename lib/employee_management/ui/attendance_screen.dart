import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/attendance_service.dart';

class AttendanceScreen extends StatefulWidget {
  final String employeeId;

  AttendanceScreen({Key? key, required this.employeeId}) : super(key: key);

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  Map<String, String> _attendanceData = {};

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  void _loadAttendanceData() async {
    String? userId = await getCurrentUserId(); 
    if (userId != null) {
      String employeeId = widget.employeeId;
      Map<String, String> data =
      await _attendanceService.fetchMonthlyAttendance(
        userId,
        employeeId,
        DateTime.now(),
      );
      setState(() {
        _attendanceData = data;
      });
    }
  }

  Future<String?> getCurrentUserId() async {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _editAttendance(DateTime date) async {
    String? userId = await getCurrentUserId(); 
    if (userId != null) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);

      
      bool hasAttendance = _attendanceData.containsKey(formattedDate);

      
      bool? newStatus = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("হাজিরা এডিট করুন"),
          content: Text("এই তারিখে কর্মচারী:"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), 
              child: Text("উপস্থিত ছিল", style: TextStyle(color: Colors.green)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), 
              child: Text("অনুপস্থিত ছিল", style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      
      if (newStatus != null) {
        
        if (!hasAttendance ||
            _attendanceData[formattedDate] !=
                (newStatus ? 'present' : 'absent')) {
          await _attendanceService.markAttendance(
            userId,
            widget.employeeId,
            date,
            newStatus,
          );
          _loadAttendanceData(); 
        }
      }
    }
  }

  Color _getDayColor(DateTime day) {
    String dayKey = DateFormat('yyyy-MM-dd').format(day);

    
    if (day.year == DateTime.now().year &&
        day.month == DateTime.now().month &&
        day.day == DateTime.now().day) {
      
      if (_attendanceData.containsKey(dayKey)) {
        return _attendanceData[dayKey] == 'present' ? Colors.green : Colors.red;
      }
    }

    
    if (_attendanceData.containsKey(dayKey)) {
      return _attendanceData[dayKey] == 'present' ? Colors.green : Colors.red;
    }

    return Colors.grey; 
  }

  void _markAttendance(bool isPresent) async {
    String? userId = await getCurrentUserId(); 
    if (userId != null) {
      await _attendanceService.markAttendance(
        userId,
        widget.employeeId,
        DateTime.now(),
        isPresent,
      );
      _loadAttendanceData(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('কর্মচারী হাজিরা'),
        automaticallyImplyLeading: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TableCalendar(
              locale: 'bn_BD',
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2030, 1, 1),
              focusedDay: DateTime.now(),
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {
                CalendarFormat.month: 'Month', 
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  bool isFutureDate = day.isAfter(
                      DateTime.now()); 
                  return GestureDetector(
                    onTap: !isFutureDate
                        ? () => _editAttendance(day)
                        : null, 
                    child: Container(
                      margin: EdgeInsets.all(4.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getDayColor(
                            day), 
                      ),
                      child: Text(DateFormat.d('bn_BD').format(day)),
                    ),
                  );
                },
                todayBuilder: (context, day, focusedDay) {
                  bool isFutureDate = day.isAfter(
                      DateTime.now()); 
                  return GestureDetector(
                    onTap: !isFutureDate
                        ? () => _editAttendance(day)
                        : null, 
                    child: Container(
                      margin: EdgeInsets.all(0.0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _getDayColor(day), 
                      ),
                      child: Text(
                        DateFormat.d('bn_BD').format(day),
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                            FontWeight.bold), 
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _markAttendance(true),
                  child: Text(
                    'উপস্থিত',
                    style: TextStyle(
                        color: Colors.green[700], fontWeight: FontWeight.bold),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _markAttendance(false),
                  child: Text(
                    'অনুপস্থিত',
                    style: TextStyle(
                        color: Colors.red[700], fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
