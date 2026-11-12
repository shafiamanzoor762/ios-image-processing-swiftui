//
//  ImageExporter.swift
//  ImageExporter
//
//  Created by Shafia Manzoor on 06/10/2026.
//

import CoreImage
import ImageIO

enum ExportFormat: String, CaseIterable, Identifiable {
    case jpeg = "JPEG", heic = "HEIC", png = "PNG"

    var id: String { rawValue }
    var fileExtension: String { rawValue.lowercased() }
}

enum ExportError: LocalizedError {
    case renderFailed
    var errorDescription: String? { "The image could not be encoded." }
}

extension ImageProcessor {

    /// Encodes a CIImage directly (no UIImage round trip).
    func encode(
        _ image: CIImage,
        format: ExportFormat,
        quality: CGFloat = 0.9
    ) throws -> Data {
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let qualityKey = CIImageRepresentationOption(
            rawValue: kCGImageDestinationLossyCompressionQuality as String
        )
        let options: [CIImageRepresentationOption: Any] = [qualityKey: quality]

        let data: Data?
        switch format {
        case .jpeg:
            data = context.jpegRepresentation(of: image, colorSpace: colorSpace, options: options)
        case .heic:
            data = context.heifRepresentation(of: image, format: .RGBA8, colorSpace: colorSpace, options: options)
        case .png:
            data = context.pngRepresentation(of: image, format: .RGBA8, colorSpace: colorSpace, options: [:])
        }
        guard let data else { throw ExportError.renderFailed }
        return data
    }
}

enum ImageExporter {
    /// Writes data to a temporary file so it can be shared with `ShareLink`.
    static func writeTemporaryFile(_ data: Data, format: ExportFormat) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("edited-\(UUID().uuidString)")
            .appendingPathExtension(format.fileExtension)
        try data.write(to: url, options: .atomic)
        return url
    }
}
