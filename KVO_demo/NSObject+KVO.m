//
//  NSObject+KVO.m
//  KVO_demo
//
//  Created by litianqi on 2018/7/18.
//  Copyright © 2018年 tqUDown. All rights reserved.
//

#import "NSObject+KVO.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSString * const kTQLKVOAssociatedObservers = @"kTQLKVOAssociatedObservers";

@interface TQL_ObserVationInfo:NSObject
/** key */
@property (nonatomic, copy) NSString *key;

/** id */
@property (nonatomic, weak) NSObject * observer;

/** TQlBlock */
@property (nonatomic, copy) TQL_NotificationBlock blockInfo;


@end

@implementation TQL_ObserVationInfo


@end




@implementation NSObject (KVO)


static NSString * setterForgetter(NSString *getterName){
    //添加类的setter方法
    NSString * firstChar = [getterName substringToIndex:1];
    NSString * nameMethod = [getterName stringByReplacingOccurrencesOfString:firstChar withString:firstChar.uppercaseString];
    nameMethod = [@"set" stringByAppendingString:nameMethod];
    nameMethod = [nameMethod stringByAppendingString:@":"];
    return nameMethod;
    
}

static NSString * getterForSetter(NSString *setterName){
    //添加类的setter方法
    setterName = [setterName stringByReplacingOccurrencesOfString:@"set" withString:@""];
    NSString * firstChar = [setterName substringToIndex:1];
    NSString * nameMethod = [setterName stringByReplacingOccurrencesOfString:firstChar withString:firstChar.lowercaseString];
    nameMethod = [nameMethod stringByReplacingOccurrencesOfString:@":" withString:@""];
    return nameMethod;
    
}


static void KVO_setterMethod(id self, SEL _cmd, int _newValue){
    NSLog(@"重写方法执行ok:%s",__func__);
    NSNumber * newValue = @(_newValue);
//    id newValue = _newValue;
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = getterForSetter(setterName);

    if (!getterName) {
        // throw invalid argument exception
    }

    id oldValue = [self valueForKey:getterName];

    struct objc_super superclazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };

    // cast our pointer so the compiler won't complain
    void (*objc_msgSendSuperCasted)(void *, SEL, id) = (void *)objc_msgSendSuper;

    // call super's setter, which is original class's setter method
    objc_msgSendSuperCasted(&superclazz, _cmd, newValue);

    // look up observers and call the blocks
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kTQLKVOAssociatedObservers));
    observers = objc_getAssociatedObject(self, &kTQLKVOAssociatedObservers);
    for (TQL_ObserVationInfo *each in observers) {
        if ([each.key isEqualToString:getterName]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                each.blockInfo(each.observer, each.key, oldValue, newValue);
            });
        }
    }
    
    
}
-(void)TQL_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context notiBlock:(TQL_NotificationBlock)block{
    //1. 创建新类
  
    Class  superClass = self.class;
    //创建新类
    Class newClass = [self createNewClassFromSuperClass:superClass];
    if (newClass) {
        //注册新类
        objc_registerClassPair(newClass);
        
        //交换
        object_setClass(self, newClass);
    }
   
    
    //添加setter方法，相当于重写setter方法， "v@:i" 含义 @: id   : SEL     v : void
    
    //    OC(消息发送机制),方法由两部分组成，方法编号@selector和方法实现(imp方法指针)，先找方法编号再得到方法的指针，再执行方法的代码块。
    SEL setterSeL = NSSelectorFromString(setterForgetter(keyPath));
 
    /*添加class方法*/
    Method setterMethod = class_getInstanceMethod(superClass, setterSeL);
    if (!setterMethod) {
        NSLog(@"invalide");
    }
    
    const char * types = method_getTypeEncoding(setterMethod);
    types = "v@:@";//对象
    types = "v@:q";//int
    /*
     类
     方法名
     IMP  函数实现的指针
     类型
     */

    if (class_addMethod(newClass,setterSeL, (IMP)KVO_setterMethod, types)){
        NSLog(@"添加方法成功%@",setterForgetter(keyPath));
    }

         /*保存观察者信息*/
    TQL_ObserVationInfo * info = [TQL_ObserVationInfo new];
    info.key = keyPath;
    info.observer = observer;
    info.blockInfo = block;
    
    NSMutableArray * obserVerArray = objc_getAssociatedObject(self, &kTQLKVOAssociatedObservers);
    if (!obserVerArray) {
        obserVerArray = @[].mutableCopy;
        [obserVerArray addObject:info];
        objc_setAssociatedObject(self, &kTQLKVOAssociatedObservers, obserVerArray, OBJC_ASSOCIATION_RETAIN);
        NSLog(@"关联对象成功");
        
    }else
        [obserVerArray addObject:info];
    
}

