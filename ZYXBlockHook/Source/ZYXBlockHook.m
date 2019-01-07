//
//  ZYXBlockHook.m
//  hook_block
//
//  Created by Zheng,Yuxin on 2018/11/20.
//  Copyright © 2018 Zheng,Yuxin. All rights reserved.
//

#import "ZYXBlockHook.h"
#import "ffi.h"

#import <objc/runtime.h>
#import <objc/message.h>

struct _zyx_block {
    Class isa;
    int flags;
    int reserved;
    void *invoke;
    struct {
        unsigned long int reserved;
        unsigned long int size;
    
        void (*copy)(void *dst, const void *src);
        void (*dispose)(const void *);
    
        const char *signature;
        const char *layout;

    } *descriptor;
};

enum {
    BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
    BLOCK_HAS_CTOR =          (1 << 26), // helpers have C++ code
    BLOCK_IS_GLOBAL =         (1 << 28),
    BLOCK_HAS_STRET =         (1 << 29), // IFF BLOCK_HAS_SIGNATURE
    BLOCK_HAS_SIGNATURE =     (1 << 30),
};

@interface ZYXHookBlockToken() {
    ffi_cif _cif;
    ffi_closure *_consure;
    void *replaceFuncPtr;
    void *_originInvoke;
}

@property (nonatomic, weak) id originBlock;


@property (nonatomic, assign) NSInteger numberOfArgs;


@property (nonatomic, strong) id hookBlock;

/*
 返回值
 */
@property (nonatomic) void *retValue;

/*
 参数列表
 */
@property (nonatomic) void **args;


@end

@implementation ZYXHookBlockToken

- (void)dealloc {
    NSLog(@"%s", __func__);
}

- (void)hook {
    
    _consure = ffi_closure_alloc(sizeof(ffi_closure), &replaceFuncPtr);
    
    const char *originBlockSignature = _blockSignature(_originBlock);
    
    int count = 0;
    
    ffi_type **types = _ffiTypesForSignature(originBlockSignature, &count);
    
    self.numberOfArgs = count;

    ffi_status status = ffi_prep_cif(&_cif, FFI_DEFAULT_ABI, count, _ffiArgForEncode(originBlockSignature[0]), types);
    
    if (status != FFI_OK) {
        abort();
    }
    
    ffi_status clo_status = ffi_prep_closure_loc(_consure, &_cif, _HookblockFFIClosureFunc, (__bridge void *)self, replaceFuncPtr);
    
    if (clo_status != FFI_OK) {
        abort();
    }
    
    // 替换实现
    _originInvoke = ((__bridge struct _zyx_block *)self.originBlock) -> invoke;
    ((__bridge struct _zyx_block *)self.originBlock) -> invoke = replaceFuncPtr;
}

- (BOOL)removeHookBlock {
    if (!_originInvoke) {
        NSLog(@"not find hook ");
        return NO;
    }
    if (self.originBlock) {
        ((__bridge struct _zyx_block *)self.originBlock) -> invoke = _originInvoke;
        return YES;
    }
    return NO;
}

#pragma mark - Private

- (void)invokeOriginBlock {
    if (_originInvoke) {
        ffi_call(&_cif, _originInvoke, self.retValue, self.args);
    } else {
        NSLog(@"block don't have origin invoke ");
    }
}

