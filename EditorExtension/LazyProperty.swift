//
//  LazyProperty.swift
//  EditorExtension
//
//  Created by lixy on 2021/8/10.
//  Copyright © 2021 lixy. All rights reserved.
//

import Cocoa

class LazyProperty: SourceEditorCommand {
    override func commandDidClick() {
        checkAndComletionGetter(with: self.firstSelection.start.line)
    }
    
    func checkAndComletionGetter(with line: Int) {
        if !isSwift {
            var currentLine = self.buffer.lines[line] as! String
            let reg = try! NSRegularExpression(pattern: "\\s*[\\-\\+]+\\s*\\(\\s*(\\w+)(.*?)\\s*\\)\\s*(\\w+)\\s*\\n$", options: .caseInsensitive)
            let replacement = String(format: "%@{\n\tif (!_$3) {\n\t\t_$3 = [[$1 alloc] init];\n\t}\n\treturn _$3;\n}\n", currentLine)
            currentLine = reg.stringByReplacingMatches(in: currentLine, options: .reportCompletion, range: NSRange(location: 0, length: currentLine.count), withTemplate: replacement)
            self.buffer.lines.removeObject(at: line)
            self.buffer.lines.insert(currentLine, at: line)
            completionHandler(nil)
        } else {
            completionHandler(nil)
        }
    }
}
