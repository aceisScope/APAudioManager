//
//  AVAudioPlayer+AudioCache.h
//  AudioManager
//
//  Created by B.H.Liu on 13-4-19.
//  Copyright (c) 2013年 Appublisher. All rights reserved.
//

#import "APAudioManager.h"
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
    APAudioLoadFromCaching
};
typedef enum APAudioLoadingType APAudioLoadingType;

@interface NSObject (AudioCache)


/**
 * Downloads the image at the given URL if not present in cache or return the cached disk path otherwise.
 *
 * @param url The URL to the audio
 * @param loadingType The type defined to stream or download&load from file system
 * @param completedPlayback A block called when operation has been completed.
 *
 *                       This block as no return value and takes the downloaded audio's path in disk as first parameter.
 *                       The second parameter is an instance of player initialised by URL either from a server or a file path
 *                       In case of error the audioPath parameter is nil and the second parameter is nil.
 *
 *                       The third parameter is an error output. 
 *
 * @return Returns an NSObject
 */
- (id)initWithURL:(NSURL *)url error:(NSError *)outError loadingType:(APAudioLoadingType)loadingType completedPlayback:(void (^)(NSString *audioPath,id player ,NSError *error))completedPlayback;

/**
 * Cancel the current download
 */
- (void)cancelCurrentAudioLoad;

@end
