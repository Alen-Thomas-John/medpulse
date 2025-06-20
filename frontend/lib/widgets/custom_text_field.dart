import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon; // 🟢 Added optional icon parameter
  final bool isNumber; // 🟢 Added isNumber parameter

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.icon, // 🟢 Optional, can be null
    this.isNumber = false, // 🟢 Defaults to false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon) : null, // 🟢 Show icon if provided
        border: OutlineInputBorder(),
      ),
    );
  }
}
