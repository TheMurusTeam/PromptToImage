//
//  Load SD Model.swift
//  PromptToImage
//
//  Created by hany on 05/12/22.
//

import Foundation
import CoreML


func loadModels(computeUnits:MLComputeUnits,
                guidanceScale:Float) {
    
    // show wait window
    (wins["main"] as! SDMainWindowController).waitProgr.startAnimation(nil)
    (wins["main"] as! SDMainWindowController).waitLabel.stringValue = "Loading CoreML models..."
    (wins["main"] as! SDMainWindowController).window?.beginSheet((wins["main"] as! SDMainWindowController).waitWin)
    
    DispatchQueue.global().async {
        
        // create Stable Diffusion pipeline from CoreML resources
        print("creating Stable Diffusion pipeline...")
        do {
            let config = MLModelConfiguration()
            config.computeUnits = computeUnits
            sdPipeline = try StableDiffusionPipeline(resourcesAt: Bundle.main.resourceURL!,
                                                     configuration:config)
            try sdPipeline?.loadResources()
        } catch {}
        
        
        // load upscale model
        print("loading upscale model...")
        Upscaler.shared.setupUpscaleModelFromPath(path: defaultUpscaleModelPath!,
                                                  computeUnits: .cpuAndGPU)
        
        // close waiw window
        DispatchQueue.main.async {
            (wins["main"] as! SDMainWindowController).window?.endSheet((wins["main"] as! SDMainWindowController).waitWin)
        }
    }
}
