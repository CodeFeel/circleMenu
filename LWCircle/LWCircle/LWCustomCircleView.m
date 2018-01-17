//
//  LWCustomCircleView.m
//  LWCircle
//
//  Created by ios on 2018/1/16.
//  Copyright © 2018年 swiftHPRT. All rights reserved.
//

#import "LWCustomCircleView.h"
#import <AudioToolbox/AudioToolbox.h>
#import "LWMacro.h"

@interface LWCustomCircleView()

/** 播放音效 */
@property (nonatomic, assign) SystemSoundID soundID;
/** 减速定时器 */
@property (nonatomic, strong) NSTimer *timer;
/** 子试图数量 */
@property (nonatomic, assign) CGFloat numOfSubView;
/** 圆形图 */
@property (nonatomic, strong) UIImageView *circleImage;
/** 减速定时器 */
@property (nonatomic, strong) UIImageView *arrowImage;
/** 子试图数组 */
@property (nonatomic, strong) NSMutableArray *subViewArray;
/** 按钮数组 */
@property (nonatomic, strong) NSMutableArray *buttonArray;
/** 第一触碰点 */
@property (nonatomic, assign) CGPoint beginPoint;
/** 第二触碰点 */
@property (nonatomic, assign) CGPoint movePoint;
/** 正在跑 */
@property (nonatomic, assign) BOOL isPlaying;
/** 滑动时间 */
@property (nonatomic, strong) NSDate *date;
/** 开始转动时间 */
@property (nonatomic, strong) NSDate *startTouchDate;
/** 减速计数 */
@property (nonatomic, assign) NSInteger decelerTime;
/** 子试图大小 */
@property (nonatomic, assign) CGSize subViewSize;
/** 滑动手势 */
@property (nonatomic, strong) UIPanGestureRecognizer *panGes;
/** 转动的角度 */
@property (nonatomic, assign) double mStartAngle;
/** 转动临界速度，超过此速度便是快速滑动，手指离开仍会转动 */
@property (nonatomic, assign) int mFlingableValue;
/** 半径 */
@property (nonatomic, assign) int mRadius;
/** 检测按下到抬起时旋转的角度 */
@property (nonatomic, assign) float mTmpAngle;

@property (nonatomic, strong) NSTimer *flowtime;

@property (nonatomic, strong) NSTimer *reverseTime;

@property (nonatomic, assign) float anglePerSecond;
/** 转动速度 */
@property (nonatomic, assign) float speed;

@end

@implementation LWCustomCircleView

- (id)initWithFrame:(CGRect)frame andImage:(UIImage *)image
{
    if (self = [super initWithFrame:frame]) {
        self.decelerTime = 0;
        self.subViewArray = [[NSMutableArray alloc] init];
        self.circleImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        
        if (image == nil) {
            self.circleImage.layer.cornerRadius = frame.size.width / 2;
        }else {
            self.circleImage.image = image;
            self.circleImage.backgroundColor = [UIColor clearColor];
        }
        self.mRadius = frame.size.width / 2;
        self.mStartAngle = M_PI_2 * 3;
        self.mFlingableValue = 300;
        self.isPlaying = false;
        self.circleImage.userInteractionEnabled = YES;
        [self addSubview:self.circleImage];
        
    }
    return self;
}

