# PromptToImage
Swift/AppKit CoreML Stable Diffusion app for macOS


# Features
- Negative Prompt
- Guidance Scale
- Multiple Images
- Image to Image
- History
- Export image with EXIF metadata
- Sandboxed app
- Custom Stable Diffusion models
- Custom upscale models
- Supports Stable Diffusion with custom output size
- Built-in 4x RealESRGAN Upscaler 
- Default model: Stable Diffusion 2.1 SPLIT EINSUM (will be downloaded at application launch)

# Download App 
Beta available via Apple TestFlight here: https://testflight.apple.com/join/oMxyZ7wO

# Stable Diffusion Models
PromptToImage supports only models in CoreML format. This repo does not include any model.
The app bundle does not include Stable Diffusion models. The first time you launch the app the default Stable Diffusion 2.1 SPLIT EINSUM model will be dowloaded and installed.
You can find more Stable Diffusion CoreML models designed for this app here:
https://huggingface.co/TheMurusTeam<br>
Learn how to convert Stable Diffusion models to CoreML format here: https://github.com/apple/ml-stable-diffusion

# Install custom Stable Diffusion models<br>
1. Download a CoreML Stable Diffusion model. You can find some models here: https://huggingface.co/TheMurusTeam/
2. Unzip model
3. Open the 'models popup button' on top of main window and select "Import CoreML Stable Diffusion model...", select model directory

# Upscale models
PromptToImage supports only upscale models in CoreML format. The app comes bundled with the built-in RealESRGAN upscale model. You can add custom models from the 'upscale popup button'. You can find more upscale CoreML models designed for this app here:
https://huggingface.co/TheMurusTeam<br>

# System Requirements
Requires an Apple Silicon Mac running macOS 13.1 Ventura<br>
Intel Macs not supported.

# About Compute Units
For best compatibility always use the default compute units "CPU and GPU". The first time you try a new model, always try it using default compute units.<br>
There are two ways to convert CoreML Stable Diffusion models: ORIGINAL and SPLIT_EINSUM<br>
Models converted using attention implementation ORIGINAL must be used only with default compute units "CPU and GPU". Attempting to use different compute units will crash the app.<br>
Models converted using attention implementation SPLIT_EINSUM can be used with all kind of compute units<br>


# Performances and energy
For best performance on M1 and M2:<br>
model: Stable Diffusion 2.1 SPLIT EINSUM, compute units: CPU and Neural Engine<br>
For best performance on M1Pro, M1Max and M1Ultra:<br>
model: Stable Diffusion 2.1 ORIGINAL, compute units: CPU and GPU<br>

To drastically reduce power consumption on laptops you can use the default model (or any SPLIT EINSUM model) and "CPU and Neural Engine" compute units. On M1Pro and M1Max it will be slower but much more energy efficient.<br><br>
To monitor compute units energy consumption you can use the free and open source app PowerMetrix, see here: https://github.com/TheMurusTeam/PowerMetrix<br><br>

# Benchmarks 
MacBook Pro 14" M1Max, 24core GPU, 32Gb RAM (macOS 13.1):
- Stable Diffusion 2.1 SPLIT EINSUM, CPU and Neural Engine:  1.8 step/sec,   3.5 Watt
- Stable Diffusion 2.1 SPLIT EINSUM, CPU and GPU:            1.95 step/sec,  21.5 Watt
- Stable Diffusion 2.1 SPLIT EINSUM, All compute units:      2.2 step/sec,   11 Watt
- Stable Diffusion 2.1 ORIGINAL, CPU and GPU:                2.7 step/sec,   28 Watt

MacMini M1, 8core GPU, 16Gb RAM (macOS 13.1):
- Stable Diffusion 2.1 SPLIT EINSUM, CPU and Neural Engine:  2.0 step/sec,   4.7 Watt
- Stable Diffusion 2.1 SPLIT EINSUM, CPU and GPU:            0.75 step/sec,  7.5 Watt
- Stable Diffusion 2.1 ORIGINAL, CPU and GPU:                0.95 step/sec,  8.8 Watt

# Known issues
1. Attempting to load an -ORIGINAL model using "CPU and Neural Engine" or "All Compute Units" fails.
2. The first time you launch the app, loading a -SPLIT_EINSUM model using "CPU and Neural Engine" may take up to 2 minutes.
3. Neural Engine performance on M1 is higher than M1Pro and M1Max
4. Models converted with attention implementation SPLIT_EINSUM do not support resolutions other than 512x512
5. Images shared using sharingpicker default services do not include EXIF metadata
6. Prompt weights not supported
7. Some Stable Diffusion models can cause hang or crash when using "CPU and Neural Engine" or "All compute units"

# Restore default settings
Keep the OPTION key pressed when launching PromptToImage in order to restore default compute units (CPU and GPU)

# Privacy
This is a sandboxed app. It is not allowed to access your personal files and data. Everything runs locally, nothing is sent to the network. None of your data is collected. <br>

# Build 
To build this app you need an Apple Silicon Mac running macOS 13 Ventura 13.1 or later, and Xcode 14.2 or later.







