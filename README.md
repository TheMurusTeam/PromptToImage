# PromptToImage
Swift/AppKit CoreML Stable Diffusion app for macOS
<img width="1369" alt="pti2" src="https://user-images.githubusercontent.com/27217431/209742328-6286bb18-fa36-40e2-b1d1-639aadd09cf5.png">


# Features
- Negative Prompt
- Guidance Scale
- Multiple Images
- Image to Image
- Custom user-defined models
- History
- 4x Upscaler 
- Export image with EXIF metadata
- Supports models with custom output size
- Sandboxed app

# Download App from this repository
See the "Releases" section of this repository to download the app.<br>
App bundles available on this repo do not include Stable Diffusion CoreML models. Launch the app and follow instructions in order to install your first model and start using PromptToImage.  

# Install Stable Diffusion models<br>
1. Download default Stable Diffusion model here: https://huggingface.co/TheMurusTeam/CoreML-Stable-Diffusion-2.1-SPLIT_EINSUM-img2img/ <br>
2. Run PromptToImage, open Settings clicking the gear button on left top.
3. Click "Reveal Custom Models Dir in Finder" to show PromptToImage custom models directory.
4. unzip model zip archive and move the resulting directory to custom models directory
5. Click the "Model" popup button in Settings and select a Stable Diffusion model to start using PromptToImage
6. You can find additional Stable Diffusion CoreML models here: https://huggingface.co/TheMurusTeam/

# System Requirements
Requires an Apple Silicon Mac running macOS 13.1 Ventura<br>
Intel Macs not supported.

# ML Models
This GitHub repo includes the RealESRGAN CoreML model, however it does not include Stable Diffusion CoreML models.<br>
You can find Stable Diffusion CoreML models designed for this app here:
https://huggingface.co/TheMurusTeam<br>
Learn how to convert Stable Diffusion models to CoreML format here: https://github.com/apple/ml-stable-diffusion

# Performances and energy
For best performance on M1 and M2:<br>
model: Stable Diffusion 2.1 SPLIT EINSUM, compute units: CPU and Neural Engine<br>
For best performance on M1Pro, M1Max and M1 Ultra:<br>
model: Stable Diffusion 2.1 ORIGINAL, compute units: CPU and GPU<br>

On Apple Silicon Macs with 24 or more GPU cores the "CPU and GPU" is by far the fastest, however, due to the high energy consumption of the GPU, if you generate more than 10 images at once, laptop fans will spin and fanless laptops will throttle. To drastically reduce power consumption you should use the default model (or any SPLIT EINSUM model) and "CPU and Neural Engine" compute units.<br>

# Benchmarks 
MacBook Pro 14" M1Max 32Gb RAM (macOS 13.1):
- Stable Diffusion 2.1 SPLIT EINSUM, CPU and Neural Engine:  1.8 step/sec,   3.5 Watt
- Stable Diffusion 2.1 SPLIT EINSUM, CPU and GPU:            1.95 step/sec,  21.5 Watt
- Stable Diffusion 2.1 SPLIT EINSUM, All compute units:      2.2 step/sec,   11 Watt
- Stable Diffusion 2.1 ORIGINAL, CPU and GPU:                2.7 step/sec,   28 Watt


# Privacy
This is a sanboxed app. It is not allowed to access your personal files and data. Everything runs locally, nothing is sent to the network. None of your data is collected. Releases available on this repo are always signed with a valid Apple Developer ID and notarized.

# Build 
To build this app you need an Apple Silicon Mac running macOS 13 Ventura 13.1 or later, and Xcode 14.2 or later.






