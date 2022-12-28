//
//  Generate Image.swift
//  PromptToImage
//
//  Created by hany on 03/12/22.
//

import Foundation
import Cocoa
import CoreML



extension SDMainWindowController {
    
    
    
    // MARK: Generate Image
    
    func generateImage(prompt:String,
                       negativePrompt:String,
                       startingImage: CGImage? = nil,
                       strength: Float = 1,
                       imageCount: Int = 1,
                       stepCount:Int,
                       seed:Int,
                       guidanceScale:Float,
                       stepsPreview:Bool) {
        
        // upscale option
        let upscale = self.upscaleCheckBox.state == .on
        
        // resize input image if needed
        var inputImage : CGImage? = nil
        if let startingImage = startingImage {
            print("original input image size: \(startingImage.width)x\(startingImage.height)")
            if let nsinputimage = resizeImage(image: NSImage(cgImage: startingImage, size: .zero)) {
                inputImage = nsinputimage.cgImage(forProposedRect: nil, context: nil, hints: nil)
                print("resized input image size: \(inputImage?.width ?? 0)x\(inputImage?.height ?? 0)")
            }
        }
        
        // set labels and indicators
        self.indicator.doubleValue = 0
        self.indicator.maxValue = startingImage == nil ? Double(stepCount) : Double(Float(stepCount) * strength)
        self.indicator.isHidden = true
        self.indindicator.isHidden = false
        self.indindicator.startAnimation(nil)
        self.progrLabel.stringValue = "Waiting for pipeline..."
        self.speedLabel.isHidden = true
        // show wait win
        self.window?.beginSheet(self.progrWin)
        
        // generate images
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if let pipeline = sdPipeline {
                    // timer for performance indicator
                    let sampleTimer = SampleTimer() // used for pipeline performance indicator
                    sampleTimer.start()
                    
                    // generate image
                    let images = try pipeline.generateImages(prompt: prompt,
                                                             negativePrompt: negativePrompt,
                                                             startingImage: inputImage,
                                                             strength: strength,
                                                             imageCount: imageCount,
                                                             stepCount: stepCount,
                                                             seed: seed,
                                                             guidanceScale: guidanceScale,
                                                             disableSafety: true,
                                                             scheduler: startingImage == nil ? .dpmSolverMultistepScheduler : .pndmScheduler) {
                        progress in
                        // performance indicator
                        DispatchQueue.main.async {
                            sampleTimer.stop()
                            self.speedLabel.stringValue = "\(String(format: "Speed: %.2f ", (1.0 / sampleTimer.median * Double(imageCount)))) step/sec"
                            if progress.stepCount != progress.step { sampleTimer.start() }
                        }
                        return self.handleProgress(progress, imageCount: imageCount)
                    }
                    
                    
                    // display images
                    self.displayResult(images: images,
                                       upscale: upscale,
                                       prompt: prompt,
                                       negativePrompt: negativePrompt,
                                       startingImage: inputImage,
                                       strength: strength,
                                       stepCount: stepCount,
                                       seed: seed,
                                       guidanceScale: guidanceScale)
                    
                    
                } else {
                    print("ERROR: cannot create pipeline")
                    DispatchQueue.main.async { self.window?.endSheet(self.progrWin) }
                }
                
            } catch {
                print("ERROR \(error)")
                DispatchQueue.main.async { self.window?.endSheet(self.progrWin) }
            }
        }
    }
    
    
    
    
    // MARK: Handle Progress
    
    private func handleProgress(_ progress: StableDiffusionPipeline.Progress, imageCount:Int) -> Bool {
        DispatchQueue.main.async {
            // progress indicator
            self.indicator.doubleValue = Double(progress.step)
            if progress.step > 0 {
                self.speedLabel.isHidden = false
                self.progrLabel.stringValue = imageCount == 1 ? "Generating image..." : "Generating \(imageCount) images..."
                self.indindicator.isHidden = true
                self.indicator.isHidden = false
            }
        }
        return isRunning
    }
    
}







