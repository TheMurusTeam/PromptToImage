//
//  AppDelegate.swift
//  PromptToImage
//
//  Created by hany on 02/12/22.
//

import Foundation
import AppKit


// COREML STABLE DIFFUSION

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { return true }
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { return true }
    func applicationDidFinishLaunching(_ aNotification: Notification) { self.startPromptToImage() }
    func applicationWillTerminate(_ aNotification: Notification) { self.willTerminate() }
}


extension AppDelegate {
    @IBAction func openSettingsWindow(_ sender: Any) {
        guard let ctrl = wins["main"] as? SDMainWindowController else { return }
        ctrl.window?.beginSheet(ctrl.settingsWindow)
    }
}
