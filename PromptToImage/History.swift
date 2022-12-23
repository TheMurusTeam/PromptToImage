//
//  History.swift
//  PromptToImage
//
//  Created by hany on 23/12/22.
//

import Foundation
import Cocoa


// MARK: History Item Model

class HistoryItem : NSObject {
    
    var date = Date()
    var originalSize = NSSize()
    var upscaledSize : NSSize? = nil
    @objc dynamic var prompt = String()
    @objc dynamic var negativePrompt = String()
    @objc dynamic var steps = Int()
    @objc dynamic var guidanceScale = Float()
    var inputImage : CGImage? = nil
    var strenght = Float()
    @objc dynamic var image = NSImage()
    var upscaledImage : NSImage? = nil
    var seed = Int()
    var upscaled = Bool()
    
    // Init history item
    convenience init(prompt:String,
                     negativePrompt:String,
                     steps:Int,
                     guidanceScale:Float,
                     inputImage:CGImage?,
                     strenght:Float,
                     image:NSImage,
                     upscaledImage:NSImage?,
                     seed:Int) {
        self.init()
        self.date = Date()
        self.prompt = prompt
        self.negativePrompt = negativePrompt
        self.steps = steps
        self.guidanceScale = guidanceScale
        self.inputImage = inputImage
        self.strenght = strenght
        self.image = image
        self.upscaledImage = upscaledImage
        self.seed = seed
        self.upscaled = self.upscaledImage != nil
        self.originalSize = self.image.size
        self.upscaledSize = self.upscaledImage?.size
    }
    
}
