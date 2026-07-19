import 'package:flutter/material.dart';

import 'update_service.dart';

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
  final _updateService = UpdateService();
  int _count = 0;
  bool _testMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateService.runUpdateFlow(context);
    });
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
