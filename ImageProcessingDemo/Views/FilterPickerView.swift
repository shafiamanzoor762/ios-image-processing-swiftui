//
//  FilterPickerView.swift
//  FilterPickerView
//
//  Created by Shafia Manzoor on 06/10/2026.
//

import SwiftUI

struct FilterPickerView: View {
    let thumbnails: [PhotoFilter: UIImage]
    let selected: PhotoFilter
    var onSelect: (PhotoFilter) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(PhotoFilter.allCases) { filter in
                    Button { onSelect(filter) } label: {
                        VStack(spacing: 4) {
                            thumbnail(for: filter)
                                .frame(width: 64, height: 64)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selected == filter ? Color.accentColor : .clear, lineWidth: 3)
                                }
                            Text(filter.title)
                                .font(.caption2)
                                .foregroundStyle(selected == filter ? Color.accentColor : .secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func thumbnail(for filter: PhotoFilter) -> some View {
        if let image = thumbnails[filter] {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            Color.secondary.opacity(0.2)
        }
    }
}
