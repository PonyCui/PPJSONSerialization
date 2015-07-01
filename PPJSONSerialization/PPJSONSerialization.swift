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
                    if let transferString = JSONObject as? String {
                        if let transferNumber = NSNumberFormatter().numberFromString(transferString) {
                            setValue(transferNumber, forKey: currentKey)
                        }
                    }
                }
                else if let _ = self.valueForKey(currentKey) as? Int {
                    if let transferString = JSONObject as? String {
                        if let transferNumber = NSNumberFormatter().numberFromString(transferString) {
                            setValue(transferNumber, forKey: currentKey)
                        }
                    }
                }
            }
            break
        case PPJSONValueType.Number:
            if let currentKey = theKey {
                if let _ = self.valueForKey(currentKey) as? String {
                    if let transferNumber = JSONObject as? NSNumber {
                        if let transferString = NSNumberFormatter().stringFromNumber(transferNumber) {
                            setValue(transferString, forKey: currentKey)
                        }
                    }
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
    
    func copyWithZone(zone: NSZone) -> AnyObject {
        return PPJSONSerialization()
    }
    
}
