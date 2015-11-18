//
//  PPJSONSerializationRecodedTests.swift
//  PPJSONSerialization
//
//  Created by 崔 明辉 on 15/10/14.
//  Copyright © 2015年 PonyCui. All rights reserved.
//

import XCTest

class OptionalTest: PPJSONSerialization {
    var optionalString: String? = nil
    var optionalInt: Int = 0 // Int is not allow to use optional type in PPJSONSerialization
    var optionalDouble: Double = 0 // Double is not allow to use optional type in PPJSONSerialization
    var optionalBool: Bool = false // Bool is not allow to use optional type in PPJSONSerialization
    var optionalNumber: NSNumber? = nil // If you really wonder to use optional, use NSNumber?
    
    override func reverseMapping() -> [String : String] {
        return ["optionalInt": "int"]
    }
    
}

class MultipleDimensionArray: PPJSONSerialization {
    var twoDimension = [[Int]]()
    var threeDimension = [[[Int]]]()
}

class DictionaryGeneric: PPJSONArraySerialization {
    var dict = [String: String]()
}

class CodeingStruct: PPJSONSerialization {
    
    var codeingDate: NSDate = NSDate()
    var optionalDate: NSDate? = nil
    
}

class DataModel {
    
    class Artist: PPJSONSerialization {
        var name: String?
        var mainSong = Song()
        var songs = [Song()]
        var mapSong = [".": Song()]
    }
    
    class Song: PPJSONSerialization {
        var name: String?
        var duration: Double = 0.0
    }
    
}

class CommonResponse: PPJSONSerialization {
    var error: String?
}

class ArtistResponse: CommonResponse {
    var name: String?
    var mainSong = DataModel.Song()
    var songs = [DataModel.Song()]
    var mapSong = [".": DataModel.Song()]
}

extension NSDate: PPCoding {
    
    func encodeAsPPObject() -> AnyObject? {
        return timeIntervalSince1970
    }
    
    func decodeWithPPObject(PPObject: AnyObject) -> AnyObject? {
        if let timestamp = PPObject as? NSTimeInterval {
            return NSDate(timeIntervalSince1970: timestamp)
        }
        return nil
    }
    
}

class PPJSONSerializationRecodedTests: XCTestCase {
    
    let nullJSON = ""
    
    let nullDictionaryJSON = "{}"
    
    let optionalStringJSON = "{\"optionalString\": \"Hello, World\"}"
    
    let optionalIntJSON = "{\"optionalInt\": \"123\"}"
    
    let optionalDoubleJSON = "{\"optionalDouble\": \"123\"}"
    
    let optionalBoolJSON = "{\"optionalBool\": \"1\"}"
    
    let optionalNumberJSON = "{\"optionalNumber\": \"123\"}"
    
    let intJSON = "{\"int\": \"123\"}"
    
    let twoDimensionArrayJSON = "{\"twoDimension\": [[1,0,2,4], [1,0,2,4]]}"
    
    let threeDimensionArrayJSON = "{\"threeDimension\": [[[1,0,2,4]]]}"
    
    let dictionaryGenericJSON = "{\"dict\":{\"hello\": \"world\", \"1\":123123}}"
    
    let codingDateJSON = "{\"codeingDate\":1444885037, \"optionalDate\":1444885037}"
    
    func testOptional() {
        XCTAssert(OptionalTest(JSONString: nullJSON) == nil, "Pass")
        if let test = OptionalTest(JSONString: nullDictionaryJSON) {
            XCTAssert(test.optionalString == nil, "Pass")
            XCTAssert(test.optionalNumber == nil, "Pass")
        }
        else {
            XCTAssert(false, "Failed")
        }
        if let test = OptionalTest(JSONString: optionalStringJSON) {
            XCTAssert(test.optionalString == "Hello, World", "Pass")
        }
        else {
            XCTAssert(false, "Failed")
        }
        if let test = OptionalTest(JSONString: optionalIntJSON) {
            XCTAssert(test.optionalInt == 123, "Pass")
        }
        else {
            XCTAssert(false, "Failed")
        }
        if let test = OptionalTest(JSONString: optionalDoubleJSON) {
            XCTAssert(test.optionalDouble == 123.0, "Pass")
        }
        else {
            XCTAssert(false, "Failed")
        }
        if let test = OptionalTest(JSONString: optionalBoolJSON) {
            XCTAssert(test.optionalBool == true, "Pass")
        }
        else {
            XCTAssert(false, "Failed")
        }
        if let test = OptionalTest(JSONString: optionalNumberJSON) {
            XCTAssert(test.optionalNumber?.doubleValue == 123.0, "Pass")
        }
        else {
            XCTAssert(false, "Failed")
        }
    }
    
    func testMapping() {
        if let test = OptionalTest(JSONString: intJSON) {
            XCTAssert(test.optionalInt == 123, "Pass")
        }
        else {
            XCTAssert(false, "Failed")
        }
    }
    
