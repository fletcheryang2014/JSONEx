//
//  JSONEx.m
//  KKTV
//
//  Created by mac on 14-4-2.
//
//

#import "JSONEx.h"
#import <objc/runtime.h>
// 用静态字典存取类的arrayPropertyItemClasses方法的值，以避免函数调用，提高访问速度
static NSDictionary* arrayPropertyClassForClass(Class cls) {
    if (!cls || ![cls respondsToSelector:@selector(arrayPropertyItemClasses)]) return nil;
    static CFMutableDictionaryRef cache;
    static dispatch_once_t onceToken;
    static dispatch_semaphore_t lock;
    dispatch_once(&onceToken, ^{
        cache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    NSDictionary *dic = CFDictionaryGetValue(cache, (__bridge const void *)(cls));
    dispatch_semaphore_signal(lock);
    if (!dic) {
        dic = [(id<JSONEx>)cls arrayPropertyItemClasses];
        if (dic) {
            NSMutableDictionary *mapper = [NSMutableDictionary new];
            [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[NSString class]])
                    mapper[key] = NSClassFromString(obj);
            }];
            dic = mapper;
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(cache, (__bridge const void *)(cls), (__bridge const void *)(dic));
            dispatch_semaphore_signal(lock);
        }
    }
    return dic;
}
// 用静态字典存取类的customPropertyNameForKeys方法的值，以避免函数调用，提高访问速度
static NSDictionary* customPropertyKeyForClass(Class cls) {
    if (!cls || ![cls respondsToSelector:@selector(customPropertyNameForKeys)]) return nil;
    static CFMutableDictionaryRef cache;
    static dispatch_once_t onceToken;
    static dispatch_semaphore_t lock;
    dispatch_once(&onceToken, ^{
        cache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        lock = dispatch_semaphore_create(1);
    });
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    NSDictionary *dic = CFDictionaryGetValue(cache, (__bridge const void *)(cls));
    dispatch_semaphore_signal(lock);
    if (!dic) {
        dic = [(id<JSONEx>)cls customPropertyNameForKeys];
        if (dic) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            CFDictionarySetValue(cache, (__bridge const void *)(cls), (__bridge const void *)(dic));
            dispatch_semaphore_signal(lock);
        }
    }
    return dic;
}

@implementation NSObject (NSObject_StringMapping)

- (void)setDic:(NSDictionary*)dic fromClass:(Class)cls
{
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList(cls, &count); //获取该类的所有属性
    for (int i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        const char* key = property_getName(property);
        NSString* strKey = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
        id value = [self valueForKey:strKey];
        [dic setValue:value forKey:strKey];
    }
    free(properties);
}

- (void)setDic:(NSDictionary*)dic fromAllClass:(Class)cls
{
    [self setDic:dic fromClass:cls];
    Class superCls = class_getSuperclass(cls);
    if(superCls != nil && strcmp(class_getName(superCls), "NSObject") != 0)
        [self setDic:dic fromAllClass:superCls];
}

- (NSString*)getJSONString//查看http请求发送的字符串
{
    Class cls = [self class];
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] initWithCapacity:0];
    [self setDic:dic fromAllClass:cls];
    
    [dic removeObjectForKey:@"hash"];
    [dic removeObjectForKey:@"superclass"];
    [dic removeObjectForKey:@"description"];
    [dic removeObjectForKey:@"debugDescription"];
    
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&error];
    if (!data)
        return nil;

    NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return str;
}

@end

@implementation NSObject (NSObject_Creation)

+ (instancetype)objectWithDictionary:(NSDictionary *)dic
{
    id obj = [[self alloc] init];
    [dic setJSONObjectValue:obj];
    return obj;
}

+ (instancetype)objectWithJsonString:(NSString *)str
{
    id obj = [[self alloc] init];
    [str setJSONObjectValue:obj];
    return obj;
}

+ (NSMutableArray *)objectArrayWithArray:(NSArray *)array
{
    NSMutableArray *modelArray = [NSMutableArray array];
    for (id item in array) {
        if ([item isKindOfClass:[NSDictionary class]]) {
            id obj = [self objectWithDictionary:item];
            [modelArray addObject:obj];
        }
    }
    return modelArray;
}

@end

@implementation NSDictionary (NSDictionary_ObjectMapping)

- (Class)getPropertyClass:(objc_property_t)property
{
    unsigned int attrCount;
    objc_property_attribute_t *attrs = property_copyAttributeList(property, &attrCount);
    for (unsigned int i = 0; i < attrCount; i++) {
        const char *name = attrs[i].name;
        const char *value = attrs[i].value;
        if (name[0] == 'T') {
            if (strlen(value) > 2 && value[0] == '@' && value[1] == '\"') {
                char *p = strrchr(value + 2, '\"');
                if (p) {
                    *p = '\0';
                    return objc_getClass(value + 2);
                }
            }
            break;
        }
    }
    return nil;
}

