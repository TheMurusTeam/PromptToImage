//
//  Controls Values.swift
//  PromptToImage
//
//  Created by hany on 25/12/22.
//

import Foundation
import AppKit

extension SDMainWindowController {
    
    
    
    func storeControlsValues() {
        UserDefaults.standard.setValue(self.promptView.stringValue, forKey: "prompt")
        UserDefaults.standard.setValue(self.negativePromptView.stringValue, forKey: "negative")
        UserDefaults.standard.setValue(self.stepsSlider.doubleValue, forKey: "steps")
        UserDefaults.standard.setValue(self.upscaleCheckBox.state == .on, forKey: "upscale")
        UserDefaults.standard.setValue(self.guidanceLabel.floatValue, forKey: "guidance")
    }
    
    func readStoredControlsValues() {
        self.promptView.stringValue = UserDefaults.standard.value(forKey: "prompt") as? String ?? String()
        self.negativePromptView.stringValue = UserDefaults.standard.value(forKey: "negative") as? String ?? String()
        self.stepsSlider.integerValue = Int(UserDefaults.standard.value(forKey: "steps") as? Double ?? 25)
        self.stepsLabel.stringValue = String(self.stepsSlider.integerValue)
        self.upscaleCheckBox.state = (UserDefaults.standard.value(forKey: "upscale") as? Bool ?? true) ? .on : .off
        let guidance = UserDefaults.standard.value(forKey: "guidance") as? Float ?? 7.50
        self.guidanceSlider.doubleValue = Double(Int(guidance * 100))
        self.guidanceLabel.stringValue = String(guidance)
    }
    
    
}
