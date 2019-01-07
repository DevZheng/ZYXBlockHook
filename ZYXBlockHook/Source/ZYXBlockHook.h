//
//  ZYXBlockHook.h
//  hook_block
//
//  Created by Zheng,Yuxin on 2018/11/20.
//  Copyright © 2018 Zheng,Yuxin. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ZYXHookBlockToken : NSObject

- (BOOL)removeHookBlock;

@end

@interface NSObject (ZyxBlockHook)

- (ZYXHookBlockToken *)zyx_hookblockUseBlock:(id)block;

- (void)zyx_removeHookBlock;

@end

NS_ASSUME_NONNULL_END
