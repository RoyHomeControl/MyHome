import 'package:flutter/material.dart';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyHome',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const CounterPage(),
    );
  }
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _count = 0;

  @override
  void initState() {
    super.initState();

    print("initState");

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("checkUpdate");
      _checkUpdate();
    });
  }

  Future<void> _checkUpdate() async {
    try {
      final response = await Dio().get(
        "http://100.108.137.1:11096/download/myhome/metadata.json",
      );

      final metadata = response.data;
      final packageInfo = await PackageInfo.fromPlatform();

      if (packageInfo.version == metadata["version"]) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("업데이트"),
            content: const Text("최신 버전입니다."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("확인"),
              ),
            ],
          )
        );
        return;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("업데이트"),
          content: const Text("새 버전이 있습니다."),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _downloadAndInstall(metadata);
              },
              child: const Text("확인"),
            ),
          ],
        ),
      );
    } catch (e) {
      print("Error checking update: $e");
    }
  }

  Future<void> _downloadAndInstall(Map metadata) async {
    final dir = await getTemporaryDirectory();

    final file = "${dir.path}/myhome.apk";

    await Dio().download(
      metadata["downloadUrl"],
      file,
    );

    final bytes = await File(file).readAsBytes();

    final hash = sha256.convert(bytes).toString();

    if (hash != metadata["sha256"]) {
      throw Exception("SHA256 mismatch");
    }

    await OpenFilex.open(file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MyHome')),
      body: Center(
        child: Text('$_count', style: const TextStyle(fontSize: 74)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _count++),
        child: const Icon(Icons.add),
      ),
    );
  }
}