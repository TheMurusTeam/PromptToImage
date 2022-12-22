//
//  Global Vars.swift
//  PromptToImage
//
//  Created by Hany El Imam on 05/12/22.
//

import Foundation
import CoreML
import AppKit

// file format
let savefileFormat : NSBitmapImageRep.FileType = .png

// model image size
let modelWidth : Double = 512
let modelHeight: Double = 512

// sd pipeline
var sdPipeline : StableDiffusionPipeline? = nil

var defaultModel = "Unet-ORIGINAL.mlmodelc"
var defaultComputeUnits : MLComputeUnits = .cpuAndGPU
var defaultGuidanceScale : Float = 7.5
var defaultUpscaleModelPath = Bundle.main.path(forResource: "realesrgan512", ofType: "mlmodelc")
