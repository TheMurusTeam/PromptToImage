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
        self.setModelsPopup()
        self.setUnitsPopup()
        self.window?.beginSheet(self.settingsWindow)
    }
    
    // MARK: close settings window
    
    @IBAction func closeSettingsWindow(_ sender: Any) {
        self.window?.endSheet(self.settingsWindow)
    }
    
    
    
    // MARK: Compute Units Popup
    
    func setUnitsPopup() {
        switch currentComputeUnits {
        case .cpuAndNeuralEngine: self.unitsPopup.selectItem(at: 0)
        case .cpuAndGPU: self.unitsPopup.selectItem(at: 1)
        default: self.unitsPopup.selectItem(at: 2) // all
        }
    }
    
    @IBAction func switchUnitsPopup(_ sender: NSPopUpButton) {
        //self.settingsWindow.close()
        self.window?.endSheet(self.settingsWindow)
        switch sender.indexOfSelectedItem {
        case 1: currentComputeUnits = .cpuAndGPU
        case 2: currentComputeUnits = .all
        default: currentComputeUnits = .cpuAndNeuralEngine
        }
        loadSDModel()
    }
    
    
    
    // MARK: SD Model Popup
    
    @IBAction func switchModelsPopup(_ sender: NSPopUpButton) {
        self.window?.endSheet(self.settingsWindow)
        // change current model url
        if let modelurl = sender.selectedItem?.representedObject as? URL {
            currentModelResourcesURL = modelurl
            print("setting currentModelResourcesURL to \(currentModelResourcesURL)")
        }
        
        // restore "CPU and GPU" compute units when switching model
        if self.settings_selectDefaultCU.state == .on {
            currentComputeUnits = defaultComputeUnits
        }
        
        // load sd model
        loadSDModel()

    }
    
    
    
    // MARK: Reveal models dir in Finder
    
    @IBAction func clickRevealModelsInFinder(_ sender: Any) {
        // self.window?.endSheet(self.settingsWindow)
        revealCustomModelsDirInFinder()
    }
    
}
