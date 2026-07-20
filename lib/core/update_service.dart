import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app_installer/flutter_app_installer.dart';
import 'package:path_provider/path_provider.dart';

import 'const.dart';

class UpdateMetadata {
  final String downloadUrl;
  final String sha256;

  UpdateMetadata({required this.downloadUrl, required this.sha256});

  factory UpdateMetadata.fromJson(Map<String, dynamic> json) {
    return UpdateMetadata(
      downloadUrl: json['downloadUrl'] as String,
      sha256: json['sha256'] as String,
    );
  }
}

class UpdateService {
  final Dio _dio;

  UpdateService([Dio? dio])
      : _dio = dio ??
            Dio(BaseOptions(
              sendTimeout: const Duration(seconds: 2),
              receiveTimeout: const Duration(seconds: 2),
            ));

  Future<bool> checkServer() async {
    final response = await _dio.get(fileServerUrl);
    final data = response.data;
    final status = data is String
        ? jsonDecode(data)['status']
        : (data as Map<String, dynamic>)['status'];
    return status == 'ok';
  }

  Future<UpdateMetadata> fetchMetadata() async {
    final response = await _dio.get('$fileServerUrl/download/myhome/metadata.json');
    final metadata = jsonDecode(response.data) as Map<String, dynamic>;
    return UpdateMetadata.fromJson(metadata);
  }

  Future<File> _hashFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$hashStorageName');
  }

  Future<String?> getStoredSha256() async {
    try {
      final file = await _hashFile();
      return await file.exists() ? file.readAsString() : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSha256(String sha256Value) async {
    final file = await _hashFile();
    await file.writeAsString(sha256Value);
  }

  Future<bool> hasNewSha256(UpdateMetadata metadata) async {
    final stored = await getStoredSha256();
    return stored != metadata.sha256;
  }

  Future<String> downloadApk(String pathOrUrl,
      {ProgressCallback? onReceiveProgress}) async {
    final dir = await getExternalStorageDirectory();
    final target = '${dir!.path}/myhome.apk';
    final url = pathOrUrl.startsWith('http') ? pathOrUrl : '$fileServerUrl/download/myhome/$pathOrUrl';
    await _dio.download(url, target, onReceiveProgress: onReceiveProgress);
    return target;
  }

  Future<String> computeFileSha256(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    return sha256.convert(bytes).toString();
  }

  Future<bool> verifySha256(String filePath, String expectedSha256) async {
    return await computeFileSha256(filePath) == expectedSha256;
  }

  Future<void> runUpdateFlow(BuildContext context) async {
    try {
      if (!await checkServer()) {
        await _showAlert(context, '서버 오류', '서버 상태가 정상적이지 않습니다.');
        return;
      }

      final metadata = await fetchMetadata();
      if (!await hasNewSha256(metadata)) return;
      if (!context.mounted) return;

      await _showAlert(
        context,
        '업데이트',
        '새 버전이 있습니다.',
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startDownload(context, metadata);
            },
            child: const Text('확인'),
          )
        ],
        barrierDismissible: false,
      );
    } catch (e) {
      if (!context.mounted) return;
      await _showAlert(context, '업데이트 오류', e.toString());
    }
  }

  Future<void> _startDownload(BuildContext context, UpdateMetadata metadata) async {
    if (!context.mounted) return;
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
            downloadApk(metadata.downloadUrl, onReceiveProgress: (count, len) {
              setState(() {
                received = count;
                total = len;
              });
            }).then((target) async {
              if (!context.mounted) return;
              if (Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop();
              }

              final valid = await verifySha256(target, metadata.sha256);
              if (!valid) {
                await _showAlert(context, '다운로드 실패', '파일 검증에 실패했습니다.');
                return;
              }

              await saveSha256(metadata.sha256);
              await _showAlert(context, '다운로드 완료', '다운로드가 완료되었습니다. 설치 화면을 엽니다.');
              await FlutterAppInstaller().installApk(filePath: target);
            }).catchError((e) async {
              if (!context.mounted) return;
              if (Navigator.of(dialogContext).canPop()) {
                Navigator.of(dialogContext).pop();
              }
              await _showAlert(context, '다운로드 실패', e.toString());
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

  Future<void> _showAlert(
    BuildContext context,
    String title,
    String message, {
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) {
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
}
