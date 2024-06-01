import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path/path.dart' as p;
import 'package:screen_record_demo/common_channerl_util.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'screenRecord Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'screenRecord Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _eventChannel = const EventChannel("com.equationl.screenRecord/commonEvent");

  bool _isFirst = true;

  List<String> videoFileList = [];
  bool isOnRecord = false;

  @override
  void initState() {
    super.initState();

    init();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFirst) {
      _isFirst = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        initEvent();
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: _buildContent(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildRecordBtn(),
          _videoFileList(),
        ],
      ),
    );
  }

  Widget _buildRecordBtn() {
    return Center(
      child: OutlinedButton(
        onPressed: () {
          if (isOnRecord) {
            CommonChannelUtil.stopScreenRecord();
          } else {
            CommonChannelUtil.startScreenRecord();
          }
        },
        child: Text(isOnRecord ? "停止录制" : "开始录制"),
      ),
    );
  }

  Widget _videoFileList() {
    return Column(
      children: List.generate(
        videoFileList.length,
        (index) {
          return Container(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: TextButton(
                onPressed: () async {
                  // 保存到相册
                  Map saveResult = await ImageGallerySaver.saveFile(
                    videoFileList[index],
                    name: p.basenameWithoutExtension(videoFileList[index]),
                    isReturnPathOfIOS: false,
                  );

                  if (saveResult['isSuccess'] == true) {
                    Fluttertoast.showToast(msg: "视频已保存至相册");
                  }
                  else {
                    Fluttertoast.showToast(msg: "保存视频失败： $saveResult");
                  }
                },
                child: Text(videoFileList[index]),
              ),
            )
          );
        },
      ),
    );
  }

  void init() async {
    isOnRecord = (await CommonChannelUtil.isScreenCaptured()) == true;
    videoFileList.clear();
    videoFileList.addAll(await getVideoFileList());
    if (mounted) {
      setState(() {});
    }
  }

  Future<List<String>> getVideoFileList() async {
    List<String> list = [];

    var savePath = await CommonChannelUtil.getScreenRecordSavePath();
    if (savePath == null) {
      print("get screen record save path fail");
      return list;
    }

    var dir = Directory(savePath);
    for (FileSystemEntity file in dir.listSync()) {
      if (file is File && p.extension(file.path) == ".mp4") {
        list.add(
          file.path,
        );
      }
    }

    return list;
  }

  void initEvent() {
    try {
      _eventChannel.receiveBroadcastStream().listen(
            (event) {
              _handlerEvent(context, jsonDecode(event));
            },
            cancelOnError: false,
            onError: (e, s) {
              print("Listener Error: $e\n$s");
            },
          );
    } catch (e, s) {
      print("Rec Common Event fail: $e\n$s");
    }
  }

  void _handlerEvent(BuildContext context, Map<String, dynamic> event) async {
    switch (event['type']) {
      // 这里接收到的是录屏完成事件，这是由我们自己发出的完成事件
      case "screenRecordFinish":
        print("接收到录屏完成事件");

        videoFileList.clear();
        videoFileList.addAll(await getVideoFileList());
        if (mounted) {
          setState(() {});
        }

        break;
      // 这里是通过监听系统录屏状态得到的事件，不一定是我们 APP 触发的录屏事件
      case "screenRecordState":
        bool? state = event['isRecord'];
        print("录屏状态改变：$state");

        isOnRecord = state == true;
        if (mounted) {
          setState(() {});
        }

        break;
    }
  }
}
