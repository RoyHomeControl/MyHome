import 'package:flutter/material.dart';

import '../models/memo.dart';


class MemoGrid extends StatelessWidget {

  final List<Memo> memos;

  final Function(Memo memo)? onTap;
  final void Function(Rect)? onDragRectChanged;

  const MemoGrid({
    super.key,
    required this.memos,
    this.onTap,
    this.onDragRectChanged,
  });


  @override
  Widget build(BuildContext context) {

    if (memos.isEmpty) {
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

      itemCount: memos.length,

      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),


      itemBuilder: (context, index) {

        final memo = memos[index];


        return Draggable<Memo>(
          data: memo,
          maxSimultaneousDrags: 1,
          onDragUpdate: (details) {
            const cardSize = Size(160, 180);
            final rect = Rect.fromCenter(center: details.globalPosition, width: cardSize.width, height: cardSize.height);
            onDragRectChanged?.call(rect);
          },
          onDragEnd: (_) {
            onDragRectChanged?.call(Rect.zero);
          },
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: 170,
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
              onTap?.call(memo);
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