//
//  MainWindowController.swift
//  PanoCapture
//
//  Created by jin junjie on 2024/8/20.
//

import Foundation
import Cocoa
import os.log

class MainWindowController: NSWindowController {
    var trackingArea: NSTrackingArea?
    var observer: Any?
    
    
    override func windowDidLoad() {
        os_log(.info, log: log, "windowDidLoad")
        super.windowDidLoad()
        window?.isOpaque = false
        window?.backgroundColor = NSColor.black.withAlphaComponent(0.5)
        window?.ignoresMouseEvents = false
        window?.acceptsMouseMovedEvents = true
        window?.styleMask = [.borderless, .fullSizeContentView]
        window?.titlebarAppearsTransparent = true
        window?.level = .screenSaver
        trackingArea = NSTrackingArea(rect: window!.contentView!.bounds,
                                          options: [.activeAlways, .mouseEnteredAndExited, .mouseMoved],
                                          owner: self,
                                          userInfo: nil)
        window?.contentView?.addTrackingArea(trackingArea!)
    }
    
    func setWindowFrame(_ frame: NSRect?) {
        guard let frame = frame else {
            os_log(.error, log: log, "error setWindowFrame")
            return
        }
        window?.setFrame(frame, display: true)
    }
    
   
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        NSLog("mouseEntered")
    }
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        print("Mouse exited")
    }
    
    func updateTrackingArea() {
        if let oldTrackingArea = trackingArea {
            window?.contentView?.removeTrackingArea(oldTrackingArea)
        }
        
        let newTrackingArea = NSTrackingArea(rect: window!.contentView!.bounds,
                                             options: [.activeAlways, .mouseEnteredAndExited, .mouseMoved],
                                             owner: self,
                                             userInfo: nil)
        window?.contentView?.addTrackingArea(newTrackingArea)
        trackingArea = newTrackingArea
    }
}
