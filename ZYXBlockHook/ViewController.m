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

typedef void(^ArgumentBlk)(int);

typedef void(^TestBlk)(ArgumentBlk a, int i, long l, id obj, Class cls);

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self testPrintArgumentsAndOriginCall];
}

- (void)testPrintHelloWorld {

    typedef void(^Block)(void);
    
    Block blk = ^(){
        NSLog(@"Origin call");
    };
    
    ZYXHookBlockToken *token = [blk zyx_hookblockWithMode:ZYXBlockHookModeInstead
                                                hookBlock:^(ZYXHookBlockToken *token){
                                                    NSLog(@"Hello world");
                                                }];
    blk();
    [token removeHookBlock];
    blk();
}

- (void)testPrintArgumentsAndOriginCall {
    
    typedef void(^Block)(int a, long b, double c, id d, SEL sel);
    
    Block blk = ^(int a, long b, double c, id d, SEL sel){
        NSLog(@"Origin call");
    };
    
    ZYXHookBlockToken *token = [blk zyx_hookblockWithMode:ZYXBlockHookModeAfter
                                                printArgs:YES
                                                hookBlock:^(ZYXHookBlockToken *token){
                                                }];
    blk(1, 2, 3.0, [NSObject new], @selector(alloc));
    
    [token removeHookBlock];
}

- (void)testPrintArgumentsForEveryBlockAfterCall {
    
    
}


@end
