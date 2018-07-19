//
//  NSObject+KVO.h
//  KVO_demo
//
//  Created by litianqi on 2018/7/18.
//  Copyright © 2018年 tqUDown. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^TQL_NotificationBlock)(id observedObject, NSString * keyPath ,id newValue ,id oldValue);

@interface NSObject (KVO)
 
-(void)TQL_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context notiBlock:(TQL_NotificationBlock)block;

@end
