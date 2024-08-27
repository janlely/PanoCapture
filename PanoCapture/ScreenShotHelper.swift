//
//  ScreenShotHelper.swift
//  PanoCapture
//
//  Created by jin junjie on 2024/8/21.
//

import Foundation
import Cocoa
import ScreenCaptureKit
import os.log

class ScreenShotHelper {
    
    static let shared: ScreenShotHelper = ScreenShotHelper()
    
    var eventTap: CFMachPort?
    var runLoopSource: CFRunLoopSource?
    var mainWindowController: MainWindowController?
    var currentScreen: NSScreen?
    var isNormalMode: Bool = true
    var isStopped: Bool = false
    let ssimCalculator = SSIMCalculator()
    
    private init() {
    }
    
    func getWindowController() -> MainWindowController {
        if mainWindowController == nil {
            // 创建窗口控制器实例
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            mainWindowController = storyboard.instantiateController(withIdentifier: "mainWindowController") as? MainWindowController
        }
        return mainWindowController!
    }
    
    //阻止mouseMoved事件以防止鼠标触达屏幕顶部时触发状态栏显示
    //阻止鼠标移动到屏幕顶部，防止失去焦点
    func enableEventTap() {
        if eventTap == nil {
            eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                         place: .headInsertEventTap,
                                         options: .defaultTap,
                                         eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue | 1 << CGEventType.leftMouseDown.rawValue | 1 << CGEventType.mouseMoved.rawValue),
                                         callback: myCGEventCallback,
                                         userInfo: nil)
        }
        
        //二次查检
        if eventTap == nil {
            os_log(.error, log: log, "error create CGEventTap")
            return
        }
        
        if runLoopSource == nil {
            runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        }
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap!, enable: true)
    }
    
    func disableEventTap() {
        guard let eventTap = eventTap, let runLoopSource = runLoopSource else {
            return
        }
        os_log(.info, log: log, "disableEventTap")
        // 禁用事件监听
        CGEvent.tapEnable(tap: eventTap, enable: false)
        
        // 从 Run Loop 中移除事件源
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
    }
    

    func captureScreenshot(display: SCDisplay, rect: CGRect, completion: @escaping (CGImage?) -> Void) {
        os_log(.info, log: log, "captureScreenshot")
        
        let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
        
        let configuration = SCStreamConfiguration()
        // 设置为指定区域抓取
        configuration.showsCursor = false
        configuration.sourceRect = rect
        configuration.width = Int(rect.width)
        configuration.height = Int(rect.height)
        
        SCScreenshotManager.captureImage(contentFilter: filter, configuration: configuration) { image, error in
            if let error = error {
                os_log(.error, log: log, "Error capturing screenshot: \(error.localizedDescription)")
                completion(nil)
            } else if let cgImage = image {
                os_log(.info, log: log, "image captured")
                completion(cgImage)
            } else {
                os_log(.info, log: log, "No image captured")
                completion(nil)
            }
        }
    }
    
    func findCurrentScreen() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        currentScreen = screens.first { $0.frame.contains(mouseLocation) }
        return currentScreen
    }
    
    func clear() {
        ScreenShotHelper.shared.disableEventTap()
        (ScreenShotHelper.shared.getWindowController().contentViewController?.view as? MainView)?.removeSubLayer()
        ScreenShotHelper.shared.getWindowController().window?.ignoresMouseEvents = false
        ScreenShotHelper.shared.getWindowController().window?.orderOut(nil)
    }
    
    func capture(_ rect: NSRect) -> CGImage? {
        os_log(.info, log: log, "start capture")
        let rect = convertRectToScreenCoordinates(rect)
        let channel = Channel<CGImage>()
        Task {
            do {
                let content = try await SCShareableContent.current
                
                guard !content.displays.isEmpty else {
                    os_log(.error, log: log, "No displays found")
                    channel.send(nil)
                    return
                }
                
                var displayFound = false
                content.displays.forEach { display in
                    os_log(.info, log: log, "display \(display.displayID)")
                    if display.frame.minX <= rect.minX && display.frame.maxX >= rect.maxX {
                        os_log(.info, log: log, "display found, start capture screen")
                        displayFound = true
                        captureScreenshot(display: display, rect: rect, completion: {image in
                            channel.send(image)
                        })
                    }
                }
                if !displayFound {
                    channel.send(nil)
                }
                
            } catch {
                os_log(.error, log: log, "Error getting shareable content: \(error.localizedDescription)")
                channel.send(nil)
            }
        }
        
        guard let image = channel.receive() else {
            os_log(.error, log: log, "error receive screen capture")
            return nil
        }
        return image
    }
    
    func save() {
        do {
            try ImageHelper.shared.save()
            clear()
        } catch {
            os_log(.error, log: log, "save image failed, \(error.localizedDescription)")
        }
    }
    
    func convertRectToScreenCoordinates(_ rect: NSRect) -> NSRect {
        let windowController = getWindowController()
        let rectInWindowCoordinates = windowController.window!.convertToScreen(rect)
        let screenRect = NSRect(x: rectInWindowCoordinates.origin.x,
                                y: currentScreen!.frame.height - rectInWindowCoordinates.origin.y - rectInWindowCoordinates.height,
                                width: rectInWindowCoordinates.width,
                                height: rectInWindowCoordinates.height)
        return screenRect
    }
}

func myCGEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, userInfo: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    if type == CGEventType.mouseMoved {
        return nil
    }
    //捕捉Esc按键退出程序
    if type == CGEventType.keyDown {
        os_log(.info, log: log, "CGEventType.keyDown")
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                
        // 检查按键代码是否为Esc键 (键码 53)
        if keyCode == 53 {
            //退出程序
            ScreenShotHelper.shared.clear()
            ScreenShotHelper.shared.isStopped = true
            return nil
        }
        // 检查按键代码是否为Enter键 (键码 36)
        if keyCode == 36 {
            //退出程序
            ScreenShotHelper.shared.clear()
            ScreenShotHelper.shared.isStopped = true
            ScreenShotHelper.shared.save()
            return nil
        }
    }
    //阻止鼠标触达屏幕顶部，因为在顶部点击会使窗口失去焦点
    if mouseHitTop(event) {
        os_log(.info, log: log, "reset mouse")
        pullMouseBack(event)
    }
    return Unmanaged.passRetained(event)
}

func mouseHitTop(_ event: CGEvent) -> Bool {
    return event.location.y <= (ScreenShotHelper.shared.currentScreen?.frame.minY)!
}

func pullMouseBack(_ event: CGEvent) {
    event.location.y = (ScreenShotHelper.shared.currentScreen?.frame.minY)!
}





//extension CGEventType {
//    var description: String {
//        switch self {
//        case .leftMouseDown:
//            return "leftMouseDown"
//        case .leftMouseUp:
//            return "leftMouseUp"
//        case .rightMouseDown:
//            return "rightMouseDown"
//        case .rightMouseUp:
//            return "rightMouseUp"
//        case .mouseMoved:
//            return "mouseMoved"
//        case .leftMouseDragged:
//            return "leftMouseDragged"
//        case .keyDown:
//            return "keyDown"
//        case .keyUp:
//            return "keyUp"
//        case .flagsChanged:
//            return "flagsChanged"
//        case .scrollWheel:
//            return "scrollWheel"
//        case .tabletPointer:
//            return "tabletPointer"
//        case .tabletProximity:
//            return "tabletProximity"
//        case .null:
//            return "null"
//        case .rightMouseDragged:
//            return "rightMouseDragged"
//        case .otherMouseDown:
//            return "otherMouseDown"
//        case .otherMouseUp:
//            return "otherMouseUp"
//        case .otherMouseDragged:
//            return "otherMouseDragged"
//        case .tapDisabledByTimeout:
//            return "tapDisabledByTimeout"
//        case .tapDisabledByUserInput:
//            return "tapDisabledByUserInput"
//        @unknown default:
//            return "Unknown Event Type"
//        }
//    }
//}
