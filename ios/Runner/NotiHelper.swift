//
//  NotiHelper.swift
//  Runner
//
//  Created by equation l on 2024/6/2.
//

import Foundation

class NotiHelper {
  static let shared = NotiHelper()

  private init() {}

  func addObserver(_ target: Any, selector: Selector, name: String) {
//    CFNotificationCenterGetDarwinNotifyCenter()
    NotificationCenter.default.addObserver(
      target,
      selector: selector,
      name: NSNotification.Name(name + ".ext"),
      object: nil)

    CFNotificationCenterAddObserver(
      CFNotificationCenterGetDarwinNotifyCenter(),
      nil, { _, _, name, _, _ in
        let nameExt = "\(name!.rawValue as String).ext"
        NotificationCenter.default.post(name: NSNotification.Name(nameExt), object: nil)
      },
      name as CFString,
      nil,
      .deliverImmediately)
  }

  func removeObserver(_ target: Any, name: String) {
    let nameExt = name + ".ext"

    NotificationCenter.default.removeObserver(
      target,
      name: NSNotification.Name(nameExt),
      object: nil)

    CFNotificationCenterRemoveObserver(
      CFNotificationCenterGetDarwinNotifyCenter(),
      nil,
      CFNotificationName(rawValue: name as CFString),
      nil)
  }

    func postNotification(name: String, saveName: String) {
        let options: CFDictionary = ["saveName" : saveName] as CFDictionary
        
        CFNotificationCenterPostNotification(
          CFNotificationCenterGetDarwinNotifyCenter(),
          CFNotificationName(name as CFString),
          nil, options, true)
  }
}
