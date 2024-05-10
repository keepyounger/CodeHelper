//
//  OC2SwiftProperty.swift
//  EditorExtension
//
//  Created by lixy on 2024/5/10.
//  Copyright © 2024 lixy. All rights reserved.
//

import Cocoa
import XcodeKit

class OC2SwiftProperty: SourceEditorCommand {
    override func commandDidClick() {
        let startL = firstSelection.start.line
        let endL = firstSelection.end.line
        let lines = buffer.lines
        for (index, line) in lines.enumerated() {
            if index < startL || index > endL {
                continue
            }
            var currentLine = line as! String
            let reg: NSRegularExpression
            var ib = ""
            var tanhao = ""
            if currentLine.contains("IBOutlet") {
                reg = try! NSRegularExpression(pattern: " *@property.*IBOutlet +(.*) +\\*? *(.*) *;", options: .caseInsensitive)
                ib = "@IBOutlet "
                tanhao = "!"
            } else {
                reg = try! NSRegularExpression(pattern: " *@property.*\\) +(.*) +\\*? *(.*) *;", options: .caseInsensitive)
            }
            let replacement = "\(ib)var $2: $1\(tanhao)"
            currentLine = reg.stringByReplacingMatches(in: currentLine, options: .reportCompletion, range: NSRange(location: 0, length: currentLine.count), withTemplate: replacement)
            self.buffer.lines.removeObject(at: index)
            self.buffer.lines.insert(currentLine, at: index)
        }
        completionHandler(nil)
    }
}