- (void)addSubviewWithSubView:(NSArray *)imageArray andTitle:(NSArray *)titleArray andSize:(CGSize)size andCenterImage:(UIImage *)centerImage
{
    self.subViewSize = size;
    self.numOfSubView = (CGFloat)titleArray.count;
    self.buttonArray = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0; i < self.numOfSubView; i++) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(20*Width, 20*Width, size.width*Width, size.height*Height)];
        [button setImage:imageArray[i] forState:UIControlStateNormal];
        //设置image在button上的位置（上top，左left，下bottom，右right）这里可以写负值，对上写－5，那么image就象上移动5个像素
        [button setTitle:titleArray[i] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:16*Width];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        CGFloat devcide = kScreenHeight;
        if (devcide == 568.000000) {
            button.imageEdgeInsets = UIEdgeInsetsMake(6,6,8,button.titleLabel.bounds.size.width);
            button.titleEdgeInsets = UIEdgeInsetsMake(55, -button.imageView.bounds.size.width-50, 0, 8);
        }else if (devcide == 480.000000){
            button.imageEdgeInsets = UIEdgeInsetsMake(2,10,5,button.titleLabel.bounds.size.width);
            button.titleEdgeInsets = UIEdgeInsetsMake(55, -button.imageView.bounds.size.width-50, 2, 5);
        }else if (devcide == 736.000000){
            button.imageEdgeInsets = UIEdgeInsetsMake(8,8,8,button.titleLabel.bounds.size.width);
            button.titleEdgeInsets = UIEdgeInsetsMake(70, -button.imageView.bounds.size.width-40, 0, 0);
        }else{
            button.imageEdgeInsets = UIEdgeInsetsMake(5,6,8,button.titleLabel.bounds.size.width);
            button.titleEdgeInsets = UIEdgeInsetsMake(60, -button.imageView.bounds.size.width-45, 0, 0);
        }
        
        [button addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
        button.tag = 100 + i;
        
        [self.buttonArray addObject:button];
        [self.subViewArray addObject:button];
        [self.circleImage addSubview:button];
    }
    //按钮布局
    [self layoutButton];
    
    //中间按钮
    UIButton *centerBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width/3.0, self.frame.size.height/3.0)];
    centerBtn.tag = 100 + self.numOfSubView + 1;
    centerBtn.layer.cornerRadius = self.frame.size.width / 6.0;
    [centerBtn setImage:centerImage forState:UIControlStateNormal];
    centerBtn.center = CGPointMake(self.frame.size.width/2.0, self.frame.size.height / 2.0);
    [centerBtn addTarget:self action:@selector(clickBtnCenter:) forControlEvents:UIControlEventTouchUpInside];
    [self.subViewArray addObject:centerBtn];
    [self.circleImage addSubview:centerBtn];
    
    //转动手势
    self.panGes = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(zhuanPgr:)];
    [self.circleImage addGestureRecognizer:self.panGes];
    
    //加点击效果
    for (NSInteger i=0; i<self.subViewArray.count; i++) {
        UIButton *button= self.subViewArray[i];
        [button addTarget:self action:@selector(subViewOut:) forControlEvents:UIControlEventTouchUpInside];
    }
}

//在此处可添加按钮的点击效果，比如说增加点击的声音
- (void)clickBtn:(UIButton *)btn
{
    //点击之后顺时针旋转布局
    if (btn.tag == 100) {
        self.mStartAngle = M_PI_2*3;
        [self layoutButton];
    }
    if (btn.tag == 101) {
        self.mStartAngle = M_PI_2*2.32;
        [self layoutButton];
    }
    if (btn.tag == 102) {
        self.mStartAngle = M_PI_2*1.68;
        [self layoutButton];
    }
    if (btn.tag == 103) {
        self.mStartAngle = M_PI_2*1;
        [self layoutButton];
    }
    if (btn.tag == 104) {
        self.mStartAngle = M_PI_2*0.32;
        [self layoutButton];
    }
    if (btn.tag == 105) {
        //        mStartAngle = M_PI_2*3.66;
        self.mStartAngle = -M_PI_2*0.32;
        [self layoutButton];
    }
}

