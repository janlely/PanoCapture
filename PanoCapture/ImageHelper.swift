//
//  ImageHandler.swift
//  PanoCapture
//
//  Created by jin junjie on 2024/8/24.
//

import Foundation
import Cocoa
import os.log
import CryptoKit

class ImageHelper {
    
    static let shared = ImageHelper()
    private var images: [CGImage] = []
    
    private init() {}
    
    func clear() {
        images = []
    }
    
    func addImage(_ image: CGImage?) {
        if let image = image {
            images.append(image)
        }
    }
    
    func save() throws {
        defer {
            clear()
        }
        if images.isEmpty {
            os_log(.error, log: log, "no image to save")
            return
        }
        let date = Date().timeIntervalSince1970
        guard let savePath = promptForDirectoryURL() else {
            os_log(.info, log: log, "error choose save path")
            clear()
            return
        }
       
        //begin debug
        var count = 0
        for image in images {
            try saveCGImageToPNG(image, to: (savePath.appendingPathComponent("PanoCapture_\(date)_\(count).png")))
            count += 1
        }
        //end debug
    
        var resultImg = images[0]
        for image in images.dropFirst() {
            guard let concatImg = ImageConcator.concatImg(img1: resultImg, img2: image) else {
                os_log(.error, log: log, "error concat image")
                return
            }
            resultImg = concatImg
        }
        try saveCGImageToPNG(resultImg, to: (savePath.appendingPathComponent("PanoCapture_\(date).png")))
        os_log(.info, log: log, "image save done")
    }
    
    
    private func saveCGImageToPNG(_ cgImage: CGImage, to fileURL: URL) throws {
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        guard let imageData = nsImage.tiffRepresentation else {
            throw NSError(domain: "com.example.app", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert CGImage to TIFF data"])
        }
        try imageData.write(to: fileURL)
    }
    
    private func getUserDesktopDirectory() -> URL? {
        // 获取桌面目录
        let desktopDirectory = FileManager.SearchPathDirectory.desktopDirectory
        let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        
        if let paths = NSSearchPathForDirectoriesInDomains(desktopDirectory, userDomainMask, true).first {
            return URL(fileURLWithPath: paths)
        }
        
        return nil
    }
    private func promptForDirectoryURL() -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select a Directory to Save Your File"
        openPanel.showsResizeIndicator = true
        openPanel.showsHiddenFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.canChooseFiles = false  // 确保不能选择文件

        if openPanel.runModal() == .OK {
            return openPanel.url
        } else {
            return nil
        }
    }

//    func selectPixels(from image: CGImage, gridSize: Int) -> [CGPoint] {
//        let width = image.width
//        let height = image.height
//        let gridWidth = width / gridSize
//        let gridHeight = height / gridSize
//        var points: [CGPoint] = []
//
//        for i in 0..<gridSize {
//            for j in 0..<gridSize {
//                // Center point
//                let centerX = (i * gridWidth) + gridWidth / 2
//                let centerY = (j * gridHeight) + gridHeight / 2
//                points.append(CGPoint(x: centerX, y: centerY))
//                // Corners
//                points.append(CGPoint(x: i * gridWidth, y: j * gridHeight))
//                points.append(CGPoint(x: (i + 1) * gridWidth - 1, y: j * gridHeight))
//                points.append(CGPoint(x: i * gridWidth, y: (j + 1) * gridHeight - 1))
//                points.append(CGPoint(x: (i + 1) * gridWidth - 1, y: (j + 1) * gridHeight - 1))
//            }
//        }
//        return points
//    }

//    func colorAtPoint(image: CGImage, point: CGPoint) -> NSColor? {
//        let dataProvider = image.dataProvider
//        let data = dataProvider?.data
//        let dataPtr = CFDataGetBytePtr(data)
//        let bytesPerPixel = image.bitsPerPixel / 8
//        let pixelOffset = Int(point.y) * image.bytesPerRow + Int(point.x) * bytesPerPixel
//
//        if let dataPtr = dataPtr {
//            let r = dataPtr[pixelOffset]
//            let g = dataPtr[pixelOffset + 1]
//            let b = dataPtr[pixelOffset + 2]
//            let a = image.bitsPerComponent == 32 ? dataPtr[pixelOffset + 3] : 255
//            return NSColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
//        }
//        return nil
//    }
//
//    func areImagesSimilar(image1: CGImage, image2: CGImage, gridSize: Int, tolerance: CGFloat) -> Bool {
//        let points = selectPixels(from: image1, gridSize: gridSize)
//        for point in points {
//            guard let color1 = colorAtPoint(image: image1, point: point),
//                  let color2 = colorAtPoint(image: image2, point: point) else {
//                return false
//            }
//            
//            var red1: CGFloat = 0, green1: CGFloat = 0, blue1: CGFloat = 0, alpha1: CGFloat = 0
//            var red2: CGFloat = 0, green2: CGFloat = 0, blue2: CGFloat = 0, alpha2: CGFloat = 0
//            
//            color1.getRed(&red1, green: &green1, blue: &blue1, alpha: &alpha1)
//            color2.getRed(&red2, green: &green2, blue: &blue2, alpha: &alpha2)
//            
//            let diff = max(abs(red1 - red2), abs(green1 - green2), abs(blue1 - blue2), abs(alpha1 - alpha2))
//            
//            if diff > tolerance {
//                return false
//            }
//        }
//        return true
//    }
    
//    func cgImageToData(_ image: CGImage) -> Data? {
//        let width = image.width
//        let height = image.height
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        let bytesPerPixel = 4
//        let bytesPerRow = bytesPerPixel * width
//        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
//        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else { return nil }
//        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
//        guard let data = context.data else { return nil }
//        return Data(bytes: data, count: bytesPerRow * height)
//    }
//
//    func sha256(data: Data) -> String {
//        let hash = SHA256.hash(data: data)
//        return hash.compactMap { String(format: "%02x", $0) }.joined()
//    }
//    
//    func areImagesEqual(_ image1: CGImage, _ image2: CGImage) -> Bool {
//        guard let imageData1 = cgImageToData(image1),
//              let imageData2 = cgImageToData(image2) else {
//            return false
//        }
//
//        let hash1 = sha256(data: imageData1)
//        let hash2 = sha256(data: imageData2)
//
//        return hash1 == hash2
//    }
}
