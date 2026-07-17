import 'package:flutter/material.dart';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

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
  bool _testMode = false;

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
        options: Options(
          sendTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
      );

      final metadata = jsonDecode(response.data) as Map<String, dynamic>;
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
    } on DioException catch (e) {
      if (e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        if (!mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("업데이트 불가"),
            content: const Text("업데이트 불가능. 연결 설정 또는 서버 상태를 확인해주세요."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("확인"),
              ),
            ],
          ),
        );
        return;
      }
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("업데이트 오류"),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인"),
            ),
          ],
        ),
      );
      print("Error checking update: $e");
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("업데이트 오류"),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인"),
            ),
          ],
        ),
      );
      print("Error checking update: $e");
    }
  }

  Future<void> _downloadAndInstall(Map metadata) async {
    try {
      final dir = await getExternalStorageDirectory();

      final file = "${dir!.path}/myhome.apk";

      await Dio().download(
        metadata["downloadUrl"],
        file,
      );

      //final bytes = await File(file).readAsBytes();

      //final hash = sha256.convert(bytes).toString();

      //if (hash != metadata["sha256"]) {
      //  throw Exception("SHA256 mismatch");
      //}

      await OpenFilex.open(file);
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("다운로드/설치 오류"),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인"),
            ),
          ],
        ),
      );
      print("Error downloading/installing: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MyHome')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('$_count', style: const TextStyle(fontSize: 74)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => setState(() => _testMode = !_testMode),
              child: Text(_testMode ? '테스트 기능 켜짐' : '테스트 기능 끔'),
            ),
            if (_testMode) ...[
              const SizedBox(height: 8),
              const Text(
                '테스트 기능이 실행 중입니다.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _count++),
        child: const Icon(Icons.add),
      ),
    );
  }
}