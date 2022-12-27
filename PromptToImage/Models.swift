//
//  Models.swift
//  PromptToImage
//
//  Created by hany on 22/12/22.
//

import Foundation
import Cocoa
 


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



func createModelsDir() {
    if !FileManager.default.fileExists(atPath: customModelsDirectoryPath) {
        do {
            try FileManager.default.createDirectory(atPath: customModelsDirectoryPath, withIntermediateDirectories: true)
        } catch { print("error creating custom models directory at \(customModelsDirectoryPath)")}
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

func createNewCustomModelDirectory(name:String) -> Bool {
    let path = "\(customModelsDirectoryPath)/\(name)"
    if FileManager.default.fileExists(atPath: path) { return false }
    do {
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
    } catch {
        print("error creating custom model directory at \(path)")
        return false
    }
    return true
}


func installedCustomModels() -> [URL] {
    var urls = [URL]()
    do {
        let directoryContents = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: customModelsDirectoryPath),includingPropertiesForKeys: nil)
        urls = directoryContents.filter({ $0.isFolder && $0.isModelURL })
    } catch {}
    return urls
}


extension URL {
    var isModelURL: Bool {
        FileManager.default.fileExists(atPath: self.path + "/merges.txt") &&
        FileManager.default.fileExists(atPath: self.path + "/vocab.json") &&
        FileManager.default.fileExists(atPath: self.path + "/TextEncoder.mlmodelc") &&
        FileManager.default.fileExists(atPath: self.path + "/Unet.mlmodelc") &&
        FileManager.default.fileExists(atPath: self.path + "/VAEDecoder.mlmodelc")
    }
    
}



extension SDMainWindowController {
    
    // MARK: Menu Delegate
    
    func menuWillOpen(_ menu: NSMenu) {
        if menu == self.modelsPopup.menu {
            self.populateModelsPopup()
        } else if menu == self.historyTableView.menu {
            self.item_saveAllSelectedImages.isEnabled = !self.historyArrayController.selectedObjects.isEmpty
        }
    }
    
    
    
    // MARK: Download models from huggingface
    
    @IBAction func clickDownloadModels(_ sender: Any) {
        let url = "https://huggingface.co/TheMurusTeam"
        if let url = URL(string: url) {
            NSWorkspace.shared.open(url)
        }
    }
    
    
    
    // MARK: Populate Models Popup
    
    func populateModelsPopup() {
        // create menu items
        if let menu = self.modelsPopup.menu {
            menu.removeAllItems()
            if builtInModelExists() {
                // default model
                let item1 = NSMenuItem()
                item1.title = "Stable Diffusion 2.1 SPLIT EINSUM (Default)"
                item1.representedObject = builtInModelResourcesURL
                menu.addItem(item1)
                let sep = NSMenuItem.separator()
                menu.addItem(sep)
            }
            // custom models
            let urls = installedCustomModels()
            for modelurl in urls {
                if modelurl.isFolder {
                    let item = NSMenuItem()
                    item.title = modelurl.lastPathComponent
                    item.representedObject = modelurl
                    menu.addItem(item)
                }
            }
        }
    }
    
    
    func setModelsPopup() {
        // set selected item
        if let menu = self.modelsPopup.menu {
            for mitem in menu.items {
                if let url = mitem.representedObject as? URL {
                    if url == currentModelResourcesURL {
                        self.modelsPopup.select(mitem)
                        print("current model: \(mitem.title)")
                    }
                }
            }
        }
    }
    
    
    
    
    
    
    
    
}
