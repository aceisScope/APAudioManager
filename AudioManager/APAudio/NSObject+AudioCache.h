//
//  AVAudioPlayer+AudioCache.h
//  AudioManager
//
//  Created by B.H.Liu on 13-4-19.
//  Copyright (c) 2013年 Appublisher. All rights reserved.
//

#import "APAudioManager.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MPMoviePlayerController.h>

enum APAudioLoadingType
{
    /**
     * The audio is streamed from the web.
     */
    APAudioLoadByStreaming = 0,
    /**
     * The audio was downloaded first, then obtained from the disk cache.
     */
    APAudioLoadFromCaching,
};
typedef enum APAudioLoadingType APAudioLoadingType;

@interface NSObject (AudioCache)

- (id)initWithURL:(NSURL *)url error:(NSError *)outError loadingType:(APAudioLoadingType)loadingType completedPlayback:(void (^)(NSString *audioPath,id player ,NSError *error))completedPlayback;

/**
 * Cancel the current download
 */
- (void)cancelCurrentAudioLoad;

@end
