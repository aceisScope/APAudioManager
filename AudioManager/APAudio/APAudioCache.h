//
//  APAudioCache.h
//  AudioManager
//
//  Created by B.H.Liu on 13-4-18.
//  Copyright (c) 2013年 Appublisher. All rights reserved.
//

#import <Foundation/Foundation.h>

enum APAudioCacheType
{
    /**
     * The audio wasn't available from disk cache, but was downloaded from the web.
     */
    APAudioCacheNone = 0,
    /**
     * The audio was obtained from the disk cache.
     */
    APAudioCacheDisk
};
typedef enum APAudioCacheType APAudioCacheType;


/**
 * APAudioCache maintains a disk cache. Disk cache write operations are performed
 * asynchronous so it doesn’t add unnecessary latency to the UI.
 */
@interface APAudioCache : NSObject

/**
 * The maximum length of time to keep an image in the cache, in seconds
 */
@property (assign, nonatomic) NSInteger maxCacheAge;

/**
 * Returns global shared cache instance
 *
 * @return APAudioCache global instance
 */
+ (APAudioCache *)sharedAudioCache;

/**
 * Init a new cache store with a specific namespace
 *
 * @param ns The namespace to use for this cache store
 */
- (id)initWithNamespace:(NSString *)ns;

/**
 * Store an audio into disk cache at the given key.
 *
 * @param data The audio data as returned by the server
 * @param key The unique image cache key, usually it's image absolute URL
 */
- (void)storeAudioData:(NSData *)data forKey:(NSString *)key;

/**
 * Query the disk cache asynchronously.
 *
 * @param key The unique key used to store the wanted audio
 */
- (void)queryDiskCacheForKey:(NSString *)key done:(void (^)(NSString *audioPath, APAudioCacheType cacheType))doneBlock;

/**
 * Remove the audio from disk cache synchronously
 *
 * @param key The unique audio cache key
 */
- (void)removeAudioForKey:(NSString *)key;

/**
 * Clear all disk cached images
 */
- (void)clearDisk;

/**
 * Remove all expired cached image from disk
 */
- (void)cleanDisk;

/**
 * Get the size used by the disk cache
 */
- (unsigned long long)getSize;

/**
 * Get the number of audios in the disk cache
 */
- (int)getDiskCount;

@end
