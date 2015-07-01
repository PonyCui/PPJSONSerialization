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
    
    internal func updateWithJSONString(JSONString: String) -> Bool {
        if let data = JSONString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            if let JSONObject: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) {
                return updateWithJSONObject(JSONObject, theKey: nil)
            }
            else {
                return false
            }
        }
        else {
            return false
        }
    }
    
    private func updateWithJSONObject(JSONObject: AnyObject, theKey: String?) -> Bool {
        switch classForInstance(JSONObject) {
        case PPJSONValueType.String:
            if let currentKey = theKey {
                if let _ = self.valueForKey(currentKey) as? String {
                    setValue(JSONObject, forKeyPath: currentKey)
                }
                else if let _ = self.valueForKey(currentKey) as? Double {
                    setValue(numberObjectFromAnyObject(JSONObject), forKey: currentKey)
                }
                else if let _ = self.valueForKey(currentKey) as? Int {
                    setValue(numberObjectFromAnyObject(JSONObject), forKey: currentKey)
                }
            }
            break
        case PPJSONValueType.Number:
            if let currentKey = theKey {
                if let _ = self.valueForKey(currentKey) as? String {
                    setValue(stringObjectFromAnyObject(JSONObject), forKey: currentKey)
                }
                else if let _ = self.valueForKey(currentKey) as? Double {
                    setValue(JSONObject, forKey: currentKey)
                }
                else if let _ = self.valueForKey(currentKey) as? Int {
                    setValue(JSONObject, forKey: currentKey)
                }
            }
            break
        case PPJSONValueType.Array:
            if let currentKey = theKey {
                if let currentArray = self.valueForKey(currentKey) as? NSArray {
                    if let tplObject: AnyObject = currentArray.lastObject {
                        var arrayWithData = NSMutableArray()
                        if tplObject.isKindOfClass(NSClassFromString("NSNumber")) {
                            if let currentObject: NSArray = JSONObject as? NSArray {
                                for currentItem in currentObject {
                                    arrayWithData.addObject(numberObjectFromAnyObject(currentItem))
                                }
                            }
                        }
                        else if tplObject.isKindOfClass(NSClassFromString("NSString")) {
                            if let currentObject: NSArray = JSONObject as? NSArray {
                                for currentItem in currentObject {
                                    arrayWithData.addObject(stringObjectFromAnyObject(currentItem))
                                }
                            }
                        }
                        else {
                            if tplObject.respondsToSelector("copy") {
                                if let currentObject: NSArray = JSONObject as? NSArray {
                                    for currentItem in currentObject {
                                        if let mirrorObject: PPJSONSerialization = tplObject.copy() as? PPJSONSerialization {
                                            mirrorObject.updateWithJSONObject(currentItem, theKey: currentKey)
                                            arrayWithData.addObject(mirrorObject)
                                        }
                                    }
                                }
                            }
                        }
                        setValue(arrayWithData, forKey: currentKey)
                        break
                    }
                }
            }
            break
        case PPJSONValueType.Dictionary:
            let theDictionary: NSDictionary! = JSONObject as? NSDictionary
            for (theKey, theValue) in theDictionary {
                if let objKey = theKey as? String {
                    updateWithJSONObject(theValue, theKey: objKey)
                }
            }
            break
        default:
            break
        }
        return false
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
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        return PPJSONSerialization()
    }
    
}
