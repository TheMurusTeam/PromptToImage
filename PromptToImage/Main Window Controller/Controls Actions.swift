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
        // clear views
        self.imageview.image = nil
        self.outputImages = [NSImage]()
        self.outputImagesArrayController.content = nil
        //
        self.saveBtn.isEnabled = false
        isRunning = true
        let inputImage = self.inputImageview.image?.cgImage(forProposedRect: nil, context: nil, hints: nil)
        // seed
        var seed : Int = Int.random(in: 0..<Int(UInt32.max))
        if self.seedBtn.state == .off && (self.seedView.integerValue < Int(UInt32.max)) && (self.seedView.integerValue > 0) {
            seed = self.seedView.integerValue
        }
        self.seedView.integerValue = seed
        
        // generate image
        self.generateImage(prompt: self.promptView.stringValue,
                           negativePrompt: self.negativePromptView.stringValue,
                           startingImage: self.inputImageview.image?.cgImage(forProposedRect: nil, context: nil, hints: nil),
                           strength: inputImage != nil ? self.strenghtLabel.floatValue : Float(1),
                           imageCount: self.imageCountStepper.integerValue,
                           stepCount: self.stepsSlider.integerValue,
                           seed: seed,
                           guidanceScale: self.guidanceLabel.floatValue,
                           stepsPreview: false /*self.stepsPreview.state == .on*/)
    }
    
    
    // MARK: Stop generate image
    
    @IBAction func clickStop(_ sender: Any) {
        self.saveBtn.isEnabled = false
        isRunning = false
        self.window?.endSheet(self.progrWin)
    }
    
    
    
    // MARK: Click Save in Share Button
     
    // main view share button
    @IBAction func clickSave(_ sender: NSButton) {
        var items = [NSImage]()
        
        if let image = self.imageview.image {
            // SHARE SINGLE IMAGE
            print("share single image")
            items = [image]
        } else if !self.outputImages.isEmpty {
            // SHARE MULTIPLE IMAGES
            print("share \(self.outputImages.count) images")
            items = self.outputImages
        }
        
        let sharingPicker = NSSharingServicePicker(items: items)
        sharingPicker.delegate = self
        sharingPicker.show(relativeTo: NSZeroRect,
                           of: sender,
                           preferredEdge: .minY)
    }
    
    
    
    
    // MARK: Collection View Item Actions
    
    // save from collection view item
    @IBAction func clickSaveInCollectionViewItem(_ sender: NSButton) {
        var i = 0
        for _ in self.colView.content {
            if let cvitem = self.colView.item(at: i) {
                if sender.isDescendant(of: cvitem.view) {
                    print("clicked item at position \(i)")
                    // save
                    let items : [NSImage] = [self.outputImages[i]]
                    let sharingPicker = NSSharingServicePicker(items: items)
                    sharingPicker.delegate = self
                    sharingPicker.show(relativeTo: NSZeroRect,
                                       of: sender,
                                       preferredEdge: .minY)
                }
            }
            i = i + 1
        }
    }

    // preview image
    @IBAction func clickPreviewImage(_ sender: NSButton) {
        var i = 0
        for _ in self.colView.content {
            if let cvitem = self.colView.item(at: i) {
                if sender.isDescendant(of: cvitem.view) {
                    print("clicked item at position \(i)")
                    winCtrl["preview"] = SDPreviewWindowController(windowNibName: "SDPreviewWindowController", image: self.outputImages[i])
                    (winCtrl["preview"] as? SDPreviewWindowController)?.window?.makeKeyAndOrderFront(nil)
                }
            }
            i = i + 1
        }
    }
    
    // move selected image to input image
    @IBAction func clickCopyImageToInputImage(_ sender: NSButton) {
        var i = 0
        for _ in self.colView.content {
            if let cvitem = self.colView.item(at: i) {
                if sender.isDescendant(of: cvitem.view) {
                    print("clicked item at position \(i)")
                    self.inputImageview.image = self.outputImages[i]
                }
            }
            i = i + 1
        }
    }
    
    
    
    // MARK: Switch Compute Units
    
    @IBAction func switchUnitsPopup(_ sender: NSPopUpButton) {
        self.reloadModel()
    }
    
    // MARK: Switch model
    
    @IBAction func switchModelsPopup(_ sender: NSPopUpButton) {
        if sender.indexOfSelectedItem == 0 {
            defaultModel = "Unet-ORIGINAL.mlmodelc"
            self.unitsPopup.selectItem(at: 1)
            self.unitsPopup.isEnabled = false
        } else {
            defaultModel = "Unet.mlmodelc"
            self.unitsPopup.isEnabled = true
        }
        self.reloadModel()
    }
    
    // Reload MLModel
    func reloadModel() {
        var units : MLComputeUnits = .cpuAndNeuralEngine
        switch self.unitsPopup.indexOfSelectedItem {
        case 1: units = .cpuAndGPU
        case 2: units = .all
        default: units = .cpuAndNeuralEngine
        }
        // update pipeline
        loadModels(computeUnits: units,
                   guidanceScale: 7.5)
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
        self.inputImageview.image = image.copy(size: NSSize(width: modelWidth,
                                                            height: modelHeight))
    }
   
    
    @IBAction func moveToInputImage(_ sender: NSButton) {
        self.inputImageview.image = self.imageview.image
    }
}



