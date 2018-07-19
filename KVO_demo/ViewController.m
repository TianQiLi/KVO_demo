//
//  ViewController.m
//  KVO_demo
//
//  Created by litianqi on 2018/7/18.
//  Copyright © 2018年 tqUDown. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"
#import "NSObject+KVO.h"
@interface ViewController ()
/**  */
@property (nonatomic, strong)  Person * person;
@end

@implementation ViewController

- (void)dealloc{
    NSLog(@"%s\n",__func__);
    [self removeObserver:_person forKeyPath:@"age"];
}

- (IBAction)clickBtn:(id)sender {
    self.person.age = @10;
    self.person.name = @"wang";
    self.person.sex = 1;
    NSLog(@"%@",self.person.class);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    Person * personTest = [Person new];
    personTest.age = @1;
    personTest.name = @"li";
    personTest.sex = 1;
    _person = personTest;
    
    
//    [self.person addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    NSLog(@"%@",_person.class);
//    [self.person TQL_addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil notiBlock:^(id observedObject, NSString *keyPath, id newValue, id oldValue) {
//        NSLog(@"%@",newValue);
//        NSLog(@"%@",oldValue);
//    }];
    
    [self.person TQL_addObserver:self forKeyPath:@"sex" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil notiBlock:^(id observedObject, NSString *keyPath, id newValue, id oldValue) {
        NSLog(@"回调啦 new age = %@",newValue);
        NSLog(@"回调啦 old age = %@",oldValue);
    }];
    
    
//    [self.person AW_addObserver:self forKeyPath:@"age" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    NSLog(@"%@\n",change);
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
