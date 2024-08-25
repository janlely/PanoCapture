//
//  ImageHandler.swift
//  PanoCapture
//
//  Created by jin junjie on 2024/8/24.
//

import Foundation
import Cocoa
import os.log

class ImageHandler {
    
    static let shared = ImageHandler()
    private var images: [CGImage] = []
    
    private init() {}
    
    func clear() {
        images = []
    }
    
    func addImage(_ image: CGImage) {
        images.append(image)
    }
    
    func save() throws {
        let date = Date().timeIntervalSince1970
        guard let savePath = promptForDirectoryURL() else {
            os_log(.info, log: log, "error choose save path")
            clear()
            return
        }
        var count = 0
        for image in images {
            try saveCGImageToPNG(image, to: (savePath.appendingPathComponent("PanoCapture_\(date)_\(count).png")))
            count += 1
        }
        clear()
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

}
