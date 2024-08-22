//
//  AppDelegate.swift
//  PanoCapture
//
//  Created by jin junjie on 2024/8/20.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var screenShotHelper: ScreenShotHelper?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        screenShotHelper = ScreenShotHelper()
        let _ = screenShotHelper?.enableEventTap()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
}


