//
//  RecoderTouchView.m
//  XCRecordingVideo
//
//  Created by xiaocan on 2017/5/26.
//  Copyright © 2017年 xiaocan. All rights reserved.
//

#import "RecoderTouchView.h"

@interface RecoderTouchView()

@property (nonatomic, strong) UILabel   *progressLabel;

@end

@implementation RecoderTouchView

- (instancetype)initWithFrame:(CGRect)frame{
    
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    
    
    CGFloat outLineWidth = 4.0;
    
    UIBezierPath *beizerPath = [UIBezierPath bezierPath];
    [[UIColor whiteColor] set];
    [beizerPath setLineWidth:outLineWidth];
    [beizerPath addArcWithCenter:CGPointMake(rect.size.width / 2.0, rect.size.height / 2.0) radius:rect.size.width / 2.0 - outLineWidth / 2.0 startAngle:0 endAngle:2 * M_PI clockwise:YES];
    [beizerPath stroke];
    
    UIBezierPath *rectPath = [UIBezierPath bezierPath];
    [[UIColor whiteColor] set];
    [rectPath addArcWithCenter:CGPointMake(rect.size.width / 2.0, rect.size.height / 2.0) radius:rect.size.width / 2.0 - outLineWidth - 4.0 startAngle:0 endAngle:2 * M_PI clockwise:YES];
    [rectPath fill];
    
    UIBezierPath *progressPath = [UIBezierPath bezierPath];
    [[UIColor blueColor] set];
    [progressPath setLineWidth:outLineWidth];
    [progressPath addArcWithCenter:CGPointMake(rect.size.width / 2.0, rect.size.height / 2.0) radius:rect.size.width / 2.0 - outLineWidth / 2.0 startAngle:-M_PI_2 endAngle:_progress * M_PI * 2 - M_PI_2 clockwise:YES];
    [progressPath stroke];
    
    
}


- (void)setProgress:(CGFloat)progress{
    _progress = progress;
    if (_progress < 0) {
        _progress = 0.f;
    }
    if (_progress > 1) {
        _progress = 1.0f;
    }
    [self setNeedsDisplay];
}

- (void)setBackgroundColor:(UIColor *)backgroundColor{
    [super setBackgroundColor:[UIColor clearColor]];
}

@end
