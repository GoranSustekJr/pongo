import SwiftUI

// The few UIKit and AppKit types the shared views use, under one name, so
// the same code builds the iPhone and the Mac app.

#if os(macOS)
    import AppKit

    typealias PlatformImage = NSImage
    typealias PlatformColor = NSColor

    extension Image {
        init(platformImage: NSImage) { self.init(nsImage: platformImage) }
    }

    extension Color {
        init(platformColor: NSColor) { self.init(nsColor: platformColor) }
    }

    nonisolated extension NSImage {
        convenience init(cgImage: CGImage) {
            self.init(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        }

        /// The image's pixels, for drawing and filtering.
        var platformCGImage: CGImage? { cgImage(forProposedRect: nil, context: nil, hints: nil) }

        /// The image decoded once, so it draws without decoding again; AppKit
        /// keeps decoded bitmaps on its own.
        func byPreparingForDisplay() async -> NSImage? { self }

        /// The image scaled down to [size], to read its colors cheaply.
        func byPreparingThumbnail(ofSize size: CGSize) async -> NSImage? {
            guard let source = platformCGImage,
                let context = CGContext(
                    data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 0,
                    space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return nil }
            context.interpolationQuality = .medium
            context.draw(source, in: CGRect(origin: .zero, size: size))
            return context.makeImage().map(NSImage.init(cgImage:))
        }
    }
#else
    import UIKit

    typealias PlatformImage = UIImage
    typealias PlatformColor = UIColor

    extension Image {
        init(platformImage: UIImage) { self.init(uiImage: platformImage) }
    }

    extension Color {
        init(platformColor: UIColor) { self.init(uiColor: platformColor) }
    }

    extension UIImage {
        var platformCGImage: CGImage? { cgImage }
    }
#endif

extension ImageRenderer {
    /// What was drawn, as an image of the platform.
    var platformImage: PlatformImage? {
        #if os(macOS)
            nsImage
        #else
            uiImage
        #endif
    }
}

extension Color {
    /// A color that's [dark] in dark mode and [light] in light mode.
    static func adaptive(light: PlatformColor, dark: PlatformColor) -> Color {
        #if os(macOS)
            Color(
                nsColor: NSColor(name: nil) { appearance in
                    appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
                })
        #else
            Color(platformColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
        #endif
    }
}

/// Copies [text] for pasting elsewhere.
func copyToPasteboard(_ text: String) {
    #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    #else
        copyToPasteboard(text)
    #endif
}

#if os(macOS)
    // iPhone modifiers the shared screens use, which a Mac window doesn't
    // need: titles sit in the toolbar and lists are inset.

    enum NavigationBarItem {
        enum TitleDisplayMode { case automatic, inline, large }
    }

    extension View {
        func navigationBarTitleDisplayMode(_ mode: NavigationBarItem.TitleDisplayMode) -> some View { self }
    }

    extension ListStyle where Self == InsetListStyle {
        static var insetGrouped: InsetListStyle { .inset }
    }
#endif

extension ToolbarItemPlacement {
    /// The end of the navigation bar, or of the window's toolbar on a Mac.
    static var barTrailing: Self {
        #if os(macOS)
            .primaryAction
        #else
            .topBarTrailing
        #endif
    }

    /// The start of the navigation bar, or of the window's toolbar on a Mac.
    static var barLeading: Self {
        #if os(macOS)
            .navigation
        #else
            .topBarLeading
        #endif
    }

    /// The bar at the bottom of the screen, or the toolbar on a Mac.
    static var barBottom: Self {
        #if os(macOS)
            .automatic
        #else
            .bottomBar
        #endif
    }
}

extension View {
    /// Draws the navigation bar's items in [scheme]; a Mac toolbar follows
    /// the window.
    @ViewBuilder func navigationBarColorScheme(_ scheme: ColorScheme?) -> some View {
        #if os(macOS)
            self
        #else
            toolbarColorScheme(scheme, for: .navigationBar)
        #endif
    }

    /// Keeps a list selecting rows, as lists on a Mac always do.
    @ViewBuilder func alwaysSelecting() -> some View {
        #if os(macOS)
            self
        #else
            environment(\.editMode, .constant(.active))
        #endif
    }
}

extension View {
    /// A picker as a wheel on the iPhone, and a pop-up menu on a Mac.
    @ViewBuilder func wheelPicker() -> some View {
        #if os(macOS)
            pickerStyle(.menu)
        #else
            pickerStyle(.wheel).frame(height: 130)
        #endif
    }

    /// A date picker as a wheel on the iPhone, and a clock-style field on a
    /// Mac.
    @ViewBuilder func wheelDatePicker() -> some View {
        #if os(macOS)
            datePickerStyle(.stepperField)
        #else
            datePickerStyle(.wheel)
        #endif
    }
}