//按钮布局
- (void)layoutButton
{
    /**
     M_PI   pi    3.14159265358979323846
     M_PI_2 pi/2  1.57079632679489661923
     M_PI_4 pi/4  0.785398163397448309616
     */
    /**
     sin((i/self.numOfSubView) * M_PI * 2 + self.mStartAngle):布局滑动时按钮均匀分布在圆的各个位置
     (self.frame.size.width/2 -  self.subViewSize.width/2 - 20)：让按钮布局在圆环间
     */
    for (NSInteger i = 0; i < self.numOfSubView; i++) {
        
        CGFloat devcide = kScreenHeight;
        if (devcide == 480.000000) {
            CGFloat yy = 145 + sin((i/self.numOfSubView) * M_PI * 2 + self.mStartAngle) * (self.frame.size.width/2 -  self.subViewSize.width/2 - 20);
            CGFloat xx = 145 + cos((i/self.numOfSubView) * M_PI * 2 + self.mStartAngle) * (self.frame.size.width/2 - self.subViewSize.width/2 - 20);
            UIButton *button = [self.buttonArray objectAtIndex:i];
            button.center = CGPointMake(xx, yy);
        }else if (devcide == 736.000000){
            CGFloat yy = 195 + sin((i/self.numOfSubView) * M_PI * 2 + self.mStartAngle) * (self.frame.size.width/2 - self.subViewSize.width/2 - 30);
            CGFloat xx = 195 + cos((i/self.numOfSubView) * M_PI * 2 + self.mStartAngle) * (self.frame.size.width/2 - self.subViewSize.width/2 - 30);
            UIButton *button = [self.buttonArray objectAtIndex:i];
            button.center = CGPointMake(xx, yy);
        }else{
            CGFloat yy = 175 * Height + sin((i/self.numOfSubView) * M_PI * 2 + self.mStartAngle) * (self.frame.size.width/2 -self.subViewSize.width/2 - 20 * Height);
            CGFloat xx = 175 * Width + cos((i/self.numOfSubView) * M_PI * 2 + self.mStartAngle) * (self.frame.size.width/2 -self.subViewSize.width/2 - 20 * Width);
            UIButton *button = [self.buttonArray objectAtIndex:i];
            button.center = CGPointMake(xx, yy);
        }
    }
    
}
//用来对浮点数进行取模（求余）
-(void)zhuanPgr:(UIPanGestureRecognizer *)pgr
{
    if (pgr.state == UIGestureRecognizerStateBegan) {
        self.mTmpAngle = 0;
        self.beginPoint = [pgr locationInView:self];
        self.startTouchDate = [NSDate date];
    }else if (pgr.state == UIGestureRecognizerStateChanged) {
        float StartAngleLast = self.mStartAngle;
        self.movePoint = [pgr locationInView:self];
        float start = [self getAngle:self.beginPoint];
        float end = [self getAngle:self.movePoint];
        if ([self getQuadrant:self.movePoint] == 1 || [self getQuadrant:self.movePoint] == 4) {
            //一、四象限
            self.mStartAngle += end - start;
            self.mTmpAngle += end - start;
            
        }else {
            //二三象限
            self.mStartAngle += start - end;
            self.mTmpAngle += start - end;
        }
        [self layoutButton];
        self.beginPoint = self.movePoint;
        self.speed = self.mStartAngle - StartAngleLast;
        
        NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:self.startTouchDate];
        self.anglePerSecond = self.mTmpAngle * 50 / time;
        
    }else if (pgr.state == UIGestureRecognizerStateEnded) {
        //计算每秒转动的角度
        NSTimeInterval time = [[NSDate date] timeIntervalSinceDate:self.startTouchDate];
        self.anglePerSecond = self.mTmpAngle * 50 / time;
        
        if (self.anglePerSecond > 0) {
            //求绝对值的函数,顺时针转动
            if (fabs(self.anglePerSecond) > self.mFlingableValue && !self.isPlaying) {
                self.isPlaying = true;
                self.flowtime = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(flowAction) userInfo:nil repeats:YES];
                [[NSRunLoop currentRunLoop] addTimer:self.flowtime forMode:NSRunLoopCommonModes];
            }
        }else {
            //逆时针转动
            if (-fabsf(self.anglePerSecond) < -self.mFlingableValue && !self.isPlaying) {
                
                self.isPlaying = true;
                self.reverseTime = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(reverseAction) userInfo:nil repeats:YES];
                [[NSRunLoop currentRunLoop] addTimer:self.reverseTime forMode:NSRunLoopCommonModes];
            }
        }
        
        if (self.isPlaying == false){
            if (self.mStartAngle >= 0){
                if (fmod(self.mStartAngle, M_PI*2) > M_PI_2*2.32+M_PI_2*0.32 && fmod(self.mStartAngle, M_PI*2) <= M_PI_2*3+M_PI_2*0.32) {
                    self.mStartAngle = M_PI_2*3;
                    [self layoutButton];
                    self.clickButton(@"100");
                }
                if (fmod(self.mStartAngle, M_PI*2) > M_PI_2*1.68+M_PI_2*0.32 && fmod(self.mStartAngle, M_PI*2) <= M_PI_2*2.32+M_PI_2*0.32) {
                    self.mStartAngle = M_PI_2*2.32;
                    [self layoutButton];
                    self.clickButton(@"101");
                }
                if (fmod(self.mStartAngle, M_PI*2) > M_PI_2*1+M_PI_2*0.32 && fmod(self.mStartAngle, M_PI*2)<=M_PI_2*1.68+M_PI_2*0.32) {
                    self.mStartAngle = M_PI_2*1.68;
                    [self layoutButton];
                    self.clickButton(@"102");
                }
                if (fmod(self.mStartAngle, M_PI*2) > M_PI_2*0.32+M_PI_2*0.32 && fmod(self.mStartAngle, M_PI*2)<=M_PI_2*1+M_PI_2*0.32) {
                    self.mStartAngle = M_PI_2*1;
                    [self layoutButton];
                    self.clickButton(@"103");
                }
                if (fmod(self.mStartAngle, M_PI*2) > 0 && fmod(self.mStartAngle, M_PI*2) <= M_PI_2*0.32+M_PI_2*0.32) {
                    self.mStartAngle = M_PI_2*0.32;
                    [self layoutButton];
                    self.clickButton(@"104");
                }
                if (fmod(self.mStartAngle, M_PI*2)-M_PI*2 <= 0 && fmod(self.mStartAngle, M_PI*2)-M_PI*2 >= -M_PI_2*0.32*2) {
                    //        mStartAngle = M_PI_2*3.66;
                    self.mStartAngle = -M_PI_2*0.32;
                    [self layoutButton];
                    self.clickButton(@"105");
                }
                
            }else {
                
                if (fmod(self.mStartAngle, M_PI*2)+M_PI*2 > M_PI_2*2.32+M_PI_2*0.32 && fmod(self.mStartAngle, M_PI*2)+M_PI*2<=M_PI_2*3+M_PI_2*0.32) {
                    self.mStartAngle = M_PI_2*3;
                    [self layoutButton];
                    self.clickButton(@"100");
                }
                if (fmod(self.mStartAngle, M_PI*2)+M_PI*2 > M_PI_2*1.68+M_PI_2*0.32 && fmod(self.mStartAngle, M_PI*2)+M_PI*2<=M_PI_2*2.32+M_PI_2*0.32) {
                    self.mStartAngle = M_PI_2*2.32;
                    [self layoutButton];
                    self.clickButton(@"101");
                }
                if (fmod(self.mStartAngle, M_PI*2)+M_PI*2 > M_PI_2*1+M_PI_2*0.32 && fmod(self.mStartAngle, M_PI*2)+M_PI*2<=M_PI_2*1.68+M_PI_2*0.32) {
                    self.mStartAngle = M_PI_2*1.68;
                    [self layoutButton];
                    self.clickButton(@"102");
                }
                if (fmod(self.mStartAngle, M_PI*2)+M_PI*2 > M_PI_2*0.32+M_PI_2*0.32 && fmod(self.mStartAngle, M_PI*2)+M_PI*2<=M_PI_2*1+M_PI_2*0.32) {
                    self.mStartAngle = M_PI_2*1;
                    [self layoutButton];
                    self.clickButton(@"103");
                }
                if (fmod(self.mStartAngle, M_PI*2)+M_PI*2 > 0+M_PI_2*0.32 && fmod(self.mStartAngle, M_PI*2)+M_PI*2<=M_PI_2*0.32+M_PI_2*0.32) {
                    self.mStartAngle = M_PI_2*0.32;
                    [self layoutButton];
                   self.clickButton(@"104");
                }
                if (fmod(self.mStartAngle, M_PI*2) <= 0 && fmod(self.mStartAngle, M_PI*2) >= -M_PI_2*0.32*2) {
                    //        mStartAngle = M_PI_2*3.66;
                    self.mStartAngle = -M_PI_2*0.32;
                    [self layoutButton];
                    self.clickButton(@"105");
                }
            }
        }
        
        
    }
}

