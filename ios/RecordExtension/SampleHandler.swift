//
//  SampleHandler.swift
//  RecordExtension
//
//  Created by equation l on 2024/6/1.
//

import Photos
import ReplayKit

class SampleHandler: RPBroadcastSampleHandler {
    var writter: AVAssetWriter?
    var videoInput: AVAssetWriterInput!
    var microInput: AVAssetWriterInput!
    let appGroup = "group.equationl.recordDemo"
    let fileManager = FileManager.default
    var sessionBeginAtSourceTime: CMTime!
    var isRecording = false
    var outputFileURL: URL!
    var outputName: String = ""
    
    let notificaitonName = "com.equationl.screenRecordDemo.broadcast.finished"

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        setupAssetWritter()
        writter?.startWriting()
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
        // User has requested to finish the broadcast.
        onFinishRecording()
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        guard canWrite() else {
          return
        }

        if sessionBeginAtSourceTime == nil {
          sessionBeginAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
          writter!.startSession(atSourceTime: sessionBeginAtSourceTime)
        }

        switch sampleBufferType {
        case RPSampleBufferType.video:
          // Handle video sample buffer

          if videoInput.isReadyForMoreMediaData {
            videoInput.append(sampleBuffer)
          }
        case RPSampleBufferType.audioApp:
          // Handle audio sample buffer for app audio
          break
        case RPSampleBufferType.audioMic:
          // Handle audio sample buffer for mic audio
//          if microInput.isReadyForMoreMediaData {
//            microInput.append(sampleBuffer)
//          }
          break
        @unknown default:
          // Handle other sample buffer types
          fatalError("Unknown type of sample buffer")
        }
    }
    
    func canWrite() -> Bool {
      return writter?.status == .writing
    }
    
    func setupAssetWritter() {
      outputFileURL = videoFileLocation()
      print("\(self).\(#function) output file at: \(outputFileURL)")
      guard let writter = try? AVAssetWriter(url: outputFileURL, fileType: .mp4) else {
        return
      }

      self.writter = writter

      let scale = UIScreen.main.scale
        
        var width = UIScreen.main.bounds.width * scale
        var height = UIScreen.main.bounds.height * scale

        // 不知道为什么 ipad 获取到的宽高是反的，所以这里就反转一下得了
        if UIDevice.current.userInterfaceIdiom == .pad {
            let temp = width
            width = height
            height = temp
        }

      let videoCompressionPropertys = [
        AVVideoAverageBitRateKey: width * height * 10.1
      ]

      let videoSettings: [String: Any] = [
        AVVideoCodecKey: AVVideoCodecType.h264,
        AVVideoWidthKey: width,
        AVVideoHeightKey: height,
        AVVideoCompressionPropertiesKey: videoCompressionPropertys
      ]

      videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
      videoInput.expectsMediaDataInRealTime = true

      // Add the microphone input
      var acl = AudioChannelLayout()
      memset(&acl, 0, MemoryLayout<AudioChannelLayout>.size)
      acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono
      let audioOutputSettings: [String: Any] =
        [AVFormatIDKey: kAudioFormatMPEG4AAC,
         AVSampleRateKey: 44100,
         AVNumberOfChannelsKey: 1,
         AVEncoderBitRateKey: 64000,
         AVChannelLayoutKey: Data(bytes: &acl, count: MemoryLayout<AudioChannelLayout>.size)]

      microInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: audioOutputSettings)
      microInput.expectsMediaDataInRealTime = true

      if writter.canAdd(videoInput) {
        writter.add(videoInput)
      }

      if writter.canAdd(microInput) {
        writter.add(microInput)
      }
    }
    
    func onFinishRecording() {
      print("\(self).\(#function)")
      sessionBeginAtSourceTime = nil

      let dispatchGroup = DispatchGroup()
      dispatchGroup.enter()

      if fileManager.fileExists(atPath: outputFileURL.path) {
        print(try? fileManager.attributesOfItem(atPath: outputFileURL.path))
      }

      videoInput.markAsFinished()
      microInput.markAsFinished()

      writter!.finishWriting { [weak self] in
        print("writter finish writing")

        guard let self = self else {
          return
        }
          
          let documentsPath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup)!
          var finishFile = documentsPath
            .appendingPathComponent("Library/Caches/videoRecord/\(outputName)")
            .appendingPathExtension("finish")
          
          if (FileManager.default.createFile(atPath: finishFile.path, contents: nil, attributes: nil)) {
              print("File created successfully.")
          } else {
              print("File not created.")
          }
          
        self.postNotification()
      }

      dispatchGroup.wait()
    }
    
    func videoFileLocation() -> URL {
      outputName = String(NSDate().timeIntervalSince1970)
      let documentsPath = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroup)!
      var videoOutputUrl = documentsPath
        .appendingPathComponent("Library/Caches/videoRecord/")
        //.appendingPathExtension("mp4")
        
        do
        {
            try FileManager.default.createDirectory(atPath: videoOutputUrl.path, withIntermediateDirectories: true, attributes: nil)
        }
        catch let error as NSError
        {
            print("Unable to create directory \(error.debugDescription)")
        }
        
        videoOutputUrl = videoOutputUrl
            .appendingPathComponent("\(outputName)")
            .appendingPathExtension("mp4")

      do {
        if fileManager.fileExists(atPath: videoOutputUrl.path) {
          try fileManager.removeItem(at: videoOutputUrl)
        }
      } catch {
        print(error)
      }

      return videoOutputUrl
    }
    
    fileprivate func postNotification() {
      print("\(self).\(#function) ")
        
    NotiHelper.shared.postNotification(name: notificaitonName, saveName: outputFileURL.path)
    }
}

