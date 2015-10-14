//
//  PPJSONSerializationTests.swift
//  PPJSONSerializationTests
//
//  Created by 崔 明辉 on 15/6/30.
//  Copyright (c) 2015年 PonyCui. All rights reserved.
//

import UIKit
import XCTest

// Define a Simple Struct;
// Be careful, All Struct are not support dictionary type;
// All properties must provide default value and type.
class SimpleStruct: PPJSONSerialization {
    var simpleStr = ""
    var simpleInt = 0
    var simpleBool:Bool = false
    var simpleDouble = 0.0
    var simpleArray = [Int]()
}

// Define an Array Struct to deal with the array JSON
class ArrayStruct: PPJSONArraySerialization {
    var root = [Int]()
}

// Define a Building Struct to deal with dictionary contains JSON
class BuildingStruct: PPJSONSerialization {
    var buildNumber = ""
    var managementRoom = RoomStruct()
    var buildRooms = [RoomStruct()]
}

// Define a Room Struct to handle sub dictionary JSON
class RoomStruct: PPJSONSerialization {
    var roomNumber = 0
    var roomSize: Double = 0.0
    var roomMates = [""]
    
    // If Struct contains in array, you must override copyWithZone func and return RoomStruct instance.
//    override func copyWithZone(zone: NSZone) -> AnyObject {
//        return RoomStruct()
//    }
}

// Define a Map Struct and override mapping() return, you can map the JSON key to Custom Property key
class MapStruct: PPJSONSerialization {
    override func mapping() -> [String : String] {
        return ["mapStr": "simpleStr"]
    }
    
    var simpleStr = ""
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

    func testErrorJSON() {
        let errorJSON = "I have a dream!"
        XCTAssert(SimpleStruct(JSONString: errorJSON) == nil, "Pass")
    }
    
    func testSimpleParser() {
        
        let simpleJSON = "{\"simpleStr\":\"String Value\", \"simpleInt\":1024, \"simpleBool\": true, \"simpleDouble\": 1024.00, \"simpleArray\": [1,0,2,4], \"doubleArray\": [[1,0,2,4]], \"doubleDoubleArray\": [[1,0,2,4]], \"doubleStringArray\": [[\"1\",\"0\",\"2\",\"4\"]], \"simpleRoom\":{\"test\":{\"roomNumber\":632, \"roomSize\":6.6}}}"
        if let simpleObject = SimpleStruct(JSONString: simpleJSON) {
            XCTAssert(simpleObject.simpleStr == "String Value", "Pass")
            XCTAssert(simpleObject.simpleInt == 1024, "Pass")
            XCTAssert(simpleObject.simpleBool == true, "Pass")
            XCTAssert(simpleObject.simpleDouble == 1024.00, "Pass")
            XCTAssert(simpleObject.simpleArray[0] == 1, "Pass")
            XCTAssert(simpleObject.simpleArray[1] == 0, "Pass")
            XCTAssert(simpleObject.simpleArray[2] == 2, "Pass")
            XCTAssert(simpleObject.simpleArray[3] == 4, "Pass")
        }
        else {
            XCTAssert(false, "JSON Parser Failable")
        }
    }

    func testTypeTransfer() {
        let typeErrorJSON = "{\"simpleStr\": 1024, \"simpleInt\": \"1024\", \"simpleBool\": null, \"simpleDouble\": \"Bool Value\", \"simpleArray\": {}}"
        if let simpleObject = SimpleStruct(JSONString: typeErrorJSON) {
            XCTAssert(simpleObject.simpleStr == "1024", "Pass")
            XCTAssert(simpleObject.simpleInt == 1024, "Pass")
            XCTAssert(simpleObject.simpleBool == false, "Pass")
            XCTAssert(simpleObject.simpleDouble == 0.0, "Pass")
            XCTAssert(simpleObject.simpleArray.count <= 0, "Pass")
        }
        else {
            XCTAssert(false, "JSON Parser Failable")
        }
    }
    
    func testArrayJSON() {
        let arrayJSON = "[1,0,2,4]"
        if let arrayObject = ArrayStruct(JSONString: arrayJSON) {
            XCTAssert(arrayObject.root.count == 4, "Pass")
            XCTAssert(arrayObject.root[0] == 1, "Pass")
            XCTAssert(arrayObject.root[1] == 0, "Pass")
            XCTAssert(arrayObject.root[2] == 2, "Pass")
            XCTAssert(arrayObject.root[3] == 4, "Pass")
        }
        else {
            XCTAssert(false, "JSON Parser Failable")
        }
    }
    
    func testDictionaryContainsJSON() {
        let dictionaryContainsJSON = "{\"buildNumber\": \"B\", \"managementRoom\":{\"roomNumber\":101, \"roomSize\":10.14}, \"buildRooms\":[{\"roomNumber\":632, \"roomSize\":6.6}, {\"roomNumber\":633, \"roomSize\":6.7}]}"
        if let buildingObject = BuildingStruct(JSONString: dictionaryContainsJSON) {
            XCTAssert(buildingObject.buildNumber == "B", "Pass")
            XCTAssert(buildingObject.managementRoom.roomNumber == 101, "Pass")
            XCTAssert(buildingObject.managementRoom.roomSize == 10.14, "Pass")
            XCTAssert(buildingObject.buildRooms.count == 2, "Pass")
            XCTAssert(buildingObject.buildRooms[0].roomNumber == 632, "Pass")
            XCTAssert(buildingObject.buildRooms[0].roomSize == 6.6, "Pass")
            XCTAssert(buildingObject.buildRooms[1].roomNumber == 633, "Pass")
            XCTAssert(buildingObject.buildRooms[1].roomSize == 6.7, "Pass")
        }
        else {
            XCTAssert(false, "JSON Parser Failable")
        }
    }
    
