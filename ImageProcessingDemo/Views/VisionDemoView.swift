//
//  VisionDemoView.swift
//  VisionDemoView
//
//  Created by Shafia Manzoor on 06/10/2026.
//

import SwiftUI
import PhotosUI
import Vision

struct VisionDemoView: View {

    enum Mode: String, CaseIterable, Identifiable {
        case faces = "Faces", text = "Text (OCR)", background = "Remove BG"
        var id: String { rawValue }
    }

    @State private var pickerItem: PhotosPickerItem?
    @State private var image: UIImage?               // always upright
    @State private var mode: Mode = .faces
    @State private var faces: [CGRect] = []
    @State private var recognizedText: [String] = []
    @State private var cutout: UIImage?
    @State private var isWorking = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Mode", selection: $mode) {
                        ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    imageArea

                    Button {
                        Task { await run() }
                    } label: {
                        if isWorking { ProgressView() } else { Text("Analyze") }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(image == nil || isWorking)

                    if mode == .text, !recognizedText.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(recognizedText.enumerated()), id: \.offset) { _, line in
                                Text(line)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                    }

                    if let errorMessage {
                        Text(errorMessage).foregroundStyle(.red).font(.callout)
                    }
                }
                .padding()
            }
            .navigationTitle("Vision")
            .toolbar {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label("Choose", systemImage: "photo.on.rectangle")
                }
            }
            .onChange(of: mode) { clearResults() }
            .task(id: pickerItem) {
                guard let pickerItem,
                      let data = try? await pickerItem.loadTransferable(type: Data.self),
                      let ui = UIImage(data: data)
                else { return }
                image = ui.normalizedOrientation()
                clearResults()
            }
        }
    }

    // MARK: Image + overlays

    @ViewBuilder
    private var imageArea: some View {
        if let image {
            if mode == .background, let cutout {
                Image(uiImage: cutout)
                    .resizable().scaledToFit()
                    .background(Color.secondary.opacity(0.25))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Image(uiImage: image)
                    .resizable().scaledToFit()
                    .overlay {
                        if mode == .faces {
                            GeometryReader { geo in
                                ForEach(Array(faces.enumerated()), id: \.offset) { _, face in
                                    let r = VisionService.viewRect(from: face, in: geo.size)
                                    Rectangle()
                                        .stroke(.yellow, lineWidth: 2)
                                        .frame(width: r.width, height: r.height)
                                        .position(x: r.midX, y: r.midY)
                                }
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        } else {
            ContentUnavailableView("No Photo", systemImage: "eye",
                                   description: Text("Choose an image to analyze."))
                .frame(height: 260)
        }
    }

    // MARK: Actions

    private func clearResults() {
        faces = []; recognizedText = []; cutout = nil; errorMessage = nil
    }

    private func run() async {
        guard let cgImage = image?.cgImage else { return }
        clearResults()
        isWorking = true
        defer { isWorking = false }

        do {
            switch mode {
            case .faces:
                faces = try await VisionService.detectFaces(in: cgImage)
                if faces.isEmpty { errorMessage = "No faces found." }
            case .text:
                recognizedText = try await VisionService.recognizeText(in: cgImage)
                if recognizedText.isEmpty { errorMessage = "No text found." }
            case .background:
                cutout = try await VisionService.removeBackground(from: cgImage)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    VisionDemoView()
}