static NSSet *foundationClasses = nil;

- (BOOL)isFoundationClass:(Class)cls
{
    if (cls == [NSObject class]) return YES;
    
    if (foundationClasses == nil)
        foundationClasses = [NSSet setWithObjects:
                                 [NSURL class],
                                 [NSDate class],
                                 [NSValue class],
                                 [NSData class],
                                 [NSError class],
                                 [NSArray class],
                                 [NSDictionary class],
                                 [NSString class],
                                 [NSAttributedString class], nil];
    
    __block BOOL result = NO;
    [foundationClasses enumerateObjectsUsingBlock:^(Class foundationClass, BOOL *stop) {
        if ([cls isSubclassOfClass:foundationClass]) {
            result = YES;
            *stop = YES;
        }
    }];
    return result;
}

- (Class)getObjArrayPropertyClass:(id)obj properyName:(NSString*)propertyName
{
    NSDictionary *dic = arrayPropertyClassForClass([obj class]);
    if (dic) {
        return dic[propertyName];
    }
    return nil;
}

- (NSString*)getObjCustomPropertyKey:(id)obj properyName:(NSString*)propertyName
{
    NSDictionary *dic = customPropertyKeyForClass([obj class]);
    if (dic) {
        return dic[propertyName];
    }
    return nil;
}

- (void)setObject:(id)obj fromClass:(Class)cls
{
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList(cls, &count); //获取该类的所有属性
    for (int i = 0; i < count; i++) {
        
        objc_property_t property = properties[i];
        const char* key = property_getName(property);
        NSString* strKey = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
        id value = [self objectForKey:strKey];//从字典里按属性名获取value
        if (value == nil) {
            //对象属性名和JSON关键词key不一致的情况，获取属性名对应的key
            NSString *jsonKey = [self getObjCustomPropertyKey:obj properyName:strKey];
            if (jsonKey != nil) {
                value = [self objectForKey:jsonKey];//再次从字典里获取value
            }
        }
        
        Class propertyCls = [self getPropertyClass:property];//获取属性的类
        if (propertyCls == nil || [self isFoundationClass:propertyCls]) {
            if(value != nil && value != (id)kCFNull) {
                if (propertyCls == [NSURL class] && [value isKindOfClass:[NSString class]]) {
                    [obj setValue:[NSURL URLWithString:value] forKey:strKey];
                } else if (propertyCls == [NSArray class] && [value isKindOfClass:[NSArray class]]) {
                    //数组属性里的元素是自定义类型
                    Class cls = [self getObjArrayPropertyClass:obj properyName:strKey];
                    if (cls) {
                        [obj setValue:[cls objectArrayWithArray:value] forKey:strKey];
                    } else {
                        [obj setValue:value forKey:strKey];
                    }
                } else {
                    [obj setValue:value forKey:strKey];//通过KVC给对象的属性赋值
                }
            }
        } else {//自定义类型属性
            if(value != nil && [value isKindOfClass:[NSDictionary class]]) {
                id subObj = [[propertyCls alloc] init];
                [value setObject:subObj fromAllClass:propertyCls];
                [obj setValue:subObj forKey:strKey];
            }
        }
    }
    free(properties);
}

- (void)setObject:(id)obj fromAllClass:(Class)cls
{
    [self setObject:obj fromClass:cls];
    Class superCls = class_getSuperclass(cls);
    if(superCls != nil && strcmp(class_getName(superCls), "NSObject") != 0)
        [self setObject:obj fromAllClass:superCls];
}

- (void)setJSONObjectValue:(id)obj
{
    Class class = object_getClass(obj);
    [self setObject:obj fromAllClass:class];
}

- (NSString*)getJSONString
{
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:self options:0 error:&error];
    if (!data)
        return nil;
    
    NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return str;
}

@end

@implementation NSString (NSString_ObjectMapping)

- (id)JSONValue
{
    NSData* data = [self dataUsingEncoding:NSUTF8StringEncoding];
    if (!data)
        return nil;
    
    NSError *error;
    id ret = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (ret && [ret isKindOfClass:[NSNull class]])
        return nil;

    return ret;
}

- (void)setJSONObjectValue:(id)obj
{
    id repr = [self JSONValue];
    if ([repr isKindOfClass:[NSDictionary class]])
        [(NSDictionary*)repr setJSONObjectValue:obj];
}

@end
