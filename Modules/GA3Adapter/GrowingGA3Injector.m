//
//  GrowingGA3Injector.m
//  GrowingAnalytics
//
//  Created by YoloMao on 2022/5/31.
//  Copyright (C) 2022 Beijing Yishu Technology Co., Ltd.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "Modules/GA3Adapter/GrowingGA3Injector.h"
#import "Modules/GA3Adapter/GrowingGA3Adapter+Internal.h"
#import "GrowingTrackerCore/Swizzle/GrowingSwizzle.h"
#import "GrowingTrackerCore/Swizzle/GrowingSwizzler.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation GrowingGA3Injector

+ (instancetype)sharedInstance {
    static GrowingGA3Injector *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });

    return _sharedInstance;
}

- (void)addAdapterSwizzles {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = NSClassFromString(@"GAI");
        if (!class) {
            @throw [NSException exceptionWithName:@"Google Analytics v3未集成"
                                           reason:@"请集成Google Analytics，再进行Growing GA3 Adapter适配"
                                         userInfo:nil];
        }
        
        {
            SEL selector = NSSelectorFromString(@"defaultTracker");
            if ([class respondsToSelector:selector]) {
                id defaultTracker = ((id (*)(id, SEL))objc_msgSend)(class, selector);
                if (defaultTracker) {
                    @throw [NSException exceptionWithName:@"Google Analytics v3已初始化"
                                                   reason:@"GrowingAnalytics初始化必须在GoogleAnalytics之前"
                                                 userInfo:nil];
                }
            }
        }
        
        {
            // -[GAI trackerWithName:trackingId:]内部有_cmd判断，需要保证swizzle之后_cmd不变
            SEL selector = NSSelectorFromString(@"trackerWithName:trackingId:");
            Method method = class_getInstanceMethod(class, selector);
            originMethodImp = method_getImplementation(method);
            method_setImplementation(method, (IMP)growingga3_trackerInit);
        }
        
        {
            __block NSInvocation *invocation = nil;
            SEL selector = NSSelectorFromString(@"removeTrackerByName:");
            id block = ^(id analytics, NSString *name) {
                if (!invocation) {
                    return;
                }
                [invocation retainArguments];
                [invocation setArgument:&name atIndex:2];
                [invocation invoke];
                
                [GrowingGA3Adapter.sharedInstance removeTrackerByName:name];
            };
            invocation = [class growing_swizzleMethod:selector withBlock:block error:nil];
        }
    });
}

static IMP originMethodImp = nil;

static id growingga3_trackerInit(id gai, SEL selector, NSString *name, NSString *trackingId) {
    id tracker = ((id(*)(id, SEL, NSString *, NSString *))originMethodImp)(gai,
                                                                           selector,
                                                                           name,
                                                                           trackingId);
    growingga3_adapter_trackerInit(tracker, name, trackingId);
    return tracker;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
static void growingga3_adapter_trackerInit(id tracker, NSString *name, NSString *trackingId) {
    [GrowingGA3Adapter.sharedInstance trackerInit:tracker name:name trackingId:trackingId];
    
    {
        SEL selector = @selector(set:value:);
        Class class = [GrowingSwizzler realDelegateClassFromSelector:selector proxy:tracker];
        if ([GrowingSwizzler realDelegateClass:class respondsToSelector:selector]) {
            __block NSInvocation *invocation = nil;
            id block = ^(id tracker, NSString *parameterName, NSString *value) {
                if (!invocation) {
                    return;
                }
                [invocation retainArguments];
                [invocation setArgument:&parameterName atIndex:2];
                [invocation setArgument:&value atIndex:3];
                [invocation invoke];
                
                [GrowingGA3Adapter.sharedInstance tracker:tracker set:parameterName value:value];
            };
            invocation = [class growing_swizzleMethod:selector withBlock:block error:nil];
        }
    }
    
    {
        SEL selector = @selector(send:);
        Class class = [GrowingSwizzler realDelegateClassFromSelector:selector proxy:tracker];
        if ([GrowingSwizzler realDelegateClass:class respondsToSelector:selector]) {
            __block NSInvocation *invocation = nil;
            id block = ^(id tracker, NSDictionary *parameters) {
                if (!invocation) {
                    return;
                }
                [invocation retainArguments];
                [invocation setArgument:&parameters atIndex:2];
                [invocation invoke];
                
                [GrowingGA3Adapter.sharedInstance tracker:tracker send:parameters];
            };
            invocation = [class growing_swizzleMethod:selector withBlock:block error:nil];
        }
    }
}
#pragma clang diagnostic pop

@end