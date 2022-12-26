//
//  Info Popover.swift
//  PromptToImage
//
//  Created by hany on 25/12/22.
//

import Foundation
import AppKit

extension SDMainWindowController {
    
    
    
    // MARK: Info Popover
    
    // display image info popover
    @IBAction func clickDisplayInfoPopover(_ sender: NSButton) {
        guard let view = sender.superview?.superview else {return}
        let row = self.historyTableView.row(for: view)
        print("ROW:\(row)")
        self.presentPopover(originview: sender as NSView, edge: NSRectEdge.maxX, historyItem: self.history[row])
        
    }
    
    
    
    // MARK: Draw Info Popover
    
    // create info Popover
    func presentPopover(originview:NSView,edge:NSRectEdge?,historyItem:HistoryItem) {
        self.setInfoPopover(item: historyItem)
        infoPopover = NSPopover()
        let popoverCtrl = NSViewController()
        popoverCtrl.view = self.infoPopoverView
        infoPopover!.contentViewController = popoverCtrl
        infoPopover!.behavior = NSPopover.Behavior.transient
        infoPopover!.animates = true
        infoPopover!.show(relativeTo: originview.bounds, of: originview, preferredEdge: edge ?? NSRectEdge.minY)
    }
    
    
    // draw info popover
    func setInfoPopover(item:HistoryItem) {
        self.info_date.stringValue = dateFormatter.string(from: item.date)
        self.info_model.stringValue = item.modelName
        self.info_prompt.stringValue = item.prompt
        self.info_negativePrompt.stringValue = item.negativePrompt
        self.info_seed.stringValue = String(item.seed)
        self.info_steps.stringValue = String(item.steps)
        self.info_guidance.stringValue = String(item.guidanceScale)
        self.info_strenght.stringValue = String(item.strenght)
        self.info_inputImage.image = NSImage()
        if let cgimage = item.inputImage {
            self.info_inputImage.image = NSImage(cgImage: cgimage, size: .zero)
            self.info_inputImageView.isHidden = false
        } else {
            self.info_inputImageView.isHidden = true
        }
        let size = item.upscaledSize ?? item.originalSize
        self.info_size.stringValue = "\(String(Int(size.width)))x\(String(Int(size.height)))"
        self.info_upscaledLabel.isHidden = !item.upscaled
    }
    
    
    
    
    
    
    // MARK: info popover actions
    
    // prompt
    @IBAction func infoCopyPrompt(_ sender: Any) {
        self.promptView.stringValue = info_prompt.stringValue
    }
    // negative prompt
    @IBAction func infoCopyNegativePrompt(_ sender: Any) {
        self.negativePromptView.stringValue = info_negativePrompt.stringValue
    }
    // seed
    @IBAction func infoCopySeed(_ sender: Any) {
        self.seedView.stringValue = info_seed.stringValue
        self.seedBtn.state = .off
        self.seedView.isSelectable = true
        self.seedView.isEditable = true
    }
    // steps
    @IBAction func infoCopySteps(_ sender: Any) {
        self.stepsSlider.integerValue = info_steps.integerValue
        self.stepsLabel.integerValue = info_steps.integerValue
    }
    // guidance scale
    @IBAction func infoCopyGuidance(_ sender: Any) {
        self.guidanceSlider.doubleValue = info_guidance.doubleValue * 100
        self.guidanceLabel.stringValue = String(info_guidance.doubleValue)
    }
    // input image strenght
    @IBAction func infoCopyStrenght(_ sender: Any) {
        self.strenghtSlider.doubleValue = info_strenght.doubleValue * 100
        self.strenghtLabel.stringValue = String(info_strenght.doubleValue)
    }
    // input image
    @IBAction func infoCopyInputImage(_ sender: Any) {
        if let pipeline = sdPipeline {
            if pipeline.canUseInputImage {
                if let image = self.info_inputImage.image {
                    self.inputImageview.image = image
                    return
                }
            }
        }
        displayErrorAlert(txt: "Image to Image is not available with current model: VAEEncoder.mlmodelc not found")
    }
    
}
