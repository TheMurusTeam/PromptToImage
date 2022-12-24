//
//  SDMainWindowController.swift
//  PromptToImage
//
//  Created by hany on 05/12/22.
//

import Cocoa

class SDMainWindowController: NSWindowController,
                              NSSharingServicePickerDelegate,
                              NSSplitViewDelegate,
                              NSMenuDelegate {

    @IBOutlet weak var splitview: NSSplitView!
    @IBOutlet weak var left: NSView!
    @IBOutlet weak var center: NSView!
    @IBOutlet weak var right: NSView!
    
    @IBOutlet weak var imageview: NSImageView!
    @IBOutlet weak var stepsSlider: NSSlider!
    @IBOutlet weak var stepsLabel: NSTextField!
    @IBOutlet weak var indicator: NSProgressIndicator!
    @IBOutlet weak var indindicator: NSProgressIndicator!
    @IBOutlet weak var mainBtn: NSButton!
    @IBOutlet weak var promptView: NSTextField!
    @IBOutlet weak var negativePromptView: NSTextField!
    @IBOutlet weak var waitWin: NSWindow!
    @IBOutlet weak var waitProgr: NSProgressIndicator!
    @IBOutlet weak var waitLabel: NSTextField!
    @IBOutlet weak var waitInfoLabel: NSTextField!
    @IBOutlet weak var unitsPopup: NSPopUpButton!
    @IBOutlet weak var progrWin: NSWindow!
    @IBOutlet weak var progrLabel: NSTextField!
    @IBOutlet weak var upscaleCheckBox: NSButton!
    @IBOutlet weak var saveBtn: NSButton!
    @IBOutlet weak var speedLabel: NSTextField!
    @IBOutlet weak var guidanceLabel: NSTextField!
    @IBOutlet weak var guidanceSlider: NSSlider!
    // img2img
    @IBOutlet weak var img2imgView: NSView!
    @IBOutlet weak var strenghtSlider: NSSlider!
    @IBOutlet weak var str_clearBtn: NSButton!
    @IBOutlet weak var str_importBtn: NSButton!
    @IBOutlet weak var str_resizePopup: NSPopUpButton!
    @IBOutlet weak var str_label: NSTextField!
    @IBOutlet weak var strenghtLabel: NSTextField!
    @IBOutlet weak var inputImageview: NSImageView!
 
    // images count
    @IBOutlet weak var imageCountStepper: NSStepper!
    @IBOutlet weak var imageCountLabel: NSTextField!
    // seed
    @IBOutlet weak var seedView: NSTextField!
    @IBOutlet weak var seedBtn: NSButton!
    @IBAction func switchSeedBtn(_ sender: NSButton) {
        self.seedView.isSelectable = sender.state == .off
        self.seedView.isEditable = sender.state == .off
    }
    
    @IBOutlet weak var modelsPopup: NSPopUpButton!
    
    
    // history collection view
    @IBOutlet weak var colScrollView: NSScrollView!
    @IBOutlet weak var colView: NSCollectionView!
    @objc dynamic var history = [HistoryItem]()
    @IBOutlet var historyArrayController: NSArrayController!
    
    // info popover
    var infoPopover : NSPopover? = nil
    @IBOutlet var infoPopoverView: NSView!
    @IBOutlet weak var info_date: NSTextField!
    @IBOutlet weak var info_prompt: NSTextField!
    @IBOutlet weak var info_negativePrompt: NSTextField!
    @IBOutlet weak var info_seed: NSTextField!
    @IBOutlet weak var info_steps: NSTextField!
    @IBOutlet weak var info_guidance: NSTextField!
    @IBOutlet weak var info_inputImage: NSImageView!
    @IBOutlet weak var info_strenght: NSTextField!
    @IBOutlet weak var info_size: NSTextField!
    @IBOutlet weak var info_upscaledLabel: NSTextField!
    @IBOutlet weak var info_model: NSTextField!
    
    @IBOutlet weak var info_inputImageView: NSView!
    @IBOutlet weak var info_btn_copyStrenght: NSButton!
    @IBOutlet weak var info_btn_copyInputImage: NSButton!
    
    // actions
    @IBAction func infoCopyPrompt(_ sender: Any) {
        self.promptView.stringValue = info_prompt.stringValue
    }
    @IBAction func infoCopyNegativePrompt(_ sender: Any) {
        self.negativePromptView.stringValue = info_negativePrompt.stringValue
    }
    @IBAction func infoCopySeed(_ sender: Any) {
        self.seedView.stringValue = info_seed.stringValue
        self.seedBtn.state = .off
        self.seedView.isSelectable = true
        self.seedView.isEditable = true
    }
    @IBAction func infoCopySteps(_ sender: Any) {
        self.stepsSlider.integerValue = info_steps.integerValue
        self.stepsLabel.integerValue = info_steps.integerValue
    }
    @IBAction func infoCopyGuidance(_ sender: Any) {
        self.guidanceSlider.doubleValue = info_guidance.doubleValue * 100
        self.guidanceLabel.stringValue = String(info_guidance.doubleValue)
    }
    @IBAction func infoCopyStrenght(_ sender: Any) {
        self.strenghtSlider.doubleValue = info_strenght.doubleValue * 100
        self.strenghtLabel.stringValue = String(info_strenght.doubleValue)
    }
    @IBAction func infoCopyInputImage(_ sender: Any) {
        if let image = self.info_inputImage.image {
            self.inputImageview.image = image
        }
    }
    
    
    
    // Settings
    @IBOutlet var settingsWindow: NSWindow!
    @IBAction func displaySettings(_ sender: Any) {
        self.setModelsPopup()
        //self.settingsWindow.makeKeyAndOrderFront(nil)
        self.window?.beginSheet(self.settingsWindow)
    }
    @IBAction func closeSettingsWindow(_ sender: Any) {
        self.window?.endSheet(self.settingsWindow)
    }
    
   
    
    @IBOutlet weak var modelsPopupMenu: NSMenu!
    
    
    var currentHistoryItem : HistoryItem? = nil
    
    
    
    
    // MARK: Init
    
    convenience init(windowNibName:String, info:[String:AnyObject]?) {
        self.init(windowNibName: windowNibName)
        NSApplication.shared.activate(ignoringOtherApps: true)
        self.window?.makeKeyAndOrderFront(nil)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.setUnitsPopup()
        self.populateModelsPopup()
    }
    
    
    // MARK: Enable/Disable IMG2IMG
    
    func enableImg2Img() {
        if let pipeline = sdPipeline {
            self.img2imgView.isHidden = !pipeline.canUseInputImage
            if pipeline.canUseInputImage {
                print("Img2Img is available")
            } else {
                print("Img2Img is NOT available (VAEEncoder not found)")
            }
        }
    }
    
    
    // MARK: Split View Delegate
    
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return subview == self.left
    }
    
    func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
        return view == self.right
    }
    
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        if dividerIndex == 1 { return 297 + 138 }
        return 297
    }
    
    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        if dividerIndex == 1 { return 297 + 138 }
        return 297
    }
    
    
    
    
}
