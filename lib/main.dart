import 'package:flutter/material.dart';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_app_installer/flutter_app_installer.dart';
import 'dart:convert';

const String DOWNLOAD_BASE = "http://100.108.137.1:11096/download/myhome";

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
      _onFirstFrame();
    });
  }

  Future<void> _onFirstFrame() async {
    print("checking server status");
    final ok = await _checkServerStatus();
    if (ok) {
      print("checkUpdate");
      await _checkUpdate();
    }
  }

  Future<bool> _checkServerStatus() async {
    try {
      final response = await Dio().get(
        "http://100.108.137.1:11096",
        options: Options(
          sendTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
      );

      final body = response.data;
      if (body is String) {
        try {
          final decoded = jsonDecode(body) as Map<String, dynamic>;
          if (decoded['status'] == 'ok') return true;
        } catch (_) {
          // not JSON or unexpected format
        }
      } else if (body is Map<String, dynamic>) {
        if (body['status'] == 'ok') return true;
      }

      if (!mounted) return false;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("서버 오류"),
          content: const Text("서버 상태가 정상적이지 않습니다 (status != ok)."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인"),
            ),
          ],
        ),
      );
      return false;
    } on DioException catch (e) {
      if (!mounted) return false;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("서버 연결 실패"),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인"),
            ),
          ],
        ),
      );
      print("Server status check error: $e");
      return false;
    } catch (e) {
      if (!mounted) return false;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("서버 오류"),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("확인"),
            ),
          ],
        ),
      );
      print("Server status check error: $e");
      return false;
    }
  }

  Future<void> _checkUpdate() async {
    try {
      final response = await Dio().get(
        "$DOWNLOAD_BASE/metadata.json",
        options: Options(
          sendTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ),
      );

      final metadata = jsonDecode(response.data) as Map<String, dynamic>;
      final packageInfo = await PackageInfo.fromPlatform();

      if (packageInfo.version == metadata["version"]) {
        // already latest - no popup
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
                await _startDownloadWithDialog(metadata);
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

  Future<String> _downloadFile(String pathOrUrl, {ProgressCallback? onReceiveProgress}) async {
    final downloadDir = await getExternalStorageDirectory();
    final target = "${downloadDir!.path}/myhome.apk";

    final url = pathOrUrl.startsWith('http') ? pathOrUrl : '$DOWNLOAD_BASE/$pathOrUrl';

    await Dio().download(url, target, onReceiveProgress: onReceiveProgress);

    return target;
  }

  Future<void> _startDownloadWithDialog(Map metadata) async {
    bool started = false;
    int received = 0;
    int total = 0;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (dialogContext, setState) {
          if (!started) {
            started = true;
            // start download
            final url = metadata["downloadUrl"] as String;
            _downloadFile(url, onReceiveProgress: (count, len) {
              setState(() {
                received = count;
                total = len;
              });
            }).then((target) async {
              // close progress dialog
              if (Navigator.of(dialogContext).canPop()) Navigator.of(dialogContext).pop();
              // notify user and open installer
              if (!mounted) return;
              await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("다운로드 완료"),
                  content: const Text("다운로드가 완료되었습니다. 설치 화면을 엽니다."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("확인"),
                    ),
                  ],
                ),
              );
              final installer = FlutterAppInstaller();
              final result = await installer.installApk(filePath: target);
              print(result);
            }).catchError((e) async {
              if (Navigator.of(dialogContext).canPop()) Navigator.of(dialogContext).pop();
              if (!mounted) return;
              await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("다운로드 실패"),
                  content: Text(e.toString()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("확인"),
                    ),
                  ],
                ),
              );
            });
          }

          double progress = total > 0 ? received / total : 0.0;
          String progressText = total > 0
              ? '${(progress * 100).toStringAsFixed(0)}% (${(received / 1024).toStringAsFixed(0)}KB / ${(total / 1024).toStringAsFixed(0)}KB)'
              : '연결중...';

          return AlertDialog(
            title: const Text('다운로드 중'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: total > 0 ? progress : null),
                const SizedBox(height: 12),
                Text(progressText),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // don't allow cancel for now
                },
                child: const Text('취소'),
              ),
            ],
          );
        });
      },
    );
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