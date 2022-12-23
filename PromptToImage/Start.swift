//
//  Start.swift
//  PromptToImage
//
//  Created by hany on 03/12/22.
//

import Foundation
import Cocoa
import CoreML




extension AppDelegate {
    
    func startPromptToImage() {
        print("Starting PromptToImage")
        // show main window
        wins["main"] = SDMainWindowController(windowNibName: "SDMainWindowController",
                                              info: nil)
        // load CoreML models
        createStableDiffusionPipeline(computeUnits: defaultComputeUnits, url:modelResourcesURL)
        
    }
    
}
