## APAudioManager ##

An audio manager for online audio streaming, downloading, caching and playing.

A humble imitation of the brilliant [SDWebImage](https://github.com/rs/SDWebImage). 

## How To Use ##
In a view controller, set up a property of MPMoviePlayerController:
 <code>@property (strong, nonatomic) MPMoviePlayerController *mvPlayer;</code>
 
 and import the category
 <code>#import "NSObject+AudioCache.h"</code>
 
 Put the codes below where to initialise an audio player:
 
```objc
NSObject *playback = [[NSObject alloc] initWithURL:"Your URL here" error:nil loadingType:"Your Loading Type here"  completedPlayback: ^(NSString *audioPath,id player ,NSError *error){
    self.mvPlayer = player;
 }];
```

If loading type is streaming, audioPath will be nil, and a player instance will be generated, then serve as parameters of the completion block.
If loading type is caching, then the programme will first check if the audio file exists on disk: if it does, a player initilised with file content will be generated immediately; 
otherwise, it will download and save the audio first, then generate the player. Completionblock in this case will have the path of the downloaded audio file as the first parameter.


**Parameters**
*URL: The URL to the audio
*loadingType: The type defined to stream or download&load from file system. Two types: APAudioLoadByStreaming and APAudioLoadFromCaching
*completedPlayback: A block called when operation has been completed.
1. This block as no return value and takes the downloaded audio's path in disk as first parameter.
2. The second parameter is an instance of player initialised by URL either from a server or a file path
3. In case of error the audioPath parameter is nil and the second parameter is nil. 
4. The third parameter is an error output. 


