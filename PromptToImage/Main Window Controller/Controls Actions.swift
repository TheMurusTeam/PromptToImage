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
        self.imageview.isHidden = true
        self.imageControlsView.isHidden = true
        isRunning = true
        let inputImage = self.inputImageview.image?.cgImage(forProposedRect: nil, context: nil, hints: nil)
        // seed
        var seed : UInt32 = UInt32(Int.random(in: 0..<Int(UInt32.max)))
        if self.seedBtn.state == .off && (self.seedView.integerValue < Int(UInt32.max)) && (self.seedView.integerValue > 0) {
            seed = UInt32(self.seedView.integerValue)
        }
        self.seedView.stringValue = String(seed)
        
        // generate image
        self.generateImage(prompt: self.promptView.stringValue,
                           negativePrompt: self.negativePromptView.stringValue,
                           startingImage: inputImage,
                           strength: inputImage != nil ? self.strengthLabel.floatValue : Float(1),
                           imageCount: self.imageCountSlider.integerValue, //self.imageCountStepper.integerValue,
                           stepCount: self.stepsSlider.integerValue,
                           seed: seed,
                           guidanceScale: self.guidanceLabel.floatValue,
                           scheduler: schedulerPopup.indexOfSelectedItem == 0 ? .pndmScheduler : .dpmSolverMultistepScheduler,
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
    
    @IBAction func setStrength(_ sender: NSSlider) {
        self.strengthLabel.stringValue = "\(Double(sender.integerValue) / 100)"
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
        self.inputImageview.image = image.resize(w: modelWidth, h: modelHeight) //image.copy(size: NSSize(width: modelWidth,height: modelHeight))
    }
   
    
    
    // MARK: ImageKit View Controls
    
    @IBAction func clickControlsSegmentedCtrl(_ sender: NSSegmentedControl) {
        switch sender.indexOfSelectedItem {
        case 0:
            self.imageview.zoomIn(self)
            self.zoomToFit = false
            self.viewZoomFactor = self.imageview.zoomFactor
        case 1:
            self.imageview.zoomOut(self)
            self.zoomToFit = false
            self.viewZoomFactor = self.imageview.zoomFactor
        case 2:
            self.imageview.zoomImageToActualSize(self)
            self.zoomToFit = false
            self.viewZoomFactor = self.imageview.zoomFactor
        default:
            self.imageview.zoomImageToFit(self)
            self.zoomToFit = true
        }
    }
    
    
    
    // MARK: Upscale image from imageview
    
    @IBAction func clickUpscale(_ sender: NSPopUpButton) {
        guard let upscalerUrl = sender.selectedItem?.representedObject as? URL else {
            print("import compiled CoreML upscale model from file")
            self.importUpscaleModel()
            return
        }
        
        guard !self.historyArrayController.selectedObjects.isEmpty else { return }
        let displayedHistoryItem = self.historyArrayController.selectedObjects[0] as! HistoryItem
        
        self.waitLabel.stringValue = "Upscaling image..."
        self.waitInfoLabel.stringValue = "Model: \(URL(string: NSURL(fileURLWithPath: upscalerUrl.path).lastPathComponent ?? String())?.deletingPathExtension().path ?? String())"
        self.waitCULabel.stringValue = ""
        self.window?.beginSheet(self.waitWin)
        
        DispatchQueue.global().async {
            
            Upscaler.shared.setupUpscaleModelFromPath(path: upscalerUrl.path, computeUnits: defaultUpscalerComputeUnits)
            
            guard let upscaledImage = Upscaler.shared.upscaledImage(image: displayedHistoryItem.image) else { return }
            displayedHistoryItem.upscaledImage = upscaledImage
            displayedHistoryItem.upscaledSize = upscaledImage.size
            displayedHistoryItem.upscaled = true
            DispatchQueue.main.async {
                self.imageview.setImage(upscaledImage.cgImage(forProposedRect: nil, context: nil, hints: nil), imageProperties: [:])
                self.imageview.zoomImageToFit(self)
                self.zoomToFit = true
                self.originalUpscaledSwitch.isHidden = displayedHistoryItem.upscaledImage == nil
                self.originalUpscaledSwitch.selectSegment(withTag: displayedHistoryItem.upscaledImage == nil ? 0 : 1)
                self.window?.endSheet(self.waitWin)
            }
        }
    }
    
    
    // MARK: Switch Original/Upscaled
    
    @IBAction func clickOriginalUpscaledSwitch(_ sender: NSSegmentedControl) {
        guard !self.historyArrayController.selectsInsertedObjects.description.isEmpty else { return }
        let displayedHistoryitem = self.historyArrayController.selectedObjects[0] as! HistoryItem
        switch sender.indexOfSelectedItem {
        case 0: // original
            self.imageview.setImage(displayedHistoryitem.image.cgImage(forProposedRect: nil, context: nil, hints: nil), imageProperties: [:])
            // zoom
            if self.zoomToFit {
                self.imageview.zoomImageToFit(self)
            } else {
                self.imageview.zoomFactor = viewZoomFactor
            }
        default: // upscaled
            guard let image = displayedHistoryitem.upscaledImage else { break }
            self.imageview.setImage(image.cgImage(forProposedRect: nil, context: nil, hints: nil), imageProperties: [:])
            // zoom
            self.imageview.zoomImageToFit(self)
            self.zoomToFit = true
        }
    }
    
    
    
    // MARK: Compute Units Images
    
   
    
    func setCUImages() {
        self.led_cpu.image = NSImage(named:"cpuon")!
        self.led_cpu.isEnabled = true
        switch currentComputeUnits {
        case .cpuAndGPU:
            self.led_gpu.image = NSImage(named:"gpuon")!
            self.led_gpu.isEnabled = true
            self.led_ane.image = NSImage(named:"aneoff")!
            self.led_ane.isEnabled = false
        case .cpuAndNeuralEngine:
            self.led_gpu.image = NSImage(named:"gpuoff")!
            self.led_gpu.isEnabled = false
            self.led_ane.image = NSImage(named:"aneon")!
            self.led_ane.isEnabled = true
        default:
            self.led_gpu.image = NSImage(named:"gpuon")!
            self.led_gpu.isEnabled = true
            self.led_ane.image = NSImage(named:"aneon")!
            self.led_ane.isEnabled = true
        }
    }
    
    func clearCUImages() {
        self.led_cpu.image = NSImage(named:"cpuoff")!
        self.led_cpu.isEnabled = false
        self.led_ane.image = NSImage(named:"aneoff")!
        self.led_ane.isEnabled = false
        self.led_gpu.image = NSImage(named:"gpuoff")!
        self.led_gpu.isEnabled = false
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












@IBDesignable class FlatButton: NSButton {
    @IBInspectable var cornerRadius: CGFloat = 5
    
    @IBInspectable var dxPadding: CGFloat = 0
    @IBInspectable var dyPadding: CGFloat = 0

    @IBInspectable var backgroundColor: NSColor = .controlAccentColor
    
    @IBInspectable var imageName: String = "NSActionTemplate"
    
    override func draw(_ dirtyRect: NSRect) {
        // Set corner radius
        self.wantsLayer = true
        self.layer?.cornerRadius = cornerRadius
        
        // Darken background color when highlighted
        if isHighlighted {
            layer?.backgroundColor =  backgroundColor.blended(
                withFraction: 0.2, of: .black
            )?.cgColor
        } else {
            layer?.backgroundColor = backgroundColor.cgColor
        }
        
        // Set Image
        imagePosition = .imageLeading
        //image = NSImage(named: imageName)

        // Reset the bounds after drawing is complete
        let originalBounds = self.bounds
        defer { self.bounds = originalBounds }

        // Inset bounds by padding
        self.bounds = originalBounds.insetBy(
            dx: dxPadding, dy: dyPadding
        )
        
        // Super
        super.draw(dirtyRect)
    }
}
