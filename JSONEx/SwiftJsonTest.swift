//
//  SwiftJsonTest.swift
//  JSONEx
//
//  Created by yangyi on 2018/4/10.
//  Copyright © 2018年 yangyi. All rights reserved.
//

import Foundation

@objcMembers class ProductInfo: NSObject {
    var name: String?
    var model: String?
}

@objcMembers class PhoneInfo: ProductInfo {
    var capacity: Int = 0
}

@objc enum OrderState: Int {
    case created = 1
    case completed = 2
    case canceled = 3
}

@objcMembers class OrderInfo: NSObject, JSONEx {
    var state: OrderState = .created
    var ID: String?
    var count: Int = 0
    var product: ProductInfo?
    
    static func customPropertyNameForKeys() -> [String : String] {
        return ["ID": "id"]
    }
}

@objcMembers class Student: NSObject {
    var name: String?
    var age: Int = 0
}

@objcMembers class School: NSObject, JSONEx {
    var address: String?
    var students: [Student] = []
    
    static func arrayPropertyItemClasses() -> [String : String] {
        return ["students": "JSONEx.Student"]
    }
}

@objc class SwiftJsonTest:NSObject {
    
    //测试模型继承的情况
    class func jsonToModel1() {
        let dic: [String: Any] = ["name": "iPhone X", "model": "MQA52CH/A", "capacity": 64]
        let obj: PhoneInfo = PhoneInfo(dictionary: dic)
        print(obj.name!)
        print("\(obj.capacity)G")
    }
    
    //测试枚举，自定义类型属性，和属性名映射的情况
    class func jsonToModel2() {
        let jsonString: String = "{\"state\":2,\"id\":\"wefehjrbncafdgasgs\",\"product\":{\"name\":\"iPhone X\",\"model\":\"MQA52CH/A\"},\"count\":5}"
        let obj: OrderInfo = OrderInfo(jsonString: jsonString)
        print(obj.ID!)
        print(obj.state.rawValue)
        print(obj.product!.name!)
    }
    
    //测试属性为自定义类型数组的情况
    class func jsonToModel3() {
        let jsonString: String = "{\"address\":\"Hangzhou,China\",\"students\":[{\"name\":\"Li Lei\",\"age\":10},{\"name\":\"Han Meimei\",\"age\":11}]}"
        let obj: School = School(jsonString: jsonString)
        print(obj.students[0].name!)
    }
}
