
//
//  PlayerView.m
//  avPlayer
//
//  Created by boyancao on 16/6/2.
//  Copyright © 2016年 boyancao. All rights reserved.
//

#import "PlayerView.h"
#import <AVFoundation/AVFoundation.h>

@interface PlayerView ()

@property (nonatomic ,strong) AVPlayer *player;

@property (nonatomic, strong) AVPlayerItem * playerItem;

@property (nonatomic, strong) AVPlayerLayer * playerlayer;

@property (nonnull, assign) BOOL * isPlay;

@property (nonatomic, strong) UIView * playView;

@property (nonatomic, strong) UISlider * slider;

@property (nonatomic, strong) UIProgressView * progressView;

@property (nonatomic, strong) UILabel * timeLable;

@property (nonatomic, strong) UIButton * playButton;

@property (nonatomic ,strong) id playbackTimeObserver;

@property (nonatomic, strong) NSDateFormatter * dateFormatter;

@property (nonatomic, strong) NSString * totalTime;

@end

@implementation PlayerView

-(instancetype)init{
    self = [super init];
    if (self) {
        [self setUp];
    }
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUp];
    }
    return self;
}

- (void)setUp{
    self.userInteractionEnabled = YES;
    self.backgroundColor = [UIColor blackColor];
    
    self.playView = [[UIView alloc]initWithFrame:CGRectMake(0, self.frame.size.height - 50, self.frame.size.width, 50)];
    self.playView.backgroundColor = [UIColor colorWithRed:0.176 green:0.176 blue:0.176 alpha:1.00];
    [self addSubview:self.playView];
    
    self.progressView = [[UIProgressView alloc]initWithFrame:CGRectMake(CGRectGetMinX(self.playView.frame) + 60, 24, self.frame.size.width - 180, 4)];
    [self.playView addSubview:self.progressView];
    [self.progressView setProgress:0.0f];
    
    self.slider = [[UISlider alloc]initWithFrame:CGRectMake(CGRectGetMinX(self.playView.frame) + 60, 24, self.frame.size.width - 180, 4)];
    [self.slider setValue:0 animated:YES];
    [self.slider addTarget:self action:@selector(valuechanged:) forControlEvents:UIControlEventValueChanged];
    [_slider addTarget:self action:@selector(sliderDragUp:) forControlEvents:UIControlEventTouchUpInside];
    [self.playView addSubview:self.slider];
    
    self.timeLable = [[UILabel alloc]initWithFrame:CGRectMake(self.frame.size.width - 100, 0, 100, 50)];
    self.timeLable.text  =@"00:00/00:00";
    [self.playView addSubview:self.timeLable];
}

-(void)setUrlStr:(NSString *)urlStr{
    _urlStr = urlStr;
    NSURL * url  = [NSURL URLWithString:_urlStr];
    self.playerItem = [AVPlayerItem playerItemWithURL:url];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerlayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerlayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - 50);
    self.playerlayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.layer addSublayer:self.playerlayer];
    
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    UIButton * butt  = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, 50)];
    [butt setBackgroundImage:[UIImage imageNamed:@"full_play_btn_hl"] forState:UIControlStateNormal];
    [butt addTarget:self action:@selector(controlStartOrPause) forControlEvents:UIControlEventTouchUpInside];
    self.playButton = butt;
    [self.playView addSubview:self.playButton];
}

- (void)controlStartOrPause{
    if (!_isPlay) {
        [self.player play];
        [self.playButton setBackgroundImage:[UIImage imageNamed:@"full_pause_btn_hl"] forState:UIControlStateNormal];
    }else{
        [self.playButton setBackgroundImage:[UIImage imageNamed:@"full_play_btn_hl"] forState:UIControlStateNormal];
        [self.player pause];
    }
    _isPlay = !_isPlay;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
   AVPlayerItem *playerItem = (AVPlayerItem *)object;
    
    if ([keyPath isEqualToString:@"status"]) {
        if ([playerItem status] == AVPlayerStatusReadyToPlay) {
            CMTime duration = self.playerItem.duration;// 获取视频总长度
            CGFloat totalSecond = playerItem.duration.value / playerItem.duration.timescale;// 转换成秒
            _totalTime = [self convertTime:totalSecond];// 转换成播放时间
            [self customVideoSlider:duration];// 自定义UISlider外观
            [self monitoringPlayback:self.playerItem];// 监听播放状态
        } else if ([playerItem status] == AVPlayerStatusFailed) {
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
        CMTime duration = _playerItem.duration;
        CGFloat totalDuration = CMTimeGetSeconds(duration);
        [self.progressView setProgress:timeInterval / totalDuration animated:YES];
    }
    
    
}

- (NSTimeInterval)availableDuration {
    NSArray *loadedTimeRanges = [self.playerItem loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}


- (void)customVideoSlider:(CMTime)duration {
    self.slider.maximumValue = CMTimeGetSeconds(duration);
    UIGraphicsBeginImageContextWithOptions((CGSize){ 1, 1 }, NO, 0.0f);
    UIImage *transparentImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self.slider setMinimumTrackImage:transparentImage forState:UIControlStateNormal];
    [self.slider setMaximumTrackImage:transparentImage forState:UIControlStateNormal];
}

- (void)monitoringPlayback:(AVPlayerItem *)playerItem {
    __weak typeof(self) weakSelf = self;
    self.playbackTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        CGFloat currentSecond = playerItem.currentTime.value/playerItem.currentTime.timescale;// 计算当前在第几秒
         [weakSelf.slider setValue:currentSecond animated:YES];
        NSString *timeString = [weakSelf convertTime:currentSecond];
        weakSelf.timeLable.text = [NSString stringWithFormat:@"%@/%@",timeString,_totalTime];
    }];
}

- (NSString *)convertTime:(CGFloat)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    if (second/3600 >= 1) {
        [[self dateFormatter] setDateFormat:@"HH:mm:ss"];
    } else {
        [[self dateFormatter] setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [[self dateFormatter] stringFromDate:d];
    return showtimeNew;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}

- (void)valuechanged:(id)sender{
    UISlider *slider = (UISlider *)sender;
    NSLog(@"value change:%f",slider.value);
    
    if (slider.value == 0.000000) {
        __weak typeof(self) weakSelf = self;
        [self.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
            [weakSelf.player play];
        }];
    }
}

- (void)sliderDragUp:(id)sender{
    
    UISlider *slider = (UISlider *)sender;
    NSLog(@"value end:%f",slider.value);
    CMTime changedTime = CMTimeMakeWithSeconds(slider.value, 1);
    
    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:changedTime completionHandler:^(BOOL finished) {
        [weakSelf.player play];
    }];
    
}

@end
