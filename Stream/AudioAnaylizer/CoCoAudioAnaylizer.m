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

CGFloat XIntercept( vDSP_Length x1, double y1, vDSP_Length x2, double y2 );

@implementation CoCoAudioAnaylizer

@dynamic representedObject;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
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
        
        /* setup observations */
        if( observationsActive == NO )
        {
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
    if( observationsActive == YES )
    {
        StAnaylizer *theAna = [self representedObject];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.lowCycle"];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.highCycle"];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.resyncThreashold"];
        [theAna removeObserver:self forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.audioChannel"];
        [theAna removeObserver:self forKeyPath:@"resultingData"];
        observationsActive = NO;
    } 
    
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
        
        [theAna setValue:[NSNumber numberWithUnsignedLongLong:fileFrameCount] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.frameCount"];
        
        size_t frameBufferSize = sizeof(AudioSampleType) * fileFrameCount * channelCount;
        AudioSampleType *frameBuffer = malloc(frameBufferSize+1);
        
        AudioBufferList bufList;
        bufList.mNumberBuffers = 1;
        bufList.mBuffers[0].mNumberChannels = (UInt32)channelCount;
        bufList.mBuffers[0].mData = frameBuffer;
        bufList.mBuffers[0].mDataByteSize = (UInt32)frameBufferSize;
        UInt32 ioFrameCount = (unsigned int)fileFrameCount;
        myErr = ExtAudioFileRead(af, &ioFrameCount, &bufList);
        NSAssert( myErr == noErr, @"CoCoAudioAnaylizer: ExtAudioFileRead: returned %d", myErr );
        
        /* destride audio sample so we only have the one selected channel */
        NSMutableData *frameBufferObject = [NSMutableData dataWithLength:sizeof(AudioSampleType) * fileFrameCount];
        AudioSampleType *frameBufferObjectBytes = [frameBufferObject mutableBytes];
        AudioSampleType *sourceAudioFrame = frameBuffer + (audioChannel - 1);
        
        for( size_t i=0; i<fileFrameCount; i++ )
        {
            frameBufferObjectBytes[i] = sourceAudioFrame[i*channelCount];
        }
        
        free( frameBuffer );
        
        [theAna setValue:frameBufferObject forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.frameBufferObject"];
        [self anaylizeAudioData];
        
        myErr = ExtAudioFileDispose(af);
        NSAssert( myErr == noErr, @"CoCoAudioAnaylizer: ExtAudioFileRead: returned %d", myErr );
    }
    else
    {
        NSLog(@"CoCoAudioAnaylizer: ExtAudioFileOpenURL: could not open file");
        return;
    }
}

- (void) anaylizeAudioData
{
    NSAssert(self.representedObject != nil, @"Anaylize Audio Data: anaylizer can not be nil");
    StAnaylizer *theAna = self.representedObject;
    
    needsAnaylyzation = NO;
    anaylizationError = NO;
    
    //    NSMutableData *priorResultingData = theAna.resultingData;
    //    NSMutableIndexSet *priorChangedIndexSet = theAna.editIndexSet;
    
    unsigned long long frameCount = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.frameCount"] unsignedLongLongValue];
    
    double sampleRate = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.sampleRate"] doubleValue];
    float lowCycle = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.lowCycle"] floatValue];
    float highCycle = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.highCycle"] floatValue];
    vDSP_Length i;
    int zc_count;
    
    AudioSampleType *audioFrames = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.frameBufferObject"] mutableBytes];
    AudioSampleType *frameStart = audioFrames;
    
    unsigned long max_possible_zero_crossings = (frameCount / 2) + 1;
    float *zero_crossings = malloc(sizeof(float)*max_possible_zero_crossings);
    zc_count = 0;
    
    /* Create temporary array of zero crossing points */
    for( i=1; i<frameCount; i++ )
    {
        vDSP_Length crossing;
        vDSP_Length total;
        const vDSP_Length findOneCrossing = 1;
        
        vDSP_nzcros(frameStart+i, 1, findOneCrossing, &crossing, &total, frameCount-i);
        
        if( crossing == 0 ) break;
        
        zero_crossings[zc_count++] = i+crossing;
        //zero_crossings[zc_count++] = XIntercept(i+crossing-1, frameStart[i+crossing-1], i+crossing, frameStart[i+crossing]);
        
        i += crossing-1;
    }
    
    /* remove unused space in zero crossing array */
    zero_crossings = realloc(zero_crossings, sizeof(float)*zc_count);
    
    /* Scan zero crossings looking for valid data */
    int max_possible_characters = (zc_count*2*8)+1;
    NSMutableData *charactersObject = [NSMutableData dataWithLength:sizeof(NSRange)*max_possible_characters];
    NSRange *characters = [charactersObject mutableBytes];
    NSMutableData *characterObject = [NSMutableData dataWithLength:sizeof(unsigned char)*max_possible_characters];
    unsigned char *character = [characterObject mutableBytes];
    NSUInteger char_count = 0;
    
    zc_count -= 1;
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
    for (i=2; i<zc_count; i+=2)
    {
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
            
            /* capture (0x0f & 0x05) sync byte */
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
            for( ; i<zc_count; i+=2 )
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
                else if( test1 > resyncThreshold )
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
    
    free(zero_crossings);
    
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
    for( i=1; i<char_count; i++ )
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
        
        for( i=0; i<coa_char_count; i++ )
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
    
    /* store new decoded data in anaylizer */
    //    BOOL resultingDataChanged = NO;
    //    
    //    if( priorResultingData != nil && ![priorResultingData isEqualToData:characterObject] )
    //        resultingDataChanged = YES;
    //    
    //    if( resultingDataChanged ) [theAna willChangeValueForKey:@"resultingData"];
    //    [theAna setValue:characterObject forKey:@"resultingData"];
    //    if( resultingDataChanged ) [theAna didChangeValueForKey:@"resultingData"];
    
    /* generate new changed index set */
    NSMutableIndexSet *changedIndexSetObject = [[NSMutableIndexSet alloc] init];
    NSMutableIndexSet *changedIndexes = [theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.changedIndexes"];
    
    NSRange maximumRange = {0, NSUIntegerMax};
    NSUInteger count = [changedIndexes countOfIndexesInRange:maximumRange];
    NSUInteger *indexBuffer = malloc( sizeof(NSUInteger) * count);
    
    [changedIndexes getIndexes:indexBuffer maxCount:count inIndexRange:&maximumRange];
    
    NSUInteger j = 0;
    i = 0;
    
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
    
    /* store new changed index set in anaylizer */
    //    BOOL changedIndexSetChanged = NO;
    //    
    //    if( priorChangedIndexSet != nil && ![priorChangedIndexSet isEqualToIndexSet:changedIndexSetObject] )
    //        changedIndexSetChanged = YES;
    //    
    //    if( changedIndexSetChanged ) [theAna willChangeValueForKey:@"editIndexSet"];
    //    [theAna setValue:changedIndexSetObject forKey:@"editIndexSet"];
    //    if( changedIndexSetChanged ) [theAna didChangeValueForKey:@"editIndexSet"];
    
    [theAna setResultingData:characterObject andChangedIndexSet:changedIndexSetObject];
    
    [changedIndexSetObject release];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //NSLog(@"ObserveValueForKeyPath: %@\nofObject: %@\nchange: %@\ncontext: %p", keyPath, object, change, context);
    
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
    NSMutableData *audioFramesObject = [optionsDictionary objectForKey:@"frameBufferObject"];
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
    free( newByteWaveForm );
    
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
    
    /* update frame count */
    unsigned long long frameCount = [[optionsDictionary objectForKey:@"frameCount"] unsignedLongLongValue];
    frameCount += delta;
    [theAna setValue:[NSNumber numberWithUnsignedLongLong:frameCount] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.frameCount"];
    
    /* setup undo */
    NSManagedObjectContext *parentContext = [theAna managedObjectContext];
    NSDictionary *previousState = [NSDictionary dictionaryWithObjectsAndKeys:previousDataObject, @"data", newRangeValue, @"range", [previousChangedSet autorelease], @"indexSet", nil];
    [[parentContext undoManager] registerUndoWithTarget:self selector:@selector(setPreviousState:) object:previousState];
    [[parentContext undoManager] setActionName:@"Byte Change"];
}

- (void) setPreviousState:(NSDictionary *)previousState
{
    StAnaylizer *theAna = self.representedObject;
    NSMutableData *frameBufferObject = [self.representedObject valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.frameBufferObject"];
    
    /* setup redo */
    NSValue *priorRange = [previousState objectForKey:@"range"];
    NSMutableIndexSet *previousChangedSet = [previousState objectForKey:@"indexSet"];
    
    NSRange range = [priorRange rangeValue];
    NSData *priorData = [frameBufferObject subdataWithRange:range];
    NSManagedObjectContext *parentContext = [theAna managedObjectContext];
    NSIndexSet *priorChangedSet = [theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.changedIndexes"];
    NSDictionary *priorState = [NSDictionary dictionaryWithObjectsAndKeys:priorData, @"data", priorRange, @"range", [[priorChangedSet mutableCopy] autorelease], @"indexSet", nil];
    [[parentContext undoManager] registerUndoWithTarget:self selector:@selector(setPreviousState:) object:priorState];
    [[parentContext undoManager] setActionName:@"Change"];
    
    /* apply previous state */
    [self.representedObject willChangeValueForKey:@"optionsDictionary.AudioAnaylizerViewController.frameBufferObject"];
    NSData *previousSamplesObject = [previousState objectForKey:@"data"];
    [frameBufferObject replaceBytesInRange:range withBytes:[previousSamplesObject bytes] length:[previousSamplesObject length]];
    [self.representedObject didChangeValueForKey:@"optionsDictionary.AudioAnaylizerViewController.frameBufferObject"];
    [self.representedObject setValue:previousChangedSet forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.changedIndexes"];
    
    /* update frame count */
    unsigned long long frameCount = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnaylizerViewController.frameCount"] unsignedLongLongValue];
    frameCount -= [previousSamplesObject length] - range.length;
    [theAna setValue:[NSNumber numberWithUnsignedLongLong:frameCount] forKeyPath:@"optionsDictionary.AudioAnaylizerViewController.frameCount"];
    
    /* re anaylize */
    [self anaylizeAudioData];
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
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithFloat:1094.68085106384f], @"lowCycle", [NSNumber numberWithFloat:2004.54545454545f], @"highCycle", [NSNumber numberWithFloat:NAN], @"scale", [NSNumber numberWithFloat:0], @"scrollOrigin", [NSNumber numberWithFloat:300.0],@"resyncThreashold", @"1", @"audioChannel", [NSArray arrayWithObject:@"1"], @"audioChannelList", [NSNull null], @"sampleRate", [NSNull null], @"channelCount", [NSNull null], @"frameCount", [NSNull null], @"coalescedObject", [NSNull null], @"frameBufferObject",[NSNumber numberWithBool:NO], @"initializedOD", [NSMutableIndexSet indexSet], @"changedIndexes", [NSNumber numberWithFloat:0.75], @"averagedMaximumSample", nil] autorelease];
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

CGFloat XIntercept( vDSP_Length x1, double y1, vDSP_Length x2, double y2 )
{
    /*  m=(Y1-Y2)/(X1-X2) */
    double m = ((double)y1 - (double)y2)/((double)x1-(double)x2);
    /*  b = Y-mX */
    double b = (double)y1 - (m * (double)x1);
    
    return (-b)/m;
}
