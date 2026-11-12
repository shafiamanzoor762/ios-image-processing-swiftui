//
//  ImageProcessor.swift
//  ImageProcessor
//
//  Created by Shafia Manzoor on 06/10/2026.
//

import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

/// Owns the single shared CIContext and turns an `EditState` into pixels.
actor ImageProcessor {

    /// One shared context (Metal-backed on device). Never create one per call.
    let context = CIContext(options: [.cacheIntermediates: false])

    // MARK: - Build the (lazy) filter graph

    /// Pure and lazy. `radiusScale` lets the full-resolution export match the
    /// look of the downsampled preview (blur/sharpen radii are in pixels).
    nonisolated func apply(
        _ state: EditState,
        to input: CIImage,
        radiusScale: Float = 1
    ) -> CIImage {
        var image = state.filter.apply(to: input)

        let color = CIFilter.colorControls()
        color.inputImage = image
        color.brightness = state.brightness
        color.contrast = state.contrast
        color.saturation = state.saturation
        image = color.outputImage ?? image

        if state.exposure != 0 {
            let f = CIFilter.exposureAdjust()
            f.inputImage = image
            f.ev = state.exposure
            image = f.outputImage ?? image
        }

        if state.sharpness > 0 {
            let f = CIFilter.sharpenLuminance()
            f.inputImage = image
            f.sharpness = state.sharpness
            f.radius = 1.69 * radiusScale
            image = f.outputImage ?? image
        }

        if state.vignette > 0 {
            let f = CIFilter.vignette()
            f.inputImage = image
            f.intensity = state.vignette
            f.radius = 2
            image = f.outputImage ?? image
        }

        if state.blurRadius > 0 {
            let original = image.extent
            let f = CIFilter.gaussianBlur()
            f.inputImage = image.clampedToExtent()   // avoid transparent edges
            f.radius = state.blurRadius * radiusScale
            image = (f.outputImage ?? image).cropped(to: original)
        }

        return image
    }

    // MARK: - Render

    func render(_ image: CIImage) -> UIImage? {
        guard let cgImage = context.createCGImage(image, from: image.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
    }

    func process(
        _ input: CIImage,
        state: EditState,
        radiusScale: Float = 1
    ) -> UIImage? {
        render(apply(state, to: input, radiusScale: radiusScale))
    }
}
