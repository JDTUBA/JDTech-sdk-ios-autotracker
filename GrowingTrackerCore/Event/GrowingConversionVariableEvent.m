//
// GrowingConversionVariableEvent.m
// GrowingAnalytics
//
//  Created by sheng on 2020/11/13.
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

#import "GrowingTrackerCore/Event/GrowingConversionVariableEvent.h"
#import "GrowingTrackerCore/Event/GrowingTrackEventType.h"

@implementation GrowingConversionVariableEvent

- (instancetype)initWithBuilder:(GrowingBaseBuilder *)builder {
    if (self = [super initWithBuilder:builder]) {
        GrowingConversionVariableBuilder *subBuilder = (GrowingConversionVariableBuilder *)builder;
        _attributes = subBuilder.attributes;
    }
    return self;
}

+ (GrowingConversionVariableBuilder *)builder {
    return [[GrowingConversionVariableBuilder alloc] init];
}

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dataDictM = [NSMutableDictionary dictionaryWithDictionary:[super toDictionary]];
    dataDictM[@"attributes"] = self.attributes;
    return dataDictM;
}

@end

@implementation GrowingConversionVariableBuilder

- (GrowingConversionVariableBuilder * (^)(NSDictionary<NSString *, NSObject *> *value))setAttributes {
    return ^(NSDictionary<NSString *, NSObject *> *value) {
        self->_attributes = value;
        return self;
    };
}

- (NSString *)eventType {
    return GrowingEventTypeConversionVariables;
}

- (GrowingBaseEvent *)build {
    return [[GrowingConversionVariableEvent alloc] initWithBuilder:self];
}

@end
