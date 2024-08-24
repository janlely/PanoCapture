//
//  AppDelegate.swift
//  PanoCapture
//
//  Created by jin junjie on 2024/8/20.
//

import Cocoa

import os.log
let log = OSLog(subsystem: "com.janlely.PanoCapture", category: "screen-capture")

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        MenuManager.shared.initialize()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
}


