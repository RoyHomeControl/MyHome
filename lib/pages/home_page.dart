import 'package:flutter/material.dart';
import 'package:myhome/pages/memo_editor_page.dart';
import 'package:provider/provider.dart';

import '../providers/home_provider.dart';
import '../widgets/memo_grid.dart';
import '../widgets/trash_area.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {

  const HomePage({super.key});


  @override
  Widget build(BuildContext context) {

    final provider =
        context.watch<HomeProvider>();


    if (provider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }


    if (provider.username == null) {
      return const LoginPage();
    }


    return Scaffold(

      appBar: AppBar(
        title: Text(provider.username!),
      ),

      body: Stack(
        children: [
          MemoGrid(
            memos: provider.memos,
            onTap: (memo) async {
              final result = await MemoEditorPage.open(
                context,
                memo: memo,
                ownerId: provider.username!,
              );

              if (result != null && context.mounted) {
                context.read<HomeProvider>().addOrUpdateMemo(result);
              }
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TrashArea(
            onDelete: (memo) {
              return context.read<HomeProvider>().deleteMemo(memo);
            },
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: () async {
              final result = await MemoEditorPage.open(
                context,
                ownerId: provider.username!,
              );

              if (result != null && context.mounted) {
                context.read<HomeProvider>().addOrUpdateMemo(result);
              }
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}