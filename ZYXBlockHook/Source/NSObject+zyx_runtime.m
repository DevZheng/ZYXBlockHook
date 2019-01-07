//
//  NSObject+zyx_runtime.m
//  hook_block
//
//  Created by Zheng,Yuxin on 2018/11/20.
//  Copyright © 2018 Zheng,Yuxin. All rights reserved.
//

#import "NSObject+zyx_runtime.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation NSObject (zyx_runtime)

+ (void)printAllPropertysNotIncludeSuper {

    Class cls = self;

    unsigned int outCount = 0;
    objc_property_t *list = class_copyPropertyList(cls, &outCount);
    printf("------------------------------------------\n");
    printf("%s propertys:\n", class_getName(cls));
    for (unsigned int i = 0; i < outCount; i ++) {
        objc_property_t pro = list[i];
        
        const char *name = property_getName(pro);
        const char *attrs = property_getAttributes(pro);
        
        printf("name: %s | attrs: %s \n", name, attrs);
    }
    printf("------------------------------------------\n");
}

+ (void)printAllInstancesNotIncludeSuper {
    
    Class cls = self;
    
    unsigned int outCount = 0;
    Ivar *lists = class_copyIvarList(cls, &outCount);
    printf("------------------------------------------\n");
    printf("%s instances:\n", class_getName(cls));
    for (unsigned int i = 0; i < outCount; i ++) {
        Ivar ivar = lists[i];
        const char *name = ivar_getName(ivar);
        const char *typeEncoding = ivar_getTypeEncoding(ivar);
        printf("name: %s | typeEncoding: %s \n", name, typeEncoding);
    }
    printf("------------------------------------------\n");
}


@end
