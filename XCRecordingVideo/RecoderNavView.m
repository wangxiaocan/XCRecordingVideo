//
//  RecoderNavView.m
//  XCRecordingVideo
//
//  Created by xiaocan on 2017/5/26.
//  Copyright © 2017年 xiaocan. All rights reserved.
//

#import "RecoderNavView.h"
#import "Masonry.h"

@implementation RecoderNavView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 44.0)];
    if (self) {
        
        CGFloat btnWidth = 44.0;
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _backBtn .frame = CGRectMake(0, 0, btnWidth, btnWidth);
        _backBtn.backgroundColor = [UIColor greenColor];
        [self addSubview:_backBtn];
        
        _changeCameraBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _changeCameraBtn.frame = CGRectMake(self.bounds.size.width - btnWidth, 0, btnWidth, btnWidth);
        _changeCameraBtn.backgroundColor = [UIColor redColor];
        [self addSubview:_changeCameraBtn];
        
        _flashBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _flashBtn.frame = CGRectMake(_changeCameraBtn.frame.origin.x - btnWidth - 10.0, 0, btnWidth, btnWidth);
        _flashBtn.backgroundColor = [UIColor orangeColor];
        [self addSubview:_flashBtn];
        
        CGFloat insets = 12.0;
        UIEdgeInsets btnInsets = UIEdgeInsetsMake(insets, insets, insets, insets);
        _backBtn.imageEdgeInsets = btnInsets;
        _flashBtn.imageEdgeInsets = btnInsets;
        _changeCameraBtn.imageEdgeInsets = btnInsets;
    }
    return self;
}

@end
