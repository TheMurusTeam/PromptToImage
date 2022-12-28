//
//  Controls Actions.swift
//  PromptToImage
//
//  Created by hany on 05/12/22.
//

import Foundation
import AppKit
import CoreML
import AVFoundation


extension SDMainWindowController {
    
    
    // MARK: Click Generate Image 
    
    @IBAction func clickGenerateImage(_ sender: NSButton) {
        self.historyArrayController.setSelectedObjects([])
        isRunning = true
        let inputImage = self.inputImageview.image?.cgImage(forProposedRect: nil, context: nil, hints: nil)
        // seed
        var seed : Int = Int.random(in: 0..<Int(UInt32.max))
        if self.seedBtn.state == .off && (self.seedView.integerValue < Int(UInt32.max)) && (self.seedView.integerValue > 0) {
            seed = self.seedView.integerValue
        }
        self.seedView.stringValue = String(seed)
        
        // generate image
        self.generateImage(prompt: self.promptView.stringValue,
                           negativePrompt: self.negativePromptView.stringValue,
                           startingImage: inputImage,
                           strength: inputImage != nil ? self.strenghtLabel.floatValue : Float(1),
                           imageCount: self.imageCountSlider.integerValue, //self.imageCountStepper.integerValue,
                           stepCount: self.stepsSlider.integerValue,
                           seed: seed,
                           guidanceScale: self.guidanceLabel.floatValue,
                           scheduler: ((schedulerPopup.indexOfSelectedItem == 0) || (inputImage != nil)) ? .pndmScheduler : .dpmSolverMultistepScheduler,
                           upscale: self.upscaleCheckBox.state == .on)
    }
    
    
    // MARK: Stop generate image
    
    @IBAction func clickStop(_ sender: Any) {
        isRunning = false
        self.window?.endSheet(self.progrWin)
    }
    
    
    
    

    
    // move selected image to input image from collection view item
    @IBAction func clickCopyImageToInputImage(_ sender: NSButton) {
        if let pipeline = sdPipeline {
            if pipeline.canUseInputImage {
                guard let view = sender.superview?.superview else {return}
                let row = self.historyTableView.row(for: view)
                print("ROW:\(row)")
                self.inputImageview.image = self.history[row].image
                return
            }
        }
        displayErrorAlert(txt: "Image to Image is not available with current model: VAEEncoder.mlmodelc not found")
        
    }
    
    
    
    
    
    // MARK: Set Guidance Scale
    
    @IBAction func setGSlider(_ sender: NSSlider) {
        self.guidanceLabel.stringValue = "\(Double(sender.integerValue) / 100)"
    }
  
    
    
    
    
    // MARK: IMG2IMG Input Image Controls
    
    @IBAction func setStrenght(_ sender: NSSlider) {
        self.strenghtLabel.stringValue = "\(Double(sender.integerValue) / 100)"
    }
    
    @IBAction func clearInputImage(_ sender: NSButton) {
        self.inputImageview.image = nil
        self.schedulerPopup.isEnabled = true
    }
    
    
    // IMPORT INPUT IMAGE FROM OPEN PANEL
    @IBAction func importInputImage(_ sender: NSButton) {
        let myFiledialog:NSOpenPanel = NSOpenPanel()
        myFiledialog.allowsMultipleSelection = false
        myFiledialog.canChooseDirectories = true
        myFiledialog.message = "Import Image"
        myFiledialog.runModal()
        
        if let url = myFiledialog.url {
            do {
                guard let typeID = try url.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else { return }
                guard let supertypes = UTType(typeID)?.supertypes else { return }
             
                if supertypes.contains(.image) {
                    if let image = NSImage(contentsOf: URL(fileURLWithPath: url.path)) {
                        self.insertNewInputImage(image: image)
                    }
                    return
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    // IMPORT INPUT IMAGE WITH DRAG AND DROP FROM FINDER
    @IBAction func dragInputImage(_ sender: NSImageView) {
        if let draggedImage = self.inputImageview.image {
            self.insertNewInputImage(image: draggedImage)
        }
    }
    
    
    // NORMALIZE INPUT IMAGE
    func insertNewInputImage(image:NSImage) {
        self.inputImageview.image = image.resize(w: modelWidth, h: modelHeight) //image.copy(size: NSSize(width: modelWidth,height: modelHeight))
        self.schedulerPopup.selectItem(at: 0)
        self.schedulerPopup.isEnabled = false
    }
   
    
    
}



let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale.autoupdatingCurrent
    formatter.timeZone = TimeZone.autoupdatingCurrent
    formatter.dateStyle = .long
    formatter.timeStyle = .medium
    formatter.doesRelativeDateFormatting = true
    return formatter
}()
