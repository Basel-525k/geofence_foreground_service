import Foundation
import UserNotifications
import UIKit

struct ThumbnailGenerator {
    enum ThumbnailIcon {
        case startWork
        case success
        case failure

        var textValue: String {
            switch self {
            case .startWork:
                return ["👷‍♀️", "👷‍♂️"].randomElement()!
            case .success:
                return "🎉"
            case .failure:
                return "🔥"
            }
        }
    }

    static func createThumbnail(with icon: ThumbnailIcon) -> UNNotificationAttachment? {
        let name = "thumbnail"
        let thumbnailFrame = CGRect(x: 0, y: 0, width: 150, height: 150)
        let thumbnail = UIView(frame: thumbnailFrame)
        thumbnail.isOpaque = false
        let label = UILabel(frame: thumbnailFrame)
        label.text = icon.textValue
        label.font = UIFont.systemFont(ofSize: 125)
        label.textAlignment = .center
        thumbnail.addSubview(label)

        do {
            let thumbnailImage = try thumbnail.renderAsImage()
            let localURL = try thumbnailImage.persist(fileName: name)
            return try UNNotificationAttachment(
                identifier: "\(GeofenceForegroundServicePlugin.identifier).\(name)",
                url: localURL,
                options: nil
            )
        } catch {
//            logInfo("\(logPrefix) \(#function) something went wrong creating a thumbnail for local debug notification")
            return nil
        }

    }

    private static var logPrefix: String {
        return "\(String(describing: GeofenceForegroundServicePlugin.self)) - \(ThumbnailGenerator.self)"
    }

}

private extension UIView {

    func renderAsImage() throws -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.isOpaque, 0.0)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else {
            throw GraphicsError.noCurrentGraphicsContextFound
        }
        self.layer.render(in: context)
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            throw GraphicsError.noCurrentGraphicsContextFound
        }

        return image
    }

    enum GraphicsError: Error {
        case noCurrentGraphicsContextFound
    }
}

private extension UIImage {

    func persist(fileName: String, in directory: URL = URL(fileURLWithPath: NSTemporaryDirectory())) throws -> URL {
        let directoryURL = directory.appendingPathComponent(GeofenceForegroundServicePlugin.identifier, isDirectory: true)
        let fileURL = directoryURL.appendingPathComponent("\(fileName).png")
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        guard let imageData = self.pngData() else {
            throw ImageError.cannotRepresentAsPNG(self)
        }
        try imageData.write(to: fileURL)

        return fileURL
    }

    enum ImageError: Error {
        case cannotRepresentAsPNG(UIImage)
    }

}
