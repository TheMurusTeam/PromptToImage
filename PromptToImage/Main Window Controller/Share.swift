//
//  Share.swift
//  PromptToImage
//
//  Created by hany on 05/12/22.
//

import Foundation
import AppKit
import AVFoundation

extension SDMainWindowController {
    
    // MARK: Click Share in History Item
    
    // save from table view item Share btn
    @IBAction func clickShareInHistoryItem(_ sender: NSButton) {
        guard let view = sender.superview?.superview else {return}
        let row = self.historyTableView.row(for: view)
        print("ROW:\(row)")
        // save
        let items : [NSImage] = [(self.history[row].upscaledImage ?? self.history[row].image)]
        self.currentHistoryItemForSharePicker = self.history[row]
        let sharingPicker = NSSharingServicePicker(items: items)
        sharingPicker.delegate = self
        sharingPicker.show(relativeTo: NSZeroRect,
                           of: sender,
                           preferredEdge: .minY)
        
    }
    
    
    
    // MARK: Sharing Picker
    
    // draw share menu
    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any], proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
        
        guard let historyItem = self.currentHistoryItemForSharePicker else { return [] }
        let btnimage = NSImage(systemSymbolName: "display.and.arrow.down", accessibilityDescription: nil) // item icon
        var share = proposedServices
        
        if let currentImages = items as? [NSImage] {
            let customService = NSSharingService(title: "Save As...", image: btnimage ?? NSImage(), alternateImage: btnimage, handler: {
                if currentImages.count == 1 {
                    // write single image to file
                    self.displaySavePanel(item:historyItem)
                }/* else if currentImages.count > 1 {
                    // write multiple images to folder
                    self.displaySavePanel(images: currentImages)
                } */
            })
            share.insert(customService, at: 0)
        }
        return share
        
        
    }


    
    
    // MARK: Save Panel for EXIF single image

    // save panel for single image with metadata
    func displaySavePanel(item:HistoryItem) {
        print("displaying save panel for single image with metadata")
        let image = item.upscaledImage ?? item.image
        guard let img = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("invalid image")
            return
        }
        let panel = NSSavePanel()
        panel.nameFieldLabel = "Image file name:"
        panel.allowedContentTypes = [.png]
        // suggested file name
        panel.nameFieldStringValue = "\(String(self.promptView.stringValue.prefix(50))).\(self.seedView.stringValue).png"
        // panel strings
        panel.title = "Save image"
        panel.prompt = "Save Image"
        
        panel.beginSheetModal(for: self.window!, completionHandler: { response in
            if response == NSApplication.ModalResponse.OK {
                guard let url = panel.url else { return }
                guard let data = CFDataCreateMutable(nil, 0) else { return }
                guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else { return }
                let iptc = [
                    kCGImagePropertyIPTCOriginatingProgram: "PromptToImage for macOS",
                    kCGImagePropertyIPTCCaptionAbstract: self.metadata(item:item),
                    kCGImagePropertyIPTCProgramVersion: "\(self.seedView.stringValue)"]
                let meta = [kCGImagePropertyIPTCDictionary: iptc]
                CGImageDestinationAddImage(destination, img, meta as CFDictionary)
                guard CGImageDestinationFinalize(destination) else { return }
                // save
                do {
                    try (data as Data).write(to: url)
                } catch {
                    print("error saving file: \(error)")
                }
            } else {
                print("cancel")
            }
        })
        
    }
           
    
    // MARK: Build metadata for IPTC
    
    private func metadata(item:HistoryItem) -> String {
        return "Prompt: \(item.prompt)\nNegative Prompt: \(item.negativePrompt)\nSeed: \(item.seed)\nModel name: \(item.modelName)\nSteps: \(item.steps)\nGuidance Scale: \(item.guidanceScale)\n\nMade with PromptToImage for macOS"
    }

    
    // MARK: Click Save in tableview contextual menu
    
    @IBAction func saveSelectedImages(_ sender: Any) {
        guard let items = self.historyArrayController.selectedObjects as? [HistoryItem] else { return }
        if !items.isEmpty { self.displaySavePanel(historyItems: items)}
    }
    
    // MARK: Save Panel for multiple images

    // open panel for multiple images
    func displaySavePanel(historyItems:[HistoryItem]) {
        print("displaying open panel for saving multiple images")
        let panel = NSOpenPanel()
        panel.canCreateDirectories = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.message = "Select a folder"
        panel.prompt = "Save Selected Images"
        
        
        panel.beginSheetModal(for: self.window!, completionHandler: { response in
            if response == NSApplication.ModalResponse.OK {
                //
                self.indindicator.isHidden = false
                self.indindicator.startAnimation(nil)
                self.progrLabel.stringValue = "Saving \(historyItems.count) images..."
                self.speedLabel.isHidden = true
                self.window?.beginSheet(self.progrWin)
                //
                guard let path = panel.url?.path(percentEncoded: false) else { return }
                
                var i = 1
                for item in historyItems {
                    let fullpath = path + "/\(String(item.prompt.prefix(50)))-\(i).\(item.seed).png"
                    let url = URL(filePath: fullpath)
                    print("save \(i) at \(url.absoluteString)")
                    
                    let nsimg = item.upscaledImage ?? item.image
                    guard let img = nsimg.cgImage(forProposedRect: nil, context: nil, hints: nil) else {return}
                    guard let data = CFDataCreateMutable(nil, 0) else { return }
                    guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else { return }
                    let iptc = [
                        kCGImagePropertyIPTCOriginatingProgram: "PromptToImage for macOS",
                        kCGImagePropertyIPTCCaptionAbstract: self.metadata(item:item),
                        kCGImagePropertyIPTCProgramVersion: "1.0"]
                    let meta = [kCGImagePropertyIPTCDictionary: iptc]
                    CGImageDestinationAddImage(destination, img, meta as CFDictionary)
                    guard CGImageDestinationFinalize(destination) else { return }
                    // save
                    do {
                        try (data as Data).write(to: url)
                    } catch {
                        print("error saving file: \(error)")
                    }
                    
                    i = i + 1
                }
                self.window?.endSheet(self.progrWin)
                
            } else {
                print("cancel")
                
            }
        })
        
    }


    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    // Click Main Share Button
     
    // main view share button
    @IBAction func clickMainShareButton(_ sender: NSButton) {
        guard let historyitems = self.historyArrayController.selectedObjects as? [HistoryItem] else { return }
        let images : [NSImage] = historyitems.map { $0.upscaledImage ?? $0.image }
        let sharingPicker = NSSharingServicePicker(items: images)
        sharingPicker.delegate = self
        sharingPicker.show(relativeTo: NSZeroRect,
                           of: sender,
                           preferredEdge: .minY)
        
        /*
        guard let historyitems = self.historyArrayController.selectedObjects as? [HistoryItem] else { return }
        //let images : [NSImage] = historyitems.map { $0.upscaledImage ?? $0.image }
        var images = [NSImage]()
        for hitem in historyitems {
            images.append(hitem.upscaledImage ?? hitem.image)
        }
        print("MAIN SHARE BUTTON items:\(images.count)")
        let sharingPicker = NSSharingServicePicker(items: images)
        sharingPicker.delegate = self
        sharingPicker.show(relativeTo: NSZeroRect,
                           of: sender,
                           preferredEdge: .minY)
         */
        
    }
    
    
    

    // MARK: Write To File

    func writeImageToFile(path: String,
                          image: NSImage,
                          format: NSBitmapImageRep.FileType) {
        let imageRep = NSBitmapImageRep(data: image.tiffRepresentation!)
        if let imageData = imageRep?.representation(using: format, properties: [:]) {
            do {
                try imageData.write(to: URL(fileURLWithPath: (path.hasSuffix(".png") ? path : "\(path).png")))
            }catch{ print(error) }
        }
    }


}


