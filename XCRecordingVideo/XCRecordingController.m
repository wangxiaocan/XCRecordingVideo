//
//  XCRecordingController.m
//  XCRecordingVideo
//
//  Created by xiaocan on 2017/5/25.
//  Copyright © 2017年 xiaocan. All rights reserved.
//

#import "XCRecordingController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>

#import "RecoderTouchView.h"
#import "RecoderNavView.h"

#define VIEW_WIDTH      ([UIScreen mainScreen].bounds.size.width)
#define VIEW_HEIGHT     ([UIScreen mainScreen].bounds.size.height)


#define RECODER_TIME    10.0



@interface XCRecordingController ()<AVCaptureFileOutputRecordingDelegate>//必须遵守不然拿不到视频

@property (nonatomic, assign) dispatch_queue_t              sessionQueue;

/** AVCaptureSession对象来执行输入设备和输出设备之间的数据传递 */
@property (nonatomic, strong) AVCaptureSession              *session;

/** 视频输入设备 */
@property (nonatomic, strong) AVCaptureDeviceInput          *videoInput;

/** 声音输入设备 */
@property (nonatomic, strong) AVCaptureDeviceInput          *audioInput;

/** 视频输出流 */
@property (nonatomic, strong) AVCaptureMovieFileOutput      *movieFileOutput;

/** 预览图层 */
@property (nonatomic, strong) AVCaptureVideoPreviewLayer    *previewLayer;

@property (nonatomic, strong) UIView                        *backView;

/** 计时器 */
@property (nonatomic, strong) NSTimer                       *timer;



@property (nonatomic, strong) RecoderNavView                *navigationView; /**< 顶部功能栏 */
@property (nonatomic, strong) RecoderTouchView              *recoderView;   /**< 录制按钮 */
@property (nonatomic, assign) CGFloat                       recoderDuration;/**< 录制时间 */

@property (nonatomic, assign) BOOL                          isBackCamera;

@end

@implementation XCRecordingController

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.session startRunning];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [self.session stopRunning];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _recoderDuration = 0.f;
    
    
    [self initAllSubViews];
    [self initAVCaptureSessionForBackCamera];
    
}


/** 添加视频录制相关按钮 */
- (void)initAllSubViews{
    
    self.backView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT)];
    self.backView.layer.masksToBounds = YES;
    self.backView.userInteractionEnabled = NO;
    self.backView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.backView];
    
    self.recoderView = [[RecoderTouchView alloc]init];
    self.recoderView.bounds = CGRectMake(0, 0, 60.0, 60.0);
    self.recoderView.center = CGPointMake(VIEW_WIDTH / 2.0, VIEW_HEIGHT - 20.0 - 30.0);
    [self.view addSubview:self.recoderView];
    
    self.navigationView = [[RecoderNavView alloc]init];
    [self.view addSubview:self.navigationView];
    self.navigationView.backBtn.tag = 0;
    self.navigationView.flashBtn.tag = 1;
    self.navigationView.changeCameraBtn.tag = 2;
    
    [self.navigationView.backBtn addTarget:self action:@selector(navigationViewBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationView.flashBtn addTarget:self action:@selector(navigationViewBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.navigationView.changeCameraBtn addTarget:self action:@selector(navigationViewBtnClicked:) forControlEvents:UIControlEventTouchUpInside];
    
}



#pragma mark-
#pragma mark- 初始化相机，连接硬件和软件
- (void)initAVCaptureSessionForBackCamera{
    if (![self isCameraAvailable]) {
        return;
    }
    if (self.session) {
        [self.session stopRunning];
        self.session = nil;
    }
    _isBackCamera = YES;
    self.session = [[AVCaptureSession alloc]init];
    
    //设置视频录制分辨率  可以设置4K
    self.session.sessionPreset = AVCaptureSessionPreset1280x720;
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
        
        AVCapturePhotoSettings *photoSet = [AVCapturePhotoSettings photoSettings];
        //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
        [device lockForConfiguration:nil];
        [photoSet setFlashMode:AVCaptureFlashModeAuto];
        [device unlockForConfiguration];
    }else{
        //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
        [device lockForConfiguration:nil];
        [device setFlashMode:AVCaptureFlashModeAuto];
        [device unlockForConfiguration];
    }
    
    NSError *error;
    self.videoInput = [[AVCaptureDeviceInput alloc]initWithDevice:device error:&error];
    self.audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:nil];
    if (error) {
        NSLog(@"%@",error);
    }
    
    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc]init];
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddInput:self.audioInput]) {
        [self.session addInput:self.audioInput];
    }
    if ([self.session canAddOutput:self.movieFileOutput]) {
        [self.session addOutput:self.movieFileOutput];
    }
    
    if (self.previewLayer) {
        [self.previewLayer removeFromSuperlayer];
        self.previewLayer = nil;
    }
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    self.previewLayer.frame = CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT);
    
    [self.backView.layer insertSublayer:self.previewLayer atIndex:0];
}

