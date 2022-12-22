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
        
        let upscale = self.upscaleCheckBox.state == .on
        self.copyOutputBtn.isHidden = imageCount > 1
        
        // input image
        if let startingImage = startingImage {print("Starting image size: \(startingImage.width)x\(startingImage.height)")}
        var inputImage : CGImage? = startingImage
        if let iimage = inputImage {
            if (iimage.width != Int(modelWidth)) || (iimage.height != Int(modelHeight)) {
                inputImage = startingImage?.resize(size: NSSize(width: modelWidth, height: modelHeight))
                print("Resized starting image size: \(inputImage?.width)x\(inputImage?.height)")
            }
        }
        
        self.indicator.doubleValue = 0
        self.indicator.maxValue = inputImage == nil ? Double(stepCount) : Double(Float(stepCount) * strength)
        self.indicator.isHidden = true
        self.indindicator.isHidden = false
        self.indindicator.startAnimation(nil)
        self.progrLabel.stringValue = "Waiting for pipeline..."
        self.speedLabel.isHidden = true
        
        self.window?.beginSheet(self.progrWin)
        
        DispatchQueue.global().async {
            do {
                if let pipeline = sdPipeline {
                    print("generating \(imageCount) images...")
                    print("seed:\(seed)")
                    let sampleTimer = SampleTimer()
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
                                                             scheduler: inputImage == nil ? .dpmSolverMultistepScheduler : .pndmScheduler)
                    { (sdprogress) -> Bool in
                        
                        // CALCULATE AND DISPLAY SPEED
                        sampleTimer.stop()
                        DispatchQueue.main.async {
                            self.speedLabel.stringValue = "\(String(format: "Speed: %.2f ", (1.0 / sampleTimer.median * Double(imageCount)))) step/sec"
                        }
                        if sdprogress.stepCount != sdprogress.step {
                            sampleTimer.start()
                        }
                        print("step \(sdprogress.step) of \(sdprogress.stepCount) (\(Int(Float(stepCount) * strength)))")
                        // UPDATE PROGRESS INDICATORS
                        DispatchQueue.main.async {
                            self.indicator.doubleValue = Double(sdprogress.step)
                            if sdprogress.step > 0 {
                                self.speedLabel.isHidden = false
                                self.progrLabel.stringValue = imageCount == 1 ? "Generating image..." : "Generating \(imageCount) images..."
                                self.indindicator.isHidden = true
                                self.indicator.isHidden = false
                            }
                        }
                        
                        if !isRunning { print("stop") }
                        return isRunning
                    }
                    
                    // DISPLAY OUTPUT IMAGES
                    print("images array count: \(images.count)")
                    print("displaying images...")
                    self.displayResult(images: images, upscale: upscale)
                    
                    
                } else {
                    print("ERROR: cannot create pipeline")
                    DispatchQueue.main.async {
                        self.saveBtn.isEnabled = false
                        self.window?.endSheet(self.progrWin)
                    }
                }
                
            } catch {
                print("ERROR \(error)")
                DispatchQueue.main.async {
                    self.saveBtn.isEnabled = false
                    self.window?.endSheet(self.progrWin)
                }
            }
        }
    }
    
    
    
    // MARK: Display Results
    
    func displayResult(images:[CGImage?],upscale:Bool) {
        DispatchQueue.main.async {
            self.imageview.isHidden = false
            self.colScrollView.isHidden = true
        }
        if images.count == 1 {
            self.displaySingleImage(image: images[0], upscale: upscale)
        } else if images.count > 1 {
            self.displayMultipleImages(images: images, upscale: upscale)
        }
    }
    
    
    // display collection view
    func displayMultipleImages(images:[CGImage?], upscale:Bool) {
        DispatchQueue.main.async {
            self.imageview.isHidden = true
            self.colScrollView.isHidden = false
            self.outputImages = [NSImage]()
            self.outputImagesArrayController.content = nil
            self.progrLabel.stringValue = "Upscaling images..."
            self.indindicator.isHidden = false
            self.indicator.isHidden = true
        }
        
        for cgimage in images {
            if cgimage != nil {
                let nsimage = NSImage(cgImage: cgimage!,size: .zero)
                    if upscale {
                        if let upscaledImage = Upscaler.shared.upscaledImage(image: nsimage) {
                            DispatchQueue.main.async {
                                self.outputImages.append(upscaledImage)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.outputImages.append(nsimage)
                        }
                    }
            }
        }
        DispatchQueue.main.async {
            self.saveBtn.isEnabled = true
            self.window?.endSheet(self.progrWin)
        }
    }
    
    
    
    
    // display image view
    func displaySingleImage(image:CGImage??, upscale:Bool) {
        if image != nil {
            let nsimage = NSImage(cgImage: image!!,
                                  size: .zero)
            DispatchQueue.main.async {
                self.imageview.image = nsimage
                isRunning = false
                
                if upscale {
                    // UPSCALE OUTPUT IMAGE
                    
                    self.progrLabel.stringValue = "Upscaling image..."
                    self.indindicator.isHidden = false
                    self.indicator.isHidden = true
                    print("upscaling image...")
                    DispatchQueue.global().async {
                        if let upscaledImage = Upscaler.shared.upscaledImage(image: nsimage) {
                            DispatchQueue.main.async {
                                self.imageview.image = upscaledImage
                                self.window?.endSheet(self.progrWin)
                                self.saveBtn.isEnabled = true
                            }
                        }
                    }
                } else {
                    self.window?.endSheet(self.progrWin)
                    self.saveBtn.isEnabled = true
                }
                
                
            }
        } else {
            print("ERROR image is nil")
            DispatchQueue.main.async {
                self.saveBtn.isEnabled = false
                self.window?.endSheet(self.progrWin)
            }
        }
    }
    
    
}











/*
// STEPS PREVIEW
if stepsPreview {
    DispatchQueue.global().async {
        if !sdprogress.currentImages.isEmpty && sdprogress.step.isMultiple(of: 5) {
            if let image1 = sdprogress.currentImages.last {
                if let image2 = image1 {
                    DispatchQueue.main.async {
                        self.imageview.image = NSImage(cgImage: image2,
                                                       size: .zero)
                    }
                }
            }
        }
    }
}
*/
