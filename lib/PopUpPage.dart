import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PopUpPage extends StatefulWidget {
  const PopUpPage({Key? key}) : super(key: key);

  @override
  _PopUpPageState createState() => _PopUpPageState();
}

class _PopUpPageState extends State<PopUpPage> {
  String? title;
  String? image;
  String? text1;
  String? text2;
  String? text3;

  @override
  void initState() {
    super.initState();
    _fetchPopupData();
  }

  Future<void> _fetchPopupData() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('PopUpPage')
          .where('about_permission', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();

        setState(() {
          title = data['title'];
          image = data['image'];
          text1 = data['text_1'];
          text2 = data['text_2'];
          text3 = data['text_3'];
        });
      }
    } catch (e) {
      print("Error fetching popup data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.of(context).size.width;
    var screenHeight = MediaQuery.of(context).size.height;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      backgroundColor: Colors.white,
      contentPadding: EdgeInsets.all(screenWidth * 0.05),
      content: SingleChildScrollView(
        child: title == null && image == null && text1 == null && text2 == null && text3 == null
            ? Center(
          child: CircularProgressIndicator(),
        )
            : Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            if (title != null && title!.isNotEmpty)
              if (title != null && title!.isNotEmpty)
                Center(
                  child: Text(
                    title!,
                    style: TextStyle(
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            if (title != null && title!.isNotEmpty)
              SizedBox(height: screenHeight * 0.02),

            
            if (image != null && image!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Image.network(
                  image!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: screenHeight * 0.25,
                ),
              ),
            if (image != null && image!.isNotEmpty)
              SizedBox(height: screenHeight * 0.02),

            
            if (text1 != null && text1!.isNotEmpty)
              Center(
                child: Text(
                  text1!,
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (text1 != null && text1!.isNotEmpty)
              SizedBox(height: screenHeight * 0.015),

            
            if (text2 != null && text2!.isNotEmpty)
              Text(
                text2!,
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  color: Colors.black87,
                ),
              ),
            if (text2 != null && text2!.isNotEmpty)
              SizedBox(height: screenHeight * 0.015),

            
            if (text3 != null && text3!.isNotEmpty)
              Text(
                text3!,
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  color: Colors.black87,
                ),
              ),
          ],
        ),
      ),
      actions: [
        Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.1,
                vertical: screenHeight * 0.015,
              ),
            ),
            child: Text(
              'Close',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
