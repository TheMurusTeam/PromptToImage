//
//  Start.swift
//  PromptToImage
//
//  Created by hany on 03/12/22.
//

import Foundation
import Cocoa
import CoreML

public protocol NSAppearanceCustomization : NSObjectProtocol {
    @available(OSX 10.9, *)
    var appearance: NSAppearance? { get set } 
}

func systemRAM() -> UInt64 {
    return ProcessInfo.processInfo.physicalMemory / 1073741824
}

extension AppDelegate {
    
    func startPromptToImage() {
        print("Starting PromptToImage")
        
        // create custom models directory in app sandbox if needed
        createModelsDir()
        
        // read user defaults
        modelResourcesURL = UserDefaults.standard.url(forKey: "modelResourcesURL") ?? defaultModelResourcesURL
        
        // set app appearance
        // NSApplication.shared.appearance = NSAppearance(named: .darkAqua)
        
        // show main window
        wins["main"] = SDMainWindowController(windowNibName: "SDMainWindowController",
                                              info: nil)
        // load Stable Diffusion and Upscaler CoreML models
        if !createStableDiffusionPipeline(computeUnits: defaultComputeUnits, url:modelResourcesURL) {
            let _ = createStableDiffusionPipeline(computeUnits: defaultComputeUnits, url:defaultModelResourcesURL)
        }
        
    }
    
}
