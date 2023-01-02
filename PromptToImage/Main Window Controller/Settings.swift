//
//  Settings.swift
//  PromptToImage
//
//  Created by hany on 25/12/22.
//

import Foundation
import AppKit

extension SDMainWindowController {
    
    // MARK: show settings window
    
    @IBAction func displaySettings(_ sender: Any) {
        self.window?.beginSheet(self.settingsWindow)
    }
    
    
    
    // MARK: close settings window
    
    @IBAction func closeSettingsWindow(_ sender: Any) {
        self.window?.endSheet(self.settingsWindow)
    }
    
    
    
    // MARK: Reveal models dir in Finder
    
    @IBAction func clickRevealModelsInFinder(_ sender: Any) {
        revealCustomModelsDirInFinder()
    }
    
    
    
    
    // MARK: Compute Units Popup
    
    func setUnitsPopup() {
        self.unitsPopup.itemArray.forEach { $0.state = .off }
        var idx = Int()
        switch currentComputeUnits {
        case .cpuAndNeuralEngine: idx = 1
        case .cpuAndGPU: idx = 2
        default: idx = 3 // all
        }
        self.unitsPopup.selectItem(at: idx)
        self.unitsPopup.item(at: idx)?.state = .on
    }
    
    @IBAction func switchUnitsPopup(_ sender: NSPopUpButton) {
        switch sender.indexOfSelectedItem {
        case 2: currentComputeUnits = .cpuAndGPU; loadSDModel()
        case 3: currentComputeUnits = .all; loadSDModel()
        case 1: currentComputeUnits = .cpuAndNeuralEngine; loadSDModel()
        default:break
        }
        
    }
    
    
    
    // MARK: Switch Models Popup
    
    @IBAction func switchModelsPopup(_ sender: NSPopUpButton) {
        guard let modelName = sender.titleOfSelectedItem else {return}
        // evaluate item
        if let modelUrl = sender.selectedItem?.representedObject as? URL {
            // item has an URL, load model
            self.loadModelFromURL(modelName: modelName, modelUrl: modelUrl)
        } else {
            // item has no URL, import model
            guard let repObj = sender.selectedItem?.representedObject as? String else { return }
            if repObj == "import" {
                // import model from dir
                self.importModel()
            } /*else if repObj == "repo" {
                // open huggingface repo in browser
                let url = "https://huggingface.co/TheMurusTeam"
                if let url = URL(string: url) { NSWorkspace.shared.open(url) }
            }*/
            // restore selected item
            self.setModelsPopup()
        }
    }
    
    
    
    // MARK: Load model from URL
    
    // called when switching models popup or when loading an imported model
    func loadModelFromURL(modelName:String, modelUrl:URL) {
        let alert = NSAlert()
        alert.messageText = "Load model?"
        alert.informativeText = "Model \(modelName) will be loaded using the specified compute units."
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Load Model")
        alert.accessoryView = self.modelAlertView
        // set alert units popup
        if self.settings_selectDefaultCU.state == .on {
            currentComputeUnits = defaultComputeUnits
            self.modelAlertCUPopup.selectItem(at: 1)
        } else {
            switch currentComputeUnits {
            case .cpuAndNeuralEngine: self.modelAlertCUPopup.selectItem(at: 0)
            case .cpuAndGPU: self.modelAlertCUPopup.selectItem(at: 1)
            default: self.modelAlertCUPopup.selectItem(at: 2) // all
            }
        }
        // show alert
        guard alert.runModal() != NSApplication.ModalResponse.alertFirstButtonReturn else {
            // Cancel
            self.setModelsPopup()
            return
        }
        // Load model
        print("loading model \(modelName)")
        // set compute units
        switch self.modelAlertCUPopup.indexOfSelectedItem {
        case 0: currentComputeUnits = .cpuAndNeuralEngine
        case 1: currentComputeUnits = .cpuAndGPU
        default: currentComputeUnits = .all
        }
        
        currentModelResourcesURL = modelUrl
        print("setting currentModelResourcesURL to \(currentModelResourcesURL)")
        // load sd model
        loadSDModel()
    }
    
    
    // MARK: Populate Upscale Popup
    
    func populateUpscalePopup() {
        guard let menu = self.upscalePopup.menu else {return}
        guard let firstitem = menu.item(at: 0) else {return}
        menu.removeAllItems()
        menu.addItem(firstitem)
        // title
        let title = NSMenuItem()
        title.title = "Select Upscale Model"
        menu.addItem(title)
        title.isEnabled = false
        
        // built-in model
        let item = NSMenuItem()
        item.title = "realesrgan512 (Default)"
        item.representedObject = URL(fileURLWithPath: defaultUpscaleModelPath!).absoluteURL
        menu.addItem(item)
        
        // custom models
        for upscaler in installedCustomUpscalers() {
            let item = NSMenuItem()
            item.title = URL(string: NSURL(fileURLWithPath: upscaler.path).lastPathComponent ?? String())?.deletingPathExtension().path ?? String()
            item.representedObject = upscaler.absoluteURL
            menu.addItem(item)
        }
        
        // add custom model
        menu.addItem(NSMenuItem.separator())
        let itemi = NSMenuItem()
        itemi.title = "Import CoreML upscale model..."
        itemi.representedObject = "import"
        menu.addItem(itemi)
        
        // set selected item
        if currentUpscalerName == "realesrgan512" {
            menu.item(at: 2)!.state = .on
        } else {
            for item in menu.items {
                if item.title == currentUpscalerName {
                    item.state = .on
                }
            }
        }
    }
    
    
    
    // MARK: Populate Models Popup
    
    func populateModelsPopup() {
        // create menu items
        if let menu = self.modelsPopup.menu {
            menu.removeAllItems()
            
            // built-in model
            if builtInModelExists() {
                let item = NSMenuItem()
                item.title = "Stable Diffusion 2.1 SPLIT EINSUM (Default)"
                item.representedObject = builtInModelResourcesURL
                menu.addItem(item)
                menu.addItem(NSMenuItem.separator())
            }
            
            // default and custom models
            let urls = installedCustomModels()
            for modelurl in urls {
                if modelurl.isFolder {
                    let item = NSMenuItem()
                    item.title = modelurl.lastPathComponent
                    item.representedObject = modelurl
                    menu.addItem(item)
                }
            }
            
            
            menu.addItem(NSMenuItem.separator())
            let item = NSMenuItem()
            item.title = "Import CoreML Stable Diffusion model..."
            item.representedObject = "import"
            menu.addItem(item)
            
            // item view
            menu.addItem(NSMenuItem.separator())
            let item3 = NSMenuItem()
            item3.view = self.modelsPopupAccView
            menu.addItem(item3)
            
            // set selected item
            self.setModelsPopup()
        }
    }
    
    
    
    
    
    // MARK: Set Models Popup
    
    func setModelsPopup() {
        // set selected item
        if let menu = self.modelsPopup.menu {
            for mitem in menu.items {
                mitem.state = .off
                if let url = mitem.representedObject as? URL {
                    if url == currentModelResourcesURL {
                        self.modelsPopup.select(mitem)
                        mitem.state = .on
                        //print("current model: \(mitem.title)")
                    }
                }
            }
        }
    }
    
  
}
