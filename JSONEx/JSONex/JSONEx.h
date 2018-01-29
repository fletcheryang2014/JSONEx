//
//  JSONEx.h
//  KKTV
//
//  Created by mac on 14-4-2.
//
//

#import <Foundation/Foundation.h>

//给需要的类添加下面方法即可，不需要实现这个协议
@protocol JSONEx <NSObject>
@optional
+ (NSDictionary<NSString *, NSString *> *)arrayPropertyItemClasses;//数组属性里元素的类型
+ (NSDictionary<NSString *, NSString *> *)customPropertyNameForKeys;//属性名和JSON关键词的映射
@end


@interface NSObject (NSObject_Creation)

+ (instancetype)objectWithDictionary:(NSDictionary *)dic;//通过NSDictionary创建模型对象

+ (instancetype)objectWithJsonString:(NSString *)str;//通过JSON字符串创建模型对象

+ (NSMutableArray *)objectArrayWithArray:(NSArray *)array;//通过数组创建模型对象数组

@end


@interface NSObject (NSObject_StringMapping)

- (NSString*)getJSONString;//把自定义对象的属性转换为JSON字符串

@end


@interface NSDictionary (NSDictionary_ObjectMapping)

- (void)setJSONObjectValue:(id)obj;//把NSDictionary映射到对应的对象

- (NSString*)getJSONString;

@end


@interface NSString (NSString_ObjectMapping)

- (id)JSONValue;//返回NSDictionary或NSArray对象

- (void)setJSONObjectValue:(id)obj;//把JSON字符串映射到对应的对象

@end
