# PPJSONSerialization [中文介绍](https://github.com/PonyCui/PPJSONSerialization/wiki)

## Introduce
There's a library, he make everything easier, faster, and safer.

It's a library, which handles all JSON operation in one class.

As we known, the JSON result always or sometimes make our app crash, because we don't even know that JSON data is completely correct. And we have Swift now! Swift is completely strong type and type safe. So, why should we still using Objective-C and Other JSON library?

## Usage

### Easy Startup

* Just add ```PPJSONSerialization.swift``` to project (I'm not planning to publish it to CocoaPods, it's a tiny library.)

* Create your own class and subclass PPJSONSerialization

```swift
class Artist: PPJSONSerialization {
  var name: String?
  var height: Double = 0.0
}
```

* Fetch data from network and create an instance of your own class

```swift
let mockString = "{\"name\": \"Pony Cui\", \"height\": 164.0}"
let artistData = Artist(JSONString: mockString)
```

* Now, you can use it briefly
```swift
if let artistData = Artist(JSONString: mockString) {
  print(artistData.name)
  print(artistData.height)
}
```

### Features

#### Type transfer

Remember we set ```height``` as ```Double``` in ```Artist``` Classes?

If the JSON type is in-correct, the most library will discard the result, or gives you an error message.

But PPJSONSerialization will try to convert it to ```Double```

For example
```swift
let mockString = "{\"name\": \"Pony Cui\", \"height\": \"164.0\"}" //height is a string value
if let artistData = Artist(JSONString: mockString) {
  print(artistData.name)
  print(artistData.height) // Now it convert to Double, print 164.0
}
```

Type transfer now applys on string, double, int, bool

#### Optional value

The best feature in Swift is optional, PPJSONSerialization also support it.

```swift
class Artist: PPJSONSerialization {
  var name: String? // We define it as a optional value
  var height: Double = 0.0
}

let mockString = "{\"height\": \"164.0\"}"

if let artistData = Artist(JSONString: mockString) {
    if let name = artistData.name {
        print(name) // code will not execute, because the mockString doesn't contains name column.
    }
}
```

#### Null crash or Invalid JSON

Never worry about that, the failable init will gives you the opportunity deal with that. Null value will never never never set to instance.

#### Array Generic support

The swift array always request a generic type define, you can't store another type in it. But JSON can! That's not an easy working while we using Objective-C.

PPJSONSerialization will handle this.

For example, you define a property ```friends```, all its member is ```String``` value.

```swift
class Artist: PPJSONSerialization {
    var name: String?
    var height: Double = 0.0
    var friends = [String]()
}
```

Just use it as below, note that we have 3 invalid types, but PPJSONSerialization will convert it.

```swift
let mockString = "{\"friends\": [\"Jack\", \"Leros\", \"Max\", \"LGY\", 1, 2, 3]}"

if let artistData = Artist(JSONString: mockString) {
    for friend in artistData.friends {
        print(friend)
    }
}

/*
Prints:
Jack
Leros
Max
LGY
1
2
3
*/
```

#### Dictionary Generic support

The dictionary generic is also support as Array. But I strongly recommend you use Sub-Struct to deal with Dictionary.

```swift
class Artist: PPJSONSerialization {
    var name: String?
    var height: Double = 0.0
    var friendsHeight = [String: Double]() // now we change it as dictionary
}

let mockString = "{\"friendsHeight\": {\"Jack\": 170, \"Leros\": 180, \"Max\": 168, \"LGY\": 177}}"

if let artistData = Artist(JSONString: mockString) {
    for (friend, height) in artistData.friendsHeight {
        print("\(friend), height:\(height)")
    }
}

/*
Prints:
Leros, height:180.0
Max, height:168.0
LGY, height:177.0
Jack, height:170.0
*/
```

#### Custom Type (Sub-Struct)

There's a really common situation is a dictionary contains another dictionary, you can use Dictionary Generic handle this, right? But, if you eager the model much easier to manage, or much pettier. Custom Type is really important for you.

Note: Custom Type can use in Dictionary/Array/Property either.

```swift
class Artist: PPJSONSerialization {
    var name: String?
    var height: Double = 0.0
    var friends = [ArtistFriend]()
}

// The Sub-Struct either subclasses PPJSONSerialization
class ArtistFriend: PPJSONSerialization {
    var name: String?
    var height: Double = 0.0
}

let mockString = "{\"friends\": [{\"name\": \"Jack\", \"height\": \"177.0\"}, {\"name\": \"Max\", \"height\": \"188.0\"}]}"

if let artistData = Artist(JSONString: mockString) {
    for friend in artistData.friends {
        print("\(friend.name), height:\(friend.height)")
    }
}

/*
Prints:
Optional("Jack"), height:177.0
Optional("Max"), height:188.0
*/
```

#### Array JSON

If the JSON is an array base struct. You should subclass ```PPJSONArraySerialization```, and define a property ```root``` with generic type.

```swift
class ArrayStruct: PPJSONArraySerialization {
    var root = [Int]()
}

let arrayJSON = "[1,0,2,4]"
if let arrayObject = ArrayStruct(JSONString: arrayJSON) {
  XCTAssert(arrayObject.root.count == 4, "Pass")
  XCTAssert(arrayObject.root[0] == 1, "Pass")
  XCTAssert(arrayObject.root[1] == 0, "Pass")
  XCTAssert(arrayObject.root[2] == 2, "Pass")
  XCTAssert(arrayObject.root[3] == 4, "Pass")
}
```

#### Multiple Dimension Array

If the array contains array, it should define like this.

```swift
class MultipleDimensionArray: PPJSONSerialization {
    var twoDimension = [[Int]]()
    var threeDimension = [[[Int]]]()
}

let twoDimensionArrayJSON = "{\"twoDimension\": [[1,0,2,4], [1,0,2,4]]}"

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

```

#### Key Mapping

Sometimes, network data key column is different to app's, there's relly simple way to handle this. Override the mapping method, and return a dictionary contains ["JSONKey": "PropertyKey"]

```
class Artist: PPJSONSerialization {
    var name: String = ""
    var height: Double = 0.0

    override func mapping() -> [String : String] {
        return ["xxxname": "name"]
    }
}

let mockString = "{\"xxxname\": \"Pony Cui\"}"

if let artistData = Artist(JSONString: mockString) {
    print(artistData.name)
}

```

#### Serialize

You use serialize to serialize PPJSONSerialization classes to JSON String or JSON Data, it's a perfect way to deliver data to server.

```swift
class Artist: PPJSONSerialization {
    var name: String = "" // ~~~Note that, optional value is not serialize to string always!~~~
    var height: Double = 0.0
}

let artistData = Artist()
artistData.name = "Pony Cui"
artistData.height = 164.0
let string = artistData.JSONString()
print(string)

/*
Prints: {"name":"Pony Cui","height":164}
*/

```

PPJSONSerialization is still in development, welcome to improve the project together.

## Requirements
* iOS 7.0+ / Mac OS X 10.10+
* Xcode 7.0
* Swift 2.0

## Integration
Add ```PPJSONSerialization.swift``` into your project, that's enough

## License
MIT License, Please feel free to use it.

## Thanks
* Thanks for @onevcat suggest use Failable init.
* Thanks for @neil-wu using and reported issues.
