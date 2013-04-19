//
//  ViewController.m
//  AudioManager
//
//  Created by B.H.Liu on 13-4-18.
//  Copyright (c) 2013年 Appublisher. All rights reserved.
//

#import "ViewController.h"
#import "APAudioManager.h"
#import "NSObject+AudioCache.h"
 
@interface ViewController () <APAudioManagerDelegate>

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@property (strong, nonatomic) MPMoviePlayerController *mvPlayer;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    NSObject *playback = [[NSObject alloc] initWithURL:[NSURL URLWithString:@"http://statcon.247base.com/xmlserver/samples/24746000-24746999/A4316F812D071EA0E040010A0B06745F.mp3"] error:nil loadingType:APAudioLoadFromCaching  completedPlayback: ^(NSString *audioPath,id player ,NSError *error){
         
        self.mvPlayer = player;
     }];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(10, 10, 100, 40);
    [button setTitle:@"PLAY" forState:UIControlStateNormal];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(playAudio) forControlEvents:UIControlEventTouchUpInside];

}

- (void)playAudio
{
    [self.mvPlayer play];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)audioManager:(APAudioManager *)audioManager shouldDownloadImageForURL:(NSURL *)audioURL
{
    return NO;
}

@end