- (void)invokeHookBlock {
    
    NSMethodSignature *originBlockSignature = [NSMethodSignature signatureWithObjCTypes:_blockSignature(self.originBlock)];
    NSMethodSignature *hookBlockSignature = [NSMethodSignature signatureWithObjCTypes:_blockSignature(self.hookBlock)];
    
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:hookBlockSignature];
    
    if (hookBlockSignature.numberOfArguments > originBlockSignature.numberOfArguments + 1) {
        NSLog(@"hook block has too many arguments");
        return;
    }
    
    if (hookBlockSignature.numberOfArguments > 1) {
        [inv setArgument:(void *)&self atIndex:1];
    }
    
    void *argBuf = NULL;
    for (NSUInteger idx = 2; idx < hookBlockSignature.numberOfArguments; idx++) {
        const char *type = [originBlockSignature getArgumentTypeAtIndex:idx - 1];
        NSUInteger sizep;
        NSGetSizeAndAlignment(type, &sizep, NULL);
        argBuf = realloc(argBuf, sizep);
        if (argBuf == NULL) {
            abort();
        }
        memcpy(argBuf, self.args[idx - 1], sizep);
        [inv setArgument:argBuf atIndex:idx];
    }
    
    [inv invokeWithTarget:self.hookBlock];
    
    if (argBuf != NULL) {
        free(argBuf);
        argBuf = NULL;
    }
}

- (void)printAllArgs {
    NSMethodSignature *originBlockSignature = [NSMethodSignature signatureWithObjCTypes:_blockSignature(self.originBlock)];
    NSInteger argCount = originBlockSignature.numberOfArguments;
    
    if (argCount <= 1) {
        return;
    }
    
    NSLog(@"origin args begin ---");

    for (int i = 1; i < argCount; i ++) {
        const char *argType = [originBlockSignature getArgumentTypeAtIndex:i];
        
#define CMP(type) strcmp(argType, @encode(type)) == 0
        if (CMP(id)) {
            id obj = (__bridge id)(*(void **)self.args[i]);
            NSLog(@"argument index: %d, type: id , value: %@ \n", i - 1 , obj);
            continue;
        } else if (CMP(Class)) {
            Class obj = (__bridge Class)(*(void **)self.args[i]);
            NSLog(@"argument index: %d, type: Class , value: %@ \n", i - 1 , obj);
            continue;
        } else if (@encode(void(^)(void))[0] == argType[0] && @encode(void(^)(void))[1] == argType[1] ) {
            id blk = (__bridge id)(*(void **)self.args[i]);
            NSLog(@"argument index: %d, type: Block , value: %@ \n", i - 1 , blk);
            continue;
        }
        
        void *value = NULL;
        NSUInteger sizep;
        NSGetSizeAndAlignment(argType, &sizep, NULL);
        value = realloc(value, sizep);
        memcpy(value, self.args[i], sizep);
        
#define HBNSLog(print, type) NSLog(@"argument index: %d, type: "#type" , value: %"#print" \n", i - 1 ,*(type *)value)
        if (CMP(int)) {
            HBNSLog(d, int);
        } else if (CMP(char)) {
            HBNSLog(c, char);
        } else if (CMP(short)) {
            HBNSLog(d, short);
        } else if (CMP(long)) {
            HBNSLog(ld, long);
        } else if (CMP(long long)) {
            HBNSLog(lld, long long);
        } else if (CMP(unsigned char)) {
            HBNSLog(c, unsigned char);
        } else if (CMP(unsigned int)) {
            HBNSLog(d, unsigned int);
        } else if (CMP(unsigned short)) {
            HBNSLog(d, unsigned short);
        } else if (CMP(unsigned long)) {
            HBNSLog(ld, unsigned long);
        } else if (CMP(unsigned long long)) {
            HBNSLog(lld, unsigned long long);
        } else if (CMP(float)) {
            HBNSLog(f, float);
        } else if (CMP(double)) {
            HBNSLog(f, double);
        } else if (CMP(BOOL)) {
            HBNSLog(d, BOOL);
        } else if (CMP(bool)) {
            HBNSLog(d, bool);
        } else if (CMP(char *)) {
            HBNSLog(s, char *);
        } else if (CMP(SEL)) {
            HBNSLog(s, SEL);
        }  else {
            NSLog(@"argument index: %d, type: unknow", i - 1);
        }
    }
    NSLog(@"origin args end  ---");
}

#pragma mark - FFIClosureFunc

void _HookblockFFIClosureFunc(ffi_cif *cif, void *ret, void **args, void *userdata) {
    
    ZYXHookBlockToken *token = (__bridge ZYXHookBlockToken *)(userdata);
    token.args = args;
    token.retValue = ret;
    
    [token printAllArgs];

    [token invokeHookBlock];
}

