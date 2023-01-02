//
//  Models.swift
//  PromptToImage
//
//  Created by hany on 22/12/22.
//

import Foundation
import Cocoa
import UniformTypeIdentifiers
import CoreML


func builtInModelExists() -> Bool {
    return FileManager.default.fileExists(atPath: builtInModelResourcesURL.path + "/merges.txt") &&
    FileManager.default.fileExists(atPath: builtInModelResourcesURL.path + "/vocab.json") &&
    FileManager.default.fileExists(atPath: builtInModelResourcesURL.path + "/TextEncoder.mlmodelc") &&
    FileManager.default.fileExists(atPath: builtInModelResourcesURL.path + "/Unet.mlmodelc") &&
    FileManager.default.fileExists(atPath: builtInModelResourcesURL.path + "/VAEDecoder.mlmodelc")
}


func currentModelName() -> String {
    // model name
    var modelName = defaultModelName
    if currentModelResourcesURL.absoluteURL != builtInModelResourcesURL.absoluteURL {
        modelName = currentModelResourcesURL.lastPathComponent
    }
    return modelName
}


// MARK: Create dirs
func createModelsDir() {
    if !FileManager.default.fileExists(atPath: customModelsDirectoryPath) {
        do {
            try FileManager.default.createDirectory(atPath: customModelsDirectoryPath, withIntermediateDirectories: true)
        } catch { print("error creating custom stable diffusion models directory at \(customModelsDirectoryPath)")}
    }
}
func createUpscalersDir() {
    if !FileManager.default.fileExists(atPath: customUpscalersDirectoryPath) {
        do {
            try FileManager.default.createDirectory(atPath: customUpscalersDirectoryPath, withIntermediateDirectories: true)
        } catch { print("error creating custom upscale models directory at \(customUpscalersDirectoryPath)")}
    }
}
func createHistoryDir() {
    if !FileManager.default.fileExists(atPath: historyPath) {
        do {
            try FileManager.default.createDirectory(atPath: historyPath, withIntermediateDirectories: true)
        } catch { print("error creating history directory at \(historyPath)")}
    }
}



func revealCustomModelsDirInFinder() {
    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: customModelsDirectoryPath).absoluteURL])
}


// MARK: Get Custom SD Models List

func installedCustomModels() -> [URL] {
    var urls = [URL]()
    do {
        let directoryContents = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: customModelsDirectoryPath),includingPropertiesForKeys: nil)
        urls = directoryContents.filter({ $0.isFolder && $0.isModelURL })
    } catch {}
    return urls
}



// check if model directory contains all needed files
extension URL {
    var isModelURL: Bool {
        FileManager.default.fileExists(atPath: self.path + "/merges.txt") &&
        FileManager.default.fileExists(atPath: self.path + "/vocab.json") &&
        FileManager.default.fileExists(atPath: self.path + "/TextEncoder.mlmodelc") &&
        FileManager.default.fileExists(atPath: self.path + "/Unet.mlmodelc") &&
        FileManager.default.fileExists(atPath: self.path + "/VAEDecoder.mlmodelc")
    }
    
} 


// MARK: Get custom upscale models list

func installedCustomUpscalers() -> [URL] {
    var urls = [URL]()
    do {
        let directoryContents = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: customUpscalersDirectoryPath),includingPropertiesForKeys: nil)
        urls = directoryContents.filter({ $0.isCompiledCoreMLModel })
    } catch {}
    return urls
}





extension SDMainWindowController {

    
    
    // MARK: Import custom SD model
    
    func importModel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.nameFieldLabel = "Model folder"
        panel.prompt = "Import Model"
        panel.message = "Select a CoreML Stable Diffusion model directory"
        let destinationPath = URL(fileURLWithPath: customModelsDirectoryPath).absoluteURL.path
        
