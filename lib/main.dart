import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_installer/flutter_app_installer.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

const serverUrl = 'http://100.108.137.1:11096';
const downloadBase = 'http://100.108.137.1:11096/download/myhome';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyHome',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _dio = Dio(BaseOptions(
    sendTimeout: const Duration(seconds: 2),
    receiveTimeout: const Duration(seconds: 2),
  ));
  int _count = 0;
  bool _testMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    if (await _checkServer()) await _checkUpdate();
  }

  Future<void> _showAlert(String title, String message,
      {List<Widget>? actions, bool barrierDismissible = true}) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: actions ?? [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          )
        ],
      ),
    );
  }

  Future<bool> _checkServer() async {
    try {
      final response = await _dio.get(serverUrl);
      final data = response.data;
      final status = data is String
          ? jsonDecode(data)['status']
          : (data as Map<String, dynamic>)['status'];
      if (status == 'ok') return true;
      await _showAlert('서버 오류', '서버 상태가 정상적이지 않습니다.');
    } catch (e) {
      if (!mounted) return false;
      await _showAlert('서버 연결 실패', e.toString());
    }
    return false;
  }

  Future<void> _checkUpdate() async {
    try {
      final response = await _dio.get('$downloadBase/metadata.json');
      final metadata = jsonDecode(response.data) as Map<String, dynamic>;
      final packageInfo = await PackageInfo.fromPlatform();
      if (packageInfo.version == metadata['version']) return;
      if (!mounted) return;
      await _showAlert('업데이트', '새 버전이 있습니다.', actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _startDownload(metadata['downloadUrl'] as String);
          },
          child: const Text('확인'),
        )
      ], barrierDismissible: false);
    } catch (e) {
      if (!mounted) return;
      await _showAlert('업데이트 오류', e.toString());
    }
  }

  Future<String> _downloadFile(String pathOrUrl,
      {ProgressCallback? onReceiveProgress}) async {
    final dir = await getExternalStorageDirectory();
    final target = '${dir!.path}/myhome.apk';
    final url = pathOrUrl.startsWith('http') ? pathOrUrl : '$downloadBase/$pathOrUrl';
    await _dio.download(url, target, onReceiveProgress: onReceiveProgress);
    return target;
  }

  Future<void> _startDownload(String url) async {
    if (!mounted) return;
    int received = 0;
    int total = 0;
    bool started = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (dialogContext, setState) {
          if (!started) {
            started = true;
            _downloadFile(url, onReceiveProgress: (count, len) {
              setState(() {
                received = count;
                total = len;
              });
            }).then((target) async {
              if (!mounted) return;
              if (Navigator.of(dialogContext).canPop()) Navigator.of(dialogContext).pop();
              await _showAlert('다운로드 완료', '다운로드가 완료되었습니다. 설치 화면을 엽니다.');
              await FlutterAppInstaller().installApk(filePath: target);
            }).catchError((e) async {
              if (!mounted) return;
              if (Navigator.of(dialogContext).canPop()) Navigator.of(dialogContext).pop();
              await _showAlert('다운로드 실패', e.toString());
            });
          }

          final progressText = total > 0
              ? '${(received / total * 100).toStringAsFixed(0)}% (${(received / 1024).toStringAsFixed(0)}KB / ${(total / 1024).toStringAsFixed(0)}KB)'
              : '연결중...';
          return AlertDialog(
            title: const Text('다운로드 중'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: total > 0 ? received / total : null),
                const SizedBox(height: 12),
                Text(progressText),
              ],
            ),
            actions: const [
              TextButton(onPressed: null, child: Text('취소')),
            ],
          );
        });
      },
    );
  }

  void _increment() => setState(() => _count++);
  void _toggleTest() => setState(() => _testMode = !_testMode);
  void _reset() => setState(() {
        _count = 0;
        _testMode = false;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MyHome')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$_count', style: const TextStyle(fontSize: 74)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleTest,
              child: Text(_testMode ? '테스트 모드 켜짐' : '테스트 모드 끔'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _reset,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
              child: const Text('리셋'),
            ),
            if (_testMode) ...[
              const SizedBox(height: 12),
              const Text('테스트 기능이 실행 중입니다.'),
            ],
          ],
        ),
      ),
      floatingActionButton: GestureDetector(
        onLongPress: _reset,
        child: FloatingActionButton(
          onPressed: _increment,
          tooltip: '증가 / 길게 눌러 리셋',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
