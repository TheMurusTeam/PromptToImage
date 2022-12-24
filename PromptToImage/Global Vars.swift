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
let modelWidth : Double = 512
let modelHeight: Double = 512

// sd pipeline
var sdPipeline : StableDiffusionPipeline? = nil




var defaultComputeUnits : MLComputeUnits = .cpuAndGPU
var defaultGuidanceScale : Float = 7.5
var defaultUpscaleModelPath = Bundle.main.path(forResource: "realesrgan512", ofType: "mlmodelc")