        panel.beginSheetModal(for: self.window!, completionHandler: { response in
            guard response == NSApplication.ModalResponse.OK else { return }
            guard let modelUrl = panel.url else { return }
            let modelDirName = modelUrl.lastPathComponent
            guard modelUrl.isModelURL else {
                // invalid model url, missing files?
                displayErrorAlert(txt: "Invalid model\n\nA CoreML Stable Diffusion model directory must include these files at least:\n- merges.txt, vocab.json, TextEncoder.mlmodelc, Unet.mlmodelc, VAEDecoder.mlmodelc")
                return
            }
            print("Valid <<\(modelDirName)>> model directory at path: \(modelUrl.path)")
            
            let toPath = destinationPath + "/" + modelDirName
            if FileManager.default.fileExists(atPath: toPath) {
                print("model already exists at \(toPath)")
                displayErrorAlert(txt: "Model already installed")
                return
            }
            panel.endSheet(self.window!)
            
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    self.waitLabel.stringValue = "Installing model"
                    self.waitInfoLabel.stringValue = modelDirName
                    self.waitCULabel.stringValue = ""
                    self.window?.beginSheet(self.waitWin)
                    
                    // copy model to app's custom models dir
                    print("copying model directory \(modelUrl.path) to PromptToImage custom models directory at \(toPath)")
                    DispatchQueue.global().async {
                        do {
                            try FileManager.default.copyItem(atPath: modelUrl.path, toPath: customModelsDirectoryPath + "/" + modelDirName)
                        } catch { self.presentError(error) }
                        
                        DispatchQueue.main.async {
                            self.window?.endSheet(self.waitWin)
                            
                            // load model
                            self.loadModelFromURL(modelName: modelDirName, modelUrl: URL(fileURLWithPath: toPath))
                        }
                    }
                }
            }
        })
    }
    
    
    
    // MARK: Import custom upscale model
    
    func importUpscaleModel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["com.apple.coreml.model"]
        panel.nameFieldLabel = "Model folder"
        panel.prompt = "Import Upscale Model"
        panel.message = "Select a CoreML upscale model file"
        let destinationPath = URL(fileURLWithPath: customUpscalersDirectoryPath).absoluteURL.path
        
        panel.beginSheetModal(for: self.window!, completionHandler: { response in
            guard response == NSApplication.ModalResponse.OK else { return }
            guard let modelUrl = panel.url else { return }
            let modelName = modelUrl.lastPathComponent
            let compiledModelName = modelUrl.lastPathComponent + "c"
            let toPath = destinationPath + "/" + compiledModelName
            panel.endSheet(self.window!)
            
            DispatchQueue.global().async {
                DispatchQueue.main.async {
                    self.waitLabel.stringValue = "Installing upscale model"
                    self.waitInfoLabel.stringValue = modelName
                    self.waitCULabel.stringValue = ""
                    self.window?.beginSheet(self.waitWin)
                    
                    // compile CoreML model
                    DispatchQueue.global().async {
                        var temporaryModelURL : URL? = nil
                        do {
                            print("compiling model...")
                            temporaryModelURL = try MLModel.compileModel(at: modelUrl)
                        } catch {
                            // error compiling model
                            displayErrorAlert(txt: "Unable to compile CoreML model")
                            return
                        }
                        
                        // copy model to app's custom models dir
                        guard let compiledModelUrl = temporaryModelURL else {
                            displayErrorAlert(txt: "Invalid CoreML model")
                            return
                        }
                        
                        // copy file
                        print("copying model directory \(compiledModelUrl.path) to PromptToImage custom models directory at \(toPath)")
                        
                        do {
                            try FileManager.default.copyItem(atPath: compiledModelUrl.path, toPath: toPath)
                        } catch {
                            DispatchQueue.main.async {
                                self.window?.endSheet(self.waitWin)
                                self.presentError(error)
                            }
                            return
                        }
                        
                        DispatchQueue.main.async {
                            self.window?.endSheet(self.waitWin)
                            let alert = NSAlert()
                            alert.messageText = "Done"
                            alert.informativeText = "Upscale model \(compiledModelName) installed"
                            alert.runModal()
                        }
                        
                    }
                    
                }
            }
        })
        
    }
    
    
    
    
}
