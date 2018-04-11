//
//  main.m
//  JSONEx
//
//  Created by yangyi on 2018/1/25.
//  Copyright © 2018年 yangyi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "JSONEx.h"
#import "GitHubUser.h"
#import "JSONEx-Swift.h"

@interface ClassA : NSObject
@property (nonatomic, assign) int a;
@property (nonatomic, assign) double b;
@property (nonatomic, assign) bool c;
@property (nonatomic, assign) BOOL d;
@property (nonatomic, strong) NSString *e;
@property (nonatomic, strong) NSString *f;
@property (nonatomic, strong) NSURL *g;
@end
@implementation ClassA
@end

@interface ClassB : NSObject
@property (nonatomic, assign) NSUInteger i;
@property (nonatomic, strong) ClassA *j;
@end
@implementation ClassB
@end

typedef NS_ENUM(NSInteger,ServerType) {
    ServerTypeProduction = 0,
    ServerTypeTest       = 1,
    ServerTypeBeta       = 2,
    ServerTypeGray       = 3,
};

@interface ClassC : NSObject
@property (nonatomic, assign) ServerType type;
@property (nonatomic, strong) NSString *name;
@end
@implementation ClassC
@end

@interface ClassD : NSObject
@property (nonatomic, assign) long count;
@property (nonatomic, strong) NSArray *array;
@end
@implementation ClassD
+ (NSDictionary*)arrayPropertyItemClasses {
    return @{@"array":@"ClassC"};
}
+ (NSDictionary*)customPropertyNameForKeys {
    return @{@"array":@"list"};
}
@end

@interface ClassE : ClassC
@property (nonatomic, strong) NSString *ip;
@end
@implementation ClassE
@end

//JSON字符串转对象
void jsonStringToObj1() {
    NSString *jsonString = @"{\"a\":123,\"b\":561.676,\"c\":false,\"d\":1,\"e\":null,\"f\":\"wefehjrbnc\",\"g\":\"https://m.kktv5.com/red_envelope\"}";
    
    ClassA *obj = [ClassA objectWithJsonString:jsonString];
    NSLog(@"%@", obj.g);
}

//JSON字符串转对象(对象里包含了自定义的类型)
void jsonStringToObj2() {
    NSString *jsonString = @"{\"i\":432,\"j\":{\"a\":123,\"b\":561.676,\"c\":false,\"d\":1,\"e\":null,\"f\":\"wefehjrbnc\",\"g\":\"https://m.kktv5.com/red_envelope\"}}";
    
    ClassB *obj = [ClassB objectWithJsonString:jsonString];
    NSLog(@"%zi", obj.i);
}

//JSON字符串转对象(对象的数组属性里的元素是自定义的类型)
void jsonStringToObj3() {
    NSString *jsonString = @"{\"count\":954294223,\"list\":[{\"type\":1,\"name\":\"oqewfsaw\"},{\"type\":2,\"name\":\"weowgmv\"}]}";
    
    ClassD *obj = [ClassD objectWithJsonString:jsonString];
    NSLog(@"%ld", ((ClassC*)(obj.array[0])).type);
}

//JSON字符串转对象(包含基类的属性)
void jsonStringToObj4() {
    NSString *jsonString = @"{\"ip\":\"10.0.0.22\",\"type\":1,\"name\":\"oqewfsaw\"}";
    
    ClassE *obj = [ClassE objectWithJsonString:jsonString];
    NSLog(@"%@", obj.name);
}

void testPerformance() {
    /// get json data
    NSString *path = [[NSBundle mainBundle] pathForResource:@"user" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    
    /// Benchmark
    int count = 10000;
    NSTimeInterval begin, end;

    begin = CACurrentMediaTime();
    @autoreleasepool {
        for (int i = 0; i < count; i++) {
            GHUser *user = [GHUser objectWithDictionary:json];
        }
    }
    end = CACurrentMediaTime();
    printf("JSONEx:        %.2lfms   \n", (end - begin) * 1000);
    
    begin = CACurrentMediaTime();
    @autoreleasepool {
        for (int i = 0; i < count; i++) {
            [YYGHUser yy_modelWithJSON:json];
        }
    }
    end = CACurrentMediaTime();
    printf("YYModel:        %.2lfms   \n", (end - begin) * 1000);
    
    begin = CACurrentMediaTime();
    @autoreleasepool {
        for (int i = 0; i < count; i++) {
            [MJGHUser mj_objectWithKeyValues:json];
        }
    }
    end = CACurrentMediaTime();
    printf("MJExtension:        %.2lfms   \n", (end - begin) * 1000);
}

int main(int argc, char * argv[]) {
    @autoreleasepool {
//        jsonStringToObj1();
//        jsonStringToObj2();
//        jsonStringToObj3();
//        jsonStringToObj4();
//        testPerformance();
//        [SwiftJsonTest jsonToModel1];
//        [SwiftJsonTest jsonToModel2];
        [SwiftJsonTest jsonToModel3];
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
