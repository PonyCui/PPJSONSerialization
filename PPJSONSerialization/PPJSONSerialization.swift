//
//  PPJSONSerialization.swift
//  PPJSONSerialization
//
//  Created by 崔 明辉 on 15/6/30.
//  Copyright (c) 2015年 PonyCui. All rights reserved.
//

import Foundation

class PPJSONSerialization: NSObject {
    
    func debug() {
        let serializationMirror = Mirror(reflecting: self)
        print(serializationMirror.subjectType)
        for child in serializationMirror.children {
            let sMirror = Mirror(reflecting: child.value)
            let typeString = "\(sMirror.subjectType)"
            print(typeString)
            print(child.label)
            print(child.value)
        }
    }
    
    /// Use mapping maps JSONKey to PropertyKey, [JSONKey: PropertyKey]
//    internal func mapping() -> [String: String] {
//        return [String: String]()
//    }
//    
//    override init() {
//        super.init()
//    }
//    
    
    static func frameworkName() -> String {
        let name = NSStringFromClass(self)
        return name.stringByReplacingOccurrencesOfString(".PPJSONSerialization", withString: "")
    }
    
    override init() {
        super.init()
    }
    
    init?(JSONData: NSData) {
        super.init()
        if self.updateWithJSONData(JSONData) == false {
            return nil
        }
    }
    
    init?(JSONString: String) {
        super.init()
        if self.updateWithJSONString(JSONString) == false {
            return nil
        }
    }
    
    internal func updateWithJSONData(JSONData: NSData) -> Bool {
        do {
            let JSONObject = try NSJSONSerialization.JSONObjectWithData(JSONData, options: [])
            update(JSONObject)
            return true
        }
        catch {
            return false
        }
    }

