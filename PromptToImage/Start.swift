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
        
        // create custom directories in app sandbox if needed
        createModelsDir()
        createHistoryDir()
        
        // set model and compute units
        if CGEventSource.keyState(CGEventSourceStateID.init(rawValue: 0)!, key: 0x3a) ||
            CGEventSource.keyState(CGEventSourceStateID.init(rawValue: 0)!, key: 0x37) {
            // app has been launched keeping ALT or COMMAND pressed, use factory settings
            currentModelResourcesURL = builtInModelResourcesURL
            currentComputeUnits = defaultComputeUnits
        } else {
            // set model url
            currentModelResourcesURL = UserDefaults.standard.url(forKey: "modelResourcesURL") ?? builtInModelResourcesURL
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
        if !builtInModelExists() && installedCustomModels().isEmpty {
            // ALL MODEL DIRS EMPTY, show model download window
            DispatchQueue.main.async {
                if let ctrl = wins["main"] as? SDMainWindowController {
                    ctrl.window?.beginSheet(ctrl.downloadWindow)
                }
            }
            
        } else {
            // ATTEMPT TO LOAD A MODEL
            DispatchQueue.global().async {
               // load last used model
                print("Load last used model from \(currentModelResourcesURL)...")
                createStableDiffusionPipeline(computeUnits: currentComputeUnits, url:currentModelResourcesURL)
                
                if sdPipeline == nil {
                    print("unable to load last used model, trying built-in model at \(builtInModelResourcesURL) (appstore only)")
                    // unable to load last used model, load built-in model if available (MacAppStore only)
                    currentComputeUnits = defaultComputeUnits
                    createStableDiffusionPipeline(computeUnits: defaultComputeUnits, url:builtInModelResourcesURL)
                }
                
                if sdPipeline == nil {
                    print("unable to load built-in model, checking custom models dir...")
                    // unable to load built-in model, checking custom models directory...
                    for customModelURL in installedCustomModels() {
                        print("Attempting to load custom model \(customModelURL.lastPathComponent)")
                        createStableDiffusionPipeline(computeUnits: defaultComputeUnits, url:customModelURL)
                        if sdPipeline != nil {
                            print("Success loading model \(customModelURL.lastPathComponent)")
                            currentModelResourcesURL = customModelURL
                            // save to user defaults
                            UserDefaults.standard.set(currentModelResourcesURL, forKey: "modelResourcesURL")
                            return
                        }
                    }
                } else {
                    // save to user defaults
                    UserDefaults.standard.set(currentModelResourcesURL, forKey: "modelResourcesURL")
                }
                
                if sdPipeline == nil {
                    // unable to load model, request user interaction
                    print("Unable to load a Stable Diffusion model!")
                    // show model download window
                    DispatchQueue.main.async {
                        if let ctrl = wins["main"] as? SDMainWindowController {
                            ctrl.window?.beginSheet(ctrl.downloadWindow)
                        }
                    }
                }
            }
        }
        
        
        
    }
    
    
    
    
    
    func willTerminate() {
        UserDefaults.standard.setValue(cu2str(cu: currentComputeUnits), forKey: "computeUnits")
    }
    
    
    
    
    
    
    // MLComputeUnits -> String -> MLComputeUnits
    
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
