//
//  Split View Delegate.swift
//  PromptToImage
//
//  Created by hany on 25/12/22.
//

import Foundation
import AppKit

extension SDMainWindowController  {
    // MARK: Split View Delegate
    
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return true //subview == self.left
    }
    
    func splitView(_ splitView: NSSplitView, shouldAdjustSizeOfSubview view: NSView) -> Bool {
        return true //view == self.right
    }
    
    func splitView(_ splitView: NSSplitView, constrainMinCoordinate proposedMinimumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        if dividerIndex == 1 { return 435 }
        return 297
    }
    
    func splitView(_ splitView: NSSplitView, constrainMaxCoordinate proposedMaximumPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        if dividerIndex == 1 { return 435 }
        return 297
    }
    
}
