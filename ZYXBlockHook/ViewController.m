//
//  ViewController.m
//  ZYXBlockHook
//
//  Created by Zheng,Yuxin on 2018/11/20.
//  Copyright © 2018 Zheng,Yuxin. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+zyx_runtime.h"
#import "ZYXBlockHook.h"

void HookBlockToPrintHelloWorld(id block) {
    [block zyx_hookblockUseBlock:^(ZYXHookBlockToken *token){
        NSLog(@"Hello world");
    }];
}

void HookBlockToPrintArguments(id block) {
    [block zyx_hookblockUseBlock:^(ZYXHookBlockToken *token){
        
    }];
}

typedef void(^ArgumentBlk)(int);

typedef void(^TestBlk)(ArgumentBlk a, int i, long l, id obj, Class cls);

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    Class a = [self class];
    
    NSLog(@"class: %@", a);
    
    TestBlk blk = ^(ArgumentBlk a,  int i, long l, id obj, Class cls){
        NSLog(@"origin call");
    };
    
    ArgumentBlk argBlk = ^(int a) {
        
    };
    
    ZYXHookBlockToken *token = [blk zyx_hookblockUseBlock:^(ZYXHookBlockToken *token, SEL a){
//        NSLog(@"%@", a);
        NSLog(@"Hello world");
    }];

    blk(argBlk, 1, 2, self, self.class);
    
    [token removeHookBlock];
    
    blk(argBlk, 1, 2, self, self.class);

}



@end
