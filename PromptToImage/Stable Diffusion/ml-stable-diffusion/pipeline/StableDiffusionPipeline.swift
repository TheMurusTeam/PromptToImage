// For licensing see accompanying LICENSE.md file.
// Copyright (C) 2022 Apple Inc. All Rights Reserved.


// negative prompt: https://github.com/apple/ml-stable-diffusion/pull/61/files
// guidance scale:  https://github.com/apple/ml-stable-diffusion/pull/46/files
// image2image:     https://github.com/apple/ml-stable-diffusion/pull/73


import Foundation
import CoreML
import Accelerate
import CoreGraphics

/// Schedulers compatible with StableDiffusionPipeline
public enum StableDiffusionScheduler {
    /// Scheduler that uses a pseudo-linear multi-step (PLMS) method
    case pndmScheduler
    /// Scheduler that uses a second order DPM-Solver++ algorithm
    case dpmSolverMultistepScheduler
}

/// A pipeline used to generate image samples from text input using stable diffusion
///
/// This implementation matches:
/// [Hugging Face Diffusers Pipeline](https://github.com/huggingface/diffusers/blob/main/src/diffusers/pipelines/stable_diffusion/pipeline_stable_diffusion.py)
@available(iOS 16.2, macOS 13.1, *)
public struct StableDiffusionPipeline: ResourceManaging {
    
    public enum Error: String, Swift.Error {
        case startingImageProvidedWithoutEncoder
        //case schedulerNotSupportedWithImage2Image
    }

    /// Model to generate embeddings for tokenized input text
    var textEncoder: TextEncoder

    /// Model used to predict noise residuals given an input, diffusion time step, and conditional embedding
    var unet: Unet

    /// Model used to generate final image from latent diffusion process
    var decoder: Decoder
    
    /// Model used to latent space for image2image, and soon, in-painting
    var encoder: Encoder?

    /// Optional model for checking safety of generated image
    var safetyChecker: SafetyChecker? = nil

    /// Controls the influence of the text prompt on sampling process (0=random images)
    var guidanceScale: Float = 7.5

    /// Reports whether this pipeline can perform safety checks
    public var canSafetyCheck: Bool {
        safetyChecker != nil
    }
    
    /// Reports whether this pipeline can perform IMG2IMG (requires VAEEncoder.mlmodelc
    public var canUseInputImage : Bool {
        encoder != nil
    }

    /// Option to reduce memory during image generation
    ///
    /// If true, the pipeline will lazily load TextEncoder, Unet, Decoder, and SafetyChecker
    /// when needed and aggressively unload their resources after
    ///
    /// This will increase latency in favor of reducing memory
    var reduceMemory: Bool = false

    /// Creates a pipeline using the specified models and tokenizer
    ///
    /// - Parameters:
    ///   - textEncoder: Model for encoding tokenized text
    ///   - unet: Model for noise prediction on latent samples
    ///   - decoder: Model for decoding latent sample to image
    ///   - safetyChecker: Optional model for checking safety of generated images
    ///   - reduceMemory: Option to enable reduced memory mode
    /// - Returns: Pipeline ready for image generation
    public init(textEncoder: TextEncoder,
                unet: Unet,
                decoder: Decoder,
                encoder: Encoder?,
                safetyChecker: SafetyChecker? = nil,
                reduceMemory: Bool = false ) {
        self.textEncoder = textEncoder
        self.unet = unet
        self.decoder = decoder
        self.encoder = encoder
        self.safetyChecker = safetyChecker
        self.reduceMemory = systemRAM() <= 8 //reduceMemory
        print("Reduce Memory: \(self.reduceMemory)")
    } 

    /// Load required resources for this pipeline
    ///
    /// If reducedMemory is true this will instead call prewarmResources instead
    /// and let the pipeline lazily load resources as needed
    public func loadResources() throws {
        if reduceMemory {
            try prewarmResources()
        } else {
            try textEncoder.loadResources();print("...text encoder")
            try unet.loadResources();print("...unet")
            try decoder.loadResources();print("...decoder")
            try safetyChecker?.loadResources();print("...safety checker")
        }
    }

    /// Unload the underlying resources to free up memory
    public func unloadResources() {
        textEncoder.unloadResources()
        unet.unloadResources()
        decoder.unloadResources()
        safetyChecker?.unloadResources()
    }
 
    // Prewarm resources one at a time
    public func prewarmResources() throws {
        try textEncoder.prewarmResources()
        try unet.prewarmResources()
        try decoder.prewarmResources()
        try safetyChecker?.prewarmResources()
    }

