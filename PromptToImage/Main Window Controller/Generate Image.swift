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
                       scheduler:StableDiffusionScheduler,
                       upscale:Bool) {
        
        // resize input image if needed
        let inputImage = self.resizeInputImage(image: startingImage)
        
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
                    
                    // generate images
                    let images = try pipeline.generateImages(prompt: prompt,
                                                             negativePrompt: negativePrompt,
                                                             startingImage: inputImage,
                                                             strength: strength,
                                                             imageCount: imageCount,
                                                             stepCount: stepCount,
                                                             seed: seed,
                                                             guidanceScale: guidanceScale,
                                                             disableSafety: true,
                                                             scheduler: scheduler) {
                        progress in
                        return self.handleProgress(progress, imageCount: imageCount, sampleTimer:sampleTimer)
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
    
    private func handleProgress(_ progress: StableDiffusionPipeline.Progress,
                                imageCount:Int,
                                sampleTimer:SampleTimer) -> Bool {
        DispatchQueue.main.async {
            // progress indicator
            self.indicator.doubleValue = Double(progress.step)
            if progress.step > 0 {
                self.speedLabel.isHidden = false
                self.progrLabel.stringValue = imageCount == 1 ? "Generating image..." : "Generating \(imageCount) images..."
                self.indindicator.isHidden = true
                self.indicator.isHidden = false
            }
            // performance indicator
            //DispatchQueue.main.async {
                sampleTimer.stop()
                self.speedLabel.stringValue = "\(String(format: "Speed: %.2f ", (1.0 / sampleTimer.median * Double(imageCount)))) step/sec"
                if progress.stepCount != progress.step { sampleTimer.start() }
            //}
        }
        return isRunning
    }
    
    
    
    // FIXME: Resize CGImage
    func resizeInputImage(image:CGImage?) -> CGImage? {
        guard let cgimage = image else { return nil }
        print("original input image size: \(cgimage.width)x\(cgimage.height)")
        guard let nsimage = resizeImage(image: NSImage(cgImage: cgimage, size: .zero), new_width: modelWidth, new_height: modelHeight) else { return nil }
        let resizedCGimage = nsimage.cgImage(forProposedRect: nil, context: nil, hints: nil)
        print("resized input image size: \(resizedCGimage?.width ?? 0)x\(resizedCGimage?.height ?? 0)")
        return resizedCGimage
    }
    
}







