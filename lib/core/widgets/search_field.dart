import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.controller,
    this.hint = 'Cari',
    this.onChanged,
  });

  final TextEditingController? controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: EcosystemSpacing.x3,
          vertical: EcosystemSpacing.x3,
        ),
      ),
    );
  }
}
