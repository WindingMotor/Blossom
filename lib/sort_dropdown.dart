import 'package:flutter/material.dart';

class SortDropdownMenu extends StatelessWidget {
  final Function(String?) onChanged;
  final List<String> items;
  final String? selectedItem;
  final String currentOption;
  final bool isSortingReversed; // Accept isSortingReversed as a parameter

  const SortDropdownMenu({
    super.key,
    required this.onChanged,
    required this.items,
    this.selectedItem,
    required this.currentOption,
    required this.isSortingReversed, // Make isSortingReversed required
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.menu_open_rounded),
            initialValue: selectedItem,
            tooltip: 'Sort by',
            onSelected: onChanged,
            itemBuilder: (BuildContext context) {
              return items.map<PopupMenuEntry<String>>((String value) {
                return PopupMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList();
            },
          ),
        ),
      ],
    );
  }
}
