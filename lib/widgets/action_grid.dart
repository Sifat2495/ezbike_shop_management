import 'package:flutter/material.dart';
import '../employee_management/ui/employee_list_screen.dart';
import '../expense/expense.dart';
import '../purchase_management/payment/supplier_due_list.dart';
import '../sales_management/diller_sale/dealer_sale_page.dart';
import '../sales_management/due/customer_due_list.dart'; 
import '../stock/stock_management/stock_management_page.dart';

class ActionGrid extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;

  ActionGrid(this.screenWidth, this.screenHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          screenHeight * 0.31,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        childAspectRatio: (screenWidth /
            (screenHeight * 0.5)),
        children: [
          _buildGridItem(
            context,
            'assets/icon/book_8998090.png',
            'দেনার খাতা',
            SupplierPage(),
            Colors.yellow.shade100,
            Colors.blue.shade100,
          ),
          _buildGridItem(
            context,
            'assets/icon/analytics_2518147.png',
            'ডিলার সেল',
            DealerSalePage(),
            Colors.blue.shade100,
            Colors.yellow.shade100,
          ),
          _buildGridItem(
            context,
            'assets/icon/due.png',
            'বাকির খাতা',
            DuePage(),
            Colors.blue.shade100,
            Colors.yellow.shade100,
          ),
          _buildGridItem(
            context,
            'assets/icon/employee.png',
            'কর্মচারী',
            EmployeeListScreen(),
            Colors.blue.shade100,
            Colors.yellow.shade100,
          ),
          _buildGridItem(
            context,
            'assets/icon/wallet_1747291.png',
            'খরচের হিসাব',
            ExpensePage(),
            Colors.yellow.shade100,
            Colors.blue.shade100,
          ),
          _buildGridItem(
            context,
            'assets/icon/logistic-distribution_14669990.png',
            'প্রোডাক্ট স্টক',
            StockManagementPage(),
            Colors.yellow.shade100,
            Colors.blue.shade100,
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, String assetPath, String label,
      Widget? page, Color color1, Color color2) {
    return InkWell(
      onTap: () {
        if (page != null) {
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => page,
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;

                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                var offsetAnimation = animation.drive(tween);

                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
            ),
          );
        }
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color1, color2],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                assetPath,
                width: 50,
                height: 50,
              ),
              SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
