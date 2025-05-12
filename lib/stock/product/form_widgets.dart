import 'package:flutter/material.dart';
import 'package:flutter/src/services/text_formatter.dart';

Widget buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon,
    {TextInputType keyboardType = TextInputType.text,
      TextStyle? style,
      int? maxLines = 1,
      required List<TextInputFormatter> inputFormatters,
      Widget? suffixIcon}) {

  return TextField(
    controller: controller,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      isDense: true,
    ),
    maxLines: maxLines,
    keyboardType: keyboardType,
    inputFormatters: inputFormatters,
  );
}

Widget buildDropdown(String label, String selectedValue, List<String> items,
    Function(String?)? onChanged) {
  return DropdownButtonFormField<String>(
    decoration: InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
    value: selectedValue,
    items: items.map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList(),
    onChanged: onChanged,
  );
}

Widget buildTitle(String title) {
  return Text(
    title,
    style: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
  );
}
