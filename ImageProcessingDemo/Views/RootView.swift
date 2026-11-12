//
//  RootView.swift
//  RootView
//
//  Created by Shafia Manzoor on 06/10/2026.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            PhotoEditorView()
                .tabItem { Label("Editor", systemImage: "slider.horizontal.3") }

            VisionDemoView()
                .tabItem { Label("Vision", systemImage: "eye") }
        }
    }
}

#Preview {
    RootView()
}