    func testAsyncParse() {
        let simpleJSON = "{\"simpleStr\":\"String Value\", \"simpleInt\":1024, \"simpleBool\": true, \"simpleDouble\": 1024.00, \"simpleArray\": [1,0,2,4]}"
        
        let simpleObject = SimpleStruct()
        simpleObject.updateWithJSONString(simpleJSON, closure: { (isSucceed) -> Void in
            if isSucceed {
                XCTAssert(simpleObject.simpleStr == "String Value", "Pass")
                XCTAssert(simpleObject.simpleInt == 1024, "Pass")
                XCTAssert(simpleObject.simpleBool == true, "Pass")
                XCTAssert(simpleObject.simpleDouble == 1024.00, "Pass")
                XCTAssert(simpleObject.simpleArray[0] == 1, "Pass")
                XCTAssert(simpleObject.simpleArray[1] == 0, "Pass")
                XCTAssert(simpleObject.simpleArray[2] == 2, "Pass")
                XCTAssert(simpleObject.simpleArray[3] == 4, "Pass")
            }
            else {
                XCTAssert(false, "JSON Parser Failable")
            }
        })
        
        NSRunLoop.currentRunLoop().runUntilDate(NSDate().dateByAddingTimeInterval(1.0))
    }
    
    func testMapping() {
        let simpleJSON = "{\"mapStr\": \"String Value\"}"
        if let simpleObject = MapStruct(JSONString: simpleJSON) {
            XCTAssert(simpleObject.simpleStr == "String Value", "Pass")
        }
        else {
            XCTAssert(false, "JSON Parser Failable")
        }
    }
    
    func testEmptyArray() {
        let simpleJSON = "{}"
        if let simpleObject = SimpleStruct(JSONString: simpleJSON) {
            XCTAssert(simpleObject.simpleArray.count == 0, "Pass")
        }
        if let arrayObject = ArrayStruct(JSONString: simpleJSON) {
            XCTAssert(arrayObject.root.count == 0, "Pass")
        }
        if let buildingObject = BuildingStruct(JSONString: simpleJSON) {
            XCTAssert(buildingObject.buildRooms.count == 0, "Pass")
        }
        if let buildingObject = BuildingStruct(JSONString: "{\"buildRooms\":[{}]}") {
            XCTAssert(buildingObject.buildRooms[0].roomMates.count == 0, "Pass")
        }
    }
    
    // The following test is serialize function
    
    func testSimpleSerialize() {
//        let simpleObject = SimpleStruct()
//        simpleObject.simpleStr = "String Value"
//        simpleObject.simpleBool = true
//        simpleObject.simpleInt = 1024
//        simpleObject.simpleDouble = 1024.01
//        simpleObject.simpleArray = [1, 0, 2, 4]
//        let JSONString = simpleObject.JSONString()
//        XCTAssert((JSONString as NSString).containsString("\"simpleStr\":\"String Value\""), "Pass")
//        XCTAssert((JSONString as NSString).containsString("\"simpleBool\":true"), "Pass")
//        XCTAssert((JSONString as NSString).containsString("\"simpleInt\":1024"), "Pass")
//        XCTAssert((JSONString as NSString).containsString("\"simpleDouble\":1024.01"), "Pass")
//        XCTAssert((JSONString as NSString).containsString("\"simpleArray\":[1,0,2,4]"), "Pass")
    }
    
    func testArraySerialize() {
//        let arrayObject = ArrayStruct()
//        arrayObject.root = [1, 0, 2, 4]
//        XCTAssert(arrayObject.JSONString() == "[1,0,2,4]", "Pass")
    }
    
    func testBuildingSerialize() {
//        let buildingObject = BuildingStruct()
//        buildingObject.buildNumber = "B"
//        buildingObject.managementRoom.roomNumber = 101
//        buildingObject.managementRoom.roomSize = 10.14
//        buildingObject.managementRoom.roomMates = ["Pony", "Chunge"]
//        buildingObject.buildRooms = []
//        let roomObjectA = RoomStruct()
//        roomObjectA.roomNumber = 632
//        roomObjectA.roomSize = 6.6
//        roomObjectA.roomMates = ["Lin", "Zeng"]
//        buildingObject.buildRooms.append(roomObjectA)
//        let roomObjectB = RoomStruct()
//        roomObjectB.roomNumber = 633
//        roomObjectB.roomSize = 7.6
//        roomObjectB.roomMates = ["Sun"]
//        buildingObject.buildRooms.append(roomObjectB)
//        let JSONString = buildingObject.JSONString()
//        XCTAssert(JSONString == "{\"buildNumber\":\"B\",\"managementRoom\":{\"roomSize\":10.14,\"roomNumber\":101,\"roomMates\":[\"Pony\",\"Chunge\"]},\"buildRooms\":[{\"roomSize\":6.6,\"roomNumber\":632,\"roomMates\":[\"Lin\",\"Zeng\"]},{\"roomSize\":7.6,\"roomNumber\":633,\"roomMates\":[\"Sun\"]}]}", "Pass")
    }
    
}
