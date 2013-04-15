//
//  CoCoAudioAnaylizer.m
//  Stream
//
//  Created by tim lindner on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CoCoAudioAnaylizer.h"
#import "AudioAnaylizerViewController.h"
#import "Accelerate/Accelerate.h"

inline UInt32 CalculateLPCMFlags (UInt32 inValidBitsPerChannel, UInt32 inTotalBitsPerChannel, bool inIsFloat, bool inIsBigEndian, bool inIsNonInterleaved );
void FillOutASBDForLPCM(AudioStreamBasicDescription *outASBD, Float64 inSampleRate, UInt32 inChannelsPerFrame, UInt32 inValidBitsPerChannel,UInt32 inTotalBitsPerChannel, bool inIsFloat, bool inIsBigEndian, bool inIsNonInterleaved);

CGFloat XIntercept( vDSP_Length x1, double y1, vDSP_Length x2, double y2 );
float *FindZeroCrossings( AudioSampleType *samples, NSUInteger frameCount, int interpolate, NSUInteger *crossingCount );
double movingavg(int which, double newvalue, int seed);

@implementation CoCoAudioAnaylizer

@dynamic representedObject;
@synthesize frameBuffer;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        self.frameBuffer = nil;
    }
    
    return self;
}

- (StAnaylizer *)representedObject
{
    return representedObject;
}

