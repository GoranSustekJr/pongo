import AVFoundation
import Flutter
import UIKit

import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let volumeObserver = DeviceVolumeObserver()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PongoDeviceVolume")
    else { return }
    FlutterEventChannel(name: "pongo/device_volume", binaryMessenger: registrar.messenger())
      .setStreamHandler(volumeObserver)
  }
}

/// Emits the device volume whenever it changes.
///
/// Volume plugins observe it too, but they change the audio session's category
/// to do so. volume_controller sets `mixWithOthers`, which lets other apps play
/// at the same time and keeps Pongo off the lock screen and Control Center.
/// This only observes, leaving the category that audio_session configured.
final class DeviceVolumeObserver: NSObject, FlutterStreamHandler {
  private var observation: NSKeyValueObservation?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    let session = AVAudioSession.sharedInstance()
    events(Double(session.outputVolume))
    observation = session.observe(\.outputVolume, options: [.new]) { _, change in
      guard let volume = change.newValue else { return }
      DispatchQueue.main.async { events(Double(volume)) }
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    observation?.invalidate()
    observation = nil
    return nil
  }
}
