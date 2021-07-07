//
// GrowingIDFAWrapper.h
// GrowingAnalytics
//
//  Created by sheng on 2021/4/21.
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

@interface GrowingUserIdentifier : NSObject

/**
 获取设备的 IDFA
 @return idfa
 */
+ (nullable NSString *)idfa;

/**
 获取设备的 IDFV
 @return idfv
 */
+ (nullable NSString *)idfv;
/**
 获取用户标识 idfa > idfv > UUID
 @return 用户标识
 */
+ (NSString *)getUserIdentifier;

@end

NS_ASSUME_NONNULL_END