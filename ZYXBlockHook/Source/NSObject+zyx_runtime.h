//
//  NSObject+zyx_runtime.h
//  hook_block
//
//  Created by Zheng,Yuxin on 2018/11/20.
//  Copyright © 2018 Zheng,Yuxin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (zyx_runtime)

+ (void)printAllPropertysNotIncludeSuper;

+ (void)printAllInstancesNotIncludeSuper;

@end

NS_ASSUME_NONNULL_END