//获取当前点弧度
/**
 hypot:计算直角三角形的斜边长
 */
-(float)getAngle:(CGPoint)point {
    double x = point.x - self.mRadius;
    double y = point.y - self.mRadius;
    return (float) (asin(y / hypot(x, y)));
}

/** 根据当前位置计算象限 */
-(int) getQuadrant:(CGPoint) point {
    int tmpX = (int) (point.x - self.mRadius);
    int tmpY = (int) (point.y - self.mRadius);
    if (tmpX >= 0) {
        return tmpY >= 0 ? 1 : 4;
    } else {
        return tmpY >= 0 ? 2 : 3;
    }
}

- (void)flowAction
{
    if (self.speed < 0.1) {
        [UIView animateWithDuration:2 animations:^{
            
        } completion:^(BOOL finished) {
            
        }];
        self.isPlaying = false;
        [self.flowtime invalidate];
        self.flowtime = nil;
        //停止转动时，布局好按钮位置,不需要这样的效果可注释
        if (fmod(self.mStartAngle, M_PI*2) > M_PI_2*2.32+M_PI_2*0.32 && fmod(self.mStartAngle, M_PI*2) <= M_PI_2*3+M_PI_2*0.32) {
            self.mStartAngle = M_PI_2*3;
            [self layoutButton];
            self.clickButton(@"100");
        }
        if (fmod(self.mStartAngle, M_PI*2) > M_PI_2*1.68+M_PI_2*0.32 && fmod(self.mStartAngle, M_PI*2) <= M_PI_2*2.32+M_PI_2*0.32) {
            self.mStartAngle = M_PI_2*2.32;
            [self layoutButton];
            self.clickButton(@"101");
        }
        if (fmod(self.mStartAngle, M_PI*2) > M_PI_2*1+M_PI_2*0.32 && fmod(self.mStartAngle, M_PI*2) <= M_PI_2*1.68+M_PI_2*0.32) {
            self.mStartAngle = M_PI_2*1.68;
            [self layoutButton];
            self.clickButton(@"102");
        }
        if (fmod(self.mStartAngle, M_PI*2) > M_PI_2*0.32+M_PI_2*0.32 && fmod(self.mStartAngle, M_PI*2) <= M_PI_2*1+M_PI_2*0.32) {
            self.mStartAngle = M_PI_2*1;
            [self layoutButton];
            self.clickButton(@"103");
        }
        if (fmod(self.mStartAngle, M_PI*2) > 0 && fmod(self.mStartAngle, M_PI*2) <= M_PI_2*0.32+M_PI_2*0.32) {
            self.mStartAngle = M_PI_2*0.32;
            [self layoutButton];
           self.clickButton(@"104");
        }
        if (fmod(self.mStartAngle, M_PI*2)-M_PI*2 <= 0 && fmod(self.mStartAngle, M_PI*2)-M_PI*2 >= -M_PI_2*0.32*2) {
            //        mStartAngle = M_PI_2*3.66;
            self.mStartAngle = -M_PI_2*0.32;
            [self layoutButton];
            self.clickButton(@"105");
        }
        return;
        
    }
    
    // 不断改变mStartAngle，让其滚动，/30为了避免滚动太快
    self.mStartAngle += self.speed ;
    self.speed = self.speed/1.1;
    // 逐渐减小这个值
    //    anglePerSecond /= 1.1;
    [self layoutButton];
}

