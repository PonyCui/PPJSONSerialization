//
//  PPJSONSerializationTests.swift
//  PPJSONSerializationTests
//
//  Created by 崔 明辉 on 15/6/30.
//  Copyright (c) 2015年 PonyCui. All rights reserved.
//

import UIKit
import XCTest

// Define a Simple Struct
// Be careful, All Struct are not support dictionary type
class SimpleStruct: PPJSONSerialization {
    var simpleStr = ""
    var simpleInt = 0
    var simpleBool = false
    var simpleDouble = 0.0
    var simpleArray = [0]
}

class PPJSONSerializationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSimpleParser() {
        let simpleJSON = "{\"simpleStr\":\"String Value\", \"simpleInt\":1024, \"simpleBool\": true, \"simpleDouble\": 1024.00, \"simpleArray\": [1,0,2,4]}"
        let simpleObject = SimpleStruct(JSONString: simpleJSON)
        XCTAssert(simpleObject.simpleStr == "String Value", "Pass")
        XCTAssert(simpleObject.simpleInt == 1024, "Pass")
        XCTAssert(simpleObject.simpleBool == true, "Pass")
        XCTAssert(simpleObject.simpleDouble == 1024.00, "Pass")
        XCTAssert(simpleObject.simpleArray[0] == 1, "Pass")
        XCTAssert(simpleObject.simpleArray[1] == 0, "Pass")
        XCTAssert(simpleObject.simpleArray[2] == 2, "Pass")
        XCTAssert(simpleObject.simpleArray[3] == 4, "Pass")
    }
    
    func testTypeTransfer() {
        let typeErrorJSON = "{\"simpleStr\": 1024, \"simpleInt\": \"1024\", \"simpleBool\": null, \"simpleDouble\": \"Bool Value\", \"simpleArray\": {}}"
        let simpleObject = SimpleStruct(JSONString: typeErrorJSON)
        XCTAssert(simpleObject.simpleStr == "1024", "Pass")
        XCTAssert(simpleObject.simpleInt == 1024, "Pass")
        XCTAssert(simpleObject.simpleBool == false, "Pass")
        XCTAssert(simpleObject.simpleDouble == 0.0, "Pass")
    }
    
}
