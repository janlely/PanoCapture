//
//  AppDelegate.swift
//  PanoCapture
//
//  Created by jin junjie on 2024/8/20.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var eventTap: CFMachPort?
    


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        blockSomeEvents()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    //阻止mouseMoved事件以防止鼠标触达屏幕顶部时触发状态栏显示
    //阻止鼠标移动到屏幕顶部，防止失去焦点
    func blockSomeEvents() {
        
        guard let eventTap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                               place: .headInsertEventTap,
                                               options: .defaultTap,
                                               eventsOfInterest: CGEventMask(1 << CGEventType.leftMouseDown.rawValue | 1 << CGEventType.rightMouseDown.rawValue | 1 << CGEventType.mouseMoved.rawValue),
                                               callback: myCGEventCallback,
                                               userInfo: nil) else {
            print("Failed to create event tap")
            return
        }
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
}

func myCGEventCallback(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, userInfo: UnsafeMutableRawPointer?) -> Unmanaged<CGEvent>? {
    if type == CGEventType.mouseMoved {
        return nil
    }
    //阻止鼠标触达屏幕顶部，因为在顶部点击会使窗口失去焦点
    if event.location.y == 0 {
        NSLog("reset mouse")
        event.location.y = 1
    }
    return Unmanaged.passRetained(event)
}


import CoreGraphics

extension CGEventType {
    var description: String {
        switch self {
        case .leftMouseDown:
            return "leftMouseDown"
        case .leftMouseUp:
            return "leftMouseUp"
        case .rightMouseDown:
            return "rightMouseDown"
        case .rightMouseUp:
            return "rightMouseUp"
        case .mouseMoved:
            return "mouseMoved"
        case .leftMouseDragged:
            return "leftMouseDragged"
        case .keyDown:
            return "keyDown"
        case .keyUp:
            return "keyUp"
        case .flagsChanged:
            return "flagsChanged"
        case .scrollWheel:
            return "scrollWheel"
        case .tabletPointer:
            return "tabletPointer"
        case .tabletProximity:
            return "tabletProximity"
        case .null:
            return "null"
        case .rightMouseDragged:
            return "rightMouseDragged"
        case .otherMouseDown:
            return "otherMouseDown"
        case .otherMouseUp:
            return "otherMouseUp"
        case .otherMouseDragged:
            return "otherMouseDragged"
        case .tapDisabledByTimeout:
            return "tapDisabledByTimeout"
        case .tapDisabledByUserInput:
            return "tapDisabledByUserInput"
        @unknown default:
            return "Unknown Event Type"
        }
    }
}
