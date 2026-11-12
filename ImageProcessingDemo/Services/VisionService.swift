//
//  VisionService.swift
//  VisionService
//
//  Created by Shafia Manzoor on 06/10/2026.
//

import UIKit
import Vision
import CoreImage

/// Vision *understands* images (Core Image *modifies* them).
/// All methods run the synchronous Vision handler off the main thread.
enum VisionService {

    private static let ciContext = CIContext()

    enum VisionError: LocalizedError {
        case noSubject, renderFailed
        var errorDescription: String? {
            switch self {
            case .noSubject: "No foreground subject was found."
            case .renderFailed: "The result could not be rendered."
            }
        }
    }

    // MARK: Faces

    /// Returns normalized bounding boxes (origin bottom-left).
    static func detectFaces(in cgImage: CGImage) async throws -> [CGRect] {
        try await Task.detached(priority: .userInitiated) {
            let request = VNDetectFaceRectanglesRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            return (request.results ?? []).map(\.boundingBox)
        }.value
    }

    // MARK: OCR

    static func recognizeText(in cgImage: CGImage) async throws -> [String] {
        try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])
            return (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }
        }.value
    }

    // MARK: Background removal (iOS 17+)

    /// Returns a transparent-background image of the foreground subject(s).
    static func removeBackground(from cgImage: CGImage) async throws -> UIImage {
        try await Task.detached(priority: .userInitiated) {
            let request = VNGenerateForegroundInstanceMaskRequest()
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try handler.perform([request])

            guard let observation = request.results?.first else {
                throw VisionError.noSubject
            }

            let buffer = try observation.generateMaskedImage(
                ofInstances: observation.allInstances,
                from: handler,
                croppedToInstancesExtent: false
            )
            let ci = CIImage(cvPixelBuffer: buffer)
            guard let out = ciContext.createCGImage(ci, from: ci.extent) else {
                throw VisionError.renderFailed
            }
            return UIImage(cgImage: out)
        }.value
    }

    // MARK: Coordinates

    /// Vision uses normalized coordinates with a bottom-left origin.
    static func viewRect(from normalized: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: normalized.minX * size.width,
            y: (1 - normalized.maxY) * size.height,
            width: normalized.width * size.width,
            height: normalized.height * size.height
        )
    }
}
