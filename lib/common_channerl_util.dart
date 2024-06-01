import 'package:flutter/services.dart';

class CommonChannelUtil {
  static const platform = MethodChannel('com.equationl.screenRecord/common');

  static Future<bool?> startScreenRecord() async {
    return await platform.invokeMethod<bool>('startScreenRecord');
  }

  static Future<bool?> stopScreenRecord() async {
    return await platform.invokeMethod<bool>('stopScreenRecord');
  }

  static Future<String?> getScreenRecordSavePath() async {
    return await platform.invokeMethod<String>('getScreenRecordSavePath');
  }

  static Future<bool?> isScreenCaptured() async {
    return await platform.invokeMethod<bool>('isScreenCaptured');
  }

}