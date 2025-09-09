import 'package:flutter/material.dart';
import 'package:marketlinkapp/components/auto_size_text.dart';
import 'package:marketlinkapp/components/colors.dart';

Widget editableTextField({
  required String label,
  required TextEditingController controller,
  required bool isEditing,
  required VoidCallback onToggle,
  required VoidCallback onSave,
  String? hintText,
  TextStyle? style,
  TextStyle? hinstyle,
  bool isPhone = false,

}) {

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CustomText(
        textLabel: label,
        fontSize: 16,
        textColor: Colors.grey.shade700,
        letterSpacing: 2,
      ),
      const SizedBox(height: 10),
      TextFormField(
        controller: controller,
        readOnly: !isEditing,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        maxLength: isPhone ? 11 : null ,
        style: style ?? TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: hinstyle,
          suffixIcon: IconButton(
            icon: Icon(
              isEditing ? Icons.check : Icons.edit,
              color: isEditing ? AppColors.appGreen : AppColors.primary,
            ),
            onPressed: () {
              if (isEditing) onSave();
              onToggle();
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      const SizedBox(height: 15),
    ],
  );
}