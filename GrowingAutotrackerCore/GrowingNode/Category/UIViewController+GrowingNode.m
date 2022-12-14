//
//  UIViewController+GrowingNode.m
//  GrowingAnalytics
//
//  Created by GrowingIO on 15/8/31.
//  Copyright (C) 2020 Beijing Yishu Technology Co., Ltd.
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

#import "GrowingTrackerCore/Thread/GrowingDispatchManager.h"
#import "GrowingAutotrackerCore/GrowingNode/GrowingNode.h"
#import "GrowingAutotrackerCore/Page/GrowingPageGroup.h"
#import "GrowingAutotrackerCore/Page/GrowingPageManager.h"
#import "GrowingAutotrackerCore/Private/GrowingPrivateCategory.h"
#import "GrowingAutotrackerCore/Autotrack/GrowingPropertyDefine.h"
#import "GrowingAutotrackerCore/Public/GrowingAutotrackConfiguration.h"
#import "GrowingTrackerCore/Helpers/NSDictionary+GrowingHelper.h"
#import "GrowingTrackerCore/Helpers/NSObject+GrowingIvarHelper.h"
#import "GrowingTrackerCore/Hook/UIApplication+GrowingNode.h"
#import "GrowingTrackerCore/Helpers/UIImage+GrowingHelper.h"
#import "GrowingTrackerCore/Helpers/UIView+GrowingHelper.h"
#import "GrowingAutotrackerCore/GrowingNode/Category/UIView+GrowingNode.h"
#import "GrowingAutotrackerCore/Autotrack/UIViewController+GrowingAutotracker.h"
#import "GrowingAutotrackerCore/GrowingNode/Category/UIViewController+GrowingNode.h"
#import "GrowingAutotrackerCore/Page/UIViewController+GrowingPageHelper.h"
#import "GrowingAutotrackerCore/GrowingNode/Category/UIWindow+GrowingNode.h"
#import "GrowingTrackerCore/Utils/GrowingArgumentChecker.h"

@implementation UIViewController (GrowingNode)

- (UIImage *)growingNodeScreenShot:(UIImage *)fullScreenImage {
    return [fullScreenImage growingHelper_getSubImage:[self.view growingNodeFrame]];
}

- (UIImage *)growingNodeScreenShotWithScale:(CGFloat)maxScale {
    return [self.view growingHelper_screenshot:maxScale];
}

- (CGRect)growingNodeFrame {
    CGRect rect = self.view.growingNodeFrame;
    //??????????????????
    //???ViewController???????????????????????????NavigationController??????,???frame???????????????????????????????????????
    BOOL isFullScreenShow =
        CGPointEqualToPoint(rect.origin, CGPointMake(0, 0)) &&
        CGSizeEqualToSize(rect.size, [UIApplication sharedApplication].growingMainWindow.bounds.size);
    if (isFullScreenShow) {
        UIViewController *parentVC = self.parentViewController;
        while (parentVC) {
            if ([parentVC isKindOfClass:[UINavigationController class]]) {
                UINavigationController *navi = (UINavigationController *)parentVC;
                if (!navi.navigationBar.window || navi.navigationBar.hidden || navi.navigationBar.alpha < 0.001 ||
                    !navi.navigationBar.superview) {
                    break;
                    ;
                }
                rect.origin.y += (navi.navigationBar.frame.size.height +
                                  [[UIApplication sharedApplication] statusBarFrame].size.height);
                rect.size.height -= (navi.navigationBar.frame.size.height +
                                     [[UIApplication sharedApplication] statusBarFrame].size.height);
            }

            if ([parentVC isKindOfClass:[UITabBarController class]]) {
                UITabBarController *tabbarvc = (UITabBarController *)parentVC;
                if (!tabbarvc.tabBar.window || tabbarvc.tabBar.hidden || tabbarvc.tabBar.alpha < 0.001 ||
                    !tabbarvc.tabBar.superview) {
                    break;
                    ;
                }
                rect.size.height -= tabbarvc.tabBar.frame.size.height;
            }
            parentVC = parentVC.parentViewController;
        }
    }
    return rect;
}

- (id<GrowingNode>)growingNodeParent {
    if (![self isViewLoaded]) {
        return nil;
    }
    // UIResponder?????????
    // UIApplication/UIWindowScene/_UIAlertControllerShimPresenterWindow/UITransitionView/UIAlertController/AlertView
    // UIAlertController???presentingViewController ??? UIApplicationRotationFollowingController
    //?????????????????????????????????????????????????????????????????????
    if ([self isKindOfClass:UIAlertController.class]) {
        return [[GrowingPageManager sharedInstance] currentViewController];
    } else {
        return self.parentViewController;
    }
}

