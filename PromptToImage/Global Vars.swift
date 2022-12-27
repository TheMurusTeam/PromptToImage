//
//  Global Vars.swift
//  PromptToImage
//
//  Created by Hany El Imam on 05/12/22.
//

import Foundation
import CoreML
import AppKit




// default model remote URL
let defaultModelPublicURL = "https://www.murusfirewall.com/downloads/Stable-Diffusion-2-1-SPLIT-EINSUM.zip"

// dirs for custom models and history file
// this is a sandboxed app, these dirs are inside app's container in user home dir
let customModelsDirectoryPath = "models"
let historyPath = "history"

// win controllers store
var wins = [String:NSWindowController]()

// sd status
var isRunning = false

// built-in stable diffusion model (MacAppStore only)
let builtInModelResourcesURL : URL = Bundle.main.resourceURL!
let defaultModelName = "Stable Diffusion 2.1 SPLIT EINSUM"

// current model resources URL
var currentModelResourcesURL : URL = Bundle.main.resourceURL!
var currentModelRealName : String? = nil {
    didSet {
        (wins["main"] as! SDMainWindowController).modelCardBtn.isHidden = currentModelRealName == nil
    }
}

// file format
let savefileFormat : NSBitmapImageRep.FileType = .png

// model image size
var modelWidth : Double = 512
var modelHeight: Double = 512

// Stable Diffusion pipeline
var sdPipeline : StableDiffusionPipeline? = nil 

// pipeline compute units
let defaultComputeUnits : MLComputeUnits = .cpuAndGPU
var currentComputeUnits : MLComputeUnits = .cpuAndGPU

// upscaler model
let defaultUpscaleModelPath = Bundle.main.path(forResource: "realesrgan512", ofType: "mlmodelc")
let defaultUpscalerComputeUnits : MLComputeUnits = .cpuAndGPU
