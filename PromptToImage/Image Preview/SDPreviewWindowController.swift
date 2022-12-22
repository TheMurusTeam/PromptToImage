//
//  SDPreviewWindowController.swift
//  PromptToImage
//
//  Created by hany on 21/12/22.
//

import Cocoa

var winCtrl = [String:NSWindowController]()

class SDPreviewWindowController: NSWindowController {

    var image = NSImage()
    @IBOutlet weak var imageView: NSImageView!
    
    convenience init(windowNibName:String, image: NSImage) {
        self.init(windowNibName:windowNibName)
        self.image = image
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.imageView.image = self.image
        self.window?.title = "Image \(String(Int(self.image.width)))x\(String(Int(self.image.height)))"
    }
    
}
