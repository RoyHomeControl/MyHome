import 'package:flutter/material.dart';

import '../models/memo.dart';


class TrashArea extends StatelessWidget {

  final Future<void> Function(Memo memo)? onDelete;


  const TrashArea({
    super.key,
    this.onDelete,
  });


  @override
  Widget build(BuildContext context) {

    return DragTarget<Memo>(

      builder:
      (context, candidateData, rejectedData) {

        final active =
            candidateData.isNotEmpty;


        return Container(

          padding:
              const EdgeInsets.all(12),


          decoration:
              BoxDecoration(

                color:
                    active
                    ? Colors.red[400]
                    : Colors.red[200],


                borderRadius:
                    BorderRadius.circular(12),
              ),


          child:
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.delete,
                  color: Colors.white,
                ),
              ),
        );
      },


      onAcceptWithDetails:
      (details) {

        onDelete?.call(
          details.data
        );

      },
    );
  }
}