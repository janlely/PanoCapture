//
//  ImageHandler.swift
//  PanoCapture
//
//  Created by jin junjie on 2024/8/24.
//

import Foundation
import Cocoa

class ImageHandler {
    
    static let shared = ImageHandler()
    private var images: [CGImage]!
    
    private init() {}
    
    func clear() {
        images = []
    }
    
    func addImage(_ image: CGImage) {
        images.append(image)
    }
    
    func concatAndSave() throws {
        let date = Date().timeIntervalSince1970
        let savePath = getUserDesktopDirectory()
        var count = 0
        for image in images {
            try saveCGImageToPNG(image, to: (savePath!.appendingPathComponent("\(date)_\(count)")))
        }
        clear()
    }
    
    
    func saveCGImageToPNG(_ cgImage: CGImage, to fileURL: URL) throws {
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        let imageData = nsImage.tiffRepresentation
        guard let data = imageData else {
            throw NSError(domain: "com.example.app", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert CGImage to TIFF data"])
        }
        try data.write(to: fileURL)
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
}
