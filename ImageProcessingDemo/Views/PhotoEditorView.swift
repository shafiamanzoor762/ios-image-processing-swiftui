//
//  PhotoEditorView.swift
//  PhotoEditorView
//
//  Created by Shafia Manzoor on 06/10/2026.
//

import SwiftUI
import PhotosUI

struct PhotoEditorView: View {
    @State private var vm = PhotoEditorViewModel()
    @State private var pickerItem: PhotosPickerItem?
    @State private var format: ExportFormat = .jpeg

    var body: some View {
        @Bindable var vm = vm

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    preview

                    if vm.hasImage {
                        FilterPickerView(
                            thumbnails: vm.thumbnails,
                            selected: vm.state.filter,
                            onSelect: vm.selectFilter
                        )

                        AdjustmentPanel(state: $vm.state, onCommit: vm.commitEdit)
                            .padding(.horizontal)

                        exportSection
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Photo Editor")
            .toolbar { toolbar }
            .onChange(of: vm.state) { vm.scheduleRender() }
            .task(id: pickerItem) {
                guard let pickerItem,
                      let data = try? await pickerItem.loadTransferable(type: Data.self)
                else { return }
                await vm.load(data: data)
            }
            .alert("Something went wrong",
                   isPresented: Binding(get: { vm.errorMessage != nil },
                                        set: { if !$0 { vm.errorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
    }

    // MARK: Pieces

    @ViewBuilder
    private var preview: some View {
        if let image = vm.displayImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
        } else {
            ContentUnavailableView(
                "No Photo",
                systemImage: "photo",
                description: Text("Choose an image to start editing.")
            )
            .frame(height: 300)
        }
    }

    private var exportSection: some View {
        VStack(spacing: 12) {
            Picker("Format", selection: $format) {
                ForEach(ExportFormat.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            HStack {
                Button {
                    Task { await vm.export(format: format) }
                } label: {
                    if vm.isExporting {
                        ProgressView()
                    } else {
                        Label("Render Full Resolution", systemImage: "square.and.arrow.down")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isExporting)

                if let url = vm.exportURL {
                    ShareLink(item: url) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button("Undo", systemImage: "arrow.uturn.backward") { vm.undo() }
                .disabled(!vm.canUndo)
            Button("Redo", systemImage: "arrow.uturn.forward") { vm.redo() }
                .disabled(!vm.canRedo)
            Button("Reset", systemImage: "arrow.counterclockwise") { vm.reset() }
                .disabled(!vm.hasImage)
        }
        ToolbarItem(placement: .topBarTrailing) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("Choose", systemImage: "photo.on.rectangle")
            }
        }
    }
}

#Preview {
    PhotoEditorView()
}
