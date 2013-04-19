//
//  APAudioManager.m
//  AudioManager
//
//  Created by B.H.Liu on 13-4-18.
//  Copyright (c) 2013年 Appublisher. All rights reserved.
//

#import "APAudioManager.h"
#import "objc/runtime.h"

@interface APAudioManager()

@property (strong, nonatomic, readwrite) APAudioCache *audioCache;
@property (strong, nonatomic) NSMutableArray *failedURLs;
@property (strong, nonatomic) NSMutableArray *runningOperations;

@property (strong, nonatomic) NSOperationQueue *operationQueue;

@end

@implementation APAudioManager

+ (id)sharedManager
{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{instance = self.new;});
    return instance;
}

- (id)init
{
    if ((self = [super init]))
    {
        _audioCache = [APAudioCache sharedAudioCache];
        _failedURLs = NSMutableArray.new;
        _runningOperations = NSMutableArray.new;
        _operationQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

#pragma mark APAudioManager (private)

- (NSString *)cacheKeyForURL:(NSURL *)url
{
    if (self.cacheKeyFilter)
    {
        return self.cacheKeyFilter(url);
    }
    else
    {
        return [url absoluteString];
    }
}

- (AFHTTPRequestOperation*)downloadWithURL:(NSURL *)url
                CompletionBlockWithSuccess:(void (^)(NSString *audioPath, NSError *error, APAudioCacheType cacheType))success
{    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    __weak AFHTTPRequestOperation *weakoperation = operation;
    
    if (!url || !success || [self.failedURLs containsObject:url])
    {
        if (success) success(nil, nil,APAudioCacheNone);
        return operation;
    }
    
    @synchronized(self.runningOperations)
    {
        [self.runningOperations addObject:operation];
    }
    
    NSString *key = [self cacheKeyForURL:url];
    
    //audio cache check
    [self.audioCache queryDiskCacheForKey:key done:^(NSString *audioPath, APAudioCacheType cacheType)
     {
         if (operation.isCancelled) return;
         
         
         if (cacheType == APAudioCacheNone && (![self.delegate respondsToSelector:@selector(audioManager:shouldDownloadImageForURL:)] || [self.delegate audioManager:self shouldDownloadImageForURL:url]))
         {
             if (weakoperation.isCancelled) {
                 success(nil,nil,APAudioCacheNone);
             }
                          
             else
             {
                 operation.outputStream = [NSOutputStream outputStreamToFileAtPath:audioPath append:NO];
                 [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                     
                     NSLog(@"Successfully downloaded file to %@", audioPath);
                     
                     success(audioPath,nil,APAudioCacheDisk);
                     
                 } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                     
                     NSLog(@"fail to download file to %@", audioPath);
                     
                     [[NSFileManager new] removeItemAtPath:audioPath error:nil];
                     
                     if (error.code != NSURLErrorNotConnectedToInternet)
                     {
                         @synchronized(self.failedURLs)
                         {
                             [self.failedURLs addObject:url];
                         }
                     }
                     
                     success(nil, nil, APAudioCacheNone);
                 }];
                 
                 [_operationQueue addOperation:operation];
                 [operation start];
                 
             }
         }
         
         else if (cacheType == APAudioCacheDisk)
         {
             success(audioPath, nil, cacheType);
             @synchronized(self.runningOperations)
             {
                 [self.runningOperations removeObject:operation];
             }
         }
         else
         {
             // Image not in cache and download disallowed by delegate
             success(nil, nil, APAudioCacheNone);  //now APAudioCacheNone should be APAudioCacheDisk
             @synchronized(self.runningOperations)
             {
                 [self.runningOperations removeObject:operation];
             }
         }

     }];
    
    return operation;

}


- (void)cancelAll
{
    @synchronized(self.runningOperations)
    {
        [self.runningOperations makeObjectsPerformSelector:@selector(cancel)];
        [self.runningOperations removeAllObjects];
        
        [_operationQueue cancelAllOperations];
    }
}

- (BOOL)isRunning
{
    return self.runningOperations.count > 0;
}

@end
