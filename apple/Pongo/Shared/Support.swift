import CoreImage
import Observation
import PongoCore
import SwiftUI

/// The app's strings in the language the user picked, which can differ from
/// the device's.
enum L10n {
    static var selectedLanguage = "en" {
        didSet { bundle = Self.bundle(for: selectedLanguage) }
    }

    private static var bundle = bundle(for: "en")

    private static func bundle(for language: String) -> Bundle {
        Bundle.main.path(forResource: language, ofType: "lproj").flatMap(Bundle.init(path:)) ?? .main
    }

    static func tr(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    /// Hello for the time of day.
    static var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12: goodmorning
        case 12..<18: goodafternoon
        default: goodevening
        }
    }
}

/// A short message shown over the app, such as that a track was downloaded.
struct Toast: Identifiable, Equatable {
    let id = UUID()
    var text: String
    var detail: String?
    var systemImage: String
    var isError: Bool
}

/// Shows toasts one at a time, each for a few seconds.
@Observable
final class MessageCenter {
    private(set) var current: Toast?
    private var dismissal: Task<Void, Never>?

    func show(_ text: String, detail: String? = nil, systemImage: String, isError: Bool = false) {
        if isError { Haptics.error() } else { Haptics.tap() }
        let toast = Toast(text: text, detail: detail, systemImage: systemImage, isError: isError)
        current = toast
        dismissal?.cancel()
        dismissal = Task {
            try? await Task.sleep(for: .seconds(detail == nil ? 3 : 4))
            guard !Task.isCancelled else { return }
            if current == toast { current = nil }
        }
    }

    func dismiss() { current = nil }
}

struct ToastView: View {
    let toast: Toast

    // One short line, so it covers as little as it can
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: toast.systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(toast.isError ? Color.orange : Color.pongoTeal)
            (Text(toast.text).fontWeight(.semibold)
                + Text(toast.detail.map { " · \($0)" } ?? "").foregroundStyle(.secondary))
                .font(.footnote)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal)
    }
}

#if os(iOS)
/// Shows the toasts in a window of their own above everything, so they
/// appear over the player and sheets too.
@MainActor
final class ToastWindow {
    private var window: UIWindow?

    func install(model: AppModel) {
        guard window == nil,
            let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else { return }
        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.isUserInteractionEnabled = false
        let host = UIHostingController(rootView: ToastHost().environment(model))
        host.view.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = false
        self.window = window
    }
}

private struct ToastHost: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack {
            if let toast = model.messages.current {
                ToastView(toast: toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.spring(duration: 0.4, bounce: 0.25), value: model.messages.current)
        .preferredColorScheme(model.settings.settings.darkMode ? .dark : .light)
    }
}
#endif

// MARK: - Images

