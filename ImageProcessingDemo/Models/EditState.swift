//
//  EditState.swift
//  EditState
//
//  Created by Shafia Manzoor on 06/10/2026.
//

import Foundation

/// Everything the user can change. The edited image is always derived from
/// `original + EditState`, which makes undo/redo and caching trivial.
struct EditState: Equatable, Sendable {
    var filter: PhotoFilter = .original
    var brightness: Float = 0     // -1 ... 1
    var contrast: Float = 1       //  0.5 ... 2
    var saturation: Float = 1     //  0 ... 2
    var exposure: Float = 0       // EV, -2 ... 2
    var sharpness: Float = 0      //  0 ... 2
    var vignette: Float = 0       //  0 ... 2
    var blurRadius: Float = 0     //  0 ... 30 (in preview pixels)
}
