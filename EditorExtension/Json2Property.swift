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
    
    var hashValue: Int {
        return className.hashValue
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
                start = "class \(className) {\n"
                end = "}\n"
            }
        } else {
            if className.count > 0 {
                start = "@interface \(className) : NSObject\n"
                end = "@end\n"
            }
        }
        deal(dic)
    }
    
    func deal(_ dic: [String: Any]) {
        for (key, value) in dic {
            if isSwift {
                if let number = value as? NSNumber {
                    let type = String(cString: number.objCType)
                    if type == "c" {
                        content += "    var \(key): Bool = false"
                    } else if type == "q" {
                        content += "    var \(key): Int = 0"
                    } else { //"d"
                        content += "    var \(key): Double = 0"
                    }
                } else if value is Array<Any> {
                    let array = value as! Array<Any>
                    if let first = array.first {
                        if first is String {
                            content += "    var \(key): [String] = []"
                        } else if let first = first as? NSNumber {
                            let type = String(cString: first.objCType)
                            if type == "c" {
                                content += "    var \(key): [Bool] = []"
                            } else if type == "q" {
                                content += "    var \(key): [Int] = []"
                            } else {
                                content += "    var \(key): [Double] = []"
                            }
                        } else {
                            content += "    var \(key): [\(key.capitalized)Model] = []"
                        }
                    } else {
                        content += "    var \(key): [\(type(of: array.first))] = []"
                    }
                } else if value is Dictionary<String, Any> {
                    content += "    var \(key): \(key.capitalized)Model = \(key.capitalized)Model()"
                } else {
                    content += "    var \(key): String = \"\""
                }
            } else {
                if let number = value as? NSNumber {
                    let type = String(cString: number.objCType)
                    if type == "c" {
                        content += "@property (nonatomic, assign) BOOL \(key);"
                    } else if type == "q" {
                        content += "@property (nonatomic, assign) NSInteger \(key);"
                    } else { //"d"
                        content += "@property (nonatomic, assign) CGFloat \(key);"
                    }
                } else if value is Array<Any> {
                    let array = value as! Array<Any>
                    if let first = array.first {
                        if first is String {
                            content += "@property (nonatomic, strong) NSArray<NSString*> *\(key);"
                        } else if first is NSNumber {
                            content += "@property (nonatomic, strong) NSArray<NSNumber*> *\(key);"
                        } else {
                            content += "@property (nonatomic, strong) NSArray<\(key.capitalized)Model*> *\(key);"
                        }
                    } else {
                        content += "@property (nonatomic, strong) NSArray<\(key.capitalized)Model*> *\(key);"
                    }
                } else if value is Dictionary<String, Any> {
                    content += "@property (nonatomic, strong) \(key.capitalized)Model *\(key);"
                } else {
                    content += "@property (nonatomic, copy) NSString *\(key);"
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
        
        let selectedString = stringForSelected()
        let pasteString =  NSPasteboard.general.string(forType: .string) ?? ""
        
        //不存在字符串
        if selectedString.count == 0 && pasteString.count == 0{
            completionHandler(nil)
            return
        }
        
        var json = try? JSONSerialization.jsonObject(with: selectedString.data(using: .utf8) ?? Data(), options: .mutableContainers)
        if json == nil {
            json = try? JSONSerialization.jsonObject(with: pasteString.data(using: .utf8) ?? Data(), options: .mutableContainers)
        }
        
        if let json = json {
            var models = deal(json)
            let mainModel = models.filter { (item) -> Bool in
                return item.className == ""
            }.first
            
            let range = buffer.selections.firstObject as! XCSourceTextRange
            if buffer.lines.count > range.start.line {
                buffer.lines.removeObjects(in: NSMakeRange(range.start.line, range.end.line-range.start.line+1))
            }
            
            if let mainModel = mainModel {
                models.remove(mainModel)
                buffer.lines.insert(mainModel.classString, at: range.start.line)
            }
            
            if !isSwift  && models.count > 0{
                
                var atClass = "@class"
                for model in models {
                    atClass += (" " + model.className + ",")
                }
                atClass.removeLast()
                atClass += ";\n"
                
                var index = -1
                for i in 0..<buffer.lines.count {
                    let string = buffer.lines[i] as! String
                    if string.contains("@interface") {
                        index = i
                    }
                }
                
                if index > -1 {
                    buffer.lines.insert(atClass, at: index)
                }
            }

            for model in models {
                buffer.lines.add(model.classString)
            }
            
            completionHandler(nil)
        } else {
            DispatchQueue.main.async {
                let alert = NSAlert.init()
                alert.messageText = "json解析错误"
                alert.addButton(withTitle: "知道了")
                alert.window.level = .statusBar
                alert.window.makeKeyAndOrderFront(nil)
                alert.runModal()
                self.completionHandler(nil)
            }
        }
        
    }
    
    func deal(_ json: Any, className: String = "") -> Set<ClassModel> {
        var classSet = Set<ClassModel>()
        if let json = json as? [String: Any] {
            let classModel = ClassModel.init(json, className: className, isSwift: isSwift)
            classSet.insert(classModel)
            for (key, value) in json {
                if (value is Array<Any>) || (value is Dictionary<String, Any>) {
                    let models = deal(value, className: "\(key.capitalized)Model")
                    classSet = classSet.union(models)
                }
            }
            
        } else if let json = json as? [Any] {
            if let value = json.first {
                let models = deal(value, className: className)
                classSet = classSet.union(models)
            }
        }
        return classSet
    }
}
