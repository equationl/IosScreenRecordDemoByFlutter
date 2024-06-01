import UIKit
import ReplayKit
import Flutter

private var commonEventSink: FlutterEventSink? = nil

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    let appGroup = "group.equationl.recordDemo"
    let fileManager = FileManager.default
    let notificationNameRaw = "com.equationl.screenRecordDemo.broadcast.finished"
    let notificaitonName = NSNotification.Name(rawValue: "com.equationl.screenRecordDemo.broadcast.finished")
     
    deinit {
       removeNotificationObserver()
    }
    
    override func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setupNotification()
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let commonChannel = FlutterMethodChannel(name: "com.equationl.screenRecord/common", binaryMessenger: controller.binaryMessenger)
        let commonEvent = FlutterEventChannel(name: "com.equationl.screenRecord/commonEvent", binaryMessenger: controller.binaryMessenger)
        
        commonChannel.setMethodCallHandler(handlerCommonChannel)
        
        commonEvent.setStreamHandler(CommonEventHandler())
        
        initListenerScreenRecordEvent()
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func initListenerScreenRecordEvent() {
      NotificationCenter.default.addObserver(self, selector: #selector(screenCaptureDidChange),
                                             name: UIScreen.capturedDidChangeNotification,
                                             object: nil)
    }
    
    @objc func screenCaptureDidChange() {
        debugPrint("screenCaptureDidChange.. isCapturing: \(UIScreen.main.isCaptured)")
        
        if !UIScreen.main.isCaptured {
            commonEventSink?("{\"type\":\"screenRecordState\",\"isRecord\":false}")
        } else {
            commonEventSink?("{\"type\":\"screenRecordState\",\"isRecord\":true}")
        }
    }
    
    func handlerCommonChannel(call: FlutterMethodCall, result: @escaping FlutterResult) {
      switch call.method {
      case "startScreenRecord":
        startScreenRecord(call: call, result: result)
      case "stopScreenRecord":
        startScreenRecord(call: call, result: result)
      case "getScreenRecordSavePath":
        getSavePath(call: call, result: result)
      case "isScreenCaptured":
        isScreenCaptured(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    func isScreenCaptured(call: FlutterMethodCall, result: @escaping FlutterResult) {
      if UIScreen.main.isCaptured {
        result(true)
      }
      else {
        result(false)
      }
    }
    
    func startScreenRecord(call: FlutterMethodCall, result: @escaping FlutterResult) {
      if #available(iOS 12.0, *) {
        let pickerView = RPSystemBroadcastPickerView()
        pickerView.preferredExtension = "com.equationl.screenRecordDemo.RecordExtension"
        pickerView.showsMicrophoneButton = false
        
        // 自动点击录制按钮
        for view in pickerView.subviews {
          if let button = view as? UIButton {
            button.sendActions(for: .allEvents)
            result(true)
          }
        }
      }
      else {
        result(false)
      }
    }
    
    func setupNotification() {
      print("\(self).\(#function) ")

        NotiHelper.shared.addObserver(
        self,
        selector: #selector(Self.handleNotification(_:)),
        name: notificationNameRaw)
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(Self.handleNotification(_:)),
        name: notificaitonName,
        object: nil)
    }
    
    func removeNotificationObserver() {
        NotiHelper.shared.removeObserver(self, name: notificationNameRaw)

      print("\(self).\(#function)")
    }

    @objc func handleNotification(_ notification: NSNotification) {
      print("\(self).\(#function) \(notification)")

      onRecordFinish()
    }
    
    func onRecordFinish() {
        commonEventSink?("{\"type\":\"screenRecordFinish\"}")
    }
    
    func getSavePath(call: FlutterMethodCall, result: @escaping FlutterResult) {
      let savePath = videoFileLocation().path
      
      result(savePath)
    }

    func videoFileLocation() -> URL {
      let documentsPath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup)!
      let videoOutputUrl = documentsPath
        .appendingPathComponent("Library/Caches/videoRecord")
      
      do
      {
          try FileManager.default.createDirectory(atPath: videoOutputUrl.path, withIntermediateDirectories: true, attributes: nil)
      }
      catch let error as NSError
      {
          print("Unable to create directory \(error.debugDescription)")
      }

      return videoOutputUrl
    }
   }

class CommonEventHandler: NSObject, FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        commonEventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        commonEventSink = nil
        return nil
    }
}