- (BOOL)growingAppearStateCanTrack {
    if ([[GrowingPageManager sharedInstance] isDidAppearController:self]) {
        return YES;
    }
    //??????????????????????????????????????????addChildViewController?????????childVC????????????didappear
    //??????checknode?????? ????????????????????????
    if ([self growingHookIsCustomAddVC]) {
        return YES;
    }
    return NO;
}

#define DonotrackCheck(theCode) \
    if (theCode) {              \
        return YES;             \
    }

- (BOOL)growingNodeDonotTrack {
    DonotrackCheck(![self isViewLoaded]) DonotrackCheck(!self.view.window)
        DonotrackCheck(self.view.window.growingNodeIsBadNode) DonotrackCheck(self.growingNodeIsBadNode)
            DonotrackCheck(![self growingAppearStateCanTrack]) return NO;
}

- (BOOL)growingNodeDonotCircle {
    return NO;
}

- (BOOL)growingNodeUserInteraction {
    return NO;
}

- (NSString *)growingNodeName {
    return @"??????";
}

- (NSString *)growingNodeContent {
    return self.accessibilityLabel;
}

- (NSDictionary *)growingNodeDataDict {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"pageName"] = ([self growingPageHelper_getPageObject].name ?: self.growingPageName);
    return dict;
}

- (UIWindow *)growingNodeWindow {
    return self.view.window;
}

- (NSString *)growingNodeUniqueTag {
    return self.growingPageAlias;
}

#pragma mark - xpath
- (NSInteger)growingNodeKeyIndex {
    NSString *classString = NSStringFromClass(self.class);
    NSArray *subResponder = [(UIViewController *)self parentViewController].childViewControllers;

    NSInteger count = 0;
    NSInteger index = -1;
    for (UIResponder *res in subResponder) {
        if ([classString isEqualToString:NSStringFromClass(res.class)]) {
            count++;
        }
        if (res == self) {
            index = count - 1;
        }
    }
    // ?????? UIViewController ??????????????????????????????
    if (![self isKindOfClass:UIAlertController.class] && count == 1) {
        index = -1;
    }
    return index;
}

- (NSString *)growingNodeSubPath {
    //??????????????????????????????????????????
    if (self.growingPageAlias) {
        return self.growingPageAlias;
    }
    NSInteger index = [self growingNodeKeyIndex];
    NSString *className = NSStringFromClass(self.class);
    return index < 0 ? className : [NSString stringWithFormat:@"%@[%ld]", className, (long)index];
}

- (NSString *)growingNodeSubSimilarPath {
    return [self growingNodeSubPath];
}

- (NSIndexPath *)growingNodeIndexPath {
    return nil;
}

- (NSArray<id<GrowingNode>> *)growingNodeChilds {
    NSMutableArray *childs = [NSMutableArray array];

    if (self.presentedViewController) {
        [childs addObject:self.presentedViewController];
        return childs;
    }
    // ViewController???childViewController.view???self.view.subviews??????????????????????????????
    // ???????????????self.view????????????,self.view.view?????????????????????
    UIView *currentView = self.view;
    if (currentView && self.isViewLoaded && currentView.growingImpNodeIsVisible) {
        [childs addObjectsFromArray:self.view.subviews];
        if (self.childViewControllers.count > 0 && ![self isKindOfClass:UIAlertController.class]) {
            // ????????????????????????
            __block BOOL isContainFullScreen = NO;

            NSArray<UIViewController *> *childViewControllers = self.childViewControllers;
            [childViewControllers
                enumerateObjectsWithOptions:NSEnumerationReverse
                                 usingBlock:^(__kindof UIViewController *_Nonnull obj, NSUInteger idx,
                                              BOOL *_Nonnull stop) {
                                     if (obj.isViewLoaded) {
                                         UIView *objSuperview = obj.view;
                                         for (long i = (long)(childs.count - 1); i >= 0; i--) {
                                             UIView *childview = childs[i];
                                             //??????childview??????????????????objsuperview
                                             if ([objSuperview isDescendantOfView:childview]) {
                                                 // xib?????????viewController????????????????????????view??????????????????subviews???????????????1
                                                 if ([childview isEqual:objSuperview] ||
                                                     (childview.subviews.count == 1 &&
                                                      [childview.subviews.lastObject isEqual:objSuperview])) {
                                                     //                            NSInteger index = [childs
                                                     //                            indexOfObject:objSuperview];
                                                     if ([objSuperview growingImpNodeIsVisible] &&
                                                         !isContainFullScreen) {
                                                         [childs replaceObjectAtIndex:i withObject:obj];
                                                     } else {
                                                         [childs removeObject:childview];
                                                     }
                                                 }
                                             }
                                         }

                                         CGRect rect = [obj.view convertRect:obj.view.bounds toView:nil];
                                         // ????????????
                                         BOOL isFullScreenShow =
                                             CGPointEqualToPoint(rect.origin, CGPointMake(0, 0)) &&
                                             CGSizeEqualToSize(
                                                 rect.size,
                                                 [UIApplication sharedApplication].growingMainWindow.bounds.size);
                                         // ??????????????????
                                         if (isFullScreenShow && [obj.view growingImpNodeIsVisible]) {
                                             isContainFullScreen = YES;
                                         }
                                     }
                                 }];
        }

        [childs addObject:currentView];
        return childs;
    }

    if ([self isKindOfClass:UIPageViewController.class]) {
        UIPageViewController *pageViewController = (UIPageViewController *)self;
        [childs addObject:pageViewController.viewControllers];
    }

    return childs;
}