/** 前置摄像头 */
- (void)initAVCaptureSessionFrontCamera{
    if (![self isFrontCameraAvailable]) {
        return;
    }
    if (self.session) {
        [self.session stopRunning];
        self.session = nil;
    }
    _isBackCamera = NO;
    self.session = [[AVCaptureSession alloc]init];
    
    //设置视频录制分辨率  可以设置4K
    self.session.sessionPreset = AVCaptureSessionPreset1280x720;
    
    AVCaptureDevice *device;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *deviceT in devices) {
        if ([deviceT position] == AVCaptureDevicePositionFront) {
            device = deviceT;
            break;
        }
    }
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
        
        AVCapturePhotoSettings *photoSet = [AVCapturePhotoSettings photoSettings];
        //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
        [device lockForConfiguration:nil];
        [photoSet setFlashMode:AVCaptureFlashModeAuto];
        [device unlockForConfiguration];
    }else{
        //更改这个设置的时候必须先锁定设备，修改完后再解锁，否则崩溃
        [device lockForConfiguration:nil];
        [device setFlashMode:AVCaptureFlashModeAuto];
        [device unlockForConfiguration];
    }
    
    NSError *error;
    self.videoInput = [[AVCaptureDeviceInput alloc]initWithDevice:device error:&error];
    self.audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:nil];
    if (error) {
        NSLog(@"%@",error);
    }
    
    self.movieFileOutput = [[AVCaptureMovieFileOutput alloc]init];
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddInput:self.audioInput]) {
        [self.session addInput:self.audioInput];
    }
    if ([self.session canAddOutput:self.movieFileOutput]) {
        [self.session addOutput:self.movieFileOutput];
    }
    
    if (self.previewLayer) {
        [self.previewLayer removeFromSuperlayer];
        self.previewLayer = nil;
    }
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.session];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    self.previewLayer.frame = CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEIGHT);
    
    [self.backView.layer insertSublayer:self.previewLayer atIndex:0];
}




#pragma mark-
#pragma mark- 开始视频录制
- (void)startRecoderVideo{
    AVCaptureConnection *movieConnection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    AVCaptureVideoOrientation avcaptureOrientation = AVCaptureVideoOrientationPortrait;
    [movieConnection setVideoOrientation:avcaptureOrientation];
    [movieConnection setVideoScaleAndCropFactor:1.0];
    
    NSString *currentDate = [NSString stringWithFormat:@"%lf",[[NSDate date] timeIntervalSince1970]];
    NSString *savePath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mov",currentDate]];
    NSURL *saveUrl = [NSURL fileURLWithPath:savePath];
    if (![self.movieFileOutput isRecording]) {
        [self.movieFileOutput startRecordingToOutputFileURL:saveUrl recordingDelegate:self];
        if (_timer) {
            [_timer invalidate];
            _timer = nil;
        }
        _recoderDuration = 0.f;
        self.recoderView.progress = 0.f;
        _timer = [NSTimer scheduledTimerWithTimeInterval:(1.0 / 60.0) target:self selector:@selector(timerFunction) userInfo:self repeats:YES];
    }
}

#pragma mark-
#pragma mark- 暂停视频录制
- (void)stopRecoderVideo{
    if ([self.movieFileOutput isRecording]) {
        [self.movieFileOutput stopRecording];
    }
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    _recoderDuration = 0.f;
    self.recoderView.progress = 0.f;
}


#pragma mark-
#pragma mark- 视频录制代理方法
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    
    //判断最小时间的哈
    if (CMTimeGetSeconds(captureOutput.recordedDuration) < 10) {
        NSLog(@"%f",CMTimeGetSeconds(captureOutput.recordedDuration));
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频时间过短" message:nil delegate:self
                                              cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
    
    NSLog(@"%s-- url = %@ ,recode = %f , int %lld kb", __func__, outputFileURL, CMTimeGetSeconds(captureOutput.recordedDuration), captureOutput.recordedFileSize / 1024);
    
    ALAssetsLibrary *lib = [[ALAssetsLibrary alloc] init];
    [lib writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
        
    }];
}



#pragma mark-
#pragma mark- 手势
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.view];
    if (CGRectContainsPoint(self.recoderView.frame, touchPoint)) {
        [self startRecoderVideo];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self stopRecoderVideo];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    //[self stopRecoderVideo];
}

- (void)timerFunction{
    CGFloat movieDuration = CMTimeGetSeconds(self.movieFileOutput.recordedDuration);
    if (movieDuration >= RECODER_TIME) {
        [self stopRecoderVideo];
    }
    self.recoderView.progress = movieDuration / RECODER_TIME;
    _recoderDuration += 1.0 / 60.0;
}



#pragma mark-
#pragma mark- 功能按钮
- (void)navigationViewBtnClicked:(UIButton *)sender{
    if (sender.tag == 0) {//退出界面
        if (self.presentingViewController) {
            [self dismissViewControllerAnimated:YES completion:^{
                
            }];
        }
        if (self.navigationController) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }else if (sender.tag == 1){//闪光灯
        [self trunOffFlash];
    }else if (sender.tag == 2){//切换前后摄像头
        if (_isBackCamera) {//切换到前置摄像头
            [self initAVCaptureSessionFrontCamera];
            [self.session startRunning];
        }else{//切换到后置摄像头
            [self initAVCaptureSessionForBackCamera];
            [self.session startRunning];
        }
    }
}


/** 关闭闪光灯 */
- (void)trunOffFlash{
    NSArray *deivces = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *device;
    for (AVCaptureDevice *deviceT in deivces) {
        if ([deviceT position] == AVCaptureDevicePositionBack) {
            device = deviceT;
            break;
        }
    }
    if (device) {
        if (device.torchMode == AVCaptureTorchModeOn) {//关闭闪光灯
            [device lockForConfiguration:nil];
            device.torchMode = AVCaptureTorchModeOff;
            device.flashMode = AVCaptureTorchModeOff;
            [device unlockForConfiguration];
        }else{//开启闪光灯
            [device lockForConfiguration:nil];
            device.torchMode = AVCaptureTorchModeOn;
            device.flashMode = AVCaptureFlashModeOn;
            [device unlockForConfiguration];
        }
    }
}







#pragma mark-
#pragma mark- 判断设备硬件是否可用

// 判断设备是否有摄像头
- (BOOL)isCameraAvailable{
    return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
}

// 前面的摄像头是否可用
- (BOOL)isFrontCameraAvailable{
    return [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
}

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
