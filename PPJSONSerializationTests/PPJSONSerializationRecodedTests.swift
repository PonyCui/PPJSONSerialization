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
    
    func testOptional() {
        XCTAssert(OptionalTest(JSONString: nullJSON) == nil, "Pass")
        if let test = OptionalTest(JSONString: nullDictionaryJSON) {
            XCTAssert(test.optionalString == nil, "Pass")
            XCTAssert(test.optionalNumber == nil, "Pass")
        }
        if let test = OptionalTest(JSONString: optionalStringJSON) {
            XCTAssert(test.optionalString == "Hello, World", "Pass")
        }
        if let test = OptionalTest(JSONString: optionalIntJSON) {
            XCTAssert(test.optionalInt == 123, "Pass")
        }
        if let test = OptionalTest(JSONString: optionalDoubleJSON) {
            XCTAssert(test.optionalDouble == 123.0, "Pass")
        }
        if let test = OptionalTest(JSONString: optionalBoolJSON) {
            XCTAssert(test.optionalBool == true, "Pass")
        }
        if let test = OptionalTest(JSONString: optionalNumberJSON) {
            XCTAssert(test.optionalNumber?.doubleValue == 123.0, "Pass")
        }
    }
    
    func testMapping() {
        if let test = OptionalTest(JSONString: intJSON) {
            XCTAssert(test.optionalInt == 123, "Pass")
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
        if let test = MultipleDimensionArray(JSONString: threeDimensionArrayJSON) {
            XCTAssert(test.threeDimension[0][0][0] == 1, "Pass")
            XCTAssert(test.threeDimension[0][0][1] == 0, "Pass")
            XCTAssert(test.threeDimension[0][0][2] == 2, "Pass")
            XCTAssert(test.threeDimension[0][0][3] == 4, "Pass")
        }
    }
    
}
