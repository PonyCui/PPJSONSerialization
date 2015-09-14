//
//  PPJSONSerialization.swift
//  PPJSONSerialization
//
//  Created by 崔 明辉 on 15/6/30.
//  Copyright (c) 2015年 PonyCui. All rights reserved.
//

import Foundation

enum PPJSONValueType: Int {
    case Unknown = 0
    case String
    case Number
    case Array
    case Dictionary
}

class PPJSONSerialization: NSObject, NSCopying {
    
    /// Use mapping maps JSONKey to PropertyKey, [JSONKey: PropertyKey]
    internal func mapping() -> [String: String] {
        return [String: String]()
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
        if let JSONObject: AnyObject = try? NSJSONSerialization.JSONObjectWithData(JSONData, options: []) {
            return updateWithJSONObject(JSONObject, JSONKey: rootKey)
        }
        else {
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
        if let JSONString = NSString(data: JSONData(), encoding: NSUTF8StringEncoding) {
            return JSONString as String
        }
        else {
            return ""
        }
    }
    
    internal func JSONData() -> NSData {
        if let JSONData = try? NSJSONSerialization.dataWithJSONObject(convertAsAnyObject(), options: []) {
            return JSONData
        }
        else {
            return NSData()
        }
    }
    
    // The following code is private
    
    private let rootKey = ""
    private var updatedKeys = [String: Bool]()
    
    private func updateWithJSONObject(JSONObject: AnyObject, JSONKey: String) -> Bool {
        var propertyKey = propertyKeyFromJSONKey(JSONKey)
        if JSONKey != rootKey {
            updatedKeys[propertyKey] = true
        }
        switch classForInstance(JSONObject) {
        case PPJSONValueType.String:
            if respondsToSelector(NSSelectorFromString(propertyKey)) {
                if let _ = self.valueForKey(propertyKey) as? String {
                    setValue(JSONObject, forKeyPath: propertyKey)
                }
                else if let _ = self.valueForKey(propertyKey) as? Double {
                    setValue(numberObjectFromAnyObject(JSONObject), forKey: propertyKey)
                }
                else if let _ = self.valueForKey(propertyKey) as? Int {
                    setValue(numberObjectFromAnyObject(JSONObject), forKey: propertyKey)
                }
            }
            break
        case PPJSONValueType.Number:
            if respondsToSelector(NSSelectorFromString(propertyKey)) {
                if let _ = self.valueForKey(propertyKey) as? String {
                    setValue(stringObjectFromAnyObject(JSONObject), forKey: propertyKey)
                }
                else if let _ = self.valueForKey(propertyKey) as? Double {
                    setValue(JSONObject, forKey: propertyKey)
                }
                else if let _ = self.valueForKey(propertyKey) as? Int {
                    setValue(JSONObject, forKey: propertyKey)
                }
            }
            break
        case PPJSONValueType.Array:
            if propertyKey == rootKey {
                propertyKey = "root"
                updatedKeys[propertyKey] = true
            }
            if respondsToSelector(NSSelectorFromString(propertyKey)) {
                if let propertyArray = self.valueForKey(propertyKey) as? NSArray {
                    if let tplObject: AnyObject = propertyArray.lastObject {
                        if let JSONArray: NSArray = JSONObject as? NSArray {
                            let objectWithData = NSMutableArray()
                            switch classForInstance(tplObject) {
                            case PPJSONValueType.Number:
                                for JSONItem in JSONArray {
                                    objectWithData.addObject(numberObjectFromAnyObject(JSONItem))
                                }
                                break
                            case PPJSONValueType.String:
                                for JSONItem in JSONArray {
                                    objectWithData.addObject(stringObjectFromAnyObject(JSONItem))
                                }
                                break
                            default:
                                if tplObject.respondsToSelector("copy") {
                                    for JSONItem in JSONArray {
                                        if let mirrorObject: PPJSONSerialization = tplObject.copy() as? PPJSONSerialization {
                                            mirrorObject.updateWithJSONObject(JSONItem, JSONKey: rootKey)
                                            objectWithData.addObject(mirrorObject)
                                        }
                                    }
                                }
                                break
                            }
                            setValue(objectWithData.copy(), forKey: propertyKey)
                        }
                        else {
                            setValue(NSArray(), forKey: propertyKey)
                        }
                        break
                    }
                }
            }
            break
        case PPJSONValueType.Dictionary:
            if JSONKey == rootKey {
                let JSONDictionary: NSDictionary! = JSONObject as? NSDictionary
                for (JSONKey, JSONValue) in JSONDictionary {
                    if let JSONStringKey = JSONKey as? String {
                        updateWithJSONObject(JSONValue, JSONKey: JSONStringKey)
                    }
                }
            }
            else {
                if respondsToSelector(NSSelectorFromString(propertyKey)) {
                    if nil != self.valueForKey(propertyKey) as? NSArray {
                        setValue(NSArray(), forKey: propertyKey)
                    }
                    else if let propertyObject = self.valueForKey(propertyKey) as? PPJSONSerialization {
                        propertyObject.updateWithJSONObject(JSONObject, JSONKey: rootKey)
                    }
                }
            }
            break
        default:
            break
        }
        if JSONKey == rootKey {
            resetEmptyArray()
        }
        return true
    }
    
    private func convertAsAnyObject() -> AnyObject {
        if respondsToSelector("root") {
            if nil != valueForKey("root") as? NSArray {
                return convertAsArray()
            }
        }
        return conventAsDictionary()
    }
    
    private func convertAsArray() -> [AnyObject] {
        if respondsToSelector("root") {
            if let propertyArrayValue: NSArray = valueForKey("root") as? NSArray {
                if let propertyNSObjectValue: NSObject = propertyArrayValue.firstObject as? NSObject {
                    let JSONArray = NSMutableArray()
                    if nil != propertyNSObjectValue as? PPJSONSerialization {
                        for propertyArrayItem in propertyArrayValue {
                            if let propertyArrayPPItem: PPJSONSerialization = propertyArrayItem as? PPJSONSerialization {
                                JSONArray.addObject(propertyArrayPPItem.convertAsAnyObject())
                            }
                        }
                    }
                    else {
                        for propertyArrayItem in propertyArrayValue {
                            JSONArray.addObject(propertyArrayItem)
                        }
                    }
                    return JSONArray as [AnyObject]
                }
            }
        }
        return []
    }
    
    private func conventAsDictionary() -> [String: AnyObject] {
        var JSONDictionary = [String: AnyObject]()
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let key = child.label {
                if key ==
                    "super" {
                    continue
                }
                if let propertyValue: NSObject = valueForKey(key) as? NSObject {
                    switch classForInstance(propertyValue) {
                    case PPJSONValueType.Number:
                        JSONDictionary[key] = propertyValue
                        break;
                    case PPJSONValueType.String:
                        JSONDictionary[key] = propertyValue
                        break;
                    case PPJSONValueType.Array:
                        if let propertyArrayValue: NSArray = propertyValue as? NSArray {
                            if let propertyNSObjectValue: NSObject = propertyArrayValue.firstObject as? NSObject {
                                let JSONArray = NSMutableArray()
                                if let _ = propertyNSObjectValue as? PPJSONSerialization {
                                    for propertyArrayItem in propertyArrayValue {
                                        if let propertyArrayPPItem: PPJSONSerialization = propertyArrayItem as? PPJSONSerialization {
                                            JSONArray.addObject(propertyArrayPPItem.convertAsAnyObject())
                                        }
                                    }
                                }
                                else {
                                    for propertyArrayItem in propertyArrayValue {
                                        JSONArray.addObject(propertyArrayItem)
                                    }
                                }
                                JSONDictionary[key] = JSONArray
                            }
                        }
                        break;
                    default:
                        if let propertyPPValue: PPJSONSerialization = propertyValue as? PPJSONSerialization {
                            JSONDictionary[key] = propertyPPValue.convertAsAnyObject()
                        }
                        break;
                    }
                }
            }
        }
        return JSONDictionary
    }
    
