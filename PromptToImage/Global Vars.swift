//
//  Global Vars.swift
//  PromptToImage
//
//  Created by Hany El Imam on 05/12/22.
//

import Foundation
import CoreML
import AppKit

// store
var wins = [String:NSWindowController]()

// sd status
var isRunning = false

// built-in stable diffusion model resources URL/name
let defaultModelPublicURL = "https://huggingface.co/TheMurusTeam/CoreML-Stable-Diffusion-2.1-SPLIT_EINSUM-img2img/blob/main/Stable%20Diffusion%202.1%20SPLIT%20EINSUM.zip"
let defaultModelResourcesURL : URL = Bundle.main.resourceURL!
let defaultModelName = "Stable Diffusion 2.1 SPLIT EINSUM"

// current model resources URL
var modelResourcesURL : URL = Bundle.main.resourceURL!

// file format
let savefileFormat : NSBitmapImageRep.FileType = .png

// model image size
var modelWidth : Double = 512
var modelHeight: Double = 512

// sd pipeline
var sdPipeline : StableDiffusionPipeline? = nil

// sd compute units
let defaultComputeUnits : MLComputeUnits = .cpuAndGPU
var currentComputeUnits : MLComputeUnits = .cpuAndGPU

// upscaler
let defaultUpscaleModelPath = Bundle.main.path(forResource: "realesrgan512", ofType: "mlmodelc")
let defaultUpscalerComputeUnits : MLComputeUnits = .cpuAndGPU
