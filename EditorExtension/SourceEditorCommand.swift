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
    var completionHandler: ((Error?) -> Void)!
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        
        self.invocation = invocation
        buffer = invocation.buffer
        self.completionHandler = completionHandler
        
        // public.objective-c-source
        // public.swift-source
        isSwift = (invocation.buffer.contentUTI == "public.swift-source")
        
        commandDidClick()
    }
    
    func commandDidClick() {
        
    }
    
    func stringForSelected() -> String {
        var jsonString = ""
        let textRange = buffer.selections.firstObject as! XCSourceTextRange
        let start = textRange.start
        let end = textRange.end
        if start.line != end.line || (start.line == end.line && start.column != end.column) {
            for line in textRange.start.line...textRange.end.line {
                jsonString += (buffer.lines[line] as! String)
            }
        }
        return jsonString
    }
}