static Class TQL_Class(id self){
    Class classTemp = class_getSuperclass(object_getClass(self));
    return classTemp;
}


- (Class)createNewClassFromSuperClass:(Class)classSuper {
    //1. 创建新类
    NSString * oldName = NSStringFromClass(classSuper);
    NSString * newName = [@"LTQ_" stringByAppendingString:oldName];
    
    
    if (![oldName hasPrefix:@"LTQ"]) {
        //创建新类
        Class newClass = objc_allocateClassPair(classSuper, [newName UTF8String], 0);
        
        
        /*添加class方法*/
        Method classMethod = class_getClassMethod(classSuper, @selector(class));
        const char * type = method_getTypeEncoding(classMethod);
        
        /*
         类
         方法名
         IMP  函数实现的指针
         类型
         */
        class_addMethod(newClass, @selector(class), (IMP)TQL_Class, type);
        NSLog(@"添加新类成功%@\n",newClass);
        
        return newClass;
    }else
        return nil;

   
    
}


-(void)AW_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context{
    //动态添加一个类
    
    NSString *oldClassName = NSStringFromClass([self class]);
    
    NSString *newClassName = [@"AWKVO_" stringByAppendingString:oldClassName];
    
    const char * newName = [newClassName UTF8String];
    
    Class myclass = objc_allocateClassPair([self class], newName, 0);
    
    
    //添加setter方法，相当于重写setter方法， "v@:i" 含义 @: id   : SEL     v : void
    
//    OC(消息发送机制),方法由两部分组成，方法编号@selector和方法实现(imp方法指针)，先找方法编号再得到方法的指针，再执行方法的代码块。
    
    class_addMethod(myclass, @selector(setAge:), (IMP)setAge, "v@:i");
    
    
    
    //注册新添加的这个类
    
    objc_registerClassPair(myclass);
    
    
    
    //修改被观察这的isa指针，isa指针指向Person类改成指向myclass这个类
    
    object_setClass(self, myclass);
    
    
    
    //将观察者的属性保存到当前类里面去
    
    objc_setAssociatedObject(self, (__bridge const void *)@"objc", observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}

//相当于重写父类的方法

void setAge(id self, SEL _cmd, int age) {
    
    
    
    //保存当前类
    
    Class myclass = [self class];
    
    
    
    //将self的isa指针指向父类
    
    object_setClass(self, class_getSuperclass([self class]));
    
    
    
    //调用父类：Build Setting--> Apple LLVM 6.0 - Preprocessing--> Enable Strict Checking of objc_msgSend Calls  改为 NO
    
    objc_msgSend(self, @selector(setAge:),age);

    
    //拿出观察者
    
   id objc = objc_getAssociatedObject(self, (__bridge const void *)@"objc");
    
    
    
    //通知观察者
    
    objc_msgSend(objc,@selector(observeValueForKeyPath:ofObject:change:context:),self,age,nil,nil);
    
    
    
    //改为子类
    
    object_setClass(self, myclass);
    
}

@end