- (void)reverseAction
{
    
    if (self.speed > -0.1) {
        [UIView animateWithDuration:2 animations:^{

        } completion:^(BOOL finished) {

        }];
        self.isPlaying = false;
        [self.reverseTime invalidate];
        self.reverseTime = nil;
        //停止转动时，布局好按钮位置,不需要这样的效果可注释
        if ((fmod(self.mStartAngle, M_PI*2)+M_PI*2 > M_PI_2*2.32+M_PI_2*0.32 && fmod(self.mStartAngle, M_PI*2)+M_PI*2 <= M_PI_2*3+M_PI_2*0.32) || (fmod(self.mStartAngle, M_PI*2)>M_PI_2*2.32+M_PI_2*0.32 && fmod(self.mStartAngle, M_PI*2)<=M_PI_2*3+M_PI_2*0.32)) {
            self.mStartAngle = M_PI_2*3;
            [self layoutButton];
            self.clickButton(@"100");
        }
        if ((fmod(self.mStartAngle, M_PI*2)+M_PI*2>M_PI_2*1.68+M_PI_2*0.32 && fmod(self.mStartAngle, M_PI*2)+M_PI*2<=M_PI_2*2.32+M_PI_2*0.32)||(fmod(self.mStartAngle, M_PI*2)>M_PI_2*1.68+M_PI_2*0.32 && fmod(self.mStartAngle, M_PI*2)<=M_PI_2*2.32+M_PI_2*0.32)) {
            self.mStartAngle = M_PI_2*2.32;
            [self layoutButton];
            self.clickButton(@"101");
        }
        if ((fmod(self.mStartAngle, M_PI*2)+M_PI*2>M_PI_2*1+M_PI_2*0.32 && fmod(self.mStartAngle, M_PI*2)+M_PI*2<=M_PI_2*1.68+M_PI_2*0.32)||(fmod(self.mStartAngle, M_PI*2)>M_PI_2*1+M_PI_2*0.32&&fmod(self.mStartAngle, M_PI*2)<=M_PI_2*1.68+M_PI_2*0.32)) {
            self.mStartAngle = M_PI_2*1.68;
            [self layoutButton];
            self.clickButton(@"102");
        }
        if ((fmod(self.mStartAngle, M_PI*2)+M_PI*2 > M_PI_2*0.32+M_PI_2*0.32 && fmod(self.mStartAngle, M_PI*2)+M_PI*2 <= M_PI_2*1+M_PI_2*0.32) || (fmod(self.mStartAngle, M_PI*2) > M_PI_2*0.32+M_PI_2*0.32&&fmod(self.mStartAngle, M_PI*2) <= M_PI_2*1+M_PI_2*0.32)) {
            self.mStartAngle = M_PI_2*1;
            [self layoutButton];
            self.clickButton(@"103");
        }
        if ((fmod(self.mStartAngle, M_PI*2)+M_PI*2>0 && fmod(self.mStartAngle, M_PI*2)+M_PI*2 <= M_PI_2*0.32+M_PI_2*0.32)||(fmod(self.mStartAngle, M_PI*2)>0&&fmod(self.mStartAngle, M_PI*2)<=M_PI_2*0.32+M_PI_2*0.32)) {
            self.mStartAngle = M_PI_2*0.32;
            [self layoutButton];
            self.clickButton(@"104");
        }
        if (fmod(self.mStartAngle, M_PI*2)<=0 && fmod(self.mStartAngle, M_PI*2) >= -M_PI_2*0.32*2) {
            //        mStartAngle = M_PI_2*3.66;
            self.mStartAngle = -M_PI_2*0.32;
            [self layoutButton];
            self.clickButton(@"105");
        }
        return;
    }
    
    self.mStartAngle += self.speed;
    self.speed = self.speed/1.1;
    
    [self layoutButton];
}

//对于中间的按钮来说，可点击后缩放圆环，再次点击展示圆环，根据项目来做具体的效果
- (void)clickBtnCenter:(UIButton *)btnCenter
{
    NSLog(@"圆心按钮点击了");
}


//按钮的点击回调方法
-(void)subViewOut:(UIButton *)button
{
    NSLog(@"快点播放，别要点我 %zd", button.tag);
    if (self.clickButton) {
        self.clickButton([NSString stringWithFormat:@"%zd",button.tag]);
    }
    
}



@end










