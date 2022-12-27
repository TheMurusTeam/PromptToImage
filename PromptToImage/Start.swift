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
        print("Built-in model exists: \(builtInModelExists())")
        
        // load upscaler CoreML model
        DispatchQueue.global().async {
            loadUpscalerModel()
        }
        
        // load Stable Diffusion CoreML models
        DispatchQueue.global().async {
           // load last used model
            createStableDiffusionPipeline(computeUnits: currentComputeUnits, url:modelResourcesURL)
            
            if sdPipeline == nil {
                // unable to load last used model, load built-in model if available
                currentComputeUnits = defaultComputeUnits
                modelResourcesURL = defaultModelResourcesURL
                createStableDiffusionPipeline(computeUnits: defaultComputeUnits, url:defaultModelResourcesURL)
            }
            
            if sdPipeline == nil {
                // unable to load built-in model, checking custom models directory...
                let customModelsURLs = installedCustomModels()
                for customModelURL in customModelsURLs {
                    print("Trying custom model \(customModelURL.lastPathComponent)")
                    modelResourcesURL = customModelURL
                    createStableDiffusionPipeline(computeUnits: defaultComputeUnits, url:modelResourcesURL)
                    if sdPipeline != nil {
                        print("Success loading model \(customModelURL.lastPathComponent)")
                        return
                    }
                }
            }
            
            if sdPipeline == nil {
                // unable to load model, request user interaction
                print("Unable to load a Stable Diffusion model!")
                
                DispatchQueue.main.async {
                    if let ctrl = wins["main"] as? SDMainWindowController {
                        ctrl.window?.beginSheet(ctrl.settingsWindow)
                        let alert = NSAlert()
                        alert.messageText = "Welcome to PromptToImage"
                        alert.informativeText = "You need to install a CoreML Stable Diffusion model in custom models directory.\n\nClick 'Download Default Model' to download the default model '\(defaultModelName)' from HuggingFace web site.\n\nTo install a model unzip it and move all files to custom models directory.\nClick 'Reveal Custom Models Dir in Finder' to display custom models directory.\n\nInstalled model will automatically appear in the 'Model' popup button. Select a model to start using PromptToImage."
                        alert.addButton(withTitle: "Download Default Model")
                        alert.addButton(withTitle: "Close This Alert")
                        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
                            if let url = URL(string: defaultModelPublicURL) {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        
                    }
                }
                
                
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