    /// Text to image generation using stable diffusion
    ///
    /// - Parameters:
    ///   - prompt: Text prompt to guide sampling
    ///   - stepCount: Number of inference steps to perform
    ///   - imageCount: Number of samples/images to generate for the input prompt
    ///   - seed: Random seed which
    ///   - guidanceScale: Controls the influence of the text prompt on sampling process (0=random images)
    ///   - disableSafety: Safety checks are only performed if `self.canSafetyCheck && !disableSafety`
    ///   - progressHandler: Callback to perform after each step, stops on receiving false response
    /// - Returns: An array of `imageCount` optional images.
    ///            The images will be nil if safety checks were performed and found the result to be un-safe
    public func generateImages(
        prompt: String,
        negativePrompt: String = "",
        startingImage: CGImage? = nil,
        strength: Float = 1.0,
        imageCount: Int = 1,
        stepCount: Int = 50,
        seed: UInt32 = 0,
        guidanceScale: Float = 7.5,
        disableSafety: Bool = false,
        scheduler schedulerType: StableDiffusionScheduler = .pndmScheduler,
        progressHandler: (Progress) -> Bool = { _ in true }
    ) throws -> [CGImage?] {
        
        print("* encoding prompt")
        // Encode the input prompt and negative prompt
        let promptEmbedding = try textEncoder.encode(prompt)
        let negativePromptEmbedding = try textEncoder.encode(negativePrompt)
        //        let blankEmbedding = try textEncoder.encode("")
        
        // Concatenate the prompt and negative prompt embeddings
        let concatEmbedding = MLShapedArray<Float32>(
            concatenating: [negativePromptEmbedding, promptEmbedding],
            alongAxis: 0
        )
        

        let hiddenStates = toHiddenStates(concatEmbedding)

        /// Setup schedulers
        print("* setup schedulers")
        let scheduler: [Scheduler] = (0..<imageCount).map { _ in
            switch schedulerType {
            case .pndmScheduler: return PNDMScheduler(stepCount: stepCount)
            case .dpmSolverMultistepScheduler: return DPMSolverMultistepScheduler(stepCount: stepCount)
            }
        }
        let stdev = scheduler[0].initNoiseSigma

        // Generate random latent samples from specified seed
        print("* generate random latent samples")
        var latents: [MLShapedArray<Float32>] = []
        let timestepStrength: Float?
        
        if let startingImage {
            print("* generate img2img latent samples")
            timestepStrength = strength
            guard let encoder else {
                throw Error.startingImageProvidedWithoutEncoder
            }
            
            // let noiseTuples = generateImage2ImageLatentSamples(imageCount, stdev: 1, seed: seed)
            
            // seed incremented +1 for batch images
            var noiseTuples : [(diagonal: MLShapedArray<Float32>, latentNoise: MLShapedArray<Float32>)] = []
            for i in 0..<imageCount {
                noiseTuples.append(contentsOf: generateImage2ImageLatentSamples(1, stdev: 1, seed: seed + UInt32(i)))
            }
            
            latents = try noiseTuples.map({
                try encoder.encode(
                    image: startingImage,
                    diagonalNoise: $0.diagonal,
                    noise: $0.latentNoise,
                    alphasCumprodStep: scheduler[0].calculateAlphasCumprod(strength: strength))
            })
        } else {
            print("* generate txt2img latent samples")
            timestepStrength = nil
            // Generate random latent samples from specified seed
            //latents = generateLatentSamples(imageCount, stdev: stdev, seed: seed)
            
            // seed incremented +1 for batch images
            for i in 0..<imageCount {
                latents.append(contentsOf: generateLatentSamples(1, stdev: stdev, seed: seed + UInt32(i)))
            }
            
            
        }

        // De-noising loop
        print("* starting denoising loop")
        let timeSteps: [Int] = scheduler[0].calculateTimesteps(strength: timestepStrength)
        for (step,t) in timeSteps.enumerated() {

            // Expand the latents for classifier-free guidance
            // and input to the Unet noise prediction model
            let latentUnetInput = latents.map {
                MLShapedArray<Float32>(concatenating: [$0, $0], alongAxis: 0)
            }

            // Predict noise residuals from latent samples
            // and current time step conditioned on hidden states
            var noise = try unet.predictNoise(
                latents: latentUnetInput,
                timeStep: t,
                hiddenStates: hiddenStates
            ) 

            noise = performGuidance(noise, guidanceScale)

            // Have the scheduler compute the previous (t-1) latent
            // sample given the predicted noise and current sample
            for i in 0..<imageCount {
                latents[i] = scheduler[i].step(
                    output: noise[i],
                    timeStep: t,
                    sample: latents[i]
                )
            }

            // Report progress
            let progress = Progress(
                pipeline: self,
                prompt: prompt,
                negativePromp: negativePrompt,
                step: step,
                stepCount: timeSteps.count,
                currentLatentSamples: latents,
                isSafetyEnabled: canSafetyCheck && !disableSafety
            )
            if !progressHandler(progress) {
                // Stop if requested by handler
                return []
            }
        }

        if reduceMemory {
            unet.unloadResources()
        }

        // Decode the latent samples to images
        print("decode latent samples to images")
        return try decodeToImages(latents, disableSafety: disableSafety)
    }

    func generateLatentSamples(_ count: Int, stdev: Float, seed: UInt32) -> [MLShapedArray<Float32>] {
        var sampleShape = unet.latentSampleShape
        sampleShape[0] = 1

        var random = NumPyRandomSource(seed: seed)
        let samples = (0..<count).map { _ in
            MLShapedArray<Float32>(
                converting: random.normalShapedArray(sampleShape, mean: 0.0, stdev: Double(stdev)))
        }
        return samples
    }
    
    
    /// For image2image -
    /// - Parameters:
    ///   - count: batch size
    ///   - stdev: 1
    ///   - seed: seed provided
    ///   - diagonalAndLatentNoiseIsSame: Diffusions library does not seem to use the same noise for the `DiagonalGaussianDistribution` operation,
    ///     but I have seen implementations of pipelines where it is the same.
    /// - Returns: An array of tuples of noise values with length of batch size.
    func generateImage2ImageLatentSamples(_ count: Int, stdev: Float, seed: UInt32, diagonalAndLatentNoiseIsSame: Bool = false) -> [(diagonal: MLShapedArray<Float32>, latentNoise: MLShapedArray<Float32>)] {
        var sampleShape = unet.latentSampleShape
        sampleShape[0] = 1

        var random = NumPyRandomSource(seed: seed)
        let samples = (0..<count).map { _ in
            if diagonalAndLatentNoiseIsSame {
                let noise = MLShapedArray<Float32>(
                    converting: random.normalShapedArray(sampleShape, mean: 0.0, stdev: Double(stdev)))
                return (noise, noise)
            } else {
                return (MLShapedArray<Float32>(
                    converting: random.normalShapedArray(sampleShape, mean: 0.0, stdev: Double(stdev))),
                        MLShapedArray<Float32>(
                            converting: random.normalShapedArray(sampleShape, mean: 0.0, stdev: Double(stdev))))
            }
        }
        return samples
    }

    func toHiddenStates(_ embedding: MLShapedArray<Float32>) -> MLShapedArray<Float32> {
        // Unoptimized manual transpose [0, 2, None, 1]
        // e.g. From [2, 77, 768] to [2, 768, 1, 77]
        let fromShape = embedding.shape
        let stateShape = [fromShape[0],fromShape[2], 1, fromShape[1]]
        var states = MLShapedArray<Float32>(repeating: 0.0, shape: stateShape)
        for i0 in 0..<fromShape[0] {
            for i1 in 0..<fromShape[1] {
                for i2 in 0..<fromShape[2] {
                    states[scalarAt:i0,i2,0,i1] = embedding[scalarAt:i0, i1, i2]
                }
            }
        }
        return states
    }

    func performGuidance(_ noise: [MLShapedArray<Float32>], _ guidanceScale: Float) -> [MLShapedArray<Float32>] {
        noise.map { performGuidance($0, guidanceScale) }
    }

    func performGuidance(_ noise: MLShapedArray<Float32>, _ guidanceScale: Float) -> MLShapedArray<Float32> {

        let blankNoiseScalars = noise[0].scalars
        let textNoiseScalars = noise[1].scalars

        var resultScalars =  blankNoiseScalars

        for i in 0..<resultScalars.count {
            // unconditioned + guidance*(text - unconditioned)
            resultScalars[i] += guidanceScale*(textNoiseScalars[i]-blankNoiseScalars[i])
        }

        var shape = noise.shape
        shape[0] = 1
        return MLShapedArray<Float32>(scalars: resultScalars, shape: shape)
    }

    func decodeToImages(_ latents: [MLShapedArray<Float32>],
                        disableSafety: Bool) throws -> [CGImage?] {

        let images = try decoder.decode(latents)
        if reduceMemory {
            decoder.unloadResources()
        }

        // If safety is disabled return what was decoded
        if disableSafety {
            return images
        }

        // If there is no safety checker return what was decoded
        guard let safetyChecker = safetyChecker else {
            return images
        }

        // Otherwise change images which are not safe to nil
        let safeImages = try images.map { image in
            try safetyChecker.isSafe(image) ? image : nil
        }

        if reduceMemory {
            safetyChecker.unloadResources()
        }

        return safeImages
    }

}

@available(iOS 16.2, macOS 13.1, *)
extension StableDiffusionPipeline {
    /// Sampling progress details
    public struct Progress {
        public let pipeline: StableDiffusionPipeline
        public let prompt: String
        public let negativePromp: String
        public let step: Int
        public let stepCount: Int
        public let currentLatentSamples: [MLShapedArray<Float32>]
        public let isSafetyEnabled: Bool
        public var currentImages: [CGImage?] {
            try! pipeline.decodeToImages(
                currentLatentSamples,
                disableSafety: !isSafetyEnabled)
        }
    }
}
