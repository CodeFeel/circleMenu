//
//  LWCustomCircleView.h
//  LWCircle
//
//  Created by ios on 2018/1/16.
//  Copyright © 2018年 swiftHPRT. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef void(^clickSomeOne)(NSString *str);

@interface LWCustomCircleView : UIView

//在想要回传的界面中定义,block必须用copy来修饰
@property (nonatomic, copy) clickSomeOne clickButton;

- (id)initWithFrame:(CGRect)frame andImage:(UIImage *)image;

- (void)addSubviewWithSubView:(NSArray *)imageArray andTitle:(NSArray *)titleArray andSize:(CGSize)size andCenterImage:(UIImage *)centerImage;

@end
