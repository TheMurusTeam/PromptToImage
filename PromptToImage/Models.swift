//
//  Models.swift
//  PromptToImage
//
//  Created by hany on 22/12/22.
//

import Foundation
import Cocoa

let customModelsDirectoryPath = "models" // inside app's sandboxed env



func currentModelName() -> String {
    // model name
    var modelName = defaultModelName
    if modelResourcesURL.absoluteURL != defaultModelResourcesURL.absoluteURL {
        modelName = modelResourcesURL.lastPathComponent
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
        urls = directoryContents
    } catch {}
    return urls //.filter{ $0.isDirectory }
}



extension SDMainWindowController {
    
    func menuWillOpen(_ menu: NSMenu) {
        self.populateModelsPopup()
    }
    
    func populateModelsPopup() {
        // create menu items
        if let menu = self.modelsPopup.menu {
            menu.removeAllItems()
            // default model
            let item1 = NSMenuItem()
            item1.title = "Stable Diffusion 2.1 SPLIT EINSUM"
            item1.representedObject = defaultModelResourcesURL
            menu.addItem(item1)
            //
            let sep = NSMenuItem.separator()
            menu.addItem(sep)
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
                    if url == modelResourcesURL {
                        self.modelsPopup.select(mitem)
                        print("current model: \(mitem.title)")
                    }
                }
            }
        }
    }
    
    
    
    
    
    
    
    
}