/// Loads and keeps decoded images, so covers don't flicker or load twice.
actor ImagePipeline {
    static let shared = ImagePipeline()

    // Thread-safe, so views can read it while they draw
    nonisolated(unsafe) private static let memory = NSCache<NSURL, PlatformImage>()
    private let blurredMemory = NSCache<NSURL, PlatformImage>()
    private var accents: [URL: PlatformColor] = [:]
    private var loading: [URL: Task<PlatformImage?, Never>] = [:]
    private let context = CIContext()

    func image(for url: URL) async -> PlatformImage? {
        if let image = Self.memory.object(forKey: url as NSURL) { return image }
        if let task = loading[url] { return await task.value }
        let task = Task<PlatformImage?, Never> {
            let data: Data? =
                url.isFileURL
                ? try? Data(contentsOf: url)
                : try? await URLSession.shared.data(for: URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)).0
            return await data.flatMap(PlatformImage.init(data:))?.byPreparingForDisplay()
        }
        loading[url] = task
        let image = await task.value
        loading[url] = nil
        if let image { Self.memory.setObject(image, forKey: url as NSURL) }
        return image
    }

    func cached(_ url: URL) -> PlatformImage? { Self.memory.object(forKey: url as NSURL) }

    /// The image at [url] if it's loaded, without waiting.
    nonisolated static func loaded(_ url: URL) -> PlatformImage? { memory.object(forKey: url as NSURL) }

    /// The image at [url] shrunk and blurred into a soft field of its colors,
    /// which scales up to full screen without a costly live blur.
    func blurred(for url: URL) async -> PlatformImage? {
        if let image = blurredMemory.object(forKey: url as NSURL) { return image }
        guard let source = await image(for: url), let blurred = await blur(source) else { return nil }
        blurredMemory.setObject(blurred, forKey: url as NSURL)
        return blurred
    }

    /// An image stored as [data], such as a playlist's cover, blurred the
    /// same way.
    func blurred(data: Data) async -> PlatformImage? {
        let key = NSURL(string: "data:\(data.hashValue)")!
        if let image = blurredMemory.object(forKey: key) { return image }
        guard let source = PlatformImage(data: data), let blurred = await blur(source) else { return nil }
        blurredMemory.setObject(blurred, forKey: key)
        return blurred
    }

    /// A light, lively color of the cover at [url], for controls drawn over
    /// its blurred colors: the most colorful part of it, made pale enough to
    /// stand out. Grey covers give white.
    func accent(for url: URL) async -> PlatformColor? {
        if let accent = accents[url] { return accent }
        guard let source = await image(for: url),
            let cgImage = await source.byPreparingThumbnail(ofSize: CGSize(width: 24, height: 24))?.platformCGImage
        else { return nil }
        let side = 24
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        pixels.withUnsafeMutableBytes { buffer in
            let context = CGContext(
                data: buffer.baseAddress, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))
        }
        var best: (score: CGFloat, hue: CGFloat, saturation: CGFloat) = (-1, 0, 0)
        for start in stride(from: 0, to: pixels.count, by: 4) {
            let color = PlatformColor(
                red: CGFloat(pixels[start]) / 255, green: CGFloat(pixels[start + 1]) / 255,
                blue: CGFloat(pixels[start + 2]) / 255, alpha: 1)
            var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
            color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
            let score = saturation * brightness
            if score > best.score { best = (score, hue, saturation) }
        }
        let accent = PlatformColor(hue: best.hue, saturation: min(best.saturation, 0.42), brightness: 1, alpha: 1)
        accents[url] = accent
        return accent
    }

    private func blur(_ source: PlatformImage) async -> PlatformImage? {
        guard let small = await source.byPreparingThumbnail(ofSize: CGSize(width: 64, height: 64))?.platformCGImage
        else { return nil }
        let input = CIImage(cgImage: small)
        let extent = input.extent
        let output = input.clampedToExtent()
            .applyingGaussianBlur(sigma: 7)
            .applyingFilter("CIColorControls", parameters: [kCIInputSaturationKey: 1.35])
            .cropped(to: extent)
        return context.createCGImage(output, from: extent).map(PlatformImage.init(cgImage:))
    }

    func clear() {
        Self.memory.removeAllObjects()
        blurredMemory.removeAllObjects()
        URLCache.shared.removeAllCachedResponses()
    }
}

/// A cover or profile image from a URL or file, with a placeholder while it
/// loads.
struct CoverImage: View {
    var url: URL?
    var data: Data?
    var placeholder = "music.note"

    @State private var image: PlatformImage?

    init(url: URL?, placeholder: String = "music.note") {
        self.url = url
        self.placeholder = placeholder
    }

    init(_ string: String?, placeholder: String = "music.note") {
        url = string.flatMap { $0.isEmpty ? nil : URL(string: $0) }
        self.placeholder = placeholder
    }

    init(data: Data?, placeholder: String = "music.note.list") {
        self.data = data
        self.placeholder = placeholder
    }

    var body: some View {
        Color.pongoCard.opacity(0.6)
            .overlay {
                // A loaded cover shows from the first frame, so rebuilt views don't flash
                if let image = image ?? url.flatMap(ImagePipeline.loaded) ?? data.flatMap(PlatformImage.init(data:)) {
                    Image(platformImage: image).resizable().scaledToFill()
                } else {
                    Image(systemName: placeholder).font(.title3).foregroundStyle(.secondary)
                }
            }
            .clipped()
            .task(id: url) {
                guard let url else {
                    image = nil
                    return
                }
                if let cached = await ImagePipeline.shared.cached(url) {
                    image = cached
                    return
                }
                let loaded = await ImagePipeline.shared.image(for: url)
                withAnimation(.easeOut(duration: 0.2)) { image = loaded }
            }
    }
}

extension View {
    /// Rounds a cover's corners the same way everywhere.
    func coverShape(_ radius: CGFloat = 8) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

/// Minutes and seconds, such as `3:07`.
func formatTime(_ seconds: Double) -> String {
    guard seconds.isFinite, seconds >= 0 else { return "0:00" }
    let total = Int(seconds)
    return String(format: "%d:%02d", total / 60, total % 60)
}

#if os(iOS)
/// Taps of the Taptic Engine that confirm what the user did.
@MainActor
enum Haptics {
    /// Something small happened, such as a track going into the queue.
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }

    /// A slider reached its end.
    static func edge() { UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.75) }

    /// A different mode or option is picked.
    static func select() { UISelectionFeedbackGenerator().selectionChanged() }

    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
}
#else
/// The trackpad's feedback for what the user did. A Mac only gives it as a
/// slider snaps to its end; other actions are silent.
@MainActor
enum Haptics {
    static func tap() {}

    /// A slider reached its end.
    static func edge() { NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now) }

    static func select() {}

    static func error() {}
}
#endif
