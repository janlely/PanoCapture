//
//  ScreenShotHelper.swift
//  PanoCapture
//
//  Created by jin junjie on 2024/8/21.
//

import Foundation
import Cocoa

class ScreenShotHelper {
    var eventTap: CFMachPort?
    var runLoopSource: CFRunLoopSource?
    
    //阻止mouseMoved事件以防止鼠标触达屏幕顶部时触发状态栏显示
    //阻止鼠标移动到屏幕顶部，防止失去焦点
    func enableEventTap() -> Bool {
        
        guard let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                               place: .headInsertEventTap,
                                               options: .defaultTap,
                                               eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue | 1 << CGEventType.leftMouseDown.rawValue | 1 << CGEventType.rightMouseDown.rawValue | 1 << CGEventType.mouseMoved.rawValue),
                                               callback: myCGEventCallback,
                                               userInfo: nil) else {
            print("Failed to create event tap")
            return false
        }
        self.eventTap = eventTap
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        return true
    }
    
    func disableEventTap() {
        guard let eventTap = eventTap, let runLoopSource = runLoopSource else {
            return
        }
        NSLog("disableEventTap")
        // 禁用事件监听
        CGEvent.tapEnable(tap: eventTap, enable: false)
        
        // 从 Run Loop 中移除事件源
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
    }
    
    func captureScreenRect(_ rect: CGRect) -> NSImage? {
        guard let screen = NSScreen.main else { return nil }
        let screenRect = screen.frame
        let captureRect = CGRect(x: screenRect.origin.x + rect.origin.x,
                                 y: screenRect.height - rect.origin.y - rect.height,
                                 width: rect.width,
                                 height: rect.height)

        guard let cgImage = CGWindowListCreateImage(captureRect, .optionOnScreenOnly, kCGNullWindowID, [.bestResolution, .boundsIgnoreFraming]) else { return nil }
        return NSImage(cgImage: cgImage, size: rect.size)
    }

}


func myCGEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, userInfo: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    if type == CGEventType.mouseMoved {
        return nil
    }
    //捕捉Esc按键退出程序
    if type == CGEventType.keyDown {
        NSLog("CGEventType.keyDown")
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                
        // 检查按键代码是否为Esc键 (键码 53)
        if keyCode == 53 {
            //退出程序
            NSApplication.shared.terminate(nil)
            return nil
        }
    }
    //阻止鼠标触达屏幕顶部，因为在顶部点击会使窗口失去焦点
    if event.location.y == 0 {
        NSLog("reset mouse")
        event.location.y = 1
    }
    return Unmanaged.passRetained(event)
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
