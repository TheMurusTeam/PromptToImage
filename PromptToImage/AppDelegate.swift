//
//  AppDelegate.swift
//  PromptToImage
//
//  Created by hany on 02/12/22.
//

import Foundation
import AppKit


// COREML STABLE DIFFUSION

var isRunning = false
var wins = [String:NSWindowController]()


@main
class AppDelegate: NSObject, NSApplicationDelegate, NSSharingServicePickerDelegate {

    @IBOutlet weak var saveItem: NSMenuItem!
    @IBAction func clickSaveMenuItem(_ sender: Any) {
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { return true }
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { return true }
    func applicationDidFinishLaunching(_ aNotification: Notification) { self.startPromptToImage() }
    func applicationWillTerminate(_ aNotification: Notification) { self.willTerminate() }
}


