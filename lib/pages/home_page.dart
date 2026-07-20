import 'package:flutter/material.dart';
import 'package:myhome/pages/memo_editor_page.dart';
import 'package:provider/provider.dart';

import '../core/update_service.dart';
import '../providers/home_provider.dart';
import '../widgets/memo_grid.dart';
import '../widgets/trash_area.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _updateService = UpdateService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateService.runUpdateFlow(context);
      }
    });
  }

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
          Scrollbar(
            child: MemoGrid(
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
          ),
          Positioned(
            left: 16,
            bottom: 16,
            child: TrashArea(
              onDelete: (memo) {
                return context.read<HomeProvider>().deleteMemo(memo);
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
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
    );
  }
}