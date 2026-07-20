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
  Offset? _dragPosition;

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
              onDragPositionChanged: (position) {
                setState(() {
                  _dragPosition = position;
                });
              },
              onTap: (memo) async {
                final result = await MemoEditorPage.open(
                  context,
                  memo: memo,
                  ownerId: provider.username!,
                );

                if (!context.mounted) return;
                if (result?.deleted == true) {
                  context.read<HomeProvider>().removeMemo(memo);
                } else if (result?.memo != null) {
                  await context.read<HomeProvider>().addOrUpdateMemo(result!.memo!);
                }
              },
            ),
          ),
          Positioned(
            left: 16,
            bottom: 60,
            child: SizedBox(
              width: 56,
              height: 56,
              child: TrashArea(
                dragPosition: _dragPosition,
                onDelete: (memo) {
                  return context.read<HomeProvider>().deleteMemo(memo);
                },
              ),
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

          if (!context.mounted) return;
          if (result?.memo != null) {
            await context.read<HomeProvider>().addOrUpdateMemo(result!.memo!);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}