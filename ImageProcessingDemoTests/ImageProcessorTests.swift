//
//  ImageProcessorTests.swift
//  ImageProcessorTests
//
//  Created by Shafia Manzoor on 06/10/2026.
//

import XCTest
import CoreImage
import CoreImage.CIFilterBuiltins
@testable import ImageProcessingDemo

final class ImageProcessorTests: XCTestCase {

    private let processor = ImageProcessor()

    private func solid(_ gray: CGFloat, size: CGFloat = 64) -> CIImage {
        CIImage(color: CIColor(red: gray, green: gray, blue: gray))
            .cropped(to: CGRect(x: 0, y: 0, width: size, height: size))
    }

    /// Average red channel (0...255) of an image.
    private func averageRed(_ image: CIImage) -> Int {
        let filter = CIFilter.areaAverage()
        filter.inputImage = image
        filter.extent = image.extent
        var pixel = [UInt8](repeating: 0, count: 4)
        CIContext().render(
            filter.outputImage!,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpace(name: CGColorSpace.sRGB)
        )
        return Int(pixel[0])
    }

    func testDefaultStateKeepsExtent() {
        let input = solid(0.3)
        let output = processor.apply(EditState(), to: input)
        XCTAssertEqual(output.extent, input.extent)
    }

    func testBrightnessIncreasesPixelValues() {
        let input = solid(0.3)
        var state = EditState()
        state.brightness = 0.4
        let before = averageRed(processor.apply(EditState(), to: input))
        let after = averageRed(processor.apply(state, to: input))
        XCTAssertGreaterThan(after, before)
    }

    func testBlurKeepsOriginalExtent() {
        var state = EditState()
        state.blurRadius = 10
        let input = solid(0.5)
        XCTAssertEqual(processor.apply(state, to: input).extent, input.extent)
    }

    func testEveryFilterRenders() async {
        for filter in PhotoFilter.allCases {
            var state = EditState()
            state.filter = filter
            let image = await processor.process(solid(0.5), state: state)
            XCTAssertNotNil(image, "Filter \(filter) failed to render")
        }
    }

    func testEncodeProducesData() async throws {
        for format in ExportFormat.allCases {
            let data = try await processor.encode(solid(0.5), format: format)
            XCTAssertFalse(data.isEmpty, "\(format) produced no data")
        }
    }

    func testDownsampleRespectsMaxPixelSize() throws {
        let big = UIGraphicsImageRenderer(size: CGSize(width: 2000, height: 1000)).image {
            UIColor.red.setFill(); $0.fill(CGRect(x: 0, y: 0, width: 2000, height: 1000))
        }
        let data = try XCTUnwrap(big.pngData())
        let small = try XCTUnwrap(ImageDownsampler.downsample(data: data, maxPixelSize: 500))
        let longest = max(small.size.width * small.scale, small.size.height * small.scale)
        XCTAssertLessThanOrEqual(longest, 500)
    }

    func testVisionRectConversionFlipsY() {
        let rect = VisionService.viewRect(
            from: CGRect(x: 0.1, y: 0.1, width: 0.2, height: 0.3),
            in: CGSize(width: 100, height: 200)
        )
        XCTAssertEqual(rect.minX, 10, accuracy: 0.001)
        XCTAssertEqual(rect.minY, 120, accuracy: 0.001)   // (1 - 0.4) * 200
        XCTAssertEqual(rect.height, 60, accuracy: 0.001)
    }
}
