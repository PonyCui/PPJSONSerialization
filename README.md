# PPJSONSerialization
PPJSONSerialization is a Swift JSON Helper Library, it helps you to convert JSON string to Swift Class.

Thanks for SwiftyJSON(https://github.com/SwiftyJSON/SwiftyJSON) brings a great way to deal with JSON, and it's convenience for us.

The way you use SwiftyJSON like this.

```swift
let json = JSON(data: dataFromNetworking)
if let userName = json[0]["user"]["name"].string{
  //Now you got your value
}
```

In my opinion, Apple gaves us a strong type language, why should we still using the old type (Obj-C) codeing?

So, the way you use PPJSONSerialization may like this

```swift
// Define a Simple Struct;
// Be careful, All Struct are not support dictionary type;
// All properties must provide default value and type.
class SimpleStruct: PPJSONSerialization {
    var simpleStr = ""
    var simpleInt = 0
    var simpleBool = false
    var simpleDouble = 0.0
    var simpleArray = [0]
}

let simpleJSON = "{\"simpleStr\":\"String Value\", \"simpleInt\":1024, \"simpleBool\": true, \"simpleDouble\": 1024.00, \"simpleArray\": [1,0,2,4]}"
let simpleObject = SimpleStruct(JSONString: simpleJSON)
print(simpleObject.simpleStr) // Use the JSON value as an object
```
