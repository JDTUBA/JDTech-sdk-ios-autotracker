//
// GrowingStatusBarEventManager.h
// GrowingAnalytics
//
//  Created by sheng on 2020/12/28.
//  Copyright (C) 2017 Beijing Yishu Technology Co., Ltd.
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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol GrowingStatusBarEventProtocol <NSObject>

- (void)didTapStatusBar:(id)gesture;

@end


@interface GrowingStatusBarEventManager : NSObject

+ (instancetype)sharedInstance;

- (void)addStatusBarObserver:(id<GrowingStatusBarEventProtocol>)delegate;

- (void)removeStatusBarObserver:(id<GrowingStatusBarEventProtocol>)delegate;

- (void)dispatchTapStatusBar:(id)gesture;

@end

NS_ASSUME_NONNULL_END
