//
//  PhotoFilter.swift
//  PhotoFilter
//
//  Created by Shafia Manzoor on 06/10/2026.
//

import CoreImage
import CoreImage.CIFilterBuiltins

/// One-tap preset looks built on Core Image's photo-effect filters.
enum PhotoFilter: String, CaseIterable, Identifiable, Sendable {
    case original, sepia, mono, noir, vivid, chrome

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    /// Pure and lazy: returns a new CIImage "recipe". Nothing is rendered here.
    func apply(to image: CIImage) -> CIImage {
        switch self {
        case .original:
            return image
        case .sepia:
            let f = CIFilter.sepiaTone()
            f.inputImage = image
            f.intensity = 0.8
            return f.outputImage ?? image
        case .mono:
            let f = CIFilter.photoEffectMono()
            f.inputImage = image
            return f.outputImage ?? image
        case .noir:
            let f = CIFilter.photoEffectNoir()
            f.inputImage = image
            return f.outputImage ?? image
        case .vivid:
            let f = CIFilter.vividLightBlendMode()
            f.inputImage = image
            return f.outputImage ?? image
        case .chrome:
            let f = CIFilter.photoEffectChrome()
            f.inputImage = image
            return f.outputImage ?? image
        }
    }
}
