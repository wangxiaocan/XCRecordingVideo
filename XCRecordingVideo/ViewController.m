//
//  ViewController.m
//  XCRecordingVideo
//
//  Created by xiaocan on 2017/5/25.
//  Copyright © 2017年 xiaocan. All rights reserved.
//

#import "ViewController.h"
#import "XCRecordingController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    XCRecordingController *recordeContro = [[XCRecordingController alloc]init];
    [self presentViewController:recordeContro animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)prefersStatusBarHidden{
    return NO;
}


@end
