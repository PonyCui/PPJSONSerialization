//
//  PPJSONSerialization.swift
//  PPJSONSerialization
//
//  Created by 崔 明辉 on 15/6/30.
//  Copyright (c) 2015年 PonyCui. All rights reserved.
//

import Foundation

protocol PPCoding: NSObjectProtocol {
    func encodeAsPPObject() -> AnyObject?
    func decodeWithPPObject(_ PPObject: AnyObject) -> AnyObject?
}

open class PPJSONSerialization: NSObject {
    
    /// Use mapping maps JSONKey to PropertyKey, [JSONKey: PropertyKey], Priorify Low
    internal func mapping() -> [String: String] {
        return [String: String]()
    }
    
    /// Use reverse mapping maps PropertyKey to JSONKey, [PropertyKey: JSONKey], Priority High
    internal func reverseMapping() -> [String: String] {
        return [String: String]()
    }
    
    static func frameworkName() -> String {
        let name = NSStringFromClass(classForCoder())
        return name.replacingOccurrences(of: ".PPJSONSerialization", with: "")
    }
    
    override init() {
        super.init()
    }
    
    init?(JSONData: Data) {
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
    
    init(JSONObject: AnyObject) {
        super.init()
        parse(JSONObject)
    }
    
    internal func updateWithJSONData(_ JSONData: Data) -> Bool {
        do {
            let JSONObject = try JSONSerialization.jsonObject(with: JSONData, options: [])
            parse(JSONObject as AnyObject)
            return true
        }
        catch {
            return false
        }
    }
    
    internal func updateWithJSONString(_ JSONString: String) -> Bool {
        if let data = JSONString.data(using: String.Encoding.utf8, allowLossyConversion: false) {
            return updateWithJSONData(data)
        }
        else {
            return false
        }
    }
    
    internal func updateWithJSONData(_ JSONData: Data, closure: @escaping (_ isSucceed: Bool) -> Void) -> Void {
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: { () -> Void in
            let result = self.updateWithJSONData(JSONData)
            DispatchQueue.main.async(execute: { () -> Void in
                closure(result)
            });
        });
    }
    
    internal func updateWithJSONString(_ JSONString: String, closure: @escaping (_ isSucceed: Bool) -> Void) -> Void {
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default).async(execute: { () -> Void in
            let result = self.updateWithJSONString(JSONString)
            DispatchQueue.main.async(execute: { () -> Void in
                closure(result)
            });
        });
    }
    
    internal func JSONString() -> String? {
        return String(data: JSONData(), encoding: String.Encoding.utf8)
    }
    
    internal func JSONData() -> Data {
        do {
            if let JSONObject = serialize() {
                let JSONData = try JSONSerialization.data(withJSONObject: JSONObject, options: [])
                return JSONData
            }
            else {
                return Data()
            }
        }
        catch {
            return Data()
        }
    }
    
    internal func serialize() -> AnyObject? {
        return _serialize(nil)
    }
    
}

class PPJSONArraySerialization: PPJSONSerialization {
    
    internal override func serialize() -> AnyObject? {
        if hasGetter("root") {
            return _serialize(value(forKey: "root") as AnyObject?)
        }
        return nil
    }
    
}

// MARK: - Parser
extension PPJSONSerialization {
    
    fileprivate func parse(_ JSONObject: AnyObject) -> Void {
        var children: [Mirror.Child] = []
        var currentMirror: Mirror? = Mirror(reflecting: self)
        repeat {
            if currentMirror == nil {
                break
            }
            for child in currentMirror!.children {
                children.append(child)
            }
            currentMirror = currentMirror!.superclassMirror
        } while(true)
        for objectProperty in children {
            if let pKey = objectProperty.label, (hasGetter(pKey) && hasSetter(pKey)) {
                let objectType = typeOfChild(objectProperty)
                if let JSONObject = JSONObject as? [String: AnyObject] {
                    if objectType.subjectType.hasPrefix("Array"),
                        let valueType = objectType.containerValueType {
                        let level = PPJSONValueFormatter.numberValue(objectType.subjectType.replacingOccurrences(of: "Array.", with: "") as AnyObject).intValue
                        if let originValue = fetchJSONObject(JSONObject, propertyKey: pKey) {
                            self.setValue(PPJSONValueFormatter.arrayValue(originValue, maxLevel: level, valueType: valueType), forKey: pKey)
                        }
                        else {
                            self.setValue(NSArray(), forKey: pKey)
                        }
                    }
                    else if let KVCValue = PPJSONValueFormatter.value(fetchJSONObject(JSONObject, propertyKey: pKey),
                                                                      eagerTypeString: objectType.subjectType) {
                        self.setValue(KVCValue, forKey: pKey)
                    }
                    else if objectType.subjectType == "Dictionary",
                        let keyType = objectType.containerKeyType,
                        let valueType = objectType.containerValueType {
                        if let KVCValue = NSDictionary().update(fetchJSONObject(JSONObject, propertyKey: pKey),
                                                                keyType: keyType,
                                                                valueType: valueType) as? NSObject {
                            self.setValue(KVCValue, forKey: pKey)
                        }
                    }
                }
                else if self.isKind(of: PPJSONArraySerialization.self), let JSONObject = JSONObject as? [AnyObject] {
                    if objectType.subjectType.hasPrefix("Array"), let valueType = objectType.containerValueType {
                        let level = PPJSONValueFormatter.numberValue(objectType.subjectType.replacingOccurrences(of: "Array.", with: "") as AnyObject).intValue
                        self.setValue(PPJSONValueFormatter.arrayValue(JSONObject as AnyObject, maxLevel: level, valueType: valueType), forKey: pKey)
                    }
                    else {
                        self.setValue(NSArray(), forKey: pKey)
                    }
                }
            }
            
        }
    }
    