    private func classForInstance(instance: AnyObject) -> PPJSONValueType {
        if instance.isKindOfClass(NSClassFromString("NSString")!) {
            return PPJSONValueType.String
        }
        else if instance.isKindOfClass(NSClassFromString("NSNumber")!) {
            return PPJSONValueType.Number
        }
        else if instance.isKindOfClass(NSClassFromString("NSArray")!) {
            return PPJSONValueType.Array
        }
        else if instance.isKindOfClass(NSClassFromString("NSDictionary")!) {
            return PPJSONValueType.Dictionary
        }
        else {
            return PPJSONValueType.Unknown
        }
    }
    
    private func propertyKeyFromJSONKey(JSONKey: AnyObject) -> String {
        let originJSONKey = stringObjectFromAnyObject(JSONKey) as String
        if let mappingPropertyKey = mapping()[originJSONKey] {
            return mappingPropertyKey
        }
        else {
            return originJSONKey
        }
    }
    
    private func numberObjectFromAnyObject(anyObject: AnyObject) -> NSNumber {
        if let transferString = anyObject as? String {
            if let transferNumber = NSNumberFormatter().numberFromString(transferString) {
                return transferNumber
            }
        }
        else if let transferNumber = anyObject as? NSNumber {
            return transferNumber
        }
        return 0
    }
    
    private func stringObjectFromAnyObject(anyObject: AnyObject) -> NSString {
        if let transferNumber = anyObject as? NSNumber {
            if let transferString = NSNumberFormatter().stringFromNumber(transferNumber) {
                return transferString
            }
        }
        else if let transferString = anyObject as? String {
            return transferString
        }
        return ""
    }
    
    private func resetEmptyArray() {
        let mirror = Mirror(reflecting: self);
        for child in mirror.children {
            if let key = child.label {
                if key == "super" {
                    continue
                }
                
                if let propertyValue: NSObject = valueForKey(key) as? NSObject {
                    if propertyValue.isKindOfClass(NSClassFromString("NSArray")!) {
                        if let _ = updatedKeys[key] {
                            //do nothing
                        }
                        else {
                            setValue(NSArray(), forKey: key)
                        }
                    }
                }

            }
        }
    }
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        return PPJSONSerialization()
    }
    
}
