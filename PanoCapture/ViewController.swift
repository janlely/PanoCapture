//
//  ViewController.swift
//  PanoCapture
//
//  Created by jin junjie on 2024/8/20.
//

import Cocoa

class ViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.becomeFirstResponder()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC 键的键码是 53
            NSLog("Esc")
            NSApplication.shared.terminate(nil)
        } else {
            super.keyDown(with: event)
        }
    }
    
}

