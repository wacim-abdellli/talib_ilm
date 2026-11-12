import Flutter
import UIKit
import UserNotifications
import AVFoundation
import Security
#if canImport(WidgetKit)
import WidgetKit
#endif

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let widgetBridgeChannelName = "com.talibilm.app/widget_bridge"
  private let snapshotFileName = "talib_widget_snapshot.json"
  private let keychainService = "com.talibilm.app.widgetSnapshot"
  private let keychainAccount = "snapshot_v1"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    registerWidgetBridgeChannel()
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    // Configure AVAudioSession for background prayer audio playback & mute-switch bypass
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("TalibIlm: AudioSession setup: \(error.localizedDescription)")
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func registerWidgetBridgeChannel() {
    guard let registrar = self.registrar(forPlugin: "TalibIlmWidgetBridge") else { return }
    let channel = FlutterMethodChannel(
      name: widgetBridgeChannelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "DISPOSED", message: "AppDelegate released", details: nil))
        return
      }
      switch call.method {
      case "getWidgetBridgeInfo":
        result(self.buildBridgeInfo())
      case "syncSnapshot":
        let args = call.arguments as? [String: Any]
        let jsonStr = args?["json"] as? String
        let prefsMap = args?["prefs"] as? [String: Any]
        result(self.syncSnapshot(jsonString: jsonStr, prefsMap: prefsMap))
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func readEmbeddedProvisionPlist() -> [String: Any]? {
    let candidates = [
      Bundle.main.path(forResource: "embedded", ofType: "mobileprovision"),
      Bundle.main.bundleURL.appendingPathComponent("embedded.mobileprovision").path
    ]
    for pathOpt in candidates {
      guard let path = pathOpt,
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { continue }
      let decoded = String(decoding: data, as: UTF8.self)
      guard let plistStart = decoded.range(of: "<plist"),
            let plistEnd = decoded.range(of: "</plist>") else { continue }
      let xmlSubstring = String(decoded[plistStart.lowerBound..<plistEnd.upperBound])
      guard let xmlData = xmlSubstring.data(using: .utf8),
            let plistObj = try? PropertyListSerialization.propertyList(
              from: xmlData,
              options: [],
              format: nil
            ) as? [String: Any] else { continue }
      return plistObj
    }
    return nil
  }

  private func discoverProvisionedAppGroups() -> [String] {
    guard let plist = readEmbeddedProvisionPlist(),
          let entitlements = plist["Entitlements"] as? [String: Any],
          let appGroups = entitlements["com.apple.security.application-groups"] as? [String] else {
      return []
    }
    var groups: [String] = []
    for g in appGroups {
      let trimmed = g.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmed.isEmpty && !groups.contains(trimmed) {
        groups.append(trimmed)
      }
    }
    return groups
  }

  private func discoverKeychainAccessGroups() -> [String] {
    var groups: [String] = []
    if let plist = readEmbeddedProvisionPlist() {
      let entitlements = plist["Entitlements"] as? [String: Any]
      if let kcGroups = entitlements?["keychain-access-groups"] as? [String] {
        for g in kcGroups {
          let trimmed = g.trimmingCharacters(in: .whitespacesAndNewlines)
          if trimmed.hasSuffix(".*") {
            let prefix = String(trimmed.dropLast(1))
            let explicit = "\(prefix)com.talibilm.app.shared"
            if !groups.contains(explicit) { groups.append(explicit) }
          } else if !trimmed.isEmpty && !groups.contains(trimmed) {
            groups.append(trimmed)
          }
        }
      }
      if let prefixes = plist["ApplicationIdentifierPrefix"] as? [String],
         let teamPrefix = prefixes.first, !teamPrefix.isEmpty {
        let explicit = "\(teamPrefix).com.talibilm.app.shared"
        if !groups.contains(explicit) { groups.append(explicit) }
      }
      if let appId = entitlements?["application-identifier"] as? String,
         let dotIdx = appId.firstIndex(of: ".") {
        let teamPrefix = String(appId[..<dotIdx])
        let explicit = "\(teamPrefix).com.talibilm.app.shared"
        if !groups.contains(explicit) { groups.append(explicit) }
      }
    }
    let fallbackTeam = "V3N9W8G24A.com.talibilm.app.shared"
    if !groups.contains(fallbackTeam) {
      groups.append(fallbackTeam)
    }
    return groups
  }

  private func candidateAppGroups() -> [String] {
    var candidates = discoverProvisionedAppGroups()
    let defaultGroup = "group.com.talibilm.app"
    if !candidates.contains(defaultGroup) {
      candidates.append(defaultGroup)
    }
    if let bundleId = Bundle.main.bundleIdentifier {
      let dynamicGroup = "group.\(bundleId)"
      if !candidates.contains(dynamicGroup) {
        candidates.append(dynamicGroup)
      }
    }
    return candidates
  }

  private func accessibleAppGroups() -> [(groupId: String, containerUrl: URL)] {
    var accessible: [(groupId: String, containerUrl: URL)] = []
    for group in candidateAppGroups() {
      if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) {
        accessible.append((groupId: group, containerUrl: url))
      }
    }
    return accessible
  }

  private func testKeychainWrite(data: Data, accessGroup: String) -> Bool {
    let baseQuery: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: keychainService,
      kSecAttrAccount as String: keychainAccount,
      kSecAttrAccessGroup as String: accessGroup
    ]
    SecItemDelete(baseQuery as CFDictionary)
    var addQuery = baseQuery
    addQuery[kSecValueData as String] = data
    addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
    let status = SecItemAdd(addQuery as CFDictionary, nil)
    return status == errSecSuccess
  }

  private func probeKeychainAccess() -> String? {
    let probeData = Data("{}".utf8)
    for kcGroup in discoverKeychainAccessGroups() {
      let probeQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: "\(keychainService).probe",
        kSecAttrAccount as String: "probe",
        kSecAttrAccessGroup as String: kcGroup
      ]
      SecItemDelete(probeQuery as CFDictionary)
      var addQuery = probeQuery
      addQuery[kSecValueData as String] = probeData
      addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
      let status = SecItemAdd(addQuery as CFDictionary, nil)
      if status == errSecSuccess {
        SecItemDelete(probeQuery as CFDictionary)
        return kcGroup
      }
    }
    return nil
  }

  private func buildBridgeInfo() -> [String: Any] {
    let candidates = candidateAppGroups()
    let accessible = accessibleAppGroups()
    let activeGroup = accessible.first?.groupId
    let activeKcGroup = probeKeychainAccess()
    return [
      "activeAppGroup": activeGroup.map { $0 as Any } ?? NSNull(),
      "containerAccessible": activeGroup != nil,
      "keychainAccessible": activeKcGroup != nil,
      "activeKeychainGroup": activeKcGroup.map { $0 as Any } ?? NSNull(),
      "candidateGroups": candidates,
      "accessibleGroups": accessible.map { $0.groupId },
      "bundleId": Bundle.main.bundleIdentifier ?? ""
    ]
  }

  private func syncSnapshot(
    jsonString: String?,
    prefsMap: [String: Any]?
  ) -> [String: Any] {
    let accessible = accessibleAppGroups()
    var fileWritten = false
    var keychainWritten = false
    var activeKcGroup: String?

    for (groupId, containerUrl) in accessible {
      if let jsonStr = jsonString, let data = jsonStr.data(using: .utf8) {
        let fileUrl = containerUrl.appendingPathComponent(snapshotFileName)
        do {
          try data.write(to: fileUrl, options: [.atomic])
          fileWritten = true
        } catch {
          print("TalibIlm: Failed writing shared widget snapshot file (\(groupId)): \(error.localizedDescription)")
        }
      }

      if let defaults = UserDefaults(suiteName: groupId) {
        if let jsonStr = jsonString {
          defaults.set(jsonStr, forKey: "prayer_data_json")
        }
        if let prefsMap = prefsMap {
          for (key, value) in prefsMap {
            if value is NSNull {
              defaults.removeObject(forKey: key)
            } else {
              defaults.set(value, forKey: key)
            }
          }
        }
        defaults.synchronize()
      }
    }

    if let jsonStr = jsonString, let data = jsonStr.data(using: .utf8) {
      for kcGroup in discoverKeychainAccessGroups() {
        if testKeychainWrite(data: data, accessGroup: kcGroup) {
          keychainWritten = true
          if activeKcGroup == nil {
            activeKcGroup = kcGroup
          }
        }
      }
    }

    #if canImport(WidgetKit)
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.reloadTimelines(ofKind: "TalibIlmWidgets")
      WidgetCenter.shared.reloadAllTimelines()
    }
    #endif

    let activeGroup = accessible.first?.groupId
    let anySyncOk = (activeGroup != nil && fileWritten) || keychainWritten
    return [
      "ok": anySyncOk,
      "activeAppGroup": activeGroup.map { $0 as Any } ?? NSNull(),
      "containerAccessible": activeGroup != nil,
      "keychainAccessible": keychainWritten,
      "activeKeychainGroup": activeKcGroup.map { $0 as Any } ?? NSNull(),
      "fileWritten": fileWritten
    ]
  }

  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .list, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
  }
}
