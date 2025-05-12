import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_html_to_pdf/flutter_html_to_pdf.dart';
import 'package:open_file/open_file.dart';
import 'dart:convert';


String formatDateTime(String dueCollectionDate) {
  try {
    DateTime parsedDate = DateTime.parse(dueCollectionDate);
    String formattedDate = DateFormat('dd-MM-yyyy', 'bn').format(parsedDate); 
    String formattedTime = DateFormat('hh:mm a', 'bn').format(parsedDate); 
    return '$formattedDate; $formattedTime';
  } catch (e) {
    
    return '';
  }
}


String formatNumber(num number) {
  return NumberFormat.decimalPattern('bn').format(number);
}


Future<void> generateAndOpenDuePdf({
  required String customerName,
  required String customerPhone,
  required String presentAddress,
  required double previousDue,
  required double discount,
  required double cashPayment,
  required double remainingDue,
  required String dueCollectionDate,
  required String nextDate,
}) async {
  
  final ByteData bytes = await rootBundle.load('assets/watermark.png');
  final String base64Image = base64Encode(bytes.buffer.asUint8List());

  final ByteData logoBytes = await rootBundle.load('assets/logo.png');
  final String base64LogoImage = base64Encode(logoBytes.buffer.asUint8List());

  
  String htmlContent = """
<!DOCTYPE html>
<html>

<head>
    <style>
        @page {
            size: A4;
            margin: 13mm;
            margin-bottom: 4mm;
            background-color: #cff0fa;
        }

        body {
            font-family: 'SolaimanLipi', sans-serif;
            margin: 0;
            padding: 0;
            font-size: 20px;
            /* Increased base font size */
        }

        .header,
        .footer {
            text-align: left;
            padding: 10px;
        }

        .header {
            border-bottom: 2px solid black;
        }

        .footer {
            border-top: 2px solid black;
            margin-top: 10px;
        }

        .logo {
            width: 150px;
            height: auto;
            margin: 0 auto;
        }

        .header h1 {
            font-size: 36px;
            /* Increased business name font size */
            margin: 5px 0;
        }

        .header p {
            font-size: 20px;
            /* Increased business details font size */
            margin: 2px 0;
        }

        .section {
            margin: 1px 16px;
            font-size: 22px;
            /* Increased content font size */
        }

        .table-container {
            margin: 1px 18px;
            overflow-x: auto;
        }

        .table {
            width: 100%;
            border-collapse: collapse;
            font-size: 22px;
            /* Increased table font size */
            background-color: rgba(255, 255, 255, 0.1);
        }

        .table th,
        .table td {
            border: 1px solid black;
            padding: 10px;
            /* Added more padding */
            text-align: right;
        }

        .table th {
            background-color: rgba(242, 242, 242, 0.1);
            text-align: center;
        }

        .table tr:nth-child(even) {
            background-color: rgba(249, 249, 249, 0.1);
        }

        .table tr:nth-child(odd) {
            background-color: rgba(255, 255, 255, 0.1);
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

        .summary {
            text-align: right;
            margin: 18px;
            font-size: 18px;
            /* Increased summary font size */
        }

        .summary p {
            margin: 5px 0;
        }

        .form-group-signature {
            display: flex;
            justify-content: space-between;
            margin-top: 70px;
        }

        .form-group-signature div {
            flex: 1;
            text-align: center;
            margin: 0 12px;
            padding-top: 2px;
            border-top: 2px solid #0a0000;
        }

        .form-group-signature div span {
            display: block;
            margin-top: 5px;
            font-weight: bold;
            font-size: 20px;
            /* Increased font size */
            color: #0a0000;
        }

        .thank-you {
            font-size: 20px;
            /* Made thank-you message more prominent */
            font-style: italic;
            font-weight: bold;
        }
    </style>
</head>

<body>
    <img src="data:image/png;base64,$base64Image" class="watermark" />
    <div style="background-color: #fafaa7; padding: 10px;">
        <div class="header">
            <div style="display: flex; align-items: center;">
                <img src="data:image/png;base64,$base64LogoImage" class="logo" style="margin-right: 10px;" />
                <div style="border-left: 2px solid black; padding-left: 15px;">
                    <h1>মেসার্স হাজী অটো হাউজ</h1>
                    <p>ঠিকানাঃ দিঘারকান্দা, ঢাকা বাইপাস মোড়,<br>(শামীম সাহেবের পাম্প উত্তর সলগ্ন) ব্রীজ রোড, ময়মনসিংহ ।
                    </p>
                    <p>মোবাইল: 01234567899, 01234567899</p>
                </div>
            </div>
            <div style="border-top: 2px solid black; margin-top: 5px;">
                <h2 style="text-align: center; margin-top: 8px; margin-bottom: 0px;">কিস্তি আদায়ের রশিদ</h2>
            </div>
        </div>
    </div>
    <div class="section" style="line-height: 0.5; margin-bottom: 0;">
        <p><strong>নাম: $customerName</strong></p>
        <p><strong>মোবাইল: $customerPhone</strong></p>
        <p><strong>ঠিকানা:</strong> $presentAddress</p>
    </div>
    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 5px; margin-left: 18px;">
        <h3 style="margin-bottom: 3px;"><span style="font-weight: bold;">কিস্তি আদায়ের তারিখ:</span> <span
                style="font-weight: normal;">${formatDateTime(dueCollectionDate)}</span></h3>
    </div>
    <div style="display: flex; justify-content: space-between; align-items: center; margin-top: 5px; margin-left: 18px;">
        <h3 style="margin-top: 3px;"><span style="font-weight: bold;">পরবর্তী কিস্তি আদায়ের তারিখ:</span> <span
                style="font-weight: normal;">${formatDateTime(nextDate)}</span></h3>
    </div>
    <div class="summary">
        <div style="text-align: left;">
            <table
                style="display: inline-block; width: auto; margin-left: auto; margin-right: auto; border-collapse: collapse; font-size: 22px;">
                <tr>
                    <td style="text-align: left; padding: 6px; font-size: 26px; font-weight: bold;">পূর্বের বকেয়া
                    </td>
                    <td style="text-align: right; padding: 6px; font-size: 26px; font-weight: bold;">:</td>
                    <td style="text-align: right; padding: 6px; font-size: 26px; font-weight: bold;">
                        ${formatNumber(previousDue)}/-</td>
                </tr>
                <tr>
                    <td style="text-align: left; padding: 6px; font-size: 26px; font-weight: bold;">ডিস্কাউন্ট</td>
                    <td style="text-align: right; padding: 6px; font-size: 26px; font-weight: bold;">:</td>
                    <td style="text-align: right; padding: 6px; font-size: 26px; font-weight: bold;">
                        ${formatNumber(discount)}/-</td>
                </tr>
                <tr>
                    <td style="text-align: left; padding: 6px; font-size: 26px; font-weight: bold; color: green;">পরিশোধ</td>
                    <td style="text-align: right; padding: 6px; font-size: 26px; font-weight: bold; color: green;">:</td>
                    <td style="text-align: right; padding: 6px; font-size: 26px; font-weight: bold; color: green;">
                        ${formatNumber(cashPayment)}/-</td>
                </tr>
                <tr>
                    <td colspan="3" style="padding: 0;"><hr style="border: 1px solid black; margin: 0;"></td>
                </tr>
                <tr>
                    <td style="text-align: left; padding: 6px; font-size: 26px; font-weight: bold; color: red;">বর্তমান বাকী
                    </td>
                    <td style="text-align: right; padding: 6px; font-size: 26px; font-weight: bold; color: red;">:</td>
                    <td style="text-align: right; padding: 6px; font-size: 26px; font-weight: bold; color: red;">
                        ${formatNumber(remainingDue)}/-</td>
                </tr>
            </table>
        </div>
        <div class="form-group-signature">
            <div>
                <span>ক্রেতার স্বাক্ষর</span>
            </div>
            <div>
                <span>বিক্রেতার স্বাক্ষর</span>
            </div>
        </div>

    </div>
    <div class="footer" style="text-align: center;">
        <p class="thank-you">৬ মাসের গ্যারান্টির ব্যাটারী নষ্ট হলে নতুন ব্যাটারী দেওয়া হয়।</p>
        <p class="thank-you">ধন্যবাদ... আবার আসবেন।</p>
    </div>
</body>

</html>


  """;

  
  Directory tempDir = await getTemporaryDirectory();
  String tempPath = tempDir.path;
  File pdfFile = await FlutterHtmlToPdf.convertFromHtmlContent(htmlContent, tempPath, "receipt");

  
  await OpenFile.open(pdfFile.path);
}