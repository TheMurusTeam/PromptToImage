//
//  Load SD Model.swift
//  PromptToImage
//
//  Created by hany on 05/12/22.
//

import Foundation
import CoreML
import AppKit


// MARK: Create Pipeline

func createStableDiffusionPipeline(computeUnits:MLComputeUnits, url:URL) {
    DispatchQueue.main.async {
        // show wait window
        (wins["main"] as! SDMainWindowController).waitProgr.startAnimation(nil)
        (wins["main"] as! SDMainWindowController).waitLabel.stringValue = "Loading Model"
        (wins["main"] as! SDMainWindowController).waitInfoLabel.stringValue = url == builtInModelResourcesURL ? "Built-in model" : url.lastPathComponent
        (wins["main"] as! SDMainWindowController).clearCUImages()
        (wins["main"] as! SDMainWindowController).modelMainLabel.stringValue = "Loading model..."
        var custring = String()
        switch computeUnits {
        case .cpuAndNeuralEngine: custring = "CPU and Neural Engine"
        case .cpuAndGPU: custring = "CPU and GPU"
        case .cpuOnly: custring = "CPU only"
        default: custring = "All Compute Units"
        }
        (wins["main"] as! SDMainWindowController).waitCULabel.stringValue = custring
        (wins["main"] as! SDMainWindowController).window?.beginSheet((wins["main"] as! SDMainWindowController).waitWin)
    }
    
    
    // clear pipeline
    sdPipeline?.unloadResources()
    sdPipeline = nil
    
    // create Stable Diffusion pipeline from CoreML resources
    print("creating Stable Diffusion pipeline...")
    print("Model: \(url.lastPathComponent)")
    print("Model dir path: \(url.path(percentEncoded: false))")
    
    do {
        let config = MLModelConfiguration()
        config.computeUnits = computeUnits
        sdPipeline = try StableDiffusionPipeline(resourcesAt: url,
                                                 configuration:config)
        try sdPipeline?.loadResources()
        DispatchQueue.main.async {
            (wins["main"] as! SDMainWindowController).modelMainLabel.stringValue = url.lastPathComponent
        }
    } catch {
        print("Unable to create Stable Diffusion pipeline")
        sdPipeline = nil
        DispatchQueue.main.async {
            (wins["main"] as! SDMainWindowController).modelMainLabel.stringValue = "No model selected"
        }
    }
    
    
    
    // close wait window
    DispatchQueue.main.async {
        (wins["main"] as! SDMainWindowController).window?.endSheet((wins["main"] as! SDMainWindowController).waitWin)
        (wins["main"] as! SDMainWindowController).enableImg2Img()
        (wins["main"] as! SDMainWindowController).setCUImages()
    }
    
}




// MARK: Reload Model

func loadSDModel() {
    DispatchQueue.global().async {
        createStableDiffusionPipeline(computeUnits: currentComputeUnits, url:currentModelResourcesURL)
        if sdPipeline == nil {
            // error
            print("error creating pipeline")
            DispatchQueue.main.async {
                displayErrorAlert(txt: "Unable to create Stable Diffusion pipeline using model at url \(currentModelResourcesURL)\n\nClick the button below to dismiss this alert and restore default model")
                // restore default model and compute units
                createStableDiffusionPipeline(computeUnits: defaultComputeUnits,
                                              url: builtInModelResourcesURL)
                currentModelResourcesURL = builtInModelResourcesURL
                // set user defaults
                UserDefaults.standard.set(currentModelResourcesURL, forKey: "modelResourcesURL")
            }
        } else {
            // save to user defaults
            UserDefaults.standard.set(currentModelResourcesURL, forKey: "modelResourcesURL")
        }
    }
}

