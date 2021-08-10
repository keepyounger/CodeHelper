//
//  SourceEditorCommand.swift
//  EditorExtension
//
//  Created by lixy on 2018/11/20.
//  Copyright © 2018 lixy. All rights reserved.
//

import Foundation
import XcodeKit
import AppKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    var isSwift = false
    var invocation: XCSourceEditorCommandInvocation!
    var buffer: XCSourceTextBuffer!
    var firstSelection: XCSourceTextRange!
    var completionHandler: ((Error?) -> Void)!
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        
        self.invocation = invocation
        self.buffer = invocation.buffer
        self.firstSelection = invocation.buffer.selections.firstObject as? XCSourceTextRange
        self.completionHandler = completionHandler
        
        // public.objective-c-source
        // public.swift-source
        isSwift = (invocation.buffer.contentUTI == "public.swift-source")
        
        commandDidClick()
    }
    
    func commandDidClick() {
        
    }
    
    var selectedString: String {
        var string = ""
        if firstSelection.start.line != firstSelection.end.line || firstSelection.start.column != firstSelection.end.column {
            for line in firstSelection.start.line...firstSelection.end.line {
                string += (buffer.lines[line] as! String)
            }
        }
        return string
    }
}
