//
//  APAudioCache.m
//  AudioManager
//
//  Created by B.H.Liu on 13-4-18.
//  Copyright (c) 2013年 Appublisher. All rights reserved.
//

#import "APAudioCache.h"
#import <CommonCrypto/CommonDigest.h>
#import <mach/mach.h>
#import <mach/mach_host.h>

#if OS_OBJECT_USE_OBJC
#define SDDispatchQueueRelease(q)
#define SDDispatchQueueSetterSementics strong
#else
#define SDDispatchQueueRelease(q) (dispatch_release(q))
#define SDDispatchQueueSetterSementics assign
#endif

static const NSInteger kDefaultCacheMaxCacheAge = 60 * 60 * 24 * 7; // 1 week

@interface APAudioCache ()

@property (strong, nonatomic) NSString *diskCachePath;
@property (SDDispatchQueueSetterSementics, nonatomic) dispatch_queue_t ioQueue;

@end

@implementation APAudioCache

+ (APAudioCache *)sharedAudioCache
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

- (id)init
{
    return [self initWithNamespace:@"default"];
}

- (id)initWithNamespace:(NSString *)ns
{
    if ((self = [super init]))
    {
        NSString *fullNamespace = [@"com.appublisher.APAudioCache." stringByAppendingString:ns];
        
        // Create IO serial queue
        _ioQueue = dispatch_queue_create("com.appublisher.APAudioCache", DISPATCH_QUEUE_SERIAL);
        
        // Init default values
        _maxCacheAge = kDefaultCacheMaxCacheAge;
        
        // Init the disk cache
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        _diskCachePath = [paths[0] stringByAppendingPathComponent:fullNamespace];
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            
            // ensure all cache directories are there (needed only once)
            NSError *error = nil;
            if(![[NSFileManager new] createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:&error]) {
                NSLog(@"Failed to create cache directory at %@", _diskCachePath);
            }
        });

        
#if TARGET_OS_IPHONE
        // Subscribe to app events
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemory)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cleanDisk)
                                                     name:UIApplicationWillTerminateNotification
                                                   object:nil];
#endif
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    SDDispatchQueueRelease(_ioQueue);
}

#pragma mark APAudioCache (private)

- (NSString*) fileNameForResourceAtURL:(NSString*)url
{
    NSString * fileName = url;
    if ([url hasPrefix:@"http://"]) fileName = [url substringFromIndex:[@"http://" length]];
    else if ([url hasPrefix:@"https://"]) fileName = [url substringFromIndex:[@"https://" length]];
    
    fileName = [fileName stringByReplacingOccurrencesOfString:@"/" withString:@"__"];
    return fileName;
}

- (NSString *)cachePathForKey:(NSString *)key
{
//    const char *str = [key UTF8String];
//    unsigned char r[CC_MD5_DIGEST_LENGTH];
//    CC_MD5(str, (CC_LONG)strlen(str), r);
//    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
//                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    NSString *filename = [self fileNameForResourceAtURL:key];
    
    return [self.diskCachePath stringByAppendingPathComponent:filename];
}

- (void)storeAudioData:(NSData *)data forKey:(NSString *)key
{
    if (!data || !key)
    {
        return;
    }

    dispatch_async(self.ioQueue, ^
                   {                       
                       if (data)
                       {
                           // Can't use defaultManager in other thread
                           NSFileManager *fileManager = NSFileManager.new;
                           
                           if (![fileManager fileExistsAtPath:_diskCachePath])
                           {
                               [fileManager createDirectoryAtPath:_diskCachePath withIntermediateDirectories:YES attributes:nil error:NULL];
                           }
                           
                           [fileManager createFileAtPath:[self cachePathForKey:key] contents:data attributes:nil];
                       }
                   });
    

}

- (void)queryDiskCacheForKey:(NSString *)key done:(void (^)(NSString *audioPath, APAudioCacheType cacheType))doneBlock
{
    if (!doneBlock) return;
    
    if (!key)
    {
        doneBlock(nil, APAudioCacheNone);
        return;
    }
    
    //check disk
    dispatch_async(self.ioQueue, ^
                   {
                       @autoreleasepool
                       {
                           NSFileManager *fileManager = [NSFileManager new];
                           if (![fileManager fileExistsAtPath:[self cachePathForKey:key]])
                           {
                               doneBlock([self cachePathForKey:key], APAudioCacheNone);
                           }
                           
                           else
                           {
                               dispatch_async(dispatch_get_main_queue(), ^
                                              {
                                                  doneBlock([self cachePathForKey:key], APAudioCacheDisk);
                                              });
                           }

                       }
                   });

}

- (void)removeAudioForKey:(NSString *)key
{
    if (key == nil)
    {
        return;
    }

    dispatch_async(self.ioQueue, ^
                   {
                       [[NSFileManager defaultManager] removeItemAtPath:[self cachePathForKey:key] error:nil];
                   });
}

- (void)clearDisk
{
    dispatch_async(self.ioQueue, ^
                   {
                       [[NSFileManager defaultManager] removeItemAtPath:self.diskCachePath error:nil];
                       [[NSFileManager defaultManager] createDirectoryAtPath:self.diskCachePath
                                                 withIntermediateDirectories:YES
                                                                  attributes:nil
                                                                       error:NULL];
                   });
}

- (void)cleanDisk
{
    dispatch_async(self.ioQueue, ^
                   {
                       NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-self.maxCacheAge];
                       // convert NSString path to NSURL path
                       NSURL *diskCacheURL = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];
                       // build an enumerator by also prefetching file properties we want to read
                       NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:diskCacheURL
                                                                                    includingPropertiesForKeys:@[ NSURLIsDirectoryKey, NSURLContentModificationDateKey ]
                                                                                                       options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                                                  errorHandler:NULL];
                       for (NSURL *fileURL in fileEnumerator)
                       {
                           // skip folder
                           NSNumber *isDirectory;
                           [fileURL getResourceValue:&isDirectory forKey:NSURLIsDirectoryKey error:NULL];
                           if ([isDirectory boolValue])
                           {
                               continue;
                           }
                           
                           // compare file date with the max age
                           NSDate *fileModificationDate;
                           [fileURL getResourceValue:&fileModificationDate forKey:NSURLContentModificationDateKey error:NULL];
                           if ([[fileModificationDate laterDate:expirationDate] isEqualToDate:expirationDate])
                           {
                               [[NSFileManager defaultManager] removeItemAtURL:fileURL error:nil];
                           }
                       }
                   });

}

- (unsigned long long)getSize
{
    unsigned long long size = 0;
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.diskCachePath];
    for (NSString *fileName in fileEnumerator)
    {
        NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        size += [attrs fileSize];
    }
    return size;
}

- (int)getDiskCount
{
    int count = 0;
    NSDirectoryEnumerator *fileEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:self.diskCachePath];
    for (NSString *fileName in fileEnumerator)
    {
        count += 1;
    }
    
    return count;
}


@end
