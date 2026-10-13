import 'package:flutter/material.dart';

/// Reusable search text field with clear button.
class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const SearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onSubmitted,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded),
                onPressed: onClear,
                tooltip: 'Clear search',
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
    );
  }
}

