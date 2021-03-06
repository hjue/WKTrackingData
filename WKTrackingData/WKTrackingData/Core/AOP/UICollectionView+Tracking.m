//
//  UICollectionView+DelegateHook.m
//  WKTrackingData
//
//  Created by wkj on 2020/1/1.
//  Copyright © 2020 wkj. All rights reserved.
//

#import "UICollectionView+Tracking.h"

#import "NSObject+Swizzling.h"
#import "WKTrackingDataViewPathHelper.h"
#import <objc/runtime.h>

@implementation UICollectionView (Tracking)

+ (void)wk_enableCellSelectTracking {
    
    [self wk_swizzleInstanceSelector:@selector(setDelegate:) replaceSelector:@selector(wk_setCollectionViewDelegate:)];
}

- (void)wk_setCollectionViewDelegate:(id)delegate {
    
    [self wk_setCollectionViewDelegate:delegate];
    
    SEL origSel_ = @selector(collectionView:didSelectItemAtIndexPath:);
    Method originalMethod = class_getInstanceMethod([delegate class], origSel_);
    
    if (originalMethod) {
        
        [delegate wk_swizzleInstanceSelector:origSel_ fromClass:[self class] replaceSelector:@selector(delegateTracking_collectionView:didSelectItemAtIndexPath:)];
    } else {
        
        /**
         如果 UICollectionView 的 delegate 未实现 collectionView:didSelectItemAtIndexPath:
         那么 UICollectionViewCell 发生点击之后，不会再 respondsToSelector collectionView:didSelectItemAtIndexPath:
         直接给未实现 method 的 SEL 添加实现的方式不再适用，单独处理：
         这里直接选取了 @selector(_selectRowAtIndexPath:animated:scrollPosition:notifyDelegate:) 进行交换
         */
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        SEL privateSel_ = @selector(_userSelectItemAtIndexPath:);
#pragma clang diagnostic pop
        
        [self wk_swizzleInstanceSelector:privateSel_ replaceSelector:@selector(tracking_userSelectItemAtIndexPath:)];
    }
}

- (void)delegateTracking_collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [WKTrackingDataViewPathHelper viewPath_didSelectItemFrom:collectionView forIndexPath:indexPath];
    
    [self delegateTracking_collectionView:collectionView didSelectItemAtIndexPath:indexPath];
}

#pragma mark - 如果未实现代理

- (void)tracking_userSelectItemAtIndexPath:(NSIndexPath *) indexPath {
    
    [WKTrackingDataViewPathHelper viewPath_didSelectItemFrom:self forIndexPath:indexPath];

    [self tracking_userSelectItemAtIndexPath:indexPath];
}

@end
