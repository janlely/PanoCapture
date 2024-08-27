//
//  OverlapFinder.swift
//  PanoCapture
//
//  Created by jin junjie on 2024/8/27.
//

import Foundation
import CoreGraphics
import os.log

class ImageConcator {
    
    static func concatImg(img1: CGImage, img2: CGImage) -> CGImage? {
        let overlapHeight = findOverlapArea(img1: img1, img2: img2)
        guard let newImg2 = img2.cropping(to: CGRect(x: 0, y: overlapHeight,
                                                     width: img2.width, height: img2.height - overlapHeight)) else {
            return nil
        }
        return appendImagesVertically(img1: img1, img2: newImg2)
    }

    private static func findOverlapArea(img1: CGImage, img2: CGImage) -> Int {
        let height1 = img1.height
        let height2 = img2.height
        assert(height2 <= height1)

        var bestHeight = 0
        var bestSSIM: Float = 0
        
        let maxHeight = height2
        // 逐步减少重叠高度
        for currentHeight in (1...maxHeight).reversed() {
            let rect1 = CGRect(x: 0, y: maxHeight - currentHeight, width: img1.width, height: currentHeight)
            let rect2 = CGRect(x: 0, y: 0, width: img2.width, height: currentHeight)

            guard let croppedImage1 = img1.cropping(to: rect1),
                  let croppedImage2 = img2.cropping(to: rect2) else {
                continue
            }

            let currentSSIM = ScreenShotHelper.shared.ssimCalculator.computeSSIM(image1: croppedImage1, image2: croppedImage2)
            
            // 更新找到的最高SSIM值及其对应的高度
            if currentSSIM > bestSSIM {
                bestSSIM = currentSSIM
                bestHeight = currentHeight
            }

            // 如果SSIM非常接近1，可以提前结束搜索
            if currentSSIM > 0.99 {
                break
            }
        }

        os_log(.info, log: log, "Best overlap height: \(bestHeight) with SSIM: \(bestSSIM)")
        return bestHeight
    }
    
    private static func appendImagesVertically(img1: CGImage, img2: CGImage) -> CGImage? {
        let width = max(img1.width, img2.width)
        let height = img1.height + img2.height
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
            return nil
        }
        
        // Draw the first image
        context.draw(img1, in: CGRect(x: 0, y: img2.height, width: img1.width, height: img1.height))
        
        // Draw the second image
        context.draw(img2, in: CGRect(x: 0, y: 0, width: img2.width, height: img2.height))
        
        // Create a new CGImage from context
        let newCGImage = context.makeImage()
        return newCGImage
    }

}

