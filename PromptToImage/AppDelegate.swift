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
    @IBOutlet weak var aboutWindow: NSWindow!
    @IBOutlet weak var aboutVersionString: NSTextField!
    
    
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
    @IBAction func openAboutWindow(_ sender: Any) {
        self.aboutVersionString.stringValue = appFullVersion()
        self.aboutWindow.makeKeyAndOrderFront(nil)
        self.aboutWindow.center()
    }
}



func appVersion() -> String {
    return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "4.0"
}
func appBuild() -> String {
    return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
}
func appFullVersion() -> String {
    return "Version " + ((Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "4.0") + " (build " + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "000") + ")")
}
