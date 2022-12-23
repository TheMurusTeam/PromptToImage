//
//  SDMainWindowController.swift
//  PromptToImage
//
//  Created by hany on 05/12/22.
//

import Cocoa

class SDMainWindowController: NSWindowController, NSSharingServicePickerDelegate, NSSplitViewDelegate {

    @IBOutlet weak var splitview: NSSplitView!
    @IBOutlet weak var left: NSView!
    @IBOutlet weak var center: NSView!
    @IBOutlet weak var right: NSView!
    
    
    @IBOutlet weak var imageview: NSImageView!
    @IBOutlet weak var stepsSlider: NSSlider!
    @IBOutlet weak var indicator: NSProgressIndicator!
    @IBOutlet weak var indindicator: NSProgressIndicator!
    @IBOutlet weak var mainBtn: NSButton!
    //@IBOutlet var promptView: NSTextView!
    //@IBOutlet var negativePromptView: NSTextView!
    @IBOutlet weak var promptView: NSTextField!
    @IBOutlet weak var negativePromptView: NSTextField!
    @IBOutlet weak var waitWin: NSWindow!
    @IBOutlet weak var waitProgr: NSProgressIndicator!
    @IBOutlet weak var waitLabel: NSTextField!
    @IBOutlet weak var unitsPopup: NSPopUpButton!
    //@IBOutlet weak var stepsPreview: NSButton!
    @IBOutlet weak var progrWin: NSWindow!
    @IBOutlet weak var progrLabel: NSTextField!
    @IBOutlet weak var upscaleCheckBox: NSButton!
    @IBOutlet weak var saveBtn: NSButton!
    @IBOutlet weak var speedLabel: NSTextField!
    @IBOutlet weak var guidanceLabel: NSTextField!
    @IBOutlet weak var guidanceSlider: NSSlider!
    // img2img
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
    
    var infoPopover : NSPopover? = nil
    @IBOutlet var infoPopoverView: NSView!
    
    
    // info popover
    @IBOutlet weak var info_date: NSTextField!
    @IBOutlet weak var info_prompt: NSTextField!
    @IBOutlet weak var info_negativePrompt: NSTextField!
    @IBOutlet weak var info_seed: NSTextField!
    @IBOutlet weak var info_steps: NSTextField!
    @IBOutlet weak var info_guidance: NSTextField!
    @IBOutlet weak var info_inputImage: NSImageView!
    @IBOutlet weak var info_strenght: NSTextField!
    @IBOutlet weak var info_noInputImageLabel: NSTextField!
    @IBOutlet weak var info_size: NSTextField!
    @IBOutlet weak var info_upscaledLabel: NSTextField!
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    convenience init(windowNibName:String, info:[String:AnyObject]?) {
        self.init(windowNibName: windowNibName)
        NSApplication.shared.activate(ignoringOtherApps: true)
        self.window?.makeKeyAndOrderFront(nil)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.setUnitsPopup()
    }
    
    func setUnitsPopup() {
        switch defaultComputeUnits {
        case .cpuAndNeuralEngine: self.unitsPopup.selectItem(at: 0)
        case .cpuAndGPU: self.unitsPopup.selectItem(at: 1)
        default: self.unitsPopup.selectItem(at: 2) // all
        }
    }
    
    
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
