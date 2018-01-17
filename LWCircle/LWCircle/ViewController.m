//
//  ViewController.m
//  LWCircle
//
//  Created by ios on 2018/1/16.
//  Copyright © 2018年 swiftHPRT. All rights reserved.
//

#import "ViewController.h"
#import "LWMacro.h"
#import "LWCustomCircleView.h"
@interface ViewController ()

@property (nonatomic, strong) LWCustomCircleView *circleView;
@property (nonatomic, strong) UIImageView *backImage;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:8/255.0 green:49/255.0 blue:140/255.0 alpha:1.0];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]}];
    self.title = @"圆环Demo";
    
    [self.view addSubview:self.backImage];
    [self.view addSubview:self.circleView];
    //处理回调的方法
    [self handlingCircleImageCallback];
}

- (void)handlingCircleImageCallback
{
//     __weak ViewController *weakSelf = self;
    self.circleView.clickButton = ^(NSString *str) {
        NSLog(@"%@",str);
    };
}

- (LWCustomCircleView *)circleView
{
    if (!_circleView) {
        UIImageView *earthImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"circle"]];
         _circleView = [[LWCustomCircleView alloc] initWithFrame:CGRectMake(8, 150*Height, kScreenWidth - 16, kScreenWidth - 16) andImage:earthImage.image];
        NSArray *imageArr = [NSArray arrayWithObjects:[UIImage imageNamed:@"jiaju"], [UIImage imageNamed:@"mensuo"],[UIImage imageNamed:@"anfang"],[UIImage imageNamed:@"huanjing"],[UIImage imageNamed:@"shequ"],[UIImage imageNamed:@"changjing"],nil];
        NSArray *titleArr = @[@"家居",@"门锁",@"安全",@"环境",@"社区",@"场景"];
        
        [_circleView addSubviewWithSubView:imageArr andTitle:titleArr andSize:CGSizeMake(80, 80) andCenterImage:[UIImage imageNamed:@"security_home_down"]];
       
    }
    return _circleView;
}

- (UIImageView *)backImage
{
    if (!_backImage) {
        _backImage = [[UIImageView alloc] init];
        _backImage.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
        _backImage.image = [UIImage imageNamed:@"家居控制界面背景.png"];
        
    }
    return _backImage;
}


@end
