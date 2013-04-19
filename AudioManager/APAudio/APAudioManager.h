//
//  APAudioManager.h
//  AudioManager
//
//  Created by B.H.Liu on 13-4-18.
//  Copyright (c) 2013年 Appublisher. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "APAudioCache.h"
#import "AFHTTPRequestOperation.h"

@class APAudioManager;
@protocol  APAudioManagerDelegate <NSObject>

@optional

/**
 * Controls whether audio should be downloaded when the audio is not found in the cache.
 *
 * @param audioManager The current `APAudioManager`
 * @param audioURL The url of the audio to be downloaded
 *
 * @return Return NO to prevent the downloading of the audio on cache misses. If not implemented, YES is implied.
 */
- (BOOL)audioManager:(APAudioManager *)audioManager shouldDownloadImageForURL:(NSURL *)audioURL;

@end


@interface APAudioManager : NSObject

@property (weak, nonatomic) id<APAudioManagerDelegate> delegate;


/**
 * The cache filter is a block used each time APAudioManager need to convert an URL into a cache key. This can
 * be used to remove dynamic part of an audio URL.
 *
 * The following example sets a filter in the application delegate that will remove any query-string from the
 * URL before to use it as a cache key:
 *
 * 	[[APAudioManager sharedManager] setCacheKeyFilter:^(NSURL *url)
 *	{
 *	    url = [[NSURL alloc] initWithScheme:url.scheme host:url.host path:url.path];
 *	    return [url absoluteString];
 *	}];
 */
@property (strong) NSString *(^cacheKeyFilter)(NSURL *url);

/**
 * Returns global APAudioManager instance.
 *
 * @return APAudioManager shared instance
 */
+ (APAudioManager *)sharedManager;

/**
 * Downloads the image at the given URL if not present in cache or return the cached disk path otherwise.
 *
 * @param url The URL to the audio
 * @param completedBlockWithSuccess A block called when operation has been completed.
 *
 *                       This block as no return value and takes the requested audio's path in disk as first parameter.
 *                       In case of error the image parameter is nil and the second parameter may contain an NSError.
 *
 *                       The third parameter is a Boolean indicating if the audio was retrived from the local cache
 *                       of from the network.
 *
 * @return Returns an AFHTTPRequestOperation
 */
- (AFHTTPRequestOperation*)downloadWithURL:(NSURL *)url
                CompletionBlockWithSuccess:(void (^)(NSString *audioPath, NSError *error, APAudioCacheType cacheType))success;

/**
 * Cancel all current opreations
 */
- (void)cancelAll;

/**
 * Check one or more operations running
 */
- (BOOL)isRunning;

@end