    fileprivate func fetchJSONObject(_ JSONObject: [String: AnyObject], propertyKey: String) -> AnyObject? {
        if let returnValue = JSONObject[(reverseMapping()[propertyKey] ?? propertyKey)] {
            return returnValue
        }
        for (mapJSONKey, mapPropertyKey) in mapping() {
            if mapPropertyKey == propertyKey, let returnValue = JSONObject[mapJSONKey] {
                return returnValue
            }
        }
        return JSONObject[propertyKey]
    }
    
}

// MARK: - Serializer
extension PPJSONSerialization {
    
    fileprivate func _serialize(_ rootObject: AnyObject?) -> AnyObject? {
        if let rootObject = rootObject as? NSArray {
            return rootObject.serializeAsPPJSONObject()
        }
        let output = NSMutableDictionary()
        let objectMirror = Mirror(reflecting: rootObject ?? self)
        for objectProperty in objectMirror.children {
            if let pKey = objectProperty.label, hasGetter(pKey) {
                let jKey = serializingJSONKey(pKey) ?? pKey
                let objectType = typeOfChild(objectProperty)
                if objectType.subjectType.hasPrefix("Array") {
                    if let arrayObject = objectProperty.value as? NSArray {
                        output.setValue(arrayObject.serializeAsPPJSONObject(), forKey: jKey)
                    }
                }
                else if objectType.subjectType == "Dictionary" {
                    if let dictionaryObject = objectProperty.value as? NSDictionary {
                        output.setValue(dictionaryObject.serializeAsPPJSONObject(), forKey: jKey)
                    }
                }
                else if let classObject = objectProperty.value as? PPJSONSerialization {
                    if let classOutput = classObject.serialize() {
                        output.setValue(classOutput, forKey: jKey)
                    }
                }
                else if let codingObject = objectProperty.value as? PPCoding {
                    if let codingOutput = codingObject.encodeAsPPObject() {
                        output.setValue(codingOutput, forKey: jKey)
                    }
                }
                else if let normalObject = objectProperty.value as? AnyObject {
                    if let normalOutput = PPJSONValueFormatter.value(normalObject, eagerTypeString: objectType.subjectType) {
                        output.setValue(normalOutput, forKey: jKey)
                    }
                }
                else {
                    if let optionalOutput = PPJSONValueFormatter.optionalValue(objectProperty.value) {
                        output.setValue(optionalOutput, forKey: jKey)
                    }
                }
            }
        }
        return output.copy() as AnyObject?
    }
    
    fileprivate func serializingJSONKey(_ propertyKey: String) -> String? {
        if let JSONKey = reverseMapping()[propertyKey] {
            return JSONKey
        }
        for (mapJSONKey, mapPropertyKey) in mapping() {
            if mapPropertyKey == propertyKey {
                return mapJSONKey
            }
        }
        return nil
    }
    
}

// MARK: - Helper
extension PPJSONSerialization {
    
    fileprivate func hasGetter(_ propertyKey: String) -> Bool {
        return responds(to: Selector("\(propertyKey)"))
    }
    
    fileprivate func hasSetter(_ propertyKey: String) -> Bool {
        return responds(to: Selector("set\(firstLetterCapitalizedString(propertyKey)):"))
    }
    
    fileprivate func firstLetterCapitalizedString(_ string: String) -> String {
        if string.lengthOfBytes(using: String.Encoding.utf8) > 1 {
            let firstLetter = string.substring(to: string.characters.index(string.startIndex, offsetBy: 1))
            let otherLetter = string.substring(from: string.characters.index(string.startIndex, offsetBy: 1))
            return "\(firstLetter.uppercased())\(otherLetter)"
        }
        else {
            return string
        }
    }
    
