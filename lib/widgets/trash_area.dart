import 'package:flutter/material.dart';

import '../models/memo.dart';

class TrashArea extends StatelessWidget {
  final Future<void> Function(Memo memo)? onDelete;
  final Rect? dragRect;

  const TrashArea({
    super.key,
    this.onDelete,
    this.dragRect,
  });

  @override
  Widget build(BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    final active = dragRect != null && renderBox != null && Rect.fromLTWH(
            renderBox.localToGlobal(Offset.zero).dx,
            renderBox.localToGlobal(Offset.zero).dy,
            renderBox.size.width,
            renderBox.size.height,
          ).overlaps(dragRect!);

    return DragTarget<Memo>(
      onWillAcceptWithDetails: (details) => true,
      onAcceptWithDetails: (details) {
        onDelete?.call(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: 56,
          height: 56,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active || candidateData.isNotEmpty ? Colors.red[400] : Colors.red[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}