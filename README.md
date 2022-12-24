# PromptToImage
Swift/AppKit CoreML Stable Diffusion app for macOS

# Features
- Negative Prompt
- Guidance Scale
- Multiple Images
- Image to Image
- Custom user-defined models
- History
- 4x Upscaler (CoreML Real esrgan)
- save image with EXIF metadata
- sandboxed

# Download App
Public beta available though TestFlight. Requires valid Apple ID.
Beta includes Stable Diffusion 2.1 model.<br>
Link: coming soon

# System Requirements
Requires an Apple Silicon Mac running macOS 13.1 Ventura<br>
Intel Macs not supported.

# ML Models
This GitHub repo does not include CoreML models.<br>
You can find CoreML models designed for this app here:
https://huggingface.co/TheMurusTeam<br>
Learn how to convert Stable Diffusion models to CoreML format here: https://github.com/apple/ml-stable-diffusion

# Privacy
This is a sanboxed app. It is not allowed to access your personal files and data. Everything runs locally, nothing is sent to the network. None of your data is collected. 

# Build 
To build this app you need an Apple Silicon Mac running macOS 13 Ventura 13.1 or later, and Xcode 14.2 or later.<br>
The Xcode project does not include CoreML models and accessory files. You need to add these files to the main project folder within Xcode before building. These files list includes at least:<br>
- realesrgan512.mlmodel
- merges.txt
- vocab.json
- TextEncoder.mlmodelc
- Unet.mlmodelc
- VAEDecoder.mlmodelc
- VAEEncoder.mlmodelc (optional, required for img2img)

