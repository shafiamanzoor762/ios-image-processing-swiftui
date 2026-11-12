# Ios Image Processing Swiftui

A SwiftUI photo editor that demonstrates image processing on iOS with
**Core Image**, **ImageIO**, **Vision** and Swift concurrency. Companion code for the article
*Image Processing in iOS with Swift & SwiftUI: The Complete Guide (Core Image, Vision, Accelerate & iOS 27)*.

## Features

- Pick photos with `PhotosPicker`
- Non-destructive editing: `original + EditState` → image (undo / redo / reset)
- Filters (sepia, mono, noir, vivid, chrome) with live thumbnails
- Brightness, contrast, saturation, exposure, sharpness, vignette, blur
- Fast preview (downsampled with ImageIO) and full-resolution export (JPEG / HEIC / PNG)
- Debounced, cancellable rendering off the main thread via an `actor`
- Vision demos: face detection, OCR, background removal
- Unit tests for the processor, downsampler and coordinate conversion
- `iOS27Examples/` — opt-in snippets for iOS 27 APIs (Xcode 27)

## Requirements

- Xcode 15.4+ (Xcode 16+ recommended)
- iOS 17.0+ deployment target (Observation framework, `VNGenerateForegroundInstanceMaskRequest`)
- Use **Swift 5 language mode** if Swift 6 strict concurrency reports Sendable warnings
  for `CIImage` / `CGImage`. Run on a real device for the best Vision/Core Image performance.

## Create the Xcode project (2 minutes)

This repo contains source files only. To build:

1. **File ▸ New ▸ Project ▸ iOS ▸ App**
   - Product Name: `ImageProcessingDemo` (the tests use `@testable import ImageProcessingDemo`)
   - Interface: **SwiftUI**, Language: **Swift**, Include Tests: ✅
   - Minimum deployment: **iOS 17.0**
2. Delete the generated `ContentView.swift` and the generated `...App.swift`.
3. Drag the folders `App`, `Models`, `Services`, `ViewModels`, `Views` from
   `ImageProcessingDemo/` into the app target (✅ *Copy items if needed*, ✅ app target).
4. Replace the generated test file with `ImageProcessingDemoTests/ImageProcessorTests.swift`.
5. Run (⌘R). `PhotosPicker` needs **no** photo-library permission.

## Project layout

```text
ImageProcessingDemo/
├── App/            ImageProcessingDemoApp.swift
├── Models/         EditState.swift, PhotoFilter.swift
├── Services/       ImageProcessor.swift      (actor + shared CIContext)
│                   ImageDownsampler.swift    (ImageIO thumbnails)
│                   ImageExporter.swift       (JPEG / HEIC / PNG encode)
│                   ImageExtensions.swift     (orientation, resize, crop)
│                   VisionService.swift       (faces, OCR, background removal)
├── ViewModels/     PhotoEditorViewModel.swift
└── Views/          RootView, PhotoEditorView, AdjustmentPanel,
                    FilterPickerView, VisionDemoView
ImageProcessingDemoTests/   ImageProcessorTests.swift
iOS27Examples/              iOS27Examples.swift (opt-in, Xcode 27)
```

## Architecture

```text
SwiftUI Views ─▶ PhotoEditorViewModel ─▶ ImageProcessor (actor) ─▶ Core Image
                                      └▶ VisionService ──────────▶ Vision
```

## iOS 27 examples

`iOS27Examples/iOS27Examples.swift` is wrapped in `#if ENABLE_IOS27_EXAMPLES`.
With Xcode 27, add the file to your target and set the *Active Compilation Condition*
`ENABLE_IOS27_EXAMPLES`. These snippets follow WWDC26 sample code and may need small
signature fixes against the shipping SDK.

## License