    internal func updateWithJSONString(JSONString: String) -> Bool {
        if let data = JSONString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            return updateWithJSONData(data)
        }
        else {
            return false
        }
    }

    internal func updateWithJSONData(JSONData: NSData, closure: (isSucceed: Bool) -> Void) -> Void {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            let result = self.updateWithJSONData(JSONData)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                closure(isSucceed: result)
            });
        });
    }
    
    internal func updateWithJSONString(JSONString: String, closure: (isSucceed: Bool) -> Void) -> Void {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            let result = self.updateWithJSONString(JSONString)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                closure(isSucceed: result)
            });
        });
    }

    internal func JSONString() -> String {
        if let JSONString = String(data: JSONData(), encoding: NSUTF8StringEncoding) {
            return JSONString as String
        }
        else {
            return ""
        }
    }
    
    internal func JSONData() -> NSData {
        return NSData()
//        do {
//            let JSONData = try NSJSONSerialization.dataWithJSONObject(convertAsAnyObject(), options: [])
//            return JSONData
//        }
//        catch {
//            return NSData()
//        }
    }
    
    // The following code is private
    
    func update(JSONObject: AnyObject) -> Void {
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let childKey = child.label {
                let childValue = child.value
                let childMirror = Mirror(reflecting: childValue)
                if let JSONObject = JSONObject as? [String: AnyObject] {
                    if "\(childMirror.subjectType)".hasPrefix("Array"),
                        let JSONArrayObject = JSONObject[childKey] as? [AnyObject] {
                            if let childValue = childValue as? NSObject {
                                if childValue.respondsToSelector("updateWithPPJSONObject:generatorType:") {
                                    var JSONValue: AnyObject?
                                    let returnValue = childValue.performSelector("updateWithPPJSONObject:generatorType:", withObject: JSONArrayObject, withObject: "\(childMirror.subjectType)")
                                    let retainValue = returnValue.takeUnretainedValue()
                                    JSONValue = retainValue
                                    if JSONValue != nil {
                                        self.setValue(JSONValue, forKey: childKey)
                                    }
                                }
                            }
                    }
                    else if let JSONValue = PPJSONValueFormatter.value(JSONObject[childKey], eagerType: childMirror.subjectType) {
                        self.setValue(JSONValue, forKey: childKey)
                    }
                    else if "\(childMirror.subjectType)".hasPrefix("Dictionary") {
                        if let childValue = childValue as? NSObject {
                            let JSONDictionaryObject = JSONObject[childKey] as? NSDictionary
                            if childValue.respondsToSelector("updateWithPPJSONObject:generatorType:") {
                                var JSONValue: AnyObject?
                                let returnValue = childValue.performSelector("updateWithPPJSONObject:generatorType:", withObject: JSONDictionaryObject, withObject: "\(childMirror.subjectType)")
                                JSONValue = returnValue.takeUnretainedValue()
                                if JSONValue != nil {
                                    self.setValue(JSONValue, forKey: childKey)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
}

class PPJSONValueFormatter {
    
    static func value(originValue: AnyObject?, eagerTypeString: String) -> AnyObject? {
        if let originValue = originValue {
            if eagerTypeString == "String" {
                return stringValue(originValue)
            }
            else if eagerTypeString == "Int" {
                return numberValue(originValue).integerValue
            }
            else if eagerTypeString == "Double" {
                return numberValue(originValue).doubleValue
            }
            else if eagerTypeString == "Bool" {
                return numberValue(originValue).boolValue
            }
            else {
                let typeString = eagerTypeString.stringByReplacingOccurrencesOfString("Optional", withString: "").stringByReplacingOccurrencesOfString("<", withString: "").stringByReplacingOccurrencesOfString(">", withString: "")
                if let instanceClass = NSClassFromString("\(PPJSONSerialization.frameworkName()).\(typeString)") {
                    if let NSObjectType = instanceClass as? NSObject.Type {
                        if let instance = NSObjectType.init() as? PPJSONSerialization {
                            instance.update(originValue)
                            return instance
                        }
                    }
                }
            }
        }
        return nil
    }
    
    static func value(originValue: AnyObject?, eagerType: Any.Type) -> AnyObject? {
        if let originValue = originValue {
            if eagerType == String.self {
                return stringValue(originValue)
            }
            else if eagerType == Int.self {
                return numberValue(originValue).integerValue
            }
            else if eagerType == Double.self {
                return numberValue(originValue).doubleValue
            }
            else if eagerType == Bool.self {
                return numberValue(originValue).boolValue
            }
            else {
                let typeString = "\(eagerType)".stringByReplacingOccurrencesOfString("Optional", withString: "").stringByReplacingOccurrencesOfString("<", withString: "").stringByReplacingOccurrencesOfString(">", withString: "")
                if let instanceClass = NSClassFromString("\(PPJSONSerialization.frameworkName()).\(typeString)") {
                    if let NSObjectType = instanceClass as? NSObject.Type {
                        if let instance = NSObjectType.init() as? PPJSONSerialization {
                            instance.update(originValue)
                            return instance
                        }
                    }
                }
            }
        }
        return nil
    }
    
    static func numberValue(originValue: AnyObject) -> NSNumber {
        if let transferString = originValue as? String {
            if let transferNumber = NSNumberFormatter().numberFromString(transferString) {
                return transferNumber
            }
        }
        else if let transferNumber = originValue as? NSNumber {
            return transferNumber
        }
        return NSNumber()
    }
    
    static func stringValue(originValue: AnyObject) -> String {
        if let transferNumber = originValue as? NSNumber {
            if let transferString = NSNumberFormatter().stringFromNumber(transferNumber) {
                return transferString
            }
        }
        else if let transferString = originValue as? String {
            return transferString
        }
        return ""
    }
    
}

extension NSArray {
    
    func updateWithPPJSONObject(PPJSONObject: AnyObject!, generatorType: String!) -> AnyObject! {
        if PPJSONObject == nil {
            return []
        }
        let maxLevel = generatorType.componentsSeparatedByString("Array").count - 1
        if let JSONObject = PPJSONObject as? [AnyObject] {
            return nextLevel(JSONObject, currentLevel: 1, maxLevel: maxLevel, generatorType: generatorType)
        }
        else {
            return []
        }
    }
    
    func nextLevel(node: [AnyObject], currentLevel: Int, maxLevel: Int, generatorType: String!) -> [AnyObject] {
        var items = [AnyObject]()
        if currentLevel < maxLevel {
            for subNode in node {
                if let subNode = subNode as? [AnyObject] {
                    let item = nextLevel(subNode, currentLevel: currentLevel+1, maxLevel: maxLevel, generatorType: generatorType)
                    items.append(item)
                }
            }
            return items
        }
        else {
            if generatorType.containsString("Int") || generatorType.containsString("Double") {
                for item in node {
                    items.append(PPJSONValueFormatter.numberValue(item))
                }
            }
            else if generatorType.containsString("String") {
                for item in node {
                    items.append(PPJSONValueFormatter.stringValue(item))
                }
            }
            else {
                let nodeClass = generatorType.stringByReplacingOccurrencesOfString("Array", withString: "").stringByReplacingOccurrencesOfString("<", withString: "").stringByReplacingOccurrencesOfString(">", withString: "")
                if let instanceClass = NSClassFromString("\(PPJSONSerialization.frameworkName()).\(nodeClass)") {
                    if let NSObjectType = instanceClass as? NSObject.Type {
                        for item in node {
                            if let instance = NSObjectType.init() as? PPJSONSerialization {
                                instance.update(item)
                            }
                        }
                    }
                }
            }
            return items
        }
    }
    
}

extension NSDictionary {
    
    func updateWithPPJSONObject(PPJSONObject: AnyObject!, generatorType: String!) -> AnyObject? {
        if PPJSONObject == nil {
            return NSDictionary()
        }
        let pureType = generatorType.stringByReplacingOccurrencesOfString("Dictionary", withString: "").stringByReplacingOccurrencesOfString("<", withString: "").stringByReplacingOccurrencesOfString(">", withString: "").stringByReplacingOccurrencesOfString(" ", withString: "")
        if let keyType = pureType.componentsSeparatedByString(",").first,
            let valueType = pureType.componentsSeparatedByString(",").last {
                let output = NSMutableDictionary()
                if let PPJSONObject = PPJSONObject as? NSDictionary {
                    PPJSONObject.enumerateKeysAndObjectsUsingBlock({ (JSONKey, JSONValue, stop) -> Void in
                        if let outputKey = PPJSONValueFormatter.value(JSONKey, eagerTypeString: keyType) as? NSCopying,
                            let outputValue = PPJSONValueFormatter.value(JSONValue, eagerTypeString: valueType) as? NSObject {
                                output.setObject(outputValue, forKey: outputKey)
                        }
                    })
                }
                return output
        }
        return NSDictionary()
    }
    
}