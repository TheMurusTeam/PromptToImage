//
//  Downloader.swift
//  DownloaderUnzipper
//
//  Created by hany on 26/12/22.
//

import Foundation
import Cocoa
import ZIPFoundation
 

// MARK: Click Download model button

extension SDMainWindowController {
    
    @IBAction func clickDownloadButton(_ sender: NSButton) {
        sender.isHidden = true
        let downloader = Downloader(downloadPath: customModelsDirectoryPath)
        downloader.startDownload(url: URL(string: defaultModelPublicURL)!)
        //
        self.progressLabel.stringValue = "Downloading Stable Diffusion model..."
        self.progressLabel.isHidden = false
        self.progressValueLabel.isHidden = false
        self.downloadProgr.doubleValue = 0
        self.downloadProgr.isHidden = false
    }
    
    
    func gotNewModel(url:URL) {
        DispatchQueue.main.async {
            self.window?.endSheet(self.downloadWindow)
            self.populateModelsPopup()
        }
        currentComputeUnits = defaultComputeUnits
        for customModelURL in installedCustomModels() {
            print("Attempting to load default model \(customModelURL.lastPathComponent)")
            currentModelResourcesURL = customModelURL
            createStableDiffusionPipeline(computeUnits: currentComputeUnits, url:currentModelResourcesURL)
            if sdPipeline != nil {
                print("Success loading default model \(customModelURL.lastPathComponent)")
                // save to user defaults
                UserDefaults.standard.set(currentModelResourcesURL, forKey: "modelResourcesURL")
                return
            }
        }
        
    }
    
    
    
}




// MARK: Downloader

class Downloader : NSObject,
                   URLSessionTaskDelegate,
                   URLSessionDownloadDelegate {
    
    var downloadPath = NSString()
    
    convenience init(downloadPath:String) {
        self.init()
        self.downloadPath = downloadPath as NSString
    }
    
    var downloadTask = URLSession.shared.downloadTask(with: URL(string: "localhost")!)
    private lazy var urlSession = URLSession(configuration: .default,
                                             delegate: self,
                                             delegateQueue: nil)
    // Start download
    func startDownload(url: URL) {
        let downloadTask = urlSession.downloadTask(with: url)
        downloadTask.resume()
        self.downloadTask = downloadTask
    }
    
    // Download Progress
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        if downloadTask == self.downloadTask {
            let calculatedProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            DispatchQueue.main.async {
                (wins["main"] as! SDMainWindowController).downloadProgr.doubleValue = Double(calculatedProgress * 100)
                (wins["main"] as! SDMainWindowController).progressValueLabel.stringValue = "\(Double(Int(calculatedProgress * 1000)) / 10)%"
            }
        }
    }
    
    
    // Download finished
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        
        // download url
        let downloadURL = URL(fileURLWithPath: downloadPath as String)
        
        // ZIP archive URL
        let archivePath = downloadPath.appendingPathComponent("archive.zip")
        let archiveURL = URL(fileURLWithPath: archivePath)
        
        
        // downloaded file
        do {
            let downloadedData = try Data(contentsOf: location)
            FileManager.default.createFile(atPath: archivePath,
                                           contents: downloadedData,
                                           attributes: nil)
            //NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: archivePath).absoluteURL])
            if FileManager.default.fileExists(atPath: archivePath) {
                self.unzip(aturl: archiveURL, tourl: downloadURL)
            }
        } catch {
            print("Error downloading file: \(error.localizedDescription)")
        }
    }
    
    
    // UNZIP downloaded archive
    func unzip(aturl:URL, tourl:URL) {
        DispatchQueue.main.async {
            (wins["main"] as! SDMainWindowController).progressLabel.stringValue = "Unzipping archive..."
            (wins["main"] as! SDMainWindowController).progressValueLabel.integerValue = 0
            (wins["main"] as! SDMainWindowController).downloadProgr.doubleValue = 0
        }
        
        let progress = Progress()
        let progrobs = progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async {
                (wins["main"] as! SDMainWindowController).downloadProgr.doubleValue = Double(progress.fractionCompleted * 100)
                (wins["main"] as! SDMainWindowController).progressValueLabel.stringValue = "\(Double(Int(progress.fractionCompleted * 1000)) / 10)%"
            }
        }
        
        do {
            try FileManager.default.unzipItem(at: aturl, to: tourl, progress: progress)
            if FileManager.default.fileExists(atPath: tourl.path) {
                print("SUCCESS! extracted file/directory exists")
                // delete ZIP archive
                try FileManager.default.removeItem(at: aturl)
                // delete bogus dir
                let bogusDirURL = URL(fileURLWithPath: downloadPath.appendingPathComponent("__MACOSX"))
                try FileManager.default.removeItem(at: bogusDirURL)
                // load model
                (wins["main"] as! SDMainWindowController).gotNewModel(url: tourl)
                
            }
        } catch {
            print("Error unzipping file: \(error.localizedDescription)")
        }
        
        progrobs.invalidate()
    }
    
    
    
    
    
    
}
