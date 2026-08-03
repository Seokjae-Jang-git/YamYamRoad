import 'package:flutter/material.dart';

class MenuSelectModal extends StatelessWidget {
  final List<String> menuOptions;
  final String selectedFilter;

  static const Color pointCoralRed = Color(0xFFFF6B57);
  static const Color deepChocolate = Color(0xFF4A3225);
  static const Color creamyIvory = Color(0xFFFFFDF9);

  const MenuSelectModal({
    super.key,
    required this.menuOptions,
    required this.selectedFilter,
  });

  static Future<String?> show(
      BuildContext context, {
        required List<String> menuOptions,
        required String selectedFilter,
      }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: creamyIvory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => MenuSelectModal(
        menuOptions: menuOptions,
        selectedFilter: selectedFilter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '메뉴 선택',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: deepChocolate,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: deepChocolate),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Divider(color: deepChocolate.withOpacity(0.12)),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: menuOptions.map((menu) {
                    final bool isSelected = menu == selectedFilter;
                    return ChoiceChip(
                      showCheckmark: false,
                      label: Text(menu),
                      selected: isSelected,
                      selectedColor: pointCoralRed,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : deepChocolate,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected ? pointCoralRed : deepChocolate.withOpacity(0.15),
                        ),
                      ),
                      onSelected: (_) => Navigator.pop(context, menu),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}