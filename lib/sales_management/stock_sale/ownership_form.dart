import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:open_file/open_file.dart';
import 'dart:convert';


String formatDateTime(String transferDate) {
  DateTime parsedDate = DateTime.parse(transferDate);
  String formattedDate = DateFormat('dd-MM-yyyy', 'bn').format(parsedDate); 
  String formattedTime = DateFormat('hh:mm a', 'bn').format(parsedDate); 
  return '$formattedDate; $formattedTime';
}


String formatNumber(num number) {
  return NumberFormat.decimalPattern('bn').format(number);
}


Future<void> generateAndOpenOwnershipTransferPdf({
  required String customerName,
  required String fatherName,
  required String motherName,
  required String phone,
  required String presentAddress,
  required String permanentAddress,
  required String saleDate,
  required String chassis,
  required String batteryName,
  required String brand,
  required String model,
  required String color,
  required double totalPrice,
  required double advance,
  required double due,
}) async {
  
  final ByteData bytes = await rootBundle.load('assets/watermark.png');
  final String base64Image = base64Encode(bytes.buffer.asUint8List());

  final ByteData logoBytes = await rootBundle.load('assets/logo.png');
  final String base64LogoImage = base64Encode(logoBytes.buffer.asUint8List());

  
  String htmlContent = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Form Design</title>
    <style>
        body {
            font-family: 'SolaimanLipi', sans-serif;
            margin: 0;
            padding: 0;
            background-color: #f9f9f9;
            font-size: 20px; /* Increased font size */
            color: #333;
        }

        .watermark {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            opacity: 0.15;
            z-index: -1;
            width: 500px;
        }

        @page {
            size: A4;
            margin: 10mm;
        }

        .container {
            width: 100%;
            margin: 0 auto;
            padding: 20px;
            background: #ffffff;
            border: 1px solid #ddd;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
            line-height: 1.8;
        }

        .header, .footer {
            text-align: left;
            padding: 10px;
            border-bottom: 3px solid #4CAF50;
        }

        .footer {
            border-top: 3px solid #4CAF50;
            margin-top: 20px;
            text-align: center;
            background-color: #f2f2f2;
        }

        .header h1 {
            font-size: 35px; /* Increased header font size */
            margin: 0;
            color: #4CAF50;
        }

        .header p {
            font-size: 20px; /* Increased font size */
            margin: 5px 0;
            color: #333;
        }

        .header h2 {
            font-size: 26px;
            color: #ff5722;
            text-align: center;
        }

    .form-group {
        display: flex;
        align-items: center;
        margin-bottom: 15px;
    }

    .form-group label {
        font-weight: bold;
        color: #555;
        font-size: 20px;
        margin-right: 10px;
        white-space: nowrap; /* Ensure text does not wrap */
    }

    .form-group span {
        display: inline-block;
        padding: 10px;
        font-size: 22px;
        border: 1px solid #ccc;
        border-radius: 5px;
        background-color: #f9f9f9;
        width: 100%;
        max-width: 800px; /* Set a fixed width */
        height: 30px; /* Set a fixed height */
        line-height: 20px; /* Center text vertically */
    }

        .form-group-row {
            display: flex;
            justify-content: space-between;
            margin-bottom: 5px; /* Decreased margin-bottom */
        }

        .form-group-row .form-group {
            width: 48%;
        }

        .form-group-signature {
            display: flex;
            justify-content: space-between;
            margin-top: 80px;
        }

        .form-group-signature div {
            flex: 1;
            text-align: center;
            margin: 0 12px;
            padding-top: 2px;
            border-top: 2px solid #ddd;
        }

        .form-group-signature div span {
            display: block;
            margin-top: 5px;
            font-weight: bold;
            font-size: 20px; /* Increased font size */
            color: #333;
        }

        .footer .thank-you {
            font-size: 20px; /* Increased footer font size */
            color: #ff5722;
            font-weight: bold;
            margin: 5px 0;
        }

        @media print {
            body {
                font-size: 18px;
            }

            .container {
                padding: 10px;
            }

            .header, .footer {
                text-align: center;
                padding: 5px;
                border: none;
            }

            .footer .thank-you {
                font-size: 18px;
            }

            .submit-btn {
                display: none;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div style="display: flex; align-items: center;">
                <img src="data:image/png;base64,$base64LogoImage" class="logo" style="width: 120px; height: auto; margin-right: 15px;" />
<div style="border-left: 3px solid #4CAF50; padding-left: 15px; line-height: 1.2;">
    <h1>মেসার্স হাজী অটো হাউজ</h1>
    <p>ঠিকানাঃ দিঘারকান্দা, ঢাকা বাইপাস মোড়,<br>(শামীম সাহেবের পাম্প উত্তর সলগ্ন) ব্রীজ রোড, ময়মনসিংহ ।</p>
    <p>মোবাইল: 01234567899, 01234567899</p>
</div>

            </div>
        </div>
<hr style="border: 2px solid #4CAF50; margin-top: 10px; margin-bottom: 20px;">
        <form>
            <div class="form-group">
    <label for="customerName">ক্রেতার নাম:</label>
    <span>$customerName</span>
</div>
<div class="form-group">
    <label for="fatherName">পিতার নাম:</label>
    <span>$fatherName</span>
</div>
<div class="form-group">
    <label for="motherName">মাতার নাম:</label>
    <span>$motherName</span>
</div>
<div class="form-group">
    <label for="address">ঠিকানা:</label>
    <span>$permanentAddress</span>
</div>
<div class="form-group">
    <label for="mobile">মোবাইল:</label>
    <span>$phone</span>
</div>

            <div class="form-group-row">
                <div class="form-group">
                    <label for="brand">ব্র্যান্ড:</label>
                    <span>$brand</span>
                </div>
                <div class="form-group">
                    <label for="model">মডেল:</label>
                    <span>$model</span>
                </div>
            </div>
            <div class="form-group-row">
                <div class="form-group">
                    <label for="color">কালার:</label>
                    <span>$color</span>
                </div>
                <div class="form-group">
                    <label for="chassis">চ্যাসিস:</label>
                    <span>$chassis</span>
                </div>
            </div>
            <div class="form-group-row">
                <div class="form-group">
                    <label for="battery">ব্যাটারির নাম:</label>
                    <span>$batteryName</span>
                </div>
                <div class="form-group">
                    <label for="price">মূল্য:</label>
                    <span>${formatNumber(totalPrice)}</span>
                </div>
            </div>
            <div class="form-group-row">
                <div class="form-group">
                    <label for="advance">জমা: </label>
                    <span>${formatNumber(advance)}</span>
                </div>
                <div class="form-group">
                    <label for="due">বাকী:</label>
                    <span>${formatNumber(due)}</span>
                </div>
            </div>

            <div class="form-group-signature">
                <div>
                    <span>ক্রেতার স্বাক্ষর</span>
                </div>
                <div>
                    <span>জামিনদারের স্বাক্ষর</span>
                </div>
                <div>
                    <span>বিক্রেতার স্বাক্ষর</span>
                </div>
            </div>
        </form>

        <div class="footer">
            <p class="thank-you">৬ মাসের গ্যারান্টির ব্যাটারী নষ্ট হলে নতুন ব্যাটারী দেওয়া হয়।</p>
            <p class="thank-you">ধন্যবাদ... আবার আসবেন।</p>
        </div>
    </div>
</body>
</html>
  """;

  
  Directory tempDir = await getTemporaryDirectory();
  String tempPath = tempDir.path;
  File pdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(htmlContent, tempPath, "ownership_transfer");

  
  await OpenFile.open(pdfFile.path);
}