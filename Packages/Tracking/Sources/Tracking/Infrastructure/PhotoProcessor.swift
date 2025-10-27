import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Utility for processing baby photos (resize and compress)
enum PhotoProcessor {
    static let maxDimension: CGFloat = 500
    static let compressionQuality: CGFloat = 0.8

    /// Process photo data: resize to max 500x500 and compress to JPEG
    /// - Parameter imageData: Original image data
    /// - Returns: Processed image data
    /// - Throws: Error if processing fails
    static func process(_ imageData: Data) throws -> Data {
        #if canImport(UIKit)
        return try processUIKit(imageData)
        #elseif canImport(AppKit)
        return try processAppKit(imageData)
        #else
        throw PhotoProcessingError.unsupportedPlatform
        #endif
    }

    #if canImport(UIKit)
    private static func processUIKit(_ imageData: Data) throws -> Data {
        guard let image = UIImage(data: imageData) else {
            throw PhotoProcessingError.invalidImageData
        }

        let resizedImage = resize(image: image, maxDimension: maxDimension)

        guard let jpegData = resizedImage.jpegData(compressionQuality: compressionQuality) else {
            throw PhotoProcessingError.compressionFailed
        }

        return jpegData
    }

    private static func resize(image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let ratio = max(size.width, size.height) / maxDimension

        guard ratio > 1 else { return image }

        let newSize = CGSize(width: size.width / ratio, height: size.height / ratio)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: newSize))

        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    #endif

    #if canImport(AppKit)
    private static func processAppKit(_ imageData: Data) throws -> Data {
        guard let image = NSImage(data: imageData) else {
            throw PhotoProcessingError.invalidImageData
        }

        let resizedImage = resize(image: image, maxDimension: maxDimension)

        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(
                using: .jpeg,
                properties: [.compressionFactor: compressionQuality]
              ) else {
            throw PhotoProcessingError.compressionFailed
        }

        return jpegData
    }

    private static func resize(image: NSImage, maxDimension: CGFloat) -> NSImage {
        let size = image.size
        let ratio = max(size.width, size.height) / maxDimension

        guard ratio > 1 else { return image }

        let newSize = CGSize(width: size.width / ratio, height: size.height / ratio)

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        defer { newImage.unlockFocus() }

        image.draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: size),
            operation: .copy,
            fraction: 1.0
        )

        return newImage
    }
    #endif
}

enum PhotoProcessingError: LocalizedError {
    case invalidImageData
    case compressionFailed
    case unsupportedPlatform

    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data"
        case .compressionFailed:
            return "Failed to compress image"
        case .unsupportedPlatform:
            return "Photo processing not supported on this platform"
        }
    }
}
