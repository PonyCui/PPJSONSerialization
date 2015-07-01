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
    var myArray = [Int]()
    var myRooms = [RoomStruct()]
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
        demoObject.updateWithJSONString("{\"myString\":\"Hello, World!\",\"myInt\":8888.88,\"myBool\":true}")
        XCTAssert(demoObject.myString == "Hello, World!", "Pass")
        XCTAssert(demoObject.myInt == 8888, "Pass")
        XCTAssert(demoObject.myBool == true, "Pass")
    }
    
}
