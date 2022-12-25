//
//  Load Upscale Models.swift
//  PromptToImage
//
//  Created by hany on 25/12/22.
//

import Foundation


func loadUpscalerModel() {
    Upscaler.shared.setupUpscaleModelFromPath(path: defaultUpscaleModelPath!, computeUnits: defaultUpscalerComputeUnits)
}
