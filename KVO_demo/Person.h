//
//  Person.h
//  KVO_demo
//
//  Created by litianqi on 2018/7/18.
//  Copyright © 2018年 tqUDown. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Person : NSObject
///** id */
//@property (nonatomic, strong)id obj;
/** age */
@property (nonatomic, strong) NSNumber *age;
@property (nonatomic, assign) NSInteger sex;

/** nama */
@property (nonatomic, copy) NSString *name;

@end
