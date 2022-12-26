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
    @objc dynamic var modelName = String()
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
    convenience init(modelName:String,
                     prompt:String,
                     negativePrompt:String,
                     steps:Int,
                     guidanceScale:Float,
                     inputImage:CGImage?,
                     strenght:Float,
                     image:NSImage,
                     upscaledImage:NSImage?,
                     seed:Int) {
        self.init()
        self.modelName = modelName
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
    
    
    // Encode history item
    func encode() -> Data {
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        archiver.encode(self.modelName, forKey: "modelName")
        archiver.encode(self.date, forKey: "date")
        archiver.encode(self.prompt, forKey: "prompt")
        archiver.encode(self.negativePrompt, forKey: "negativePrompt")
        archiver.encode(self.steps, forKey: "steps")
        archiver.encode(self.guidanceScale, forKey: "guidanceScale")
        archiver.encode(self.strenght, forKey: "strenght")
        archiver.encode(self.seed, forKey: "seed")
        archiver.encode(self.image.tiffRepresentation, forKey: "image")
        if let inputImage = self.inputImage {
            archiver.encode(NSImage(cgImage: inputImage, size: .zero).tiffRepresentation, forKey: "inputImage")
        }
        return archiver.encodedData
    }
    
    
    // Decode history item
    convenience init?(data:Data) {
        self.init()
        do {
            let unarchiver = try NSKeyedUnarchiver.init(forReadingFrom: data)
            unarchiver.requiresSecureCoding = false
            defer { unarchiver.finishDecoding() }
            self.modelName = unarchiver.decodeObject(forKey: "modelName") as? String ?? String()
            self.date = unarchiver.decodeObject(forKey: "date") as? Date ?? Date()
            self.prompt = unarchiver.decodeObject(forKey: "prompt") as? String ?? String()
            self.negativePrompt = unarchiver.decodeObject(forKey: "negativePrompt") as? String ?? String()
            self.steps = unarchiver.decodeInteger(forKey: "steps")
            self.guidanceScale = unarchiver.decodeFloat(forKey: "guidanceScale")
            self.strenght = unarchiver.decodeFloat(forKey: "strenght")
            self.seed = unarchiver.decodeInteger(forKey: "seed")
            
            // original image
            if let imageData = unarchiver.decodeObject(forKey: "image") as? Data {
                if let image = NSImage(data: imageData) {
                    self.image = image
                }
            }
            // input image
            if let imageData = unarchiver.decodeObject(forKey: "inputImage") as? Data {
                if let image = NSImage(data: imageData) {
                    self.inputImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
                }
            }
            //
            self.originalSize = self.image.size
            self.upscaled = false
            
            
        } catch let error as NSError {
            NSLog("Error decoding history item" + error.localizedDescription)
        }
    }
    
}







extension SDMainWindowController {
    
    // MARK: Save History
    
    func saveHistory() {
        print("Saving history...")
        let dict : [String:Any] = ["history": (self.history.map { $0.encode() })]
        var confdata : Data? = nil
        do {
            confdata = try PropertyListSerialization.data(fromPropertyList:dict,
                                                          format: .xml,
                                                          options: 0)
            
             
        } catch let error as NSError {
            NSLog("Error creating history data: " + error.localizedDescription)
        }
        // save
        guard let confdata = confdata else { return }
        do {
            try confdata.write(to: URL(fileURLWithPath: historyPath + "/PromptToImage.history"))
            
        } catch let error as NSError {
            NSLog("Error" + error.localizedDescription)
        }
    }
    
    // MARK: Load History
    
    func loadHistory() {
        print("loading history...")
        DispatchQueue.global().async {
            if let historydict = NSDictionary.init(contentsOfFile: historyPath + "/PromptToImage.history") {
                if let items = historydict["history"] as? [Data] {
                    print("importing \(items.count) history items")
                    for data in items {
                        if let newitem = HistoryItem(data: data) {
                            DispatchQueue.main.async {
                                self.historyArrayController.addObject(newitem)
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    
}