    fileprivate func typeOfChild(_ child: Mirror.Child) -> (subjectType: String, containerKeyType: String?, containerValueType: String?) {
        
        let mirror = Mirror(reflecting: child.value)
        if mirror.displayStyle == nil {
            return ("\(mirror.subjectType)", nil, nil)
        }
        else if mirror.displayStyle == Mirror.DisplayStyle.optional {
            let subjectType = "\(mirror.subjectType)"
            let trimedType = subjectType.replacingOccurrences(of: "Optional<(.*?)>",
                                                              with: "$1",
                                                              options: NSString.CompareOptions.regularExpression,
                                                              range: nil)
            return ("\(trimedType)", nil, nil)
        }
        else if mirror.displayStyle == Mirror.DisplayStyle.collection {
            //Array
            let subjectType = "\(mirror.subjectType)"
            let levelCount = subjectType.components(separatedBy: "Array").count - 1
            if let sampleArray = child.value as? NSArray {
                if sampleArray.count > 0 {
                    var sampleObject: AnyObject = sampleArray
                    repeat {
                        if let firstObject = sampleObject.firstObject {
                            if let firstObject = firstObject {
                                sampleObject = firstObject as AnyObject
                                continue
                            }
                        }
                        break
                    } while (sampleObject is NSArray)
                    
                    if let sampleObject = sampleObject as? PPJSONSerialization {
                        return ("Array.\(levelCount)", nil, NSStringFromClass(sampleObject.classForCoder))
                    }
                }
            }
            let valueType = subjectType.replacingOccurrences(of: "Array|<|>", with: "", options: NSString.CompareOptions.regularExpression, range: nil)
            return ("Array.\(levelCount)", nil, valueType)
        }
        else if mirror.displayStyle == Mirror.DisplayStyle.dictionary {
            //Dictionary
            let subjectType = "\(mirror.subjectType)"
            let valueType = subjectType.replacingOccurrences(of: "Dictionary|<|>|\\s", with: "", options: NSString.CompareOptions.regularExpression, range: nil)
            let components = valueType.components(separatedBy: ",")
            if components.count == 2 {
                if let sampleDictionary = child.value as? NSDictionary {
                    if sampleDictionary.count > 0 {
                        if let sampleObject = sampleDictionary.allValues.first as? PPJSONSerialization {
                            return ("Dictionary", components[0], NSStringFromClass(sampleObject.classForCoder))
                        }
                    }
                }
                return ("Dictionary", components[0], components[1])
            }
        }
        else if mirror.displayStyle == Mirror.DisplayStyle.class {
            if let subjectType = mirror.subjectType as? PPJSONSerialization.Type {
                return (NSStringFromClass(subjectType), nil, nil)
            }
        }
        return ("", nil, nil)
    }
    
}

class PPJSONValueFormatter {
    
    static func optionalValue(_ originValue: Any) -> AnyObject? {
        var stringValue = "\(originValue)"
        stringValue = stringValue.replacingOccurrences(of: "Optional\\((.*?)\\)", with: "$1", options: NSString.CompareOptions.regularExpression, range: nil)
        if stringValue.hasPrefix("\"") && stringValue.hasSuffix("\"") {
            stringValue = stringValue.replacingOccurrences(of: "\"(.*?)\"", with: "$1", options: NSString.CompareOptions.regularExpression, range: nil)
            return self.stringValue(stringValue as AnyObject) as AnyObject?
        }
        else {
            return self.numberValue(stringValue as AnyObject)
        }
    }
    
    static func value(_ originValue: AnyObject?, eagerTypeString: String) -> AnyObject? {
        let trimedEagerTypeString = eagerTypeString.replacingOccurrences(of: "Optional|<|>", with: "", options: NSString.CompareOptions.regularExpression, range: nil)
        if let originValue = originValue {
            if trimedEagerTypeString == "String" {
                return stringValue(originValue) as AnyObject?
            }
            else if trimedEagerTypeString == "Int" {
                return numberValue(originValue).intValue as AnyObject?
            }
            else if trimedEagerTypeString == "Double" {
                return numberValue(originValue).doubleValue as AnyObject?
            }
            else if trimedEagerTypeString == "Bool" {
                return numberValue(originValue).boolValue as AnyObject?
            }
            else if trimedEagerTypeString == "NSNumber" {
                return numberValue(originValue)
            }
            else if let codeingInstance = codingValue(originValue, className: trimedEagerTypeString) {
                return codeingInstance
            }
            else {
                if let instanceClass = NSClassFromString(trimedEagerTypeString) ??
                    NSClassFromString("\(PPJSONSerialization.frameworkName()).\(trimedEagerTypeString)") {
                    if let NSObjectType = instanceClass as? NSObject.Type {
                        if let instance = NSObjectType.init() as? PPJSONSerialization {
                            instance.parse(originValue)
                            return instance
                        }
                    }
                }
            }
        }
        return nil
    }
    
