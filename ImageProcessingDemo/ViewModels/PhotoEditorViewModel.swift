//
//  PhotoEditorViewModel.swift
//  PhotoEditorViewModel
//
//  Created by Shafia Manzoor on 06/10/2026.
//

import SwiftUI
import CoreImage

@MainActor
@Observable
final class PhotoEditorViewModel {

    // Sources
    private(set) var previewSource: CIImage?     // downsampled, for interaction
    private(set) var fullSource: CIImage?        // full resolution, for export
    private(set) var displayImage: UIImage?
    private(set) var thumbnails: [PhotoFilter: UIImage] = [:]

    // Edit state
    var state = EditState()
    private var undoStack: [EditState] = []
    private var redoStack: [EditState] = []

    var canUndo: Bool { undoStack.count > 1 }
    var canRedo: Bool { !redoStack.isEmpty }
    var hasImage: Bool { previewSource != nil }

    // Export
    private(set) var isExporting = false
    private(set) var exportURL: URL?
    var errorMessage: String?

    private let processor = ImageProcessor()
    private var renderTask: Task<Void, Never>?

    // MARK: Loading

    func load(data: Data) async {
        typealias Loaded = (preview: CIImage, full: CIImage, thumbSource: CIImage)

        let loaded: Loaded? = await Task.detached(priority: .userInitiated) {
            guard
                let previewUI = ImageDownsampler.downsample(data: data, maxPixelSize: 1600),
                let previewCI = CIImage(image: previewUI),
                let thumbUI = ImageDownsampler.downsample(data: data, maxPixelSize: 160),
                let thumbCI = CIImage(image: thumbUI),
                let fullCI = CIImage(data: data, options: [.applyOrientationProperty: true])
            else { return nil }
            return (previewCI, fullCI, thumbCI)
        }.value

        guard let loaded else {
            errorMessage = "That image could not be loaded."
            return
        }

        previewSource = loaded.preview
        fullSource = loaded.full
        state = EditState()
        undoStack = [state]
        redoStack = []
        exportURL = nil
        scheduleRender(immediately: true)
        await buildThumbnails(from: loaded.thumbSource)
    }

    private func buildThumbnails(from source: CIImage) async {
        var result: [PhotoFilter: UIImage] = [:]
        for filter in PhotoFilter.allCases {
            if let image = await processor.render(filter.apply(to: source)) {
                result[filter] = image
            }
        }
        thumbnails = result
    }

    // MARK: Rendering (debounced + cancellable)

    func scheduleRender(immediately: Bool = false) {
        renderTask?.cancel()
        exportURL = nil
        guard let source = previewSource else { return }
        let state = self.state

        renderTask = Task { [processor] in
            if !immediately {
                try? await Task.sleep(for: .milliseconds(30))   // debounce
            }
            guard !Task.isCancelled else { return }

            let image = await processor.process(source, state: state)
            guard !Task.isCancelled else { return }
            self.displayImage = image
        }
    }

    // MARK: History

    /// Call when a gesture ends (slider released, filter tapped).
    func commitEdit() {
        guard state != undoStack.last else { return }
        undoStack.append(state)
        redoStack.removeAll()
    }

    func selectFilter(_ filter: PhotoFilter) {
        state.filter = filter
        commitEdit()
    }

    func undo() {
        guard canUndo else { return }
        redoStack.append(undoStack.removeLast())
        state = undoStack[undoStack.count - 1]
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(next)
        state = next
    }

    func reset() {
        state = EditState()
        commitEdit()
    }

    // MARK: Export (full resolution)

    func export(format: ExportFormat, quality: CGFloat = 0.9) async {
        guard let full = fullSource, let preview = previewSource else { return }
        isExporting = true
        defer { isExporting = false }

        // Blur/sharpen radii are in pixels: scale them up to match the preview look.
        let ratio = Float(full.extent.width / max(preview.extent.width, 1))
        let edited = processor.apply(state, to: full, radiusScale: ratio)

        do {
            let data = try await processor.encode(edited, format: format, quality: quality)
            exportURL = try ImageExporter.writeTemporaryFile(data, format: format)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