#pragma mark -

static const char *_blockSignature(id block) {
    
    struct _zyx_block *blk = (__bridge void*)block;
    
    if (!(blk -> flags & BLOCK_HAS_SIGNATURE)) { // 没有签名
        NSLog(@"origin block don't have sig");
        abort();
    }
    
    void *desc = blk -> descriptor;
    desc += sizeof(unsigned long int) * 2;
    
    if (blk -> flags & BLOCK_HAS_COPY_DISPOSE) {
        desc += sizeof(void *) * 2;
    }
    
    return *(const char **)desc;
}

static unsigned int _argCountForSingnature(const char *str) {
    int count = -1; // 包含返回参数
    while (str && *str) {
        const char *temp = NSGetSizeAndAlignment(str, NULL, NULL);
        while(isdigit(*temp))
            temp++;
        str = temp;
        count += 1;
    }
    return count;
}

static ffi_type * _ffiArgForEncode(const char ch) {
    
#define SINT(type) do { \
        if (ch == @encode(type)[0]) { \
            if (sizeof(type) == 1) { \
                return &ffi_type_sint8; \
            } else if (sizeof(type) == 2) { \
                return &ffi_type_sint16;\
            } else if (sizeof(type) == 4) {\
                return &ffi_type_sint32;\
            } else if (sizeof(type) == 8){\
                return &ffi_type_sint64;\
            } else {\
                NSLog(@"未知类型");\
                abort();\
            }\
        }\
        \
    } while(0)\

#define UINT(type) do { \
        if (ch == @encode(type)[0]) { \
            if (sizeof(type) == 1) { \
                return &ffi_type_uint8; \
            } else if (sizeof(type) == 2) { \
                return &ffi_type_uint16;\
            } else if (sizeof(type) == 4) {\
                return &ffi_type_uint32;\
            } else if (sizeof(type) == 8){\
                return &ffi_type_uint64;\
            } else {\
                NSLog(@"未知类型");\
                abort();\
            }\
        }\
    \
    } while(0)\

#define INT(type) do { \
        SINT(type); \
        UINT(unsigned type); \
    } while (0)


#define COND(type, name) do { \
    if (ch == @encode(type)[0]) { \
    return &ffi_type_##name; \
    }\
} while (0)\

#define PTR(type) COND(type, pointer)

    SINT(_Bool);
    SINT(signed char);
    UINT(unsigned char);
    
    INT(int);
    INT(short);
    INT(long long);
    INT(long);
    
    COND(float, float);
    COND(double, double);
    COND(void, void);
    
    PTR(id);
    PTR(Class);
    PTR(SEL);
    PTR(char *);
    PTR(void *);
    PTR(void (*)(void));
    
    // todo struct

    NSLog(@"未知类型");
    abort();
}

static ffi_type ** _ffiTypesForSignature(const char *sig, int *count) {
    
    int argCount = _argCountForSingnature(sig);
    
    ffi_type **types = malloc(sizeof(ffi_type *) * argCount);
    int i = -1;
    
    while (sig && *sig) {
        const char *temp = NSGetSizeAndAlignment(sig, NULL, NULL);
        while (isdigit(*temp)) {
            temp ++;
        }
        if (i >= 0) { // 第一个是返回值
            ffi_type *type = _ffiArgForEncode(sig[0]);
            types[i] = type;
        }
        sig = temp;
        i ++;
    }
    
    *count = argCount;
    return types;
}


@end

@implementation NSObject (ZyxBlockHook)

#pragma mark - Public

#define kAssociatedKey @"kAssociatedKey"

- (ZYXHookBlockToken *)zyx_hookblockUseBlock:(id)block {
    ZYXHookBlockToken *token = [[ZYXHookBlockToken alloc] init];
    token.originBlock = self;
    token.hookBlock = block;
    
    [token hook];

    return token;
}

- (void)zyx_removeHookBlock {
    
}

@end
