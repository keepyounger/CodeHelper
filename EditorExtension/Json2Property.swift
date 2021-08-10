//
//  Json2Property.swift
//  EditorExtension
//
//  Created by lixy on 2019/1/24.
//  Copyright © 2019 lixy. All rights reserved.
//

import Cocoa
import XcodeKit

class ClassModel: Hashable {
    
    static func == (lhs: ClassModel, rhs: ClassModel) -> Bool {
        return lhs.className == rhs.className
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(className)
    }
    
    private(set) var start: String = ""
    private(set) var end: String = ""
    private(set) var content: String = ""
    private(set) var className: String = ""
    private(set) var isSwift: Bool = false
    
    init(_ dic: [String: Any], className: String, isSwift: Bool = true) {
        
        self.className = className
        self.isSwift = isSwift
        
        if isSwift {
            if className.count > 0 {
                start   = "class \(className) {\n"
                end     = "}\n"
            }
        } else {
            if className.count > 0 {
                start   = "@interface \(className) : NSObject\n"
                end     = "@end\n"
            }
        }
        
        deal(dic)
    }
    
    func deal(_ dic: [String: Any]) {
        for (key, value) in dic {
            if isSwift {
                content += "    var \(key): "
                if let number = value as? NSNumber {
                    let type = String(cString: number.objCType)
                    if type == "c" {
                        content += "Bool = false"
                    } else if type == "q" {
                        content += "Int = 0"
                    } else { //"d"
                        content += "Double = 0"
                    }
                } else if let array = value as? [Any] {
                    if let first = array.first {
                        if first is String {
                            content += "[String] = []"
                        } else if let first = first as? NSNumber {
                            let type = String(cString: first.objCType)
                            if type == "c" {
                                content +=  "[Bool] = []"
                            } else if type == "q" {
                                content +=  "[Int] = []"
                            } else {
                                content +=  "[Double] = []"
                            }
                        } else {
                            content += "[\(key.capitalized)Model] = []"
                        }
                    } else {
                        content += "[String] = []"
                    }
                } else if value is [String: Any] {
                    content += "\(key.capitalized)Model = \(key.capitalized)Model()"
                } else {
                    content += "String = \"\""
                }
            } else {
                if let number = value as? NSNumber {
                    let type = String(cString: number.objCType)
                    content += "@property (nonatomic, assign) "
                    if type == "c" {
                        content += "BOOL \(key);"
                    } else if type == "q" {
                        content += "NSInteger \(key);"
                    } else { //"d"
                        content += "CGFloat \(key);"
                    }
                } else if let array = value as? [Any] {
                    content += "@property (nonatomic, strong) "
                    if let first = array.first {
                        if first is String {
                            content += "NSArray<NSString*> *\(key);"
                        } else if first is NSNumber {
                            content += "NSArray<NSNumber*> *\(key);"
                        } else {
                            content += "NSArray<\(key.capitalized)Model*> *\(key);"
                        }
                    } else {
                        content += "NSArray<NSString*> *\(key);"
                    }
                } else if value is Dictionary<String, Any> {
                    content += "@property (nonatomic, strong) "
                    content += "\(key.capitalized)Model *\(key);"
                } else {
                    content += "@property (nonatomic, copy) "
                    content += "NSString *\(key);"
                }
            }
            
            content += "\n"
        }
    }
    
    var classString: String {
        return start + content + end + "\n"
    }
}

class Json2Property: SourceEditorCommand {
    
    override func commandDidClick() {
        
        var selectedString = self.selectedString
        if selectedString.count == 0, let pasteString = NSPasteboard.general.string(forType: .string) {
            selectedString = pasteString
        }
        
        //空字符串
        if selectedString.isEmpty {
            completionHandler(nil)
            return
        }
        
        guard let data = selectedString.data(using: .utf8) else {
            completionHandler(nil)
            return
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            DispatchQueue.main.async {
                self.addLocalNotification(with: "JSON解析错误!")
            }
            self.completionHandler(nil)
            return
        }
        
        var models = deal(json)
        let mainModel = models.filter { (item) -> Bool in
            return item.className == ""
        }.first
        
        if buffer.lines.count > firstSelection.start.line {
            buffer.lines.removeObjects(in: NSMakeRange(firstSelection.start.line, firstSelection.end.line-firstSelection.start.line+1))
        }
        
        if let mainModel = mainModel {
            models.remove(mainModel)
            buffer.lines.insert(mainModel.classString, at: firstSelection.start.line)
        }
        
        if !isSwift && models.count > 0 {
            
            var atClass = "@class"
            var atImplementation = ""
            for model in models {
                atClass += (" \(model.className),")
                atImplementation += "@implementation \(model.className)\n@end\n\n"
            }
            atClass.removeLast()
            atClass += ";\n\n"
            
            DispatchQueue.main.async {
                NSPasteboard.general.declareTypes([.string], owner: nil)
                NSPasteboard.general.setString(atImplementation, forType: .string)
                self.addLocalNotification(with: "@implementation已复制的剪贴板。")
            }
            
            var top = -1
            var bottom = -1
            for i in 0..<buffer.lines.count {
                let str = buffer.lines[i] as! String
                if str.contains("@interface") {
                    top = i
                }
                if str.contains("NS_ASSUME_NONNULL_END") {
                    bottom = i
                }
            }
            
            if bottom > -1 {
                for model in models {
                    buffer.lines.insert(model.classString, at: bottom)
                }
            } else {
                for model in models {
                    buffer.lines.add(model.classString)
                }
            }
            
            if top > -1 {
                buffer.lines.insert(atClass, at: top)
            }
        }
        
        if isSwift {
            for model in models {
                buffer.lines.add(model.classString)
            }
        }
        
        completionHandler(nil)
        
    }
    
    func deal(_ json: Any, className: String = "") -> Set<ClassModel> {
        var classSet = Set<ClassModel>()
        if let json = json as? [String: Any] {
            let classModel = ClassModel(json, className: className, isSwift: isSwift)
            classSet.insert(classModel)
            for (key, value) in json {
                let models = deal(value, className: "\(key.capitalized)Model")
                classSet.formUnion(models)
            }
        } else if let json = json as? [Any] {
            if let value = json.first {
                let models = deal(value, className: className)
                classSet.formUnion(models)
            }
        }
        return classSet
    }
    
    func addLocalNotification(with title: String) {
        let noti = NSUserNotification()
        noti.title = title
        NSUserNotificationCenter.default.deliver(noti)
    }
}
