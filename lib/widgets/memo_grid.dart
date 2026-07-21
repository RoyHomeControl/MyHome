import 'package:flutter/material.dart';

import '../models/memo.dart';

class MemoCardSize {
  static const width = 170.0;
  static const height = 180.0;
}

class MemoGrid extends StatefulWidget {

  final List<Memo> memos;
  final Function(Memo memo)? onTap;
  final Rect? trashRect;
  final ValueChanged<bool>? onTrashHoverChanged;
  final Future<void> Function(Memo)? onDeleteRequest;
  final Future<void> Function(Rect)? onDragUpdate;
  final Future<void> Function(Rect)? onDragRectChanged;

  const MemoGrid({
    super.key,
    required this.memos,
    this.onTap,
    this.onTrashHoverChanged,
    this.onDeleteRequest,
    this.trashRect,
    this.onDragUpdate,
    this.onDragRectChanged,
  });
  
  @override
  State<MemoGrid>  createState() => _MemoGridState();
}

class _MemoGridState extends State<MemoGrid> {
  Rect? currentRect;

  @override
  Widget build(BuildContext context) {

    if (widget.memos.isEmpty) {
      return const Center(
        child: Text(
          '메모가 없습니다.\n+ 버튼을 눌러 메모를 추가하세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      );
    }


    return GridView.builder(

      padding: const EdgeInsets.all(12),

      itemCount: widget.memos.length,

      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),


      itemBuilder: (context, index) {

        final memo = widget.memos[index];

        return Draggable<Memo>(
          data: memo,
          maxSimultaneousDrags: 1,
          onDragUpdate: (details) {
            currentRect = Rect.fromCenter(
              center: details.globalPosition,
              width: MemoCardSize.width,
              height: MemoCardSize.height,
            );

            widget.onDragRectChanged?.call(currentRect!);

            final active =
                widget.trashRect != null &&
                widget.trashRect!.overlaps(currentRect!);

            widget.onTrashHoverChanged?.call(active);
          },
          onDragEnd: (_) async {

            if (currentRect != null &&
                widget.trashRect != null &&
                widget.trashRect!.overlaps(currentRect!)) {

              await widget.onDeleteRequest?.call(memo);

            }

            widget.onTrashHoverChanged?.call(false);

            widget.onDragRectChanged?.call(Rect.zero);

          },
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: MemoCardSize.width,
              height: MemoCardSize.height,
              child: _MemoCard(memo: memo),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.4,
            child: _MemoCard(memo: memo),
          ),
          child: InkWell(

            borderRadius:
                BorderRadius.circular(16),

            onTap: () {
              widget.onTap?.call(memo);
            },


            child: _MemoCard(
              memo: memo,
            ),
          ),
        );
      },
    );
  }
}

class _MemoCard extends StatelessWidget {

  final Memo memo;


  const _MemoCard({
    required this.memo,
  });


  @override
  Widget build(BuildContext context) {

    return Container(

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.yellow[200],

        borderRadius:
            BorderRadius.circular(16),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 8,
          ),
        ],
      ),


      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,


        children: [

          Text(
            memo.title,

            maxLines: 2,

            overflow:
                TextOverflow.ellipsis,

            style:
                const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
          ),


          const SizedBox(height: 8),


          Expanded(

            child: Text(

              memo.content,

              maxLines: 6,

              overflow:
                  TextOverflow.ellipsis,

              style:
                  const TextStyle(
                    fontSize: 14,
                  ),
            ),
          ),


          if (memo.dueAt != null)

            Text(
              '알림: ${_formatDateTime(memo.dueAt!)}',

              style:
                  const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
            ),
        ],
      ),
    );
  }



  String _formatDateTime(DateTime dateTime) {

    return '${dateTime.year.toString().padLeft(4, '0')}-'
        '${dateTime.month.toString().padLeft(2, '0')}-'
        '${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}