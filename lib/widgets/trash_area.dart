import 'package:flutter/material.dart';

class TrashArea extends StatelessWidget {

  final bool active;

  const TrashArea({
    super.key,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {

    return Container(
      width: 56,
      height: 56,

      decoration: BoxDecoration(
        color: active
            ? Colors.red
            : Colors.red[200],
        borderRadius: BorderRadius.circular(12),
      ),

      child: const Icon(
        Icons.delete,
        color: Colors.white,
      ),
    );
  }
}