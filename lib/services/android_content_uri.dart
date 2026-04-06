import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android `content://` URI içeriğini yerel dosyaya kopyalar (ses içe aktarma).
class AndroidContentUri {
  AndroidContentUri._();

  static const MethodChannel _channel =
      MethodChannel('com.example.voice_2_note_ai/content');

  /// [destPath] üst klasörü oluşturulmuş olmalı. Başarısızsa false.
  static Future<bool> copyToFile(String contentUri, String destPath) async {
    if (!Platform.isAndroid) {
      return false;
    }
    if (!contentUri.startsWith('content:')) {
      return false;
    }
    try {
      final ok = await _channel.invokeMethod<bool>(
        'copyContentUriToFile',
        <String, String>{
          'uri': contentUri,
          'destPath': destPath,
        },
      );
      return ok == true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AndroidContentUri.copyToFile: $e\n$st');
      }
      return false;
    }
  }
}
