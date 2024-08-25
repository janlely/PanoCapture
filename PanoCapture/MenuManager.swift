//
//  MenuManager.swift
//  PanoCapture
//
//  Created by jin junjie on 2024/8/22.
//

import Foundation
import Cocoa
import os.log

class MenuManager {
    
    static let shared: MenuManager = MenuManager()
    
    var statusItem: NSStatusItem?
    var menu: NSMenu?
    
    
    private init() {}
    
    func initialize() {
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "bell", accessibilityDescription: "Notification")
        }
        
        // 创建菜单
        menu = NSMenu()
        let normalShot = NSMenuItem(title: "普通截图", action: #selector(startQuickSelection), keyEquivalent: "")
        normalShot.target = self
        menu?.addItem(normalShot)
        menu?.addItem(NSMenuItem.separator())
        let fullviewShot = NSMenuItem(title: "动态全景", action: #selector(startDynamicSelection), keyEquivalent: "")
        fullviewShot.target = self
        menu?.addItem(fullviewShot)
        menu?.addItem(NSMenuItem.separator())
        menu?.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
        
        statusItem?.menu = menu
    }
    
    @objc func startQuickSelection() {
        ScreenShotHelper.shared.isNormalMode = true
        showCaptureUI()
    }
    
    @objc func startDynamicSelection() {
        ScreenShotHelper.shared.isNormalMode = false
        showCaptureUI()
    }
    
    func showCaptureUI() {
        let windowController = ScreenShotHelper.shared.getWindowController()
        ScreenShotHelper.shared.disableEventTap()
        guard let currentScreen = ScreenShotHelper.shared.findCurrentScreen() else {
            os_log(.error, log: log, "error findCurrentScreen")
            return
        }
        windowController.setWindowFrame(currentScreen.frame)
        NSLog("\(String(describing: NSWorkspace.shared.frontmostApplication?.bundleIdentifier))")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeMain(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: windowController.window
        )
        NSApp.activate(ignoringOtherApps: true)
        windowController.showWindow(nil)
        ScreenShotHelper.shared.enableEventTap()
    }
    @objc func windowDidBecomeMain(_ notification: Notification) {
        NSLog("windowDidBecomeMain")
        //更新光标样式
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            NSCursor.crosshair.set()
        }
        NotificationCenter.default.removeObserver(
            self,
            name: NSWindow.didBecomeKeyNotification,
            object: notification.object
        )
    }
}
