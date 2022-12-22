//
//  Upscaler.swift
//  FreeScaler
//
//  Created by Hany El Imam on 28/11/22.
//


import Foundation
import Cocoa
import Vision
import Accelerate



// default model: realesrgan512

class Upscaler : NSObject {
    
    static let shared = Upscaler()
    private override init() {}
    
    let conf = MLModelConfiguration()
    var request: VNCoreMLRequest?
    var visionModel: VNCoreMLModel?
     
    var myWidth : CGFloat = 0
    var myHeight : CGFloat = 0

    
    // MARK: Setup CoreML Model
    
    func setupUpscaleModelFromPath(path:String,
                                   computeUnits:MLComputeUnits) {
        print("setting up CoreML model from path \(path)")
        self.conf.computeUnits = computeUnits
        
        // model
        let classificationModel = try! MLModel(contentsOf: URL(fileURLWithPath: path), configuration: self.conf)
        if let visionModel = try? VNCoreMLModel(for: classificationModel) {
            self.visionModel = visionModel
            self.request = VNCoreMLRequest(model: visionModel)
            self.request?.imageCropAndScaleOption = .scaleFill
            self.request?.usesCPUOnly = false
        } else {
            fatalError()
        }
    }


    
    
    // MARK: Upscale
    
    func upscaledImage(image:NSImage) -> NSImage? {
        return self.predict(with: image)
    }
    
    
    
    func predict(with image: NSImage) -> NSImage? {
        self.myWidth = image.size.width
        self.myHeight = image.size.height
        guard let ciImage = image.ciImage() else { fatalError() }
        guard let request = self.request else { fatalError() }
        let handler = VNImageRequestHandler(ciImage: ciImage)
        try? handler.perform([request])
        // result
        if let result = request.results?.first as? VNPixelBufferObservation {
            // resize output pixbuf
            let factor : CGFloat = 4
            if let newbuffer = self.resizePixelBuffer(result.pixelBuffer,
                                                      width: Int(self.myWidth * factor),
                                                      height: Int(self.myHeight * factor)) {
                return self.pixbufferToNSImage(pixbuf: newbuffer)
            }
            
        }
        return nil
        
    }

    
    
    // MARK: Pixel Buffer

    // PIXELBUFFER TO NSIMAGE
    func pixbufferToNSImage(pixbuf:CVPixelBuffer) -> NSImage {
        let ciimage = CIImage(cvPixelBuffer: pixbuf)
        let context = CIContext(options: nil)
        let width = CVPixelBufferGetWidth(pixbuf)
        let height = CVPixelBufferGetHeight(pixbuf)
        let cgImage = context.createCGImage(ciimage, from: CGRect(x: 0, y: 0, width: width, height: height))
        let nsImage = NSImage(cgImage: cgImage!, size: CGSize(width: width, height: height))
        //print("pixbufferToNSImage output width:\(width) height:\(height)")
        return nsImage
    }
        
        



    // RESIZE PIXELBUFFER
    func resizePixelBuffer(_ pixelBuffer: CVPixelBuffer,
                           width: Int, height: Int) -> CVPixelBuffer? {
        return resizePixelBuffer(pixelBuffer, cropX: 0, cropY: 0,
                                 cropWidth: CVPixelBufferGetWidth(pixelBuffer),
                                 cropHeight: CVPixelBufferGetHeight(pixelBuffer),
                                 scaleWidth: width, scaleHeight: height)
    }

    func resizePixelBuffer(_ srcPixelBuffer: CVPixelBuffer,
                           cropX: Int,
                           cropY: Int,
                           cropWidth: Int,
                           cropHeight: Int,
                           scaleWidth: Int,
                           scaleHeight: Int) -> CVPixelBuffer? {

        CVPixelBufferLockBaseAddress(srcPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        guard let srcData = CVPixelBufferGetBaseAddress(srcPixelBuffer) else {
            print("Error: could not get pixel buffer base address")
            return nil
        }
        let srcBytesPerRow = CVPixelBufferGetBytesPerRow(srcPixelBuffer)
        let offset = cropY*srcBytesPerRow + cropX*4
        var srcBuffer = vImage_Buffer(data: srcData.advanced(by: offset),
                                      height: vImagePixelCount(cropHeight),
                                      width: vImagePixelCount(cropWidth),
                                      rowBytes: srcBytesPerRow)

        let destBytesPerRow = scaleWidth*4
        guard let destData = malloc(scaleHeight*destBytesPerRow) else {
            print("Error: out of memory")
            return nil
        }
        var destBuffer = vImage_Buffer(data: destData,
                                       height: vImagePixelCount(scaleHeight),
                                       width: vImagePixelCount(scaleWidth),
                                       rowBytes: destBytesPerRow)

        let error = vImageScale_ARGB8888(&srcBuffer, &destBuffer, nil, vImage_Flags(0))
        CVPixelBufferUnlockBaseAddress(srcPixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        if error != kvImageNoError {
            print("Error:", error)
            free(destData)
            return nil
        }

        let releaseCallback: CVPixelBufferReleaseBytesCallback = { _, ptr in
            if let ptr = ptr {
                free(UnsafeMutableRawPointer(mutating: ptr))
            }
        }

        let pixelFormat = CVPixelBufferGetPixelFormatType(srcPixelBuffer)
        var dstPixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreateWithBytes(nil, scaleWidth, scaleHeight,
                                                  pixelFormat, destData,
                                                  destBytesPerRow, releaseCallback,
                                                  nil, nil, &dstPixelBuffer)
        if status != kCVReturnSuccess {
            print("Error: could not create new pixel buffer")
            free(destData)
            return nil
        }
        return dstPixelBuffer
    }



    
}
