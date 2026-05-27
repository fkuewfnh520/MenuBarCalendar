import AppKit
import Foundation
import SwiftUI
import UniformTypeIdentifiers

@MainActor
enum BackgroundImageStore {
    static func image(for settings: AppSettings) -> NSImage? {
        if !settings.backgroundImagePath.isEmpty,
           let image = NSImage(contentsOfFile: settings.backgroundImagePath) {
            return image
        }

        return nil
    }

    static func chooseImage(attachedTo window: NSWindow?, for settings: AppSettings) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.title = "选择背景图片"
        panel.prompt = "选择"

        let handleSelection: (NSApplication.ModalResponse) -> Void = { response in
            guard response == .OK, let sourceURL = panel.url else { return }
            setImage(from: sourceURL, for: settings)
        }

        if let window {
            panel.beginSheetModal(for: window, completionHandler: handleSelection)
        } else {
            handleSelection(panel.runModal())
        }
    }

    private static func setImage(from sourceURL: URL, for settings: AppSettings) {
        do {
            let destinationURL = try copyToApplicationSupport(sourceURL)
            settings.backgroundImagePath = destinationURL.path
            settings.backgroundOffsetX = 0.5
            settings.backgroundOffsetY = 0.5
            settings.backgroundScale = 0.5
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    static func removeImage(_ settings: AppSettings) {
        settings.backgroundImagePath = ""
        settings.backgroundOpacity = 0.18
        settings.backgroundOffsetX = 0.5
        settings.backgroundOffsetY = 0.5
        settings.backgroundScale = 0.5
    }

    private static func copyToApplicationSupport(_ sourceURL: URL) throws -> URL {
        let directory = try supportDirectory()
        let ext = sourceURL.pathExtension.isEmpty ? "png" : sourceURL.pathExtension
        let destinationURL = directory.appendingPathComponent("background-\(UUID().uuidString).\(ext)")

        if sourceURL.startAccessingSecurityScopedResource() {
            defer { sourceURL.stopAccessingSecurityScopedResource() }
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        } else {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        }

        return destinationURL
    }

    private static func supportDirectory() throws -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appendingPathComponent("MenuBarCalendar/Backgrounds", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}

struct PositionedBackgroundImage: View {
    let image: NSImage
    let offsetX: Double
    let offsetY: Double
    let scale: Double

    var body: some View {
        GeometryReader { proxy in
            let imageSize = image.size
            let baseScale = max(
                proxy.size.width / max(imageSize.width, 1),
                proxy.size.height / max(imageSize.height, 1)
            )
            let displayScale = baseScale * zoomFactor
            let displayWidth = imageSize.width * displayScale
            let displayHeight = imageSize.height * displayScale
            let xTravel = max(displayWidth - proxy.size.width, 0)
            let yTravel = max(displayHeight - proxy.size.height, 0)

            Image(nsImage: image)
                .resizable()
                .frame(width: displayWidth, height: displayHeight)
                .offset(
                    x: -xTravel * normalizedOffsetX,
                    y: -yTravel * normalizedOffsetY
                )
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
                .clipped()
        }
    }

    private var normalizedOffsetX: Double {
        min(max(offsetX, 0), 1)
    }

    private var normalizedOffsetY: Double {
        min(max(offsetY, 0), 1)
    }

    private var zoomFactor: Double {
        max(0.1, min(scale, 1) * 2)
    }
}
