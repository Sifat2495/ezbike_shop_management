import 'package:flutter/material.dart';
import '../models/employee_model.dart';
import '../services/employee_service.dart';
import 'employee_detail_screen.dart';
import 'add_employee_screen.dart';
import 'salary_transaction_screen.dart';
import 'attendance_screen.dart';

class EmployeeListScreen extends StatelessWidget {
  final EmployeeService employeeService = EmployeeService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('কর্মচারীর তালিকা')),
      body: StreamBuilder<List<Employee>>(
        stream: employeeService.getEmployees(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final employees = snapshot.data!;
            return ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, index) {
                final employee = employees[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: employee.imageUrl != null &&
                        employee.imageUrl!.isNotEmpty
                        ? NetworkImage(employee.imageUrl!)
                        : AssetImage('assets/placeholder.png') as ImageProvider,
                  ),
                  title: Text(employee.name),
                  subtitle: Text(employee.phoneNumber.toString()),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmployeeDetailScreen(employee: employee),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.money,
                            color: Colors
                                .green), 
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SalaryTransactionScreen(
                                  employee:
                                  employee), 
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.calendar_month,
                            color:
                            Colors.green), 
                        onPressed: () {
                          showDialog(
                            context: context,
                            barrierDismissible: true, 
                            builder: (BuildContext context) {
                              
                              double screenWidth = MediaQuery.of(context).size.width;
                              double screenHeight = MediaQuery.of(context).size.height;

                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20), 
                                ),
                                child: Container(
                                  width: screenWidth * 0.8, 
                                  height: screenHeight * 0.75, 
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20), 
                                    child: AttendanceScreen(
                                      employeeId: employee.id, 
                                    ),
                                  ),
                                ),
                              );
                            },
                          );

                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('কর্মচারী ডিলিট করুন'),
                              content: Text(
                                  'আপনি ${employee.name} কর্মচারীর সকল তথ্য ডিলিট করতে চান?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text('হ্যাঁ',
                                      style: TextStyle(color: Colors.red)),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: Text('না'),
                                ),
                              ],
                            ),
                          );

                          if (confirmDelete ?? false) {
                            await employeeService.deleteEmployee(employee.id);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('দুঃখিত: ${snapshot.error}'));
          }
          return Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20), 
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20), 
                  child: AddEmployeeScreen(),
                ),
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
