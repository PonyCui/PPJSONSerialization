//
//  PPJSONSerializationTests.swift
//  PPJSONSerializationTests
//
//  Created by 崔 明辉 on 15/6/30.
//  Copyright (c) 2015年 PonyCui. All rights reserved.
//

import UIKit
import XCTest

class RoomStruct: PPJSONSerialization {
    var roomID: String = ""
    
    override func copyWithZone(zone: NSZone) -> AnyObject {
        return RoomStruct()
    }
    
}

class DemoStruct: PPJSONSerialization {
    var myString = ""
    var myInt = 0
    var myBool = false
    var myArray = [0.0]
    var myStringArray = [""]
    var myRooms = [RoomStruct()]
    
    override init() {
        super.init()
        JSONMap["myStringArray"] = "myArray"
    }
    
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
    
    func testParser() {
        
        let demoObject = DemoStruct()
        demoObject.updateWithJSONString("{\"myString\":\"Hello, World!\",\"myInt\":8888.88,\"myBool\":true,\"myArray\":[1,2,3],\"myRooms\":[{\"roomID\":\"1\"}]}")
        XCTAssert(demoObject.myString == "Hello, World!", "Pass")
        XCTAssert(demoObject.myInt == 8888, "Pass")
        XCTAssert(demoObject.myBool == true, "Pass")
        XCTAssert(demoObject.myArray[0] == 1, "Pass")
        XCTAssert(demoObject.myArray[1] == 2, "Pass")
        XCTAssert(demoObject.myArray[2] == 3, "Pass")
//        XCTAssert(demoObject.myArray[0] == "1", "Pass")
//        XCTAssert(demoObject.myArray[1] == "2", "Pass")
//        XCTAssert(demoObject.myArray[2] == "3", "Pass")
        XCTAssert(demoObject.myRooms[0].roomID == "1", "Pass")

    }
    
}