@end

@implementation UIViewController (GrowingAttributes)

static char kGrowingPageIgnorePolicyKey;
static char kGrowingPageAttributesKey;

GrowingSafeStringPropertyImplementation(growingPageAlias, setGrowingPageAlias)

- (void)mergeGrowingAttributesPvar:(NSDictionary<NSString *, NSObject *> *)growingAttributesPvar {
    //???GrowingMobileDebugger?????????????????? - pvar
    if (growingAttributesPvar.count != 0) {
        NSMutableDictionary<NSString *, NSObject *> *pvar = [self growingAttributesMutablePvar];
        [pvar addEntriesFromDictionary:growingAttributesPvar];
    }
}

- (void)removeGrowingAttributesPvar:(NSString *)key {
    if (key == nil) {
        [self.growingAttributesMutablePvar removeAllObjects];
    } else if (key.length > 0) {
        [self.growingAttributesMutablePvar removeObjectForKey:key];
    }
}

- (NSMutableDictionary<NSString *, NSObject *> *)growingAttributesMutablePvar {
    NSMutableDictionary<NSString *, NSObject *> *pvar = objc_getAssociatedObject(self, &kGrowingPageAttributesKey);
    if (pvar == nil) {
        pvar = [[NSMutableDictionary alloc] init];
        objc_setAssociatedObject(self, &kGrowingPageAttributesKey, pvar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return pvar;
}

- (void)setGrowingPageAttributes:(NSDictionary<NSString *, NSString *> *)growingPageAttributes {
    [GrowingDispatchManager trackApiSel:_cmd
                   dispatchInMainThread:^{
                       if (!growingPageAttributes || ([growingPageAttributes isKindOfClass:NSDictionary.class] &&
                                                      growingPageAttributes.count == 0)) {
                           [self removeGrowingAttributesPvar:nil];  // remove all

                       } else {
                           if ([GrowingArgumentChecker isIllegalAttributes:growingPageAttributes]) {
                               return;
                           }
                           [self mergeGrowingAttributesPvar:growingPageAttributes];
                       }
                   }];
}

- (NSDictionary<NSString *, NSString *> *)growingPageAttributes {
    return [[self growingAttributesMutablePvar] copy];
}

- (void)setGrowingPageIgnorePolicy:(GrowingIgnorePolicy)growingPageIgnorePolicy {
    objc_setAssociatedObject(self, &kGrowingPageIgnorePolicyKey,
                             [NSNumber numberWithUnsignedInteger:growingPageIgnorePolicy],
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (GrowingIgnorePolicy)growingPageIgnorePolicy {
    id policyObjc = objc_getAssociatedObject(self, &kGrowingPageIgnorePolicyKey);
    if (!policyObjc) {
        return GrowingIgnoreNone;
    }

    if ([policyObjc isKindOfClass:NSNumber.class]) {
        NSNumber *policyNum = (NSNumber *)policyObjc;
        return policyNum.unsignedIntegerValue;
    }

    return GrowingIgnoreNone;
}

@end
