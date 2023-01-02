//
//  SDMainWindowController.swift
//  PromptToImage
//
//  Created by hany on 05/12/22.
//

import Cocoa
import Quartz

func displayErrorAlert(txt:String) {
    DispatchQueue.main.async {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = txt
        alert.runModal()
    }
}


class SDMainWindowController: NSWindowController,
                              NSWindowDelegate,
                              NSSharingServicePickerDelegate,
                              NSSplitViewDelegate,
                              NSMenuDelegate,
                              NSTableViewDelegate {
    
    
    @IBOutlet weak var imagescrollview: NSScrollView!
    @IBOutlet weak var imageview: IKImageView!
    @IBOutlet weak var imageControlsView: NSView!
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
    @IBOutlet weak var waitCULabel: NSTextField!
    @IBOutlet weak var unitsPopup: NSPopUpButton!
    @IBOutlet weak var progrWin: NSWindow!
    @IBOutlet weak var progrLabel: NSTextField!
    @IBOutlet weak var upscaleCheckBox: NSButton!
    @IBOutlet weak var speedLabel: NSTextField!
    @IBOutlet weak var guidanceLabel: NSTextField!
    @IBOutlet weak var guidanceSlider: NSSlider!
    // img2img
    @IBOutlet weak var img2imgView: NSView!
    @IBOutlet weak var strengthSlider: NSSlider!
    @IBOutlet weak var str_clearBtn: NSButton!
    @IBOutlet weak var str_importBtn: NSButton!
    @IBOutlet weak var str_label: NSTextField!
    @IBOutlet weak var strengthLabel: NSTextField!
    @IBOutlet weak var inputImageview: NSImageView!
    // images count
    @IBOutlet weak var imageCountSlider: NSSlider!
    @IBOutlet weak var imageCountLabel: NSTextField!
    // seed
    @IBOutlet weak var seedView: NSTextField!
    @IBOutlet weak var seedBtn: NSButton!
    @IBAction func switchSeedBtn(_ sender: NSButton) {
        self.seedView.isSelectable = sender.state == .off
        self.seedView.isEditable = sender.state == .off
    }
    // scheduler
    @IBOutlet weak var schedulerPopup: NSPopUpButton!
    // models
    @IBOutlet weak var modelsPopup: NSPopUpButton!
    // table view menu items
    @IBOutlet weak var item_saveAllSelectedImages: NSMenuItem!
    // history
    @IBOutlet weak var historyTableView: NSTableView!
    @objc dynamic var history = [HistoryItem]()
    @IBOutlet var historyArrayController: NSArrayController!
    @IBOutlet weak var settings_keepHistoryBtn: NSButton!
    var currentHistoryItemForSharePicker : HistoryItem? = nil // used for sharing a single item from item's share btn
    // info popover
    var currentHistoryItemForInfoPopover : HistoryItem? = nil
    var infoPopover : NSPopover? = nil
    @IBOutlet var infoPopoverView: NSView!
    @IBOutlet weak var info_date: NSTextField!
    @IBOutlet weak var info_prompt: NSTextField!
    @IBOutlet weak var info_negativePrompt: NSTextField!
    @IBOutlet weak var info_seed: NSTextField!
    @IBOutlet weak var info_steps: NSTextField!
    @IBOutlet weak var info_guidance: NSTextField!
    @IBOutlet weak var info_inputImage: NSImageView!
    @IBOutlet weak var info_strength: NSTextField!
    @IBOutlet weak var info_size: NSTextField!
    @IBOutlet weak var info_upscaledsize: NSTextField!
    @IBOutlet weak var info_model: NSTextField!
    @IBOutlet weak var info_sampler: NSTextField!
    @IBOutlet weak var info_inputImageView: NSView!
    @IBOutlet weak var info_btn_copyStrength: NSButton!
    @IBOutlet weak var info_btn_copyInputImage: NSButton!
    @IBOutlet var info_upscaledView: NSView!
    // Settings
    @IBOutlet var settingsWindow: NSWindow!
    @IBOutlet weak var modelsPopupMenu: NSMenu!
    @IBOutlet weak var settings_selectDefaultCU: NSButton!
    @IBOutlet weak var settings_historyLimitLabel: NSTextField!
    @IBOutlet weak var settings_historyLimitStepper: NSStepper!
    @IBOutlet weak var settings_downloadBtn: NSButton!
    // Download default model
    @IBOutlet var downloadWindow: NSWindow!
    @IBOutlet weak var downloadProgr: NSProgressIndicator!
    @IBOutlet weak var progressLabel: NSTextField!
    @IBOutlet weak var progressValueLabel: NSTextField!
    @IBOutlet weak var downloadButton: NSButton!
    // model info button (show model card on Huggingface)
    @IBOutlet weak var modelCardBtn: NSButton!
    @IBAction func clickModelCardBtn(_ sender: Any) {
        if let name = currentModelRealName { // real name taken from Unet model
            let url = "https://huggingface.co/\(name)"
            if let url = URL(string: url) { NSWorkspace.shared.open(url) }
        }
    }
    // IKImageView status
    var viewZoomFactor : CGFloat = 1
    var zoomToFit : Bool = true
    // IKImageView image popup
    @IBOutlet weak var upscalePopup: NSPopUpButton!
    @IBOutlet weak var imageItem_upscale: NSMenuItem!
    // model alert accessory view
    @IBOutlet var modelAlertView: NSView!
    @IBOutlet weak var modelAlertCUPopup: NSPopUpButton!
    // original/upscaled switch
    @IBOutlet weak var originalUpscaledSwitch: NSSegmentedControl!
    // compute units images
    @IBOutlet weak var led_cpu: NSImageView!
    @IBOutlet weak var led_gpu: NSImageView!
    @IBOutlet weak var led_ane: NSImageView!
    
    // models popup accessory view
    @IBOutlet var modelsPopupAccView: NSView!
    // open huggingface repo in browser
    @IBAction func openModelsRepo(_ sender: Any) {
        let url = "https://huggingface.co/TheMurusTeam"
        if let url = URL(string: url) { NSWorkspace.shared.open(url) }
    }
    @IBAction func openAppleRepo(_ sender: Any) {
        let url = "https://github.com/apple/ml-stable-diffusion"
        if let url = URL(string: url) { NSWorkspace.shared.open(url) }
    }
    
    
    
    
    // MARK: Init
    
    convenience init(windowNibName:String, info:[String:AnyObject]?) {
        self.init(windowNibName: windowNibName)
        NSApplication.shared.activate(ignoringOtherApps: true)
        self.window?.makeKeyAndOrderFront(nil)
        //self.window?.appearance = NSAppearance(named: .darkAqua)
        
    }
    
    
    
    // MARK: Did Load
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.setUnitsPopup()
        self.populateModelsPopup()
        self.readStoredControlsValues()
        self.loadHistory()
        // main IKImageView
        self.imageview.hasVerticalScroller = true
        self.imageview.hasHorizontalScroller = true
        self.imageview.autohidesScrollers = false
    }
    
    
    
    
    // MARK: Will Close
    
    func windowWillClose(_ notification: Notification) {
        saveHistory()
        storeControlsValues()
    }
    
    
    
    // MARK: Menu Delegate
    
    func menuWillOpen(_ menu: NSMenu) {
        if menu == self.modelsPopup.menu {
            // Models popup
            self.populateModelsPopup()
        } else if menu == self.unitsPopup.menu {
            // Compute Units popup
            self.setUnitsPopup()
        } else if menu == self.upscalePopup.menu {
            // Upscale popup
            self.populateUpscalePopup()
            /*
            guard !self.historyArrayController.selectedObjects.isEmpty else { return }
            let displayedHistoryItem = self.historyArrayController.selectedObjects[0] as! HistoryItem
            self.imageItem_upscale.isEnabled = displayedHistoryItem.upscaledImage == nil
            */
            
        } else if menu == self.historyTableView.menu {
            // history tableview contextual menu
            self.item_saveAllSelectedImages.isEnabled = !self.historyArrayController.selectedObjects.isEmpty
        }
    }
    
    //
    
    
    
    
    // MARK: Enable/Disable IMG2IMG
    
    // display/hide img2img controls view according to pipeline parameter
    func enableImg2Img() {
        if let pipeline = sdPipeline {
            self.img2imgView.isHidden = !pipeline.canUseInputImage
            if !pipeline.canUseInputImage {
                self.inputImageview.image = nil
            }
        }
    }
    
    
    
    
    // MARK: TableView Selection Did Change
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if self.historyArrayController.selectedObjects.isEmpty {
            self.imageview.isHidden = true
            self.imageControlsView.isHidden = true
        } else {
            let displayedHistoryItem = self.historyArrayController.selectedObjects[0] as! HistoryItem
            let image = displayedHistoryItem.upscaledImage ?? displayedHistoryItem.image
            self.originalUpscaledSwitch.isHidden = displayedHistoryItem.upscaledImage == nil
            self.originalUpscaledSwitch.selectSegment(withTag: displayedHistoryItem.upscaledImage == nil ? 0 : 1)
            self.imageview.isHidden = false
            self.imageControlsView.isHidden = false
            var viewRect = self.imageview.visibleRect as CGRect
            self.imageview.setImage(image.cgImage(forProposedRect: &viewRect, context: nil, hints: nil), imageProperties: [:])
            // zoom
            if self.zoomToFit {
                self.imageview.zoomImageToFit(self)
            } else {
                self.imageview.zoomFactor = viewZoomFactor
            }
        }
    }
    
    
    
    
    // MARK: Window Did Resize
    
    func windowDidResize(_ notification: Notification) {
        if self.zoomToFit { self.imageview.zoomImageToFit(self) }
    }
    
    
    
    
    
    
    
    
}














