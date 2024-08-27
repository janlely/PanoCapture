//
//  MainView.swift
//  PanoCapture
//
//  Created by jin junjie on 2024/8/20.
//

import Foundation
import Cocoa
import os.log

class MainView: NSView, CAAnimationDelegate {
    
    var startPoint: NSPoint?
    var currentPoint: NSPoint?
    var selectionRect: NSRect!
    var selectionLayer: CAShapeLayer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        os_log(.info, log: log, "wantsLayer ")
        self.wantsLayer = true // 告诉NSView使用layer
        self.layer = CALayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        os_log(.info, log: log, "wantsLayer ")
        self.wantsLayer = true // 告诉NSView使用layer
        self.layer = CALayer()
    }
    
    
    override func mouseDown(with event: NSEvent) {
        NSLog("\(String(describing: NSWorkspace.shared.frontmostApplication?.bundleIdentifier))")
        startPoint = event.locationInWindow
    }
    
    override func mouseDragged(with event: NSEvent) {
        currentPoint = event.locationInWindow
        updateSelectionLayer()
    }
    
    override func mouseUp(with event: NSEvent) {
        NSLog("mouseUp")
        needsDisplay = true
        guard let sp = startPoint, let cp = currentPoint else {
            return
        }
        if abs(sp.x - cp.x) < 5 || abs(sp.y - cp.y) < 5 {
            return
        }
        //截图区域为选择区域向内缩小一个像素，避免边框被截到
        if let selectionRect = selectionRect?.insetBy(dx: 1, dy: 1) {
            if ScreenShotHelper.shared.isNormalMode {
                ImageHelper.shared.addImage(ScreenShotHelper.shared.capture(selectionRect))
                playCaptureAnimation(selectionRect) {
                    ScreenShotHelper.shared.clear()
                    ScreenShotHelper.shared.save()
                }
            }else {
                self.window?.ignoresMouseEvents = true
                NSCursor.arrow.set()
                //TODO: 开启一个定时任务，定时截取区域中的图像，如果图像发生变动且停留达到0.75秒则再截取一张，同时立即渲染一个结束按钮
                dynamicCapture(selectionRect, lastImage: nil, isNew: true, repeat: 0)
                
            }
        }
    }
    
    func dynamicCapture(_ rect: NSRect, lastImage: CGImage?, isNew: Bool, repeat: Int) {
        if ScreenShotHelper.shared.isStopped {
            //手动停止
            os_log(.info, log: log, "capture stopped")
            return
        }
        guard let image = ScreenShotHelper.shared.capture(rect) else {
            //获取屏幕截图失败
            os_log(.error, log: log, "error capture screen")
            return
        }
        switch nameItLater(image1: lastImage, image2: image, isNew: isNew, repeat: `repeat`) {
        case .begin, .satisfied:
            ImageHelper.shared.addImage(image)
            playCaptureAnimation(rect) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.dynamicCapture(rect, lastImage: image, isNew: false, repeat: 0)
                }
            }
        case .captured:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.dynamicCapture(rect, lastImage: image, isNew: false, repeat: 0)
            }
        case .changing:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.dynamicCapture(rect, lastImage: image, isNew: true, repeat: 0)
            }
        case .staying:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.dynamicCapture(rect, lastImage: image, isNew: true, repeat: `repeat`+1)
            }
        }
    }
    
    //比较前后两张截图，推断是否为用户想要添加的截图
    func nameItLater(image1: CGImage?, image2: CGImage, isNew: Bool, repeat: Int) -> NameItLater {
        //第一张图
        guard let image1 = image1 else {
            return .begin
        }
        
        //正在改变内容
        if !sameImage(image1: image1, image2: image2) {
            return .changing
        }
        
        //已经截过了
        if !isNew {
            return .captured
        }
        
        //停留时间不足
        if `repeat` < 2 {
            return .staying
        }
        
        //可以截图了
        return .satisfied
    }
    
    func sameImage(image1: CGImage, image2: CGImage) -> Bool {
        os_log(.info, log: log, "start at: \(Date().timeIntervalSince1970)")
        let result = ScreenShotHelper.shared.ssimCalculator.computeSSIM(image1: image1, image2: image2)
        os_log(.info, log: log, "end at: \(Date().timeIntervalSince1970), result: \(result)")
        return result > 0.99
    }
    
    override func viewDidMoveToWindow() {
        window?.acceptsMouseMovedEvents = true
        window?.contentView?.postsFrameChangedNotifications = true
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    
    func updateSelectionLayer() {
        if selectionLayer == nil {
            selectionLayer = CAShapeLayer()
            selectionLayer?.strokeColor = NSColor.blue.cgColor
            selectionLayer?.fillColor = nil // 无填充
            selectionLayer?.lineWidth = 1.0
            self.layer?.addSublayer(selectionLayer!)
        }
        
        if let startPoint = startPoint, let currentPoint = currentPoint {
            selectionRect = NSRect(x: min(startPoint.x, currentPoint.x),
                              y: min(startPoint.y, currentPoint.y),
                              width: abs(currentPoint.x - startPoint.x),
                              height: abs(currentPoint.y - startPoint.y))
            selectionLayer?.path = CGPath(rect: selectionRect, transform: nil)
        }
    }
    
    func removeSubLayer() {
        self.selectionLayer?.removeFromSuperlayer()
        self.selectionLayer = nil
    }
    
    func playCaptureAnimation(_ rect: NSRect, completion: @escaping () -> Void) {
        
        let flashLayer = CALayer()
        flashLayer.frame = rect
        flashLayer.backgroundColor = NSColor.white.withAlphaComponent(0.5).cgColor
        flashLayer.zPosition = 1000 // 确保闪光层在顶部
        self.layer?.addSublayer(flashLayer)

        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.duration = 0.25 // 闪光持续时间
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.delegate = self
        flashLayer.add(animation, forKey: "flashAnimation")
        
        // 动画完成后移除layer
        CATransaction.setCompletionBlock {
            flashLayer.removeFromSuperlayer()
            completion()
        }
    }
    

    
}

enum NameItLater {
    case begin
    case changing
    case staying
    case captured
    case satisfied
}
