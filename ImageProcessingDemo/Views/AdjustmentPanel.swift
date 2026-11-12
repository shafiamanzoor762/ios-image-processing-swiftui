//
//  AdjustmentPanel.swift
//  AdjustmentPanel
//
//  Created by Shafia Manzoor on 06/10/2026.
//

import SwiftUI

struct AdjustmentPanel: View {
    @Binding var state: EditState
    var onCommit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            row("Brightness", $state.brightness, -1...1)
            row("Contrast",   $state.contrast,   0.5...2)
            row("Saturation", $state.saturation, 0...2)
            row("Exposure",   $state.exposure,  -2...2)
            row("Sharpness",  $state.sharpness,  0...2)
            row("Vignette",   $state.vignette,   0...2)
            row("Blur",       $state.blurRadius, 0...30)
        }
    }

    private func row(_ title: String, _ value: Binding<Float>, _ range: ClosedRange<Float>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Slider(value: value, in: range) { editing in
                if !editing { onCommit() }
            }
        }
    }
}