    static func codingValue(_ originValue: AnyObject, className: String) -> AnyObject? {
        if let classType = NSClassFromString(className) as? NSObject.Type {
            if let classInstance = classType.init() as? PPCoding {
                return classInstance.decodeWithPPObject(originValue) ?? classInstance
            }
        }
        return nil
    }
    
    static func numberValue(_ originValue: AnyObject) -> NSNumber {
        if let transferString = originValue as? String {
            return NumberFormatter().number(from: transferString) ?? NSNumber()
        }
        else if let transferNumber = originValue as? NSNumber {
            return transferNumber
        }
        return NSNumber()
    }
    
    static func stringValue(_ originValue: AnyObject) -> String {
        if let transferNumber = originValue as? NSNumber {
            return NumberFormatter().string(from: transferNumber) ?? ""
        }
        else if let transferString = originValue as? String {
            return transferString
        }
        return ""
    }
    
    static func arrayValue(_ originValue: AnyObject, maxLevel: Int, valueType: String) -> NSArray {
        if let originValue = originValue as? [AnyObject] {
            return NSArray().nextLevel(originValue, currentLevel: 1, maxLevel: maxLevel, valueType: valueType) as NSArray
        }
        return NSArray()
    }
    
}

extension NSArray {
    
    func nextLevel(_ node: [AnyObject], currentLevel: Int, maxLevel: Int, valueType: String!) -> [AnyObject] {
        var items = [AnyObject]()
        if currentLevel < maxLevel {
            for subNode in node {
                if let subNode = subNode as? [AnyObject] {
                    let item = nextLevel(subNode, currentLevel: currentLevel+1, maxLevel: maxLevel, valueType: valueType)
                    items.append(item as AnyObject)
                }
            }
            return items
        }
        else {
            if valueType.contains("Int") || valueType.contains("Double") || valueType.contains("Bool") {
                for item in node {
                    items.append(PPJSONValueFormatter.numberValue(item))
                }
            }
            else if valueType.contains("String") {
                for item in node {
                    items.append(PPJSONValueFormatter.stringValue(item) as AnyObject)
                }
            }
            else {
                for item in node {
                    if let instance = PPJSONValueFormatter.value(item, eagerTypeString: valueType) {
                        items.append(instance)
                    }
                }
            }
            return items
        }
    }
    
    func serializeAsPPJSONObject() -> AnyObject {
        let items = NSMutableArray()
        enumerateObjects({ (theObject, theIndex, stop) -> Void in
            if let nextObject = theObject as? NSArray {
                items.add(nextObject.serializeAsPPJSONObject())
            }
            else if let nextObject = theObject as? NSDictionary {
                items.add(nextObject.serializeAsPPJSONObject())
            }
            else if let nextObject = theObject as? PPJSONSerialization {
                if let nextSerializedObject = nextObject.serialize() {
                    items.add(nextSerializedObject)
                }
            }
            else {
                items.add(theObject)
            }
        })
        return items.copy() as AnyObject
    }
    
}

extension NSDictionary {
    
    func update(_ PPJSONObject: AnyObject?, keyType: String, valueType: String) -> AnyObject? {
        if let JSONObject = PPJSONObject as? [String: AnyObject] {
            let output = NSMutableDictionary()
            for (JSONKey, JSONValue) in JSONObject {
                if let outputKey = PPJSONValueFormatter.value(JSONKey as AnyObject?, eagerTypeString: "String") as? NSCopying,
                    let outputValue = PPJSONValueFormatter.value(JSONValue, eagerTypeString: valueType) as? NSObject{
                    output.setObject(outputValue, forKey: outputKey)
                }
            }
            return output
        }
        else {
            return nil
        }
    }
    
    func serializeAsPPJSONObject() -> AnyObject {
        let items = NSMutableDictionary()
        enumerateKeysAndObjects({ (theKey, theObject, _) -> Void in
            if let theKey = theKey as? NSCopying {
                if let nextObject = theObject as? NSArray {
                    items.setObject(nextObject.serializeAsPPJSONObject(), forKey: theKey)
                }
                else if let nextObject = theObject as? NSDictionary {
                    items.setObject(nextObject.serializeAsPPJSONObject(), forKey: theKey)
                }
                else if let nextObject = theObject as? PPJSONSerialization {
                    if let nextSerializedObject = nextObject.serialize() {
                        items.setObject(nextSerializedObject, forKey: theKey)
                    }
                }
                else {
                    items.setObject(theObject, forKey: theKey)
                }
            }
        })
        return items.copy() as AnyObject
    }
    
}

