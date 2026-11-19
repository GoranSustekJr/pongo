#if os(iOS)
    import AVFoundation
    import AVKit
    import MediaPlayer
    import Observation
    import SwiftUI

    /// The device's music volume: observed, and set through a hidden system
    /// volume view, the only way an app can change it.
    @Observable
    final class DeviceVolume {
        private(set) var level: Double
        @ObservationIgnored private var observation: NSKeyValueObservation?
        @ObservationIgnored private let volumeView = MPVolumeView(frame: CGRect(x: -100, y: -100, width: 10, height: 10))

        init() {
            let session = AVAudioSession.sharedInstance()
            level = Double(session.outputVolume)
            // Observes only: activating the session here would stop other
            // apps' audio as soon as Pongo opens. The player activates it when
            // it plays, and the volume updates from then on
            observation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
                guard let volume = change.newValue else { return }
                Task { @MainActor in self?.level = Double(volume) }
            }
        }

        func set(_ level: Double) {
            self.level = level
            if volumeView.superview == nil {
                volumeView.alpha = 0.01
                UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.keyWindow }.first?
                    .addSubview(volumeView)
            }
            let slider = volumeView.subviews.compactMap { $0 as? UISlider }.first
            slider?.setValue(Float(level), animated: false)
            slider?.sendActions(for: .valueChanged)
        }
    }

    /// The AirPlay and Bluetooth output picker.
    struct RoutePicker: UIViewRepresentable {
        func makeUIView(context: Context) -> AVRoutePickerView {
            let view = AVRoutePickerView()
            view.tintColor = .white
            view.activeTintColor = UIColor(Color.accentColor)
            return view
        }

        func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
    }
#endif
