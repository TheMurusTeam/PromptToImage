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
        UserDefaults.standard.setValue(self.settings_selectDefaultCU.state == .on, forKey: "alwaysSetDefaultCUwhenSwitchingModel")
        UserDefaults.standard.setValue(self.settings_keepHistoryBtn.state == .on, forKey: "keepHistory")
        UserDefaults.standard.setValue(self.settings_historyLimitStepper.doubleValue, forKey: "historyLimit")
        UserDefaults.standard.setValue(self.schedulerPopup.indexOfSelectedItem, forKey: "schedulerPopupItem")
        UserDefaults.standard.setValue(Float(self.viewZoomFactor), forKey: "viewZoomFactor")
        UserDefaults.standard.setValue(self.zoomToFit, forKey: "zoomToFit")
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
        self.settings_selectDefaultCU.state = (UserDefaults.standard.value(forKey: "alwaysSetDefaultCUwhenSwitchingModel") as? Bool ?? true) ? .on : .off
        self.settings_keepHistoryBtn.state = (UserDefaults.standard.value(forKey: "keepHistory") as? Bool ?? true) ? .on : .off
        self.settings_historyLimitStepper.integerValue = Int(UserDefaults.standard.value(forKey: "historyLimit") as? Double ?? 50)
        self.settings_historyLimitLabel.stringValue = String(self.settings_historyLimitStepper.integerValue)
        self.schedulerPopup.selectItem(at: UserDefaults.standard.value(forKey: "schedulerPopupItem") as? Int ?? 0)
        self.viewZoomFactor = UserDefaults.standard.value(forKey: "viewZoomFactor") as? CGFloat ?? 1
        self.zoomToFit = UserDefaults.standard.value(forKey: "zoomToFit") as? Bool ?? true
    }
    
    
}
