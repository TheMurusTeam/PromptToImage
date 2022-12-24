//
//  Global Vars.swift
//  PromptToImage
//
//  Created by Hany El Imam on 05/12/22.
//

import Foundation
import CoreML
import AppKit

// stable diffusion model resources URL
let defaultModelResourcesURL : URL = Bundle.main.resourceURL!
let defaultModelName = "Stable Diffusion 2.1 SPLIT EINSUM"

var modelResourcesURL : URL = Bundle.main.resourceURL!

// file format
let savefileFormat : NSBitmapImageRep.FileType = .png

// model image size
var modelWidth : Double = 512
var modelHeight: Double = 512

// sd pipeline
var sdPipeline : StableDiffusionPipeline? = nil



let defaultComputeUnits : MLComputeUnits = .cpuAndGPU
var currentComputeUnits : MLComputeUnits = .cpuAndGPU

var defaultGuidanceScale : Float = 7.5
var defaultUpscaleModelPath = Bundle.main.path(forResource: "realesrgan512", ofType: "mlmodelc")
