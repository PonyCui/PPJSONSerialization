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
    func decodeWithPPObject(PPObject: AnyObject) -> AnyObject?
}

class PPJSONSerialization: NSObject {
    
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
            parse(JSONObject)
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
        do {
            if let JSONObject = serialize() {
                let JSONData = try NSJSONSerialization.dataWithJSONObject(JSONObject, options: [])
                return JSONData
            }
            else {
                return NSData()
            }
        }
        catch {
            return NSData()
        }
    }
    
    internal func serialize() -> AnyObject? {
        return _serialize(nil)
    }
    
}

class PPJSONArraySerialization: PPJSONSerialization {
    
    internal override func serialize() -> AnyObject? {
        if hasGetter("root") {
            return _serialize(valueForKey("root"))
        }
        return nil
    }
    
}

// MARK: - Parser
extension PPJSONSerialization {
    
    private func parse(JSONObject: AnyObject) -> Void {
        let objectMirror = Mirror(reflecting: self)
        for objectProperty in objectMirror.children {
            
            if let pKey = objectProperty.label {
                if !hasGetter(pKey) || !hasSetter(pKey) {
                    continue
                }
                let objectType = typeOfChild(objectProperty)
                if let JSONObject = JSONObject as? [String: AnyObject] {
                    if objectType.subjectType.hasPrefix("Array"),
                        let valueType = objectType.containerValueType {
                        let level = PPJSONValueFormatter.numberValue(objectType.subjectType.stringByReplacingOccurrencesOfString("Array.", withString: "")).integerValue
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
                else if self.isKindOfClass(PPJSONArraySerialization), let JSONObject = JSONObject as? [AnyObject] {
                    if objectType.subjectType.hasPrefix("Array"), let valueType = objectType.containerValueType {
                        let level = PPJSONValueFormatter.numberValue(objectType.subjectType.stringByReplacingOccurrencesOfString("Array.", withString: "")).integerValue
                        self.setValue(PPJSONValueFormatter.arrayValue(JSONObject, maxLevel: level, valueType: valueType), forKey: pKey)
                    }
                    else {
                        self.setValue(NSArray(), forKey: pKey)
                    }
                }
            }
            
        }
    }
    
    private func fetchJSONObject(JSONObject: [String: AnyObject], propertyKey: String) -> AnyObject? {
        let rMapping = reverseMapping()
        if rMapping.count > 0 {
            if let JSONKey = rMapping[propertyKey] {
                if let returnValue = JSONObject[JSONKey] {
                    return returnValue
                }
            }
        }
        let aMapping = mapping()
        if aMapping.count > 0 {
            for (mapJSONKey, mapPropertyKey) in aMapping {
                if mapPropertyKey == propertyKey, let returnValue = JSONObject[mapJSONKey] {
                    return returnValue
                }
            }
        }
        return JSONObject[propertyKey]
    }
    
}

// MARK: - Serializer
extension PPJSONSerialization {
    
    private func _serialize(rootObject: AnyObject?) -> AnyObject? {
        if let rootObject = rootObject as? NSArray {
            return rootObject.serializeAsPPJSONObject()
        }
        let output = NSMutableDictionary()
        let objectMirror = Mirror(reflecting: rootObject ?? self)
        for objectProperty in objectMirror.children {
            if let pKey = objectProperty.label {
                if !hasGetter(pKey) {
                    continue
                }
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
        return output.copy()
    }
    
    private func serializingJSONKey(propertyKey: String) -> String? {
        let rMapping = reverseMapping()
        if rMapping.count > 0 {
            if let JSONKey = rMapping[propertyKey] {
                return JSONKey
            }
        }
        let aMapping = mapping()
        if aMapping.count > 0 {
            for (mapJSONKey, mapPropertyKey) in aMapping {
                if mapPropertyKey == propertyKey {
                    return mapJSONKey
                }
            }
        }
        return nil
    }
    
}

// MARK: - Helper
extension PPJSONSerialization {
    
    private func hasGetter(propertyKey: String) -> Bool {
        return respondsToSelector(Selector("\(propertyKey)"))
    }
    
    private func hasSetter(propertyKey: String) -> Bool {
        return respondsToSelector(Selector("set\(firstLetterCapitalizedString(propertyKey)):"))
    }
    
    private func firstLetterCapitalizedString(string: String) -> String {
        if string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 1 {
            let firstLetter = string.substringToIndex(string.startIndex.advancedBy(1))
            let otherLetter = string.substringFromIndex(string.startIndex.advancedBy(1))
            return "\(firstLetter.uppercaseString)\(otherLetter)"
        }
        else {
            return string
        }
    }
    
    private func typeOfChild(child: Mirror.Child) -> (subjectType: String, containerKeyType: String?, containerValueType: String?) {
        
        let mirror = Mirror(reflecting: child.value)
        if mirror.displayStyle == nil {
            return ("\(mirror.subjectType)", nil, nil)
        }
        else if mirror.displayStyle == Mirror.DisplayStyle.Optional {
            let subjectType = "\(mirror.subjectType)"
            let trimedType = subjectType.stringByReplacingOccurrencesOfString("Optional<(.*?)>",
                withString: "$1",
                options: NSStringCompareOptions.RegularExpressionSearch,
                range: nil)
            return ("\(trimedType)", nil, nil)
        }
        else if mirror.displayStyle == Mirror.DisplayStyle.Collection {
            //Array
            let subjectType = "\(mirror.subjectType)"
            let levelCount = subjectType.componentsSeparatedByString("Array").count - 1
            if let sampleArray = child.value as? NSArray {
                if sampleArray.count > 0 {
                    var sampleObject: AnyObject = sampleArray
                    repeat {
                        if let firstObject = sampleObject.firstObject {
                            if let firstObject = firstObject {
                                sampleObject = firstObject
                                continue
                            }
                        }
                        break
                    } while (sampleObject.isKindOfClass(NSArray))
                    
                    if let sampleObject = sampleObject as? PPJSONSerialization {
                        return ("Array.\(levelCount)", nil, NSStringFromClass(sampleObject.classForCoder))
                    }
                }
            }
            let valueType = subjectType.stringByReplacingOccurrencesOfString("Array|<|>", withString: "", options: NSStringCompareOptions.RegularExpressionSearch, range: nil)
            return ("Array.\(levelCount)", nil, valueType)
        }
        else if mirror.displayStyle == Mirror.DisplayStyle.Dictionary {
            //Dictionary
            let subjectType = "\(mirror.subjectType)"
            let valueType = subjectType.stringByReplacingOccurrencesOfString("Dictionary|<|>|\\s", withString: "", options: NSStringCompareOptions.RegularExpressionSearch, range: nil)
            let components = valueType.componentsSeparatedByString(",")
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
        else if mirror.displayStyle == Mirror.DisplayStyle.Class {
            if let subjectType = mirror.subjectType as? PPJSONSerialization.Type {
                return (NSStringFromClass(subjectType), nil, nil)
            }
        }
        return ("", nil, nil)
    }
    
}

class PPJSONValueFormatter {
    
    static func optionalValue(originValue: Any) -> AnyObject? {
        var stringValue = "\(originValue)"
        stringValue = stringValue.stringByReplacingOccurrencesOfString("Optional\\((.*?)\\)", withString: "$1", options: NSStringCompareOptions.RegularExpressionSearch, range: nil)
        if stringValue.hasPrefix("\"") && stringValue.hasSuffix("\"") {
            stringValue = stringValue.stringByReplacingOccurrencesOfString("\"(.*?)\"", withString: "$1", options: NSStringCompareOptions.RegularExpressionSearch, range: nil)
            return self.stringValue(stringValue)
        }
        else {
            return self.numberValue(stringValue)
        }
    }
    
    static func value(originValue: AnyObject?, eagerTypeString: String) -> AnyObject? {
        let trimedEagerTypeString = eagerTypeString.stringByReplacingOccurrencesOfString("Optional|<|>", withString: "", options: NSStringCompareOptions.RegularExpressionSearch, range: nil)
        if let originValue = originValue {
            if trimedEagerTypeString == "String" {
                return stringValue(originValue)
            }
            else if trimedEagerTypeString == "Int" {
                return numberValue(originValue).integerValue
            }
            else if trimedEagerTypeString == "Double" {
                return numberValue(originValue).doubleValue
            }
            else if trimedEagerTypeString == "Bool" {
                return numberValue(originValue).boolValue
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
    
    static func codingValue(originValue: AnyObject, className: String) -> AnyObject? {
        if let classType = NSClassFromString(className) as? NSObject.Type {
            if let classInstance = classType.init() as? PPCoding {
                if let returnValue = classInstance.decodeWithPPObject(originValue) {
                    return returnValue
                }
                else {
                    return classInstance
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
    
    static func arrayValue(originValue: AnyObject, maxLevel: Int, valueType: String) -> NSArray {
        if let originValue = originValue as? [AnyObject] {
            return NSArray().nextLevel(originValue, currentLevel: 1, maxLevel: maxLevel, valueType: valueType)
        }
        return NSArray()
    }
    
}

extension NSArray {
    
    func nextLevel(node: [AnyObject], currentLevel: Int, maxLevel: Int, valueType: String!) -> [AnyObject] {
        var items = [AnyObject]()
        if currentLevel < maxLevel {
            for subNode in node {
                if let subNode = subNode as? [AnyObject] {
                    let item = nextLevel(subNode, currentLevel: currentLevel+1, maxLevel: maxLevel, valueType: valueType)
                    items.append(item)
                }
            }
            return items
        }
        else {
            if valueType.containsString("Int") || valueType.containsString("Double") || valueType.containsString("Bool") {
                for item in node {
                    items.append(PPJSONValueFormatter.numberValue(item))
                }
            }
            else if valueType.containsString("String") {
                for item in node {
                    items.append(PPJSONValueFormatter.stringValue(item))
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
        enumerateObjectsUsingBlock { (theObject, theIndex, stop) -> Void in
            if let nextObject = theObject as? NSArray {
                items.addObject(nextObject.serializeAsPPJSONObject())
            }
            else if let nextObject = theObject as? NSDictionary {
                items.addObject(nextObject.serializeAsPPJSONObject())
            }
            else if let nextObject = theObject as? PPJSONSerialization {
                if let nextSerializedObject = nextObject.serialize() {
                    items.addObject(nextSerializedObject)
                }
            }
            else {
                items.addObject(theObject)
            }
        }
        return items.copy()
    }
    
}

extension NSDictionary {
    
    func update(PPJSONObject: AnyObject?, keyType: String, valueType: String) -> AnyObject? {
        if let JSONObject = PPJSONObject as? [String: AnyObject] {
            let output = NSMutableDictionary()
            for (JSONKey, JSONValue) in JSONObject {
                if let outputKey = PPJSONValueFormatter.value(JSONKey, eagerTypeString: "String") as? NSCopying,
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
        enumerateKeysAndObjectsUsingBlock { (theKey, theObject, _) -> Void in
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
        }
        return items.copy()
    }
    
}
