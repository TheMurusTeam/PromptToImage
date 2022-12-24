//
//  Load SD Model.swift
//  PromptToImage
//
//  Created by hany on 05/12/22.
//

import Foundation
import CoreML


// MARK: Create Pipeline

func createStableDiffusionPipeline(computeUnits:MLComputeUnits, url:URL) -> Bool {
    
    sdPipeline?.unloadResources()
    sdPipeline = nil
    
    // show wait window
    (wins["main"] as! SDMainWindowController).waitProgr.startAnimation(nil)
    (wins["main"] as! SDMainWindowController).waitLabel.stringValue = "Loading Model"
    (wins["main"] as! SDMainWindowController).waitInfoLabel.stringValue = currentModelName()
    (wins["main"] as! SDMainWindowController).window?.beginSheet((wins["main"] as! SDMainWindowController).waitWin)
    
    DispatchQueue.global().sync {
        
        // create Stable Diffusion pipeline from CoreML resources
        print("creating Stable Diffusion pipeline...")
        print("Model: \(modelResourcesURL.path(percentEncoded: false))")
        do {
            let config = MLModelConfiguration()
            config.computeUnits = computeUnits
            sdPipeline = try StableDiffusionPipeline(resourcesAt: url,
                                                     configuration:config)
            try sdPipeline?.loadResources()
        } catch {
            print("Unable to create Stable Diffusion pipeline")
            
        }
        
        
        // load upscale model
        print("loading upscale model...")
        Upscaler.shared.setupUpscaleModelFromPath(path: defaultUpscaleModelPath!,
                                                  computeUnits: .cpuAndGPU)
        
        // close waiw window
        DispatchQueue.main.async {
            (wins["main"] as! SDMainWindowController).window?.endSheet((wins["main"] as! SDMainWindowController).waitWin)
            (wins["main"] as! SDMainWindowController).enableImg2Img()
            
            if let shape = (sdPipeline?.unet.models[0].loadedModel?.modelDescription.inputDescriptionsByName["sample"] as? MLFeatureDescription)?.multiArrayConstraint?.shape {
                modelWidth = Double(shape[3]) * 8
                modelHeight = Double(shape[2]) * 8
                print("Model resolution: \(modelWidth)x\(modelHeight)")
            }
        }
    }
    
    
    return sdPipeline != nil
}
