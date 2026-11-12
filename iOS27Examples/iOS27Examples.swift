//
//  iOS27Examples.swift
//  iOS27Examples
//
//  Created by Shafia Manzoor on 06/10/2026.
//

// iOS 27 EXAMPLES — NOT part of the default build.
//
// These snippets are adapted from Apple's WWDC26 sessions
// "What's new in image understanding" (237) and "Enhance RAW image processing
// with Core Image" (305). API surfaces may differ in the shipping Xcode 27 SDK.
//
// To try them: use Xcode 27, add this file to the app target, and add the
// Swift compilation condition ENABLE_IOS27_EXAMPLES
// (Build Settings > Active Compilation Conditions). Fix any signature
// differences against the SDK documentation.

#if ENABLE_IOS27_EXAMPLES

import UIKit
import CoreImage
import Vision
import FoundationModels

// MARK: - Core Image RAW

@available(iOS 27, *)
enum RAWExamples {

    /// Don't render more pixels than you display.
    static func preview(url: URL, maxDimension: CGFloat) -> CIImage? {
        guard let raw = CIRAWFilter(imageURL: url) else { return nil }
        let longest = max(raw.nativeSize.width, raw.nativeSize.height)
        raw.scaleFactor = Float(min(1, maxDimension / longest))
        return raw.outputImage
    }

    static func exportJPEG(_ image: CIImage, to url: URL, context: CIContext) throws {
        guard let space = CGColorSpace(name: CGColorSpace.displayP3) else { return }
        try context.writeJPEGRepresentation(of: image, to: url, colorSpace: space, options: [:])
    }
}

// MARK: - Vision tap-to-segment

@available(iOS 27, *)
enum SegmentationExamples {

    /// `seed` is normalized (0...1), origin bottom-left.
    static func segment(_ image: CGImage, seed: NormalizedPoint) async throws -> CVPixelBuffer? {
        let handler = ImageRequestHandler(image)
        let request = GenerateIterativeSegmentationRequest(seed: seed)
        let observation = try await handler.perform(request)
        return observation?.pixelBuffer
    }

    /// Cut an object out with Core Image using the returned mask.
    static func cutout(foreground: CIImage, background: CIImage, mask: CIImage) -> CIImage {
        let blend = CIFilter.blendWithMask()
        blend.inputImage = foreground
        blend.backgroundImage = background
        blend.maskImage = mask
        return blend.outputImage ?? foreground
    }
}

// MARK: - Foundation Models image input

@available(iOS 27, *)
enum FoundationModelsImageExamples {

    static func caption(for image: UIImage, session: LanguageModelSession) async throws -> String {
        let prompt = Prompt {
            "Generate a short, descriptive caption for this image."
            Attachment(image)
        }
        let response = try await session.respond(to: prompt)
        return response.content
    }
}

// MARK: - Saliency crop (also on watchOS)

@available(iOS 27, *)
enum SaliencyExamples {

    static func prominentSubject(in image: CGImage) async throws -> NormalizedRect? {
        let request = GenerateObjectnessBasedSaliencyImageRequest()
        let observation = try await request.perform(on: image)
        return observation.salientObjects.first
    }
}

#endif