- (void) setRepresentedObject:(StAnaylizer *)inRepresentedObject
{
    if( representedObject != nil && inRepresentedObject == nil )
    {
        if( observationsActive == YES )
        {
            StAnaylizer *theAna = [self representedObject];
            [theAna removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.lowCycle"];
            [theAna removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.highCycle"];
            [theAna removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.resyncThreashold"];
            [theAna removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannel"];
            [theAna removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.amplify"];
            [theAna removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.interpolate"];
            [theAna removeObserver:self forKeyPath:@"resultingData"];
            observationsActive = NO;
        } 
    }
    
    representedObject = inRepresentedObject;
    
    if( inRepresentedObject != nil )
    {
        StAnaylizer *theAna = inRepresentedObject;
        [theAna addSubOptionsDictionary:[CoCoAudioAnaylizer anaylizerKey] withDictionary:[CoCoAudioAnaylizer defaultOptions]];
        
        if( [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.initializedOD"] boolValue] == NO )
        {
            int audioChannel = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannel"] intValue];
            [self loadAudioChannel:audioChannel];
            [theAna setValue:[NSNumber numberWithBool:YES] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.initializedOD"];
        }
        else {
            [self reloadChachedAudioFrames];
        }
        /* setup observations */
        if( observationsActive == NO )
        {
            [theAna addObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.amplify" options:NSKeyValueChangeSetting context:nil];
            [theAna addObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.interpolate" options:NSKeyValueChangeSetting context:nil];
            [theAna addObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.lowCycle" options:NSKeyValueChangeSetting context:nil];
            [theAna addObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.highCycle" options:NSKeyValueChangeSetting context:nil];
            [theAna addObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.resyncThreashold" options:NSKeyValueChangeSetting context:nil];
            [theAna addObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannel" options:NSKeyValueChangeSetting context:nil];
            [theAna addObserver:self forKeyPath:@"resultingData" options:NSKeyValueChangeReplacement context:nil];
            observationsActive = YES;
        }
    }
}

- (void)dealloc
{
    StAnaylizer *theAna = [self representedObject];
    AudioAnaylizerViewController *vc = (AudioAnaylizerViewController *)[theAna viewController];
    [vc anaylizerIsDeallocating];
    
    if( observationsActive == YES )
    {
        StAnaylizer *theAna = [self representedObject];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.amplify"];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.interpolate"];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.lowCycle"];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.highCycle"];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.resyncThreashold"];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannel"];
        [theAna removeObserver:self forKeyPath:@"resultingData"];
        observationsActive = NO;
    } 
    
    self.frameBuffer = nil;
    [super dealloc];
}

- (void) loadAudioChannel:(int)audioChannel
{
    currentAudioChannel = audioChannel;
    StAnaylizer *theAna = self.representedObject;    
    OSStatus myErr;
    UInt32 propSize;
    
    /* clear out modified data index set*/
    NSMutableIndexSet *changedSampleSet = [theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.changedIndexes"];
    [changedSampleSet removeAllIndexes];
    NSMutableIndexSet *editIndexSet = theAna.editIndexSet;
    [editIndexSet removeAllIndexes];
    NSMutableIndexSet *failIndexSet = theAna.failIndexSet;
    [failIndexSet removeAllIndexes];
    
    /* Convert data to samples */
    NSURL *fileURL = [theAna urlForCachedData];
    ExtAudioFileRef af;
    myErr = ExtAudioFileOpenURL((CFURLRef)fileURL, &af);
    
    if (myErr == noErr)
    {
        SInt64 fileFrameCount;
        
        AudioStreamBasicDescription clientFormat;
        propSize = sizeof(clientFormat);
        
        myErr = ExtAudioFileGetProperty(af, kExtAudioFileProperty_FileDataFormat, &propSize, &clientFormat);
        NSAssert( myErr == noErr, @"CoCoAudioAnaylizer: ExtAudioFileGetProperty1: returned %d", myErr );
        
        UInt32 channelCount = clientFormat.mChannelsPerFrame;
        [theAna setValue:[NSNumber numberWithUnsignedInt:clientFormat.mChannelsPerFrame] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.channelCount"];
        
        if( audioChannel > channelCount )
            audioChannel = channelCount;
        
        [theAna setValue:[NSString stringWithFormat:@"%d", audioChannel] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannel"];
        [theAna setValue:[NSNumber numberWithDouble:clientFormat.mSampleRate] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.sampleRate"];
        
        /* Build array for channel popup list in accessory view */
        NSMutableArray *theChannelList = [[NSMutableArray alloc] init];
        for( int i=1; i<=channelCount; i++ )
        {
            [theChannelList addObject:[NSString stringWithFormat:@"%d", i]];
        }
        
        [theAna setValue:theChannelList forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannelList"];
        [theChannelList release];
        
        propSize = sizeof(SInt64);
        myErr = ExtAudioFileGetProperty(af, kExtAudioFileProperty_FileLengthFrames, &propSize, &fileFrameCount);
        NSAssert( myErr == noErr, @"CoCoAudioAnaylizer: ExtAudioFileGetProperty2: returned %d", myErr );
        
        SetCanonical(&clientFormat, (UInt32)channelCount, YES);
        
        propSize = sizeof(clientFormat);
        myErr = ExtAudioFileSetProperty(af, kExtAudioFileProperty_ClientDataFormat, propSize, &clientFormat);
        NSAssert( myErr == noErr, @"CoCoAudioAnaylizer: ExtAudioFileSetProperty: returned %d", myErr );
        
        size_t frameBufferSize = sizeof(AudioSampleType) * fileFrameCount * channelCount;
        AudioSampleType *frameBufferAS = malloc(frameBufferSize+1);
        
        AudioBufferList bufList;
        bufList.mNumberBuffers = 1;
        bufList.mBuffers[0].mNumberChannels = (UInt32)channelCount;
        bufList.mBuffers[0].mData = frameBufferAS;
        bufList.mBuffers[0].mDataByteSize = (UInt32)frameBufferSize;
        UInt32 ioFrameCount = (unsigned int)fileFrameCount;
        myErr = ExtAudioFileRead(af, &ioFrameCount, &bufList);
        NSAssert( myErr == noErr, @"CoCoAudioAnaylizer: ExtAudioFileRead: returned %d", myErr );
        
        /* destride audio sample so we only have the one selected channel */
        NSMutableData *frameBufferObject = [NSMutableData dataWithLength:sizeof(AudioSampleType) * fileFrameCount];
        AudioSampleType *frameBufferObjectBytes = [frameBufferObject mutableBytes];
        AudioSampleType *sourceAudioFrame = frameBufferAS + (audioChannel - 1);
        
        for( size_t i=0; i<fileFrameCount; i++ )
        {
            frameBufferObjectBytes[i] = sourceAudioFrame[i*channelCount];
        }
        
        free( frameBufferAS );
        
        [self willChangeValueForKey:@"frameBuffer"];
        self.frameBuffer = frameBufferObject;
        NSMutableData *frameBufferCopy = [frameBufferObject copy];
        [theAna setValue:frameBufferCopy forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.cachedframeBuffer"];
        [frameBufferCopy release];
        [self applyAmplify];
        [self applyAllEdits];
        [self anaylizeAudioData];
        [self didChangeValueForKey:@"frameBuffer"];
        
        myErr = ExtAudioFileDispose(af);
        NSAssert( myErr == noErr, @"CoCoAudioAnaylizer: ExtAudioFileRead: returned %d", myErr );
    }
    else
    {
        NSLog(@"CoCoAudioAnaylizer: ExtAudioFileOpenURL: could not open file");
        return;
    }
}

- (NSURL*) makeTemporaryWavFileWithData: (NSData *)data
{
    NSString *tempFileTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:@"myapptempfile.XXXXXX.wav"];
    const char *tempFileTemplateCString = [tempFileTemplate fileSystemRepresentation];
    int desc = mkstemps((char *)tempFileTemplateCString, 4);
    close( desc );
    NSString *filePathString = [NSString stringWithCString:tempFileTemplateCString encoding:NSASCIIStringEncoding];
    NSURL *temporaryURL = [NSURL fileURLWithPath:filePathString isDirectory:NO];

    return [self makeWavFile:temporaryURL withData:data];
}   

- (NSURL*) makeWavFile:(NSURL *)waveFile withData:(NSData *)data
{
        
    StAnaylizer *theAna = self.representedObject;
    Float64 _sample_rate = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.sampleRate"] doubleValue];
    UInt32 _channel_count = 1;
    float *_samples = (float *)[data bytes];
    UInt32 _frame_count = [data length] / sizeof(float);
    
    
    AudioStreamBasicDescription file_desc = {0};
    ExtAudioFileRef fout;
    FillOutASBDForLPCM(&file_desc, _sample_rate, _channel_count, sizeof(float)*8, sizeof(float)*8, false, false, true);
    file_desc.mFormatFlags = kAudioFormatFlagsCanonical;
    
    OSStatus rv = ExtAudioFileCreateWithURL((CFURLRef)waveFile, kAudioFileWAVEType, &file_desc, NULL, kAudioFileFlags_EraseFile, &fout);
    if (rv == noErr)
    {
        int buff_size = sizeof(AudioBufferList) + sizeof(AudioBuffer);
        AudioBufferList* bufferList = (AudioBufferList*)malloc(buff_size);
        bufferList->mNumberBuffers = 1;
        bufferList->mBuffers[0].mData = _samples;
        bufferList->mBuffers[0].mNumberChannels = _channel_count;
        bufferList->mBuffers[0].mDataByteSize = _channel_count * _frame_count * sizeof(float);
        ExtAudioFileWrite(fout, _frame_count, bufferList);
        free(bufferList);
        ExtAudioFileDispose(fout);
        return waveFile;
    }
    else
    {
        return nil;
    }
}

- (void) anaylizeAudioData
{
    NSAssert(self.representedObject != nil, @"Anaylize Audio Data: anaylizer can not be nil");
    StAnaylizer *theAna = self.representedObject;
    
    needsAnaylyzation = NO;
    anaylizationError = NO;

    double sampleRate = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.sampleRate"] doubleValue];
    float lowCycle = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.lowCycle"] floatValue];
    float highCycle = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.highCycle"] floatValue];
    BOOL interpolate = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.interpolate"] boolValue];
    
//    NSMutableData *frameBufferObject = [theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.frameBufferObject"];
    NSMutableData *frameBufferObject = self.frameBuffer;
    AudioSampleType *audioFrames = [frameBufferObject mutableBytes];
    NSUInteger frameCount = [frameBufferObject length] / sizeof(AudioSampleType);
    AudioSampleType *frameStart = audioFrames;
    NSUInteger crossingCount;
    
    float *zero_crossings = FindZeroCrossings( frameStart, frameCount, interpolate, &crossingCount ); 
        
    /* Store zero crossing array for wave form display */
    NSData *zerocrossingObject = [NSData dataWithBytesNoCopy:zero_crossings length:sizeof(float)*crossingCount];
    [theAna setValue:zerocrossingObject forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.zeroCrossingArray"];

    /* Scan zero crossings looking for valid data */
    int max_possible_characters = (crossingCount*2*8)+1;
    NSMutableData *charactersObject = [NSMutableData dataWithLength:sizeof(NSRange)*max_possible_characters];
    NSRange *characters = [charactersObject mutableBytes];
    NSMutableData *characterObject = [NSMutableData dataWithLength:sizeof(unsigned char)*max_possible_characters];
    unsigned char *character = [characterObject mutableBytes];
    NSUInteger char_count = 0;
    
    crossingCount -= 1;
    unsigned short even_parity = 0, odd_parity = 0;
    double dataThreashold = ((sampleRate/lowCycle) + (sampleRate/highCycle)) / 2.0, test1, test2;
    float resyncThresholdHertz = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.resyncThreashold"] floatValue];
    
    if( resyncThresholdHertz > lowCycle/2.0 )
    {
        //self.errorString = @"Resynchronization threshold cannot be larger than half of the low frequency target.";
        //self.anaylizationError = YES;
        NSLog( @"Setting anaylization error" );
        return;
    }
    
    double resyncThreshold = sampleRate/resyncThresholdHertz;
    int bit_count = 0;
    
    /* start by scanning zero crossing looking for the start of a block */
    for (int i=2; i<crossingCount; i+=2)
    {
        
        if( (zero_crossings[i] - zero_crossings[i-1]) < (sampleRate/(2400.0*2.0)) ) i++;
        
        /* test frequency of 2 zero crossings */
        even_parity >>= 1;
        test1 = (zero_crossings[i] - zero_crossings[i-2]);
        if( test1 < dataThreashold )
            even_parity |= 0x8000;
        
        /* test frequency of 2 zero crossings, offset by one zero crossing into the future */
        odd_parity >>= 1;
        test2 = (zero_crossings[i+1] - zero_crossings[i-1]);
        if( test2 < dataThreashold )
            odd_parity |= 0x8000;
        
        /* test for start block bit pattern */
              
        if( (even_parity & 0xfff0) == 0x3c50 || (odd_parity & 0xfff0) == 0x3c50 )
        {
            if( (odd_parity & 0xfff0) == 0x3c50 )
            {
                /* adjust position one zero crossing into the future */
                i++;
                even_parity = odd_parity;
            }
            
            /* capture (0x5x) sync byte */
            characters[char_count].location = zero_crossings[i-(16*2)];
            characters[char_count].length = zero_crossings[i-(8*2)] - zero_crossings[i-(16*2)];
            character[char_count] = even_parity & 0x00ff;
            char_count++;
            
            /* capture 0x3c sync byte */
            characters[char_count].location = zero_crossings[i-(8*2)];
            characters[char_count].length = zero_crossings[i] - zero_crossings[i-(8*2)];
            character[char_count] = even_parity >> 8;
            char_count++;
            
            /* start capturing synchronized bits */
            i += 2;
            for( ; i<crossingCount; i+=2 )
            {
                /* mark begining of byte */
                if(bit_count == 0)
                {
                    characters[char_count].location = zero_crossings[i-2];
                    //characters[char_count].length = 0;
                }
                
                /* test frequency of 2 zero crossings */ 
                even_parity >>= 1;
                test1 = (zero_crossings[i] - zero_crossings[i-2]);
                if( test1 < dataThreashold )
                    even_parity |= 0x8000;
                bit_count++;

                if( bit_count == 8 )
                {
                    /* we have eight bits, finish byte capture */
                    if( test1 > resyncThreshold )
                        characters[char_count].length = zero_crossings[i-1] - characters[char_count].location + resyncThreshold;
                    else
                        characters[char_count].length = zero_crossings[i] - characters[char_count].location;
                    character[char_count] = even_parity >> 8;
                    char_count++;
                    bit_count = 0;
                }
                
                if( test1 > resyncThreshold )
                {
                    /* lost sync, finish off last byte, break out of loop to try to re-synchronize */
                    characters[char_count].length = zero_crossings[i-1] - characters[char_count].location + resyncThreshold;
                    character[char_count] = even_parity >> 8;
                    char_count++;
                    bit_count = 0;
                    i += 2;
                    break;
                }
                else if( test1 < sampleRate/(2400.0*1.5) )
                {
                    /* lost sync, finish off last byte, break out of loop to try to re-synchronize */
                    characters[char_count].length = zero_crossings[i-1] - characters[char_count].location + resyncThreshold;
                    character[char_count] = even_parity >> 8;
                    char_count++;
                    bit_count = 0;
                    i += 2;
                    break;
                }
            }
        }
        
        /* done testing zero crossings, finish off last byte capture */
        if( bit_count == 7 )
        {
            even_parity >>= 1;
            characters[char_count].length = frameCount - characters[char_count].location;
            character[char_count] = even_parity >> 8;
            char_count++;
        }
    }
    
    /* no need to free buffer, it was wrapped in an NSData object */
    //free(zero_crossings);
    
    /* shirnk buffers to actual size */
    [charactersObject setLength:sizeof(NSRange)*char_count];
    [characterObject setLength:sizeof(unsigned char)*char_count];
    
    if( characters != [charactersObject mutableBytes] )
        characters = [charactersObject mutableBytes];
    
    NSMutableData *coalescedObject = [NSMutableData dataWithLength:sizeof(NSRange)*char_count];
    NSRange *coalescedCharacters = [coalescedObject mutableBytes];
    
    coalescedCharacters[0] = characters[0];
    NSUInteger coa_char_count = 1;
    
    /* coalesce nearby found byte rectangles into single continous rectangle */
    /* this greatly speeds up the "found data" tint when zoomed out */
    for(int i=1; i<char_count; i++ )
    {
        if( characters[i].location-5.0 <= coalescedCharacters[coa_char_count-1].location + coalescedCharacters[coa_char_count-1].length )
            coalescedCharacters[coa_char_count-1].length += characters[i].length - (coalescedCharacters[coa_char_count-1].location + coalescedCharacters[coa_char_count-1].length - characters[i].location);
        else
            coalescedCharacters[coa_char_count++] = characters[i];
    }
    
    /* shirnk buffer to actual size */
    [coalescedObject setLength:sizeof(NSRange)*coa_char_count];
    
    /* find average of max value for each coalessed range */
    /* this will be used when creating new wave forms during writing */
    AudioSampleType average;
    
    if( coa_char_count != 0 )
    {
        average = 0;
        
        for(int i=0; i<coa_char_count; i++ )
        {
            AudioSampleType maxValue;
            vDSP_maxv( audioFrames + coalescedCharacters[i].location, 1, &maxValue, coalescedCharacters[i].length );
            average += maxValue;
        }
        
        average = average / coa_char_count;
    }
    else
        average = 0.75; /* this is a decent value if there is no found data */
    
    [theAna setValue:[NSNumber numberWithFloat:average] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.averagedMaximumSample"];
    
    /* store NSMutableData Objects away */
    [theAna setValue:coalescedObject forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.coalescedObject"];
    [theAna setValue:charactersObject forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.charactersObject"];

    /* generate new changed index set */
    NSMutableIndexSet *changedIndexSetObject = [[NSMutableIndexSet alloc] init];
    NSMutableIndexSet *changedIndexes = [theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.changedIndexes"];
    
    NSRange maximumRange = {0, NSUIntegerMax};
    NSUInteger count = [changedIndexes countOfIndexesInRange:maximumRange];
    NSUInteger *indexBuffer = malloc( sizeof(NSUInteger) * count);
    
    [changedIndexes getIndexes:indexBuffer maxCount:count inIndexRange:&maximumRange];

    NSUInteger j = 0;
    int i = 0;
    
    while( i < count && j < char_count)
    {
        if( indexBuffer[i] < characters[j].location )
        {
            i++;
        }
        else if( NSLocationInRange(indexBuffer[i], characters[j] ) )
        {
            [changedIndexSetObject addIndex:j];
            i++;
            j++;
        }
        else
            j++;
    }
    
    free( indexBuffer );

    [theAna setResultingData:characterObject andChangedIndexSet:changedIndexSetObject];
    
    [changedIndexSetObject release];
}

- (void) applyAllEdits
{
    for (AnaylizerEdit *edit in [representedObject edits])
    {
        [self.frameBuffer replaceBytesInRange:NSMakeRange(edit.location, edit.length) withBytes:[edit.data bytes] length:[edit.data length]];
    }
}

- (void) reloadChachedAudioFrames
{
    StAnaylizer *theAna = self.representedObject;
    NSMutableData *cachedAudio = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.cachedframeBuffer"] mutableCopy];
    self.frameBuffer = cachedAudio;
    [cachedAudio release];
    [self applyAllEdits];
    [self applyAmplify];
}

- (void) applyAmplify
{
    StAnaylizer *theAna = self.representedObject;
    NSInteger amplify = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.amplify"] integerValue];
    
    if( amplify != 0 )
    {
        if( amplify > 100 ) amplify *= 5.0;
        
        float *frames = (float *)[self.frameBuffer bytes];
        NSUInteger length = [self.frameBuffer length] / sizeof(float);
        float divisor = amplify/100.0;

        vDSP_vsmul( frames, 1, &divisor, frames, 1, length );
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //NSLog(@"ObserveValueForKeyPath: %@\nofObject: %@\nchange: %@\ncontext: %p", keyPath, object, change, context);
    
    if( [keyPath isEqualToString:@"optionsDictionary.AudioAnaylizerViewController.interpolate"] )
    {
        if( [change objectForKey:@"new"] != [NSNull null] )
            [self anaylizeAudioData];
        return;
    }
    
    if( [keyPath isEqualToString:@"optionsDictionary.AudioAnaylizerViewController.lowCycle"] )
    {
        if( [change objectForKey:@"new"] != [NSNull null] )
            [self anaylizeAudioData];
        return;
    }
    
    if( [keyPath isEqualToString:@"optionsDictionary.AudioAnaylizerViewController.highCycle"] )
    {
        if( [change objectForKey:@"new"] != [NSNull null] )
            [self anaylizeAudioData];
        return;
    }
    
    if( [keyPath isEqualToString:@"optionsDictionary.AudioAnaylizerViewController.resyncThreashold"])
    {
        if( [change objectForKey:@"new"] != [NSNull null] )
            [self anaylizeAudioData];
        return;
    }
    
    if( [keyPath isEqualToString:@"optionsDictionary.AudioAnaylizerViewController.amplify"])
    {
        if( [change objectForKey:@"new"] != [NSNull null] )
        {
            [self reloadChachedAudioFrames];
        }
        return;
    }
    
    if( [keyPath isEqualToString:@"optionsDictionary.AudioAnaylizerViewController.audioChannel"] )
    {
        if( [change objectForKey:@"new"] != [NSNull null] )
        {
            int audioChannel = [[self.representedObject valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannel"] intValue];
            if( currentAudioChannel != audioChannel )
            {
                [self loadAudioChannel:audioChannel];
            }
        }
        return;
    }
    
    if( [keyPath isEqualToString:@"resultingData"] )
    {
        //NSLog(@"ObserveValueForKeyPath: %@\nofObject: %@\nchange: %@\ncontext: %p", keyPath, object, change, context);
        NSUInteger kind = [[change objectForKey:@"kind"] unsignedIntegerValue];
        if( kind == NSKeyValueChangeReplacement )
        {
            NSIndexSet *idxSet = [change objectForKey:@"indexes"];
            NSUInteger count = [idxSet count];
            NSUInteger *indexes = malloc( sizeof(NSUInteger)*count );
            [idxSet getIndexes:indexes maxCount:count inIndexRange:nil];
            
            for( int i=0; i<count; i++ )
            {
                [self updateWaveFormForCharacter:indexes[i]];
            }
            
            free( indexes );
        }
        
        return;
    }

    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void) updateWaveFormForCharacter:(NSUInteger)idx
{
    StAnaylizer *theAna = self.representedObject;
    
    /* get max of current wave form */
    NSDictionary *optionsDictionary = [theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController"];
    NSMutableData *charactersObject = [optionsDictionary objectForKey:@"charactersObject"];
    NSRange *characters = (NSRange *)[charactersObject mutableBytes];
    NSMutableData *audioFramesObject = self.frameBuffer;
    AudioSampleType *audioFrames = [audioFramesObject mutableBytes];
    AudioSampleType *frameStart = audioFrames + characters[idx].location;
    AudioSampleType maxValue = [[optionsDictionary objectForKey:@"averagedMaximumSample"] floatValue];
    NSData *previousDataObject = [NSData dataWithBytes:frameStart length:sizeof(AudioSampleType) * characters[idx].length];
    
    /* calculate waveform buffer size */
    NSMutableData *characterObject = [theAna valueForKey:@"resultingData"];
    unsigned char *character = [characterObject mutableBytes];
    int zeros = 0, ones = 0;
    unsigned int test = character[idx];
    
    for( int i=0; i<8; i++ )
    {
        if( (test & 0x01) == 0x01 ) ones++; else zeros++;
        test >>= 1;
    }
    
    double sampleRate = [[optionsDictionary objectForKey:@"sampleRate"] doubleValue];
    float lowCycle = [[optionsDictionary objectForKey:@"lowCycle"] floatValue];
    float highCycle = [[optionsDictionary objectForKey:@"highCycle"] floatValue];
    
    int onesLength = sampleRate / highCycle;
    int zerosLength = sampleRate / lowCycle;
    int totalLength = (ones * onesLength) + (zeros * zerosLength);
    
    NSValue *newRangeValue = [NSValue valueWithRange:NSMakeRange(sizeof(AudioSampleType) * characters[idx].location, sizeof(AudioSampleType) * totalLength)];
    AudioSampleType *newByteWaveForm = malloc( sizeof(AudioSampleType) * totalLength );
    int waveFormIndex = 0;
    test = character[idx];
    
    float offset = ((frameStart[-1] > frameStart[0]) ? pi : pi * 2.0);
    
    /* build new byte waveform */
    for( int i=0; i<8; i++ )
    {
        int sinusoidal_length = ((test & 0x01) == 0x01 ? onesLength : zerosLength);
        test >>= 1;
        float increment = (pi * 2.0) / sinusoidal_length;
        
        for( int j=0; j<sinusoidal_length; j++ )
        {
            newByteWaveForm[waveFormIndex++] = sinf( offset + (increment * j) ) * maxValue;
        }
    }
    
    /* replace old wave buffer with new wave buffer */
    NSRange oldRange = NSMakeRange(sizeof(AudioSampleType) * characters[idx].location, sizeof(AudioSampleType) * characters[idx].length);
    [audioFramesObject replaceBytesInRange:oldRange withBytes:newByteWaveForm length:sizeof(AudioSampleType) * totalLength];
    
    NSData *newByteWaveFormObject = [NSData dataWithBytesNoCopy:newByteWaveForm length:sizeof(AudioSampleType) * totalLength];
    //free( newByteWaveForm );
    
    /* slide changed byte to accomadate new size */
    unsigned long delta = totalLength - characters[idx].length;
    NSMutableIndexSet *changedSet = [optionsDictionary objectForKey:@"changedIndexes"];
    NSMutableIndexSet *previousChangedSet = [changedSet mutableCopy];
    [changedSet shiftIndexesStartingAtIndex:characters[idx+1].location by:delta];
    
    /* adjust characters accounting */
    characters[idx].length = totalLength;
    for( unsigned long i = idx+1; i < [characterObject length]; i++ )
        characters[i].location += delta;
    
    /* add newley generated waveform to changed set */
    [changedSet addIndexesInRange:characters[idx]];

    /* setup undo */
    NSManagedObjectContext *parentContext = [theAna managedObjectContext];
    NSUndoManager *um = [parentContext undoManager];
    NSDictionary *previousState = [NSDictionary dictionaryWithObjectsAndKeys:previousDataObject, @"data", newRangeValue, @"range", previousChangedSet, @"indexSet", nil];
    [previousChangedSet release];
    [um registerUndoWithTarget:self selector:@selector(setPreviousState:) object:previousState];
    [um setActionName:@"Byte Change"];
    
    /* post edit to anaylizer */
    [theAna postEdit:newByteWaveFormObject atLocation:oldRange.location withLength:oldRange.length];
}


- (void) setPreviousState:(NSDictionary *)previousState
{
    StAnaylizer *theAna = self.representedObject;
    NSMutableDictionary *optionsDict = [theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController"];
    NSMutableData *frameBufferObject = self.frameBuffer;
    
    /* setup redo */
    NSValue *priorRange = [previousState objectForKey:@"range"];
    NSMutableIndexSet *previousChangedSet = [previousState objectForKey:@"indexSet"];
    
    NSRange range = [priorRange rangeValue];
    NSData *priorData = [frameBufferObject subdataWithRange:range];
    NSManagedObjectContext *parentContext = [theAna managedObjectContext];
    NSIndexSet *priorChangedSet = [optionsDict objectForKey:@"changedIndexes"];
    NSDictionary *priorState = [NSDictionary dictionaryWithObjectsAndKeys:priorData, @"data", priorRange, @"range", [[priorChangedSet mutableCopy] autorelease], @"indexSet", nil];
    
    /* register redo */
    [[parentContext undoManager] registerUndoWithTarget:self selector:@selector(setPreviousState:) object:priorState];
    [[parentContext undoManager] setActionName:@"Change"];
    
    /* apply previous state */
//    [optionsDict willChangeValueForKey:@"frameBufferObject"];
    NSData *previousSamplesObject = [previousState objectForKey:@"data"];
    [frameBufferObject replaceBytesInRange:range withBytes:[previousSamplesObject bytes] length:[previousSamplesObject length]];
//    [optionsDict didChangeValueForKey:@"frameBufferObject"];
    [optionsDict setObject:previousChangedSet forKey:@"changedIndexes"];
    
    /* re anaylize */
    [self anaylizeAudioData];
}

- (void) determineFrequencyOrigin:(NSUInteger)origin width:(NSUInteger)width
{
    NSMutableData *frameBufferObject = self.frameBuffer;
    AudioSampleType *audioFrames = [frameBufferObject mutableBytes];
    NSUInteger crossingCount;
    StAnaylizer *theAna = self.representedObject;
    BOOL interpolate = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.interpolate"] boolValue];
    float *zero_crossings = FindZeroCrossings( audioFrames+origin, width, interpolate, &crossingCount );
    
    double sampleRate = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.sampleRate"] doubleValue];
    double diff1, diff2, diff3, diff4, diff5;
    double movingAverage1, movingAverage2, movingAverage3, movingAverage4, movingAverageHigh, movingAverageLow;

    for( int i=1; i<crossingCount/4; i++ )
    {
        /* create sliding window of four consecutive differences */
        for( int j=0; j<4; j++ )
        {
            diff1 = diff2;
            diff2 = diff3;
            diff3 = diff4;
            diff4 = diff5;
            diff5 = (double)zero_crossings[ i * 4 + j ] - zero_crossings[ i * 4 + j - 1 ];
        }

        movingAverage1 = movingavg( 0, sampleRate/(diff1+diff2), i==1 ? 0 : 1 );
        movingAverage2 = movingavg( 1, sampleRate/(diff2+diff3), i==1 ? 0 : 1 );
        movingAverage3 = movingavg( 2, sampleRate/(diff3+diff4), i==1 ? 0 : 1 );
        movingAverage4 = movingavg( 3, sampleRate/(diff4+diff5), i==1 ? 0 : 1 );
    }

    movingAverageLow = fmin( fmin( fmin( movingAverage1, movingAverage2 ), movingAverage3 ), movingAverage4 );
    movingAverageHigh = fmax( fmax( fmax( movingAverage1, movingAverage2 ), movingAverage3 ), movingAverage4 );

    [theAna setValue:[NSNumber numberWithFloat:movingAverageLow] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.lowCycle"];
    [theAna setValue:[NSNumber numberWithFloat:movingAverageHigh] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.highCycle"];
    
    free( zero_crossings );
}

+ (NSArray *)anaylizerUTIs
{
    return [NSArray arrayWithObject:@"public.audio"];
}

+ (NSString *)anayliserName
{
    return @"Color Computer Audio Anaylizer";
}

+ (NSString *)anaylizerKey
{
    return @"AudioAnaylizerViewController";
}

- (Class)viewController
{
    return [AudioAnaylizerViewController class];
}

+ (NSString *)AnaylizerPopoverAccessoryViewNib
{
    return @"AudioAnaylizer";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithFloat:1094.68085106384f], @"lowCycle", [NSNumber numberWithFloat:2004.54545454545f], @"highCycle", [NSNumber numberWithFloat:NAN], @"scale", [NSNumber numberWithFloat:0], @"scrollOrigin", [NSNumber numberWithFloat:300.0],@"resyncThreashold", @"1", @"audioChannel", [NSArray arrayWithObject:@"1"], @"audioChannelList", [NSNull null], @"sampleRate", [NSNull null], @"channelCount", [NSNull null], @"coalescedObject",[NSNumber numberWithBool:NO], @"initializedOD", [NSMutableIndexSet indexSet], @"changedIndexes", [NSNumber numberWithFloat:0.75], @"averagedMaximumSample", [NSNull null], @"zeroCrossingArray", [NSNumber numberWithInteger:100], @"amplify", [NSNull null], @"cachedframeBuffer", [NSNumber numberWithBool:NO], @"selected", [NSNumber numberWithBool:NO], @"interpolate", nil] autorelease];
}

@end

/* taken from: /Developer/Extras/CoreAudio/PublicUtility/CAStreamBasicDescription.h */

void SetCanonical(AudioStreamBasicDescription *clientFormat, UInt32 nChannels, bool interleaved)
// note: leaves sample rate untouched
{
    clientFormat->mFormatID = kAudioFormatLinearPCM;
    int sampleSize = ((UInt32)sizeof(AudioSampleType)); //SizeOf32(AudioSampleType);
    clientFormat->mFormatFlags = kAudioFormatFlagsCanonical;
    clientFormat->mBitsPerChannel = 8 * sampleSize;
    clientFormat->mChannelsPerFrame = nChannels;
    clientFormat->mFramesPerPacket = 1;
    if (interleaved)
        clientFormat->mBytesPerPacket = clientFormat->mBytesPerFrame = nChannels * sampleSize;
    else {
        clientFormat->mBytesPerPacket = clientFormat->mBytesPerFrame = sampleSize;
        clientFormat->mFormatFlags |= kAudioFormatFlagIsNonInterleaved;
    }
}

UInt32 CalculateLPCMFlags (UInt32 inValidBitsPerChannel, UInt32 inTotalBitsPerChannel, bool inIsFloat, bool inIsBigEndian, bool inIsNonInterleaved )
{
    return (inIsFloat ? kAudioFormatFlagIsFloat : kAudioFormatFlagIsSignedInteger) | (inIsBigEndian ? ((UInt32)kAudioFormatFlagIsBigEndian) : 0)             | ((!inIsFloat && (inValidBitsPerChannel == inTotalBitsPerChannel)) ? kAudioFormatFlagIsPacked : kAudioFormatFlagIsAlignedHigh)           | (inIsNonInterleaved ? ((UInt32)kAudioFormatFlagIsNonInterleaved) : 0);
}


void FillOutASBDForLPCM(AudioStreamBasicDescription *outASBD, Float64 inSampleRate, UInt32 inChannelsPerFrame, UInt32 inValidBitsPerChannel,UInt32 inTotalBitsPerChannel, bool inIsFloat, bool inIsBigEndian, bool inIsNonInterleaved)
{
    outASBD->mSampleRate = inSampleRate;
    outASBD->mFormatID = kAudioFormatLinearPCM;
    outASBD->mFormatFlags = CalculateLPCMFlags(inValidBitsPerChannel, inTotalBitsPerChannel, inIsFloat, inIsBigEndian, inIsNonInterleaved);
    outASBD->mBytesPerPacket = (inIsNonInterleaved ? 1 : inChannelsPerFrame) * (inTotalBitsPerChannel/8);
    outASBD->mFramesPerPacket = 1;
    outASBD->mBytesPerFrame = (inIsNonInterleaved ? 1 : inChannelsPerFrame) * (inTotalBitsPerChannel/8);
    outASBD->mChannelsPerFrame = inChannelsPerFrame;
    outASBD->mBitsPerChannel = inValidBitsPerChannel;
}


CGFloat XIntercept( vDSP_Length x1, double y1, vDSP_Length x2, double y2 )
{
    /*  m=(Y1-Y2)/(X1-X2) */
    double m = ((double)y1 - (double)y2)/((double)x1-(double)x2);
    /*  b = Y-mX */
    double b = (double)y1 - (m * (double)x1);
    
    return (-b)/m;
}

float *FindZeroCrossings( AudioSampleType *samples, NSUInteger frameCount, int interpolate, NSUInteger *crossingCount )
{
    vDSP_Length i;
    int zc_count;
    
    unsigned long max_possible_zero_crossings = (frameCount / 2) + 1;
    float *zero_crossings = malloc(sizeof(float)*max_possible_zero_crossings);
    zc_count = 0;
    
    if (interpolate)
    {
        /* Create temporary array of zero crossing points */
        for( i=1; i<frameCount; i++ )
        {
            vDSP_Length crossing;
            vDSP_Length total;
            const vDSP_Length findOneCrossing = 1;
            
            vDSP_nzcros(samples+i, 1, findOneCrossing, &crossing, &total, frameCount-i);
            
            if( crossing == 0 ) break;
            
            zero_crossings[zc_count++] = XIntercept(i+crossing-1, samples[i+crossing-1], i+crossing, samples[i+crossing]);

            i += crossing-1;
        }
    }
    else
    {
        /* Create temporary array of zero crossing points */
        for( i=1; i<frameCount; i++ )
        {
            vDSP_Length crossing;
            vDSP_Length total;
            const vDSP_Length findOneCrossing = 1;
            
            vDSP_nzcros(samples+i, 1, findOneCrossing, &crossing, &total, frameCount-i);
            
            if( crossing == 0 ) break;
            
            zero_crossings[zc_count++] = i+crossing;
            
            i += crossing-1;
        }

    }
    
    /* remove unused space in zero crossing array */
    zero_crossings = realloc(zero_crossings, sizeof(float)*zc_count);
    
    *crossingCount = zc_count;
    return zero_crossings;
}

#define MACOUNT 5
#define MASIZE 20
               
double movingavg(int which, double newvalue, int seed)
{
    static double sum[MACOUNT] = {0.0, 0.0, 0.0, 0.0, 0.0};
    static int index[MACOUNT] = {0, 0, 0, 0, 0};
    static double history[MACOUNT][MASIZE] = {{ 0.0, 0.0, 0.0, 0.0, 0.0 },
                                            { 0.0, 0.0, 0.0, 0.0, 0.0 },
                                            { 0.0, 0.0, 0.0, 0.0, 0.0 },
                                            { 0.0, 0.0, 0.0, 0.0, 0.0 },
                                            { 0.0, 0.0, 0.0, 0.0, 0.0 } };
    static int full[MACOUNT] = {0, 0, 0, 0, 0};

    if( which < MACOUNT )
    {
        if( seed )
        {
            sum[which] = newvalue;
            return newvalue;
        }
        else
        {
            sum[which] -= history[which][index[which]];
            sum[which] += (history[which][index[which]++] = newvalue);

            if (index[which] >= MASIZE)
            {
                index[which] -= MASIZE;
                full[which] = 1;
            }

            if (full[which])
                return sum[which] / MASIZE;
            else
                return sum[which] / index[which];
        }
    }
    
    return 0.0;
}

