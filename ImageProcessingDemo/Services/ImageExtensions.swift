//
//  ImageExtensions.swift
//  ImageExtensions
//
//  Created by Shafia Manzoor on 06/10/2026.
//

import UIKit
import ImageIO

extension UIImage {

    /// Returns an image with `.up` orientation and pixels physically rotated.
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// Resizes an already-decoded image. For big photos prefer `ImageDownsampler`.
    func resized(to newSize: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    /// Crops using a rect expressed in *pixel* coordinates of the upright image.
    func cropped(toPixelRect rect: CGRect) -> UIImage? {
        let upright = normalizedOrientation()
        guard let cropped = upright.cgImage?.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cropped, scale: upright.scale, orientation: .up)
    }
}

extension CGImagePropertyOrientation {
    init(_ ui: UIImage.Orientation) {
        switch ui {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
