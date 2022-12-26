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
        
        // set app appearance
        NSApplication.shared.appearance = NSAppearance(named: .darkAqua)
        
        // create custom directories in app sandbox if needed
        createModelsDir()
        createHistoryDir()
        
        // set model and compute units
        if CGEventSource.keyState(CGEventSourceStateID.init(rawValue: 0)!, key: 0x3a) ||
            CGEventSource.keyState(CGEventSourceStateID.init(rawValue: 0)!, key: 0x37) {
            // app has been launched keeping ALT or COMMAND pressed, use factory settings
            modelResourcesURL = defaultModelResourcesURL
            currentComputeUnits = defaultComputeUnits
        } else {
            // set model url
            modelResourcesURL = UserDefaults.standard.url(forKey: "modelResourcesURL") ?? defaultModelResourcesURL
            // set compute units
            if let str = UserDefaults.standard.value(forKey: "computeUnits") as? String {
                print("Compute units: \(str)")
                currentComputeUnits = str2cu(str: str)
            }
        }
           
        // show main window
        wins["main"] = SDMainWindowController(windowNibName: "SDMainWindowController", info: nil)
        
        // load models
        DispatchQueue.global().async {
            // load upscaler CoreML model
            loadUpscalerModel()
            
            // load Stable Diffusion CoreML models
            // load last used model
            createStableDiffusionPipeline(computeUnits: currentComputeUnits, url:modelResourcesURL)
            if sdPipeline == nil {
                // load factory model
                createStableDiffusionPipeline(computeUnits: defaultComputeUnits, url:defaultModelResourcesURL)
            }
        }
        
    }
    
    
    
    
    
    
    
    
    
    func willTerminate() {
        UserDefaults.standard.setValue(cu2str(cu: currentComputeUnits), forKey: "computeUnits")
    }
    
    
    func cu2str(cu:MLComputeUnits) -> String {
        switch cu {
        case .cpuAndGPU: return "cpuAndGPU"
        case .cpuAndNeuralEngine: return "cpuAndNeuralEngine"
        case .cpuOnly: return "cpuOnly"
        default: return "all"
        }
    }
    
    func str2cu(str:String) -> MLComputeUnits {
        switch str {
        case "cpuAndGPU": return .cpuAndGPU
        case "cpuAndNeuralEngine": return .cpuAndNeuralEngine
        case "cpuOnly": return .cpuOnly
        default: return .all
        }
    }
    
}
