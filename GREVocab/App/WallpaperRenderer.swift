import Photos
import SwiftUI
import UIKit

enum WallpaperRenderer {
    /// Portrait screen size in points plus the native scale, so the image matches the device pixel-for-pixel.
    @MainActor
    static var screenMetrics: (size: CGSize, scale: CGFloat) {
        let screen = UIScreen.main
        let scale = screen.nativeScale
        let pixels = screen.nativeBounds.size
        let width = min(pixels.width, pixels.height) / scale
        let height = max(pixels.width, pixels.height) / scale
        return (CGSize(width: width, height: height), scale)
    }

    @MainActor
    static func render(word: VocabWord, theme: WallpaperTheme) -> UIImage? {
        let metrics = screenMetrics
        let renderer = ImageRenderer(content: WallpaperView(word: word, theme: theme, size: metrics.size))
        renderer.proposedSize = ProposedViewSize(metrics.size)
        renderer.scale = metrics.scale
        return renderer.uiImage
    }

    enum SaveError: LocalizedError {
        case notAuthorized

        var errorDescription: String? {
            "Photo library access was denied. Allow \"Add Photos Only\" for GRE Vocab in Settings › Privacy & Security › Photos."
        }
    }

    static func saveToPhotos(_ image: UIImage) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw SaveError.notAuthorized }
        try await PHPhotoLibrary.shared().performChanges {
            _ = PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }
}