    func testDimensionArray() {
        if let test = MultipleDimensionArray(JSONString: twoDimensionArrayJSON) {
            XCTAssert(test.twoDimension[0][0] == 1, "Pass")
            XCTAssert(test.twoDimension[0][1] == 0, "Pass")
            XCTAssert(test.twoDimension[0][2] == 2, "Pass")
            XCTAssert(test.twoDimension[0][3] == 4, "Pass")
            XCTAssert(test.twoDimension[1][0] == 1, "Pass")
            XCTAssert(test.twoDimension[1][1] == 0, "Pass")
            XCTAssert(test.twoDimension[1][2] == 2, "Pass")
            XCTAssert(test.twoDimension[1][3] == 4, "Pass")
        }
        else {
            XCTAssert(false, "Failed")
        }
        if let test = MultipleDimensionArray(JSONString: threeDimensionArrayJSON) {
            XCTAssert(test.threeDimension[0][0][0] == 1, "Pass")
            XCTAssert(test.threeDimension[0][0][1] == 0, "Pass")
            XCTAssert(test.threeDimension[0][0][2] == 2, "Pass")
            XCTAssert(test.threeDimension[0][0][3] == 4, "Pass")
        }
        else {
            XCTAssert(false, "Failed")
        }
    }
    
    func testDictionaryGeneric() {
        if let test = DictionaryGeneric(JSONString: dictionaryGenericJSON) {
            XCTAssert(test.dict["hello"] == "world", "Pass")
            XCTAssert(test.dict["1"] == "123123", "Pass")
        }
        else {
            XCTAssert(false, "Failed")
        }
    }
    
    func testCodeing() {
        if let test = CodeingStruct(JSONString: codingDateJSON) {
            XCTAssert(test.codeingDate.description == "2015-10-15 04:57:17 +0000", "Pass")
            if let date = test.optionalDate {
                XCTAssert(date.description == "2015-10-15 04:57:17 +0000", "Pass")
            }
        }
    }
    
    func testChainning() {
        
        let JSONString = "{\"name\": \"Pony Cui\", \"mainSong\": {\"name\":\"Love Song\", \"duration\": 168.0}, \"songs\": [{\"name\":\"Love Song\", \"duration\": 168.0}], \"mapSong\": {\"sampleKey\": {\"name\":\"Love Song\", \"duration\": 168.0}}}"
        
        if let test = DataModel.Artist(JSONString: JSONString) {
            XCTAssert(test.name! == "Pony Cui", "Pass")
            XCTAssert(test.mainSong.name == "Love Song", "Pass")
            XCTAssert(test.mainSong.duration == 168.0, "Pass")
            XCTAssert(test.songs[0].name == "Love Song", "Pass")
            XCTAssert(test.songs[0].duration == 168.0, "Pass")
            XCTAssert(test.mapSong["sampleKey"]?.name == "Love Song", "Pass")
            XCTAssert(test.mapSong["sampleKey"]?.duration == 168.0, "Pass")
        }
        else {
            XCTAssert(false, "Failed")
        }
    }
    
    func testObject() {
        let JSONString = "{\"name\": \"Pony Cui\", \"mainSong\": {\"name\":\"Love Song\", \"duration\": 168.0}, \"songs\": [{\"name\":\"Love Song\", \"duration\": 168.0}], \"mapSong\": {\"sampleKey\": {\"name\":\"Love Song\", \"duration\": 168.0}}}"
        let JSONObject = try! NSJSONSerialization.JSONObjectWithData(JSONString.dataUsingEncoding(NSUTF8StringEncoding)!, options: [])
        let test = DataModel.Artist(JSONObject: JSONObject)
        XCTAssert(test.name! == "Pony Cui", "Pass")
        XCTAssert(test.mainSong.name == "Love Song", "Pass")
        XCTAssert(test.mainSong.duration == 168.0, "Pass")
        XCTAssert(test.songs[0].name == "Love Song", "Pass")
        XCTAssert(test.songs[0].duration == 168.0, "Pass")
        XCTAssert(test.mapSong["sampleKey"]?.name == "Love Song", "Pass")
        XCTAssert(test.mapSong["sampleKey"]?.duration == 168.0, "Pass")
    }
    
    func testSubclass() {
        let JSONString = "{\"error\":\"404 not found!\"}"
        let JSONObject = try! NSJSONSerialization.JSONObjectWithData(JSONString.dataUsingEncoding(NSUTF8StringEncoding)!, options: [])
        let test = ArtistResponse(JSONObject: JSONObject)
        XCTAssert(test.error == "404 not found!", "Pass")
    }
    
    func testSubclassII() {
        let JSONString = "{\"name\": \"Pony Cui\", \"mainSong\": {\"name\":\"Love Song\", \"duration\": 168.0}, \"songs\": [{\"name\":\"Love Song\", \"duration\": 168.0}], \"mapSong\": {\"sampleKey\": {\"name\":\"Love Song\", \"duration\": 168.0}}}"
        let JSONObject = try! NSJSONSerialization.JSONObjectWithData(JSONString.dataUsingEncoding(NSUTF8StringEncoding)!, options: [])
        let test = ArtistResponse(JSONObject: JSONObject)
        XCTAssert(test.name! == "Pony Cui", "Pass")
        XCTAssert(test.mainSong.name == "Love Song", "Pass")
        XCTAssert(test.mainSong.duration == 168.0, "Pass")
        XCTAssert(test.songs[0].name == "Love Song", "Pass")
        XCTAssert(test.songs[0].duration == 168.0, "Pass")
        XCTAssert(test.mapSong["sampleKey"]?.name == "Love Song", "Pass")
        XCTAssert(test.mapSong["sampleKey"]?.duration == 168.0, "Pass")
    }
    
}
