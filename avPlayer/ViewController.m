//
//  ViewController.m
//  avPlayer
//
//  Created by boyancao on 16/6/2.
//  Copyright © 2016年 boyancao. All rights reserved.
//

#import "ViewController.h"
#import "PlayerView.h"

@interface ViewController ()

@property (nonatomic, strong) PlayerView * playerView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.playerView = [[PlayerView alloc]initWithFrame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 300)];
    self.playerView.urlStr = @"http://flv2.bn.netease.com/videolib3/1606/02/GQOob3917/SD/GQOob3917-mobile.mp4";
    [self.view addSubview:self.playerView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
