//
//  AVAudioPlayer+AudioCache.m
//  AudioManager
//
//  Created by B.H.Liu on 13-4-19.
//  Copyright (c) 2013年 Appublisher. All rights reserved.
//

#import "NSObject+AudioCache.h"
#import <objc/runtime.h>

static char operationKey;

@implementation NSObject (AudioCache)

- (id)initWithURL:(NSURL *)url error:(NSError *)outError loadingType:(APAudioLoadingType)loadingType completedPlayback:(void (^)(NSString *audioPath,id player ,NSError *error))completedPlayback
{
    [self cancelCurrentAudioLoad];
    
    self = [[NSObject alloc] init];
    
    if (loadingType == APAudioLoadByStreaming)
    {
//        dispatch_queue_t backgroundQueue = dispatch_queue_create("com.mycompany.myqueue", 0);
//        
//        dispatch_async(backgroundQueue, ^(void){
//            NSData *soundData = [NSData dataWithContentsOfURL:url];
//            AVAudioPlayer *avplayer = [[AVAudioPlayer alloc] initWithData:soundData error: nil];
//            
//            dispatch_async(dispatch_get_main_queue(), ^{
//                if (completedPlayback) {
//                    completedPlayback(nil,avplayer,outError);
//                }
//            });
//        });
    
        
        if (completedPlayback) {
            
            MPMoviePlayerController * mvplayer = [[MPMoviePlayerController alloc] init];
            [mvplayer setContentURL:url];
            [mvplayer prepareToPlay];
            
            completedPlayback(nil,mvplayer,outError);
        }
    }
    
    else
    {
        AFHTTPRequestOperation *operation =  [[APAudioManager sharedManager] downloadWithURL:url CompletionBlockWithSuccess:^(NSString *audioPath, NSError *error, APAudioCacheType cacheType){
            
//            NSData *songFile = [[NSData alloc] initWithContentsOfURL:[NSURL fileURLWithPath:audioPath] options:NSDataReadingMappedIfSafe error:nil ];
//            AVAudioPlayer *avplayer =  [[AVAudioPlayer alloc] initWithData:songFile error:nil];
            
            if (completedPlayback) {
                
                MPMoviePlayerController *mvplayer = [[MPMoviePlayerController alloc]initWithContentURL:[NSURL fileURLWithPath:audioPath]];
                completedPlayback(audioPath,cacheType == APAudioCacheDisk?mvplayer:nil,outError);
            }
            
        }];
        
        objc_setAssociatedObject(self, &operationKey, operation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return self;
}

- (void)cancelCurrentAudioLoad
{
    // Cancel in progress downloader from queue
    AFHTTPRequestOperation * operation = objc_getAssociatedObject(self, &operationKey);
    if (operation)
    {
        [operation cancel];
        objc_setAssociatedObject(self, &operationKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

@end
