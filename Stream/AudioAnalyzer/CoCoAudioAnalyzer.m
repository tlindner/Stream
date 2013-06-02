//
//  CoCoAudioAnalyzer.m
//  Stream
//
//  Created by tim lindner on 9/11/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CoCoAudioAnalyzer.h"
#import "AudioAnalyzerViewController.h"
#import "Accelerate/Accelerate.h"
#import "AnalyzerEdit.h"

inline UInt32 CalculateLPCMFlags (UInt32 inValidBitsPerChannel, UInt32 inTotalBitsPerChannel, bool inIsFloat, bool inIsBigEndian, bool inIsNonInterleaved );
void FillOutASBDForLPCM(AudioStreamBasicDescription *outASBD, Float64 inSampleRate, UInt32 inChannelsPerFrame, UInt32 inValidBitsPerChannel,UInt32 inTotalBitsPerChannel, bool inIsFloat, bool inIsBigEndian, bool inIsNonInterleaved);

CGFloat XIntercept( vDSP_Length x1, double y1, vDSP_Length x2, double y2 );
float *FindZeroCrossings( AudioSampleType *samples, NSUInteger frameCount, int interpolate, NSUInteger *crossingCount );
double movingavg(int which, double newvalue, int seed);
float DCBlockFloat( float inSample );
unsigned short DCBlocking( unsigned short inSample );
BOOL hi_to_low_at(NSUInteger i, float zero_crossings[], AudioSampleType audioFrames[]);

@implementation CoCoAudioAnalyzer

@dynamic representedObject;
@synthesize frameBuffer;
@synthesize resultingData;
@synthesize cachedframeBuffer;
@synthesize zeroCrossingArray;
@synthesize changedIndexes;
@synthesize coalescedObject;
@synthesize charactersObject;
@synthesize characterObject;

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        self.frameBuffer = nil;
    }
    
    return self;
}

- (StAnalyzer *)representedObject
{
    return representedObject;
}

- (void) setRepresentedObject:(StAnalyzer *)inRepresentedObject
{
    if( representedObject != nil && inRepresentedObject == nil )
    {
        [self suspendObservations];
    }
    
    representedObject = inRepresentedObject;

    if( [inRepresentedObject respondsToSelector:@selector(addSubOptionsDictionary:withDictionary:)] )
    {
        [inRepresentedObject addSubOptionsDictionary:[CoCoAudioAnalyzer analyzerKey] withDictionary:[CoCoAudioAnalyzer defaultOptions]];
    }
    
    [self resumeObservations];
}

- (void)dealloc
{
    StAnalyzer *theAna = [self representedObject];
    AudioAnalyzerViewController *vc = (AudioAnalyzerViewController *)[theAna viewController];
    [vc analyzerIsDeallocating];
    [self suspendObservations];
    self.frameBuffer = nil;
    self.cachedframeBuffer = nil;
    self.zeroCrossingArray = nil;
    self.changedIndexes = nil;
    self.coalescedObject = nil;
    self.charactersObject = nil;
    self.characterObject = nil;
    
    [super dealloc];
}

- (void) analyzeData
{
    StAnalyzer *theAna = self.representedObject;
    int audioChannel = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController.audioChannel"] intValue];
    [self loadAudioChannel:audioChannel];
}

- (void) loadAudioChannel:(NSUInteger)audioChannel
{
    currentAudioChannel = audioChannel;
    StAnalyzer *theAna = self.representedObject;
    theAna.errorString = @"";
    OSStatus myErr;
    UInt32 propSize;
    
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
        if (myErr != noErr) {
            theAna.errorString = [NSString stringWithFormat:@"ExtAudioFileGetProperty (1): returned error: %d", myErr];
            return;
        }
        
        UInt32 channelCount = clientFormat.mChannelsPerFrame;
        [theAna setValue:[NSNumber numberWithUnsignedInt:clientFormat.mChannelsPerFrame] forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.channelCount"];
        
        if( audioChannel > channelCount )
            audioChannel = channelCount;
        
//        [theAna setValue:[NSString stringWithFormat:@"%d", audioChannel] forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.audioChannel"];
        [theAna setValue:[NSNumber numberWithDouble:clientFormat.mSampleRate] forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.sampleRate"];
        
        /* Build array for channel popup list in accessory view */
        NSMutableArray *theChannelList = [[NSMutableArray alloc] init];
        for( NSUInteger i=1; i<=channelCount; i++ )
        {
            [theChannelList addObject:[NSString stringWithFormat:@"%ld", (unsigned long)i]];
        }
        
        [theAna setValue:theChannelList forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.audioChannelList"];
        [theChannelList release];
        
        propSize = sizeof(SInt64);
        myErr = ExtAudioFileGetProperty(af, kExtAudioFileProperty_FileLengthFrames, &propSize, &fileFrameCount);
        if (myErr != noErr) {
            theAna.errorString = [NSString stringWithFormat:@"ExtAudioFileGetProperty (2): returned error: %d", myErr];
            return;
        }
        
        SetCanonical(&clientFormat, (UInt32)channelCount, YES);
        
        propSize = sizeof(clientFormat);
        myErr = ExtAudioFileSetProperty(af, kExtAudioFileProperty_ClientDataFormat, propSize, &clientFormat);
        if (myErr != noErr) {
            theAna.errorString = [NSString stringWithFormat:@"ExtAudioFileSetProperty: returned error: %d", myErr];
            return;
        }
        
        size_t frameBufferSize = sizeof(AudioSampleType) * fileFrameCount * channelCount;
        AudioSampleType *frameBufferAS = malloc(frameBufferSize+1);
        
        AudioBufferList bufList;
        bufList.mNumberBuffers = 1;
        bufList.mBuffers[0].mNumberChannels = (UInt32)channelCount;
        bufList.mBuffers[0].mData = frameBufferAS;
        bufList.mBuffers[0].mDataByteSize = (UInt32)frameBufferSize;
        UInt32 ioFrameCount = (unsigned int)fileFrameCount;
        myErr = ExtAudioFileRead(af, &ioFrameCount, &bufList);
        if (myErr != noErr) {
            theAna.errorString = [NSString stringWithFormat:@"ExtAudioFileRead: returned error: %d", myErr];
            return;
        }
        
        /* destride audio sample so we only have the one selected channel */
        NSMutableData *frameBufferObject = [NSMutableData dataWithLength:sizeof(AudioSampleType) * fileFrameCount];
        AudioSampleType *frameBufferObjectBytes = [frameBufferObject mutableBytes];
        AudioSampleType *sourceAudioFrame = frameBufferAS + (audioChannel - 1);
        [theAna setValue:[NSString stringWithFormat:@"%lld", fileFrameCount] forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.frameCount"];

        for( SInt64 i=0; i<fileFrameCount; i++ )
        {
            frameBufferObjectBytes[i] = sourceAudioFrame[i*channelCount];
        }
        
        free( frameBufferAS );
        
        theAna.resultingUTI = @"com.microsoft.cocobasic.tape";

        [self willChangeValueForKey:@"frameBuffer"];
        self.frameBuffer = frameBufferObject;
        self.cachedframeBuffer = [[frameBufferObject copy] autorelease];
        [self applyInvert];
        [self applyAmplify];
        [self applyDCBlocking];
        [self applyAllEdits];
        [self analyzeAudioData];
        [self didChangeValueForKey:@"frameBuffer"];
        
        myErr = ExtAudioFileDispose(af);
        if (myErr != noErr) {
            theAna.errorString = [NSString stringWithFormat:@"ExtAudioFileDispose: returned error: %d", myErr];
        }
    }
    else
    {
        theAna.errorString = @"ExtAudioFileOpenURL: could not open file";
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
    StAnalyzer *theAna = self.representedObject;
    Float64 _sample_rate = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController.sampleRate"] doubleValue];
    UInt32 _channel_count = 1;
    float *_samples = (float *)[data bytes];
    UInt32 _frame_count = [data length] / sizeof(float);
    
    
    AudioStreamBasicDescription file_desc = {0, 0, 0, 0, 0, 0, 0, 0, 0};
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

- (void) analyzeAudioData
{
    NSAssert(self.representedObject != nil, @"Analyze Audio Data: analyzer can not be nil");
    StAnalyzer *theAna = self.representedObject;
    
    needsAnalyzation = NO;
    analyzationError = NO;

    double sampleRate = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController.sampleRate"] doubleValue];
    float lowCycle = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController.lowCycle"] floatValue];
    float highCycle = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController.highCycle"] floatValue];
    BOOL interpolate = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController.interpolate"] boolValue];
    
    NSMutableData *frameBufferObject = self.frameBuffer;
    AudioSampleType *audioFrames = [frameBufferObject mutableBytes];
    NSUInteger frameCount = [frameBufferObject length] / sizeof(AudioSampleType);
    AudioSampleType *frameStart = audioFrames;
    NSUInteger crossingCount;
    
    float *zero_crossings = FindZeroCrossings( frameStart, frameCount, interpolate, &crossingCount ); 
        
    /* Store zero crossing array for wave form display */
    self.zeroCrossingArray = [NSData dataWithBytesNoCopy:zero_crossings length:sizeof(float)*crossingCount];

    /* Scan zero crossings looking for valid data */
    int max_possible_characters = (crossingCount*2*8)+1;
    self.charactersObject = [NSMutableData dataWithLength:sizeof(NSRange)*max_possible_characters];
    NSRange *characters = [self.charactersObject mutableBytes];
    self.characterObject = [NSMutableData dataWithLength:sizeof(unsigned char)*max_possible_characters];
    unsigned char *character = [self.characterObject mutableBytes];
    NSUInteger char_count = 0;
    
    crossingCount -= 1;
    unsigned short even_parity = 0, odd_parity = 0, *found_parity = nil;
    double dataThreashold = ((sampleRate/lowCycle) + (sampleRate/highCycle)) / 2.0, test1, test2;
    float resyncThresholdHertz = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController.resyncThreashold"] floatValue];
    
    if( resyncThresholdHertz > lowCycle/2.0 )
    {
        theAna.errorString = @"Resynchronization threshold cannot be larger than half of the low frequency target.";
        return;
    }
    
    double resyncThreshold = sampleRate/resyncThresholdHertz;
    int bit_count = 0, bump;
    
    /* start by scanning zero crossing looking for the start of a block */
    NSUInteger i;
    for (i=2; i<crossingCount-1; i+=2)
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
        
        if (found_parity) {
            if (test1 > resyncThreshold || test2 > resyncThreshold) {
                /* finish off byte */
                character[char_count] = *found_parity >> 8;
                NSUInteger actualLength = MIN(zero_crossings[i+bump] - characters[char_count].location, resyncThreshold * 8);
                characters[char_count].length = actualLength;
                char_count++;
                bit_count = 0;
                found_parity = nil;
            }
            else {
            /* continue building bytes */
                if (bit_count == 7) {
                    character[char_count] = *found_parity >> 8;
                    characters[char_count].length = zero_crossings[i+bump] - characters[char_count].location;
                    char_count++;
                    bit_count = 0;
                    
                    characters[char_count].location = zero_crossings[i+bump];
                    characters[char_count].length = 0;
                } else {
                    bit_count++;
                }
            }
        }
        else {
            /* test for start block bit pattern */
            
            if ((even_parity & 0xfff0) == 0x3c50 && hi_to_low_at(i-2, zero_crossings, audioFrames)) {
                found_parity = &even_parity;
                bump = 0;
            } else if ((odd_parity & 0xfff0) == 0x3c50 && hi_to_low_at(i-1, zero_crossings, audioFrames)) {
                found_parity = &odd_parity;
                bump = 1;
            }
            else {
                found_parity = nil;
            }
            
            if (found_parity) {

                /* capture (0x5x) sync byte */
                characters[char_count].location = zero_crossings[i+bump-(16*2)];
                characters[char_count].length = zero_crossings[i+bump-(8*2)] - zero_crossings[i+bump-(16*2)];
                character[char_count] = *found_parity & 0x00ff;
                char_count++;
                
                /* capture 0x3c sync byte */
                characters[char_count].location = zero_crossings[i+bump-(8*2)];
                characters[char_count].length = zero_crossings[i+bump] - zero_crossings[i+bump-(8*2)];
                character[char_count] = *found_parity >> 8;
                char_count++;
                
                characters[char_count].location = zero_crossings[i+bump];
                characters[char_count].length = 0;

                bit_count = 0;
            }
        }
    }
    
    if (bit_count > 0) {
        assert(i+bump < crossingCount);
        characters[char_count].length = zero_crossings[i+bump] - characters[char_count].location;
    }
    
    /* no need to free buffer, it was wrapped in an NSData object */
    //free(zero_crossings);
    
    /* shirnk buffers to actual size */
    [self.charactersObject setLength:sizeof(NSRange)*char_count];
    [self.characterObject setLength:sizeof(unsigned char)*char_count];
    
    if( characters != [self.charactersObject mutableBytes] )
        characters = [self.charactersObject mutableBytes];
    
    self.coalescedObject = [NSMutableData dataWithLength:sizeof(NSRange)*char_count];
    NSRange *coalescedCharacters = [self.coalescedObject mutableBytes];
    
    coalescedCharacters[0] = characters[0];
    NSUInteger coa_char_count = 1;
    
    /* coalesce nearby found byte rectangles into single continous rectangle */
    /* this greatly speeds up the "found data" tint when zoomed out */
    for(NSUInteger i=1; i<char_count; i++ )
    {
        if( characters[i].location-5.0 <= coalescedCharacters[coa_char_count-1].location + coalescedCharacters[coa_char_count-1].length )
            coalescedCharacters[coa_char_count-1].length += characters[i].length - (coalescedCharacters[coa_char_count-1].location + coalescedCharacters[coa_char_count-1].length - characters[i].location);
        else
            coalescedCharacters[coa_char_count++] = characters[i];
    }
    
    /* shirnk buffer to actual size */
    [self.coalescedObject setLength:sizeof(NSRange)*coa_char_count];
    
    /* find average of max value for each coalessed range */
    /* this will be used when creating new wave forms during writing */
    AudioSampleType average;
    
    if( coa_char_count != 0 )
    {
        average = 0;
        
        for(NSUInteger i=0; i<coa_char_count; i++ )
        {
            AudioSampleType maxValue;
            vDSP_maxv( audioFrames + coalescedCharacters[i].location, 1, &maxValue, coalescedCharacters[i].length );
            average += maxValue;
        }
        
        average = average / coa_char_count;
    }
    else
        average = 0.75; /* this is a decent value if there is no found data */
    
    [theAna setValue:[NSNumber numberWithFloat:average] forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.averagedMaximumSample"];
    
    /* generate new changed index set */
//    NSMutableIndexSet *changedIndexSetObject = [[NSMutableIndexSet alloc] init];
//    NSMutableIndexSet *changedIndexes = [theAna valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController.changedIndexes"];
    
//    NSRange maximumRange = {0, NSUIntegerMax};
//    NSUInteger count = [self.changedIndexes countOfIndexesInRange:maximumRange];
//    NSUInteger *indexBuffer = malloc( sizeof(NSUInteger) * count);
    
//    [self.changedIndexes getIndexes:indexBuffer maxCount:count inIndexRange:&maximumRange];

//    NSUInteger j = 0;
//    i = 0;
//    
//    while( i < count && j < char_count)
//    {
//        if( indexBuffer[i] < characters[j].location )
//        {
//            i++;
//        }
//        else if( NSLocationInRange(indexBuffer[i], characters[j] ) )
//        {
//            [changedIndexSetObject addIndex:j];
//            i++;
//            j++;
//        }
//        else
//            j++;
//    }
//    
//    free( indexBuffer );

    self.resultingData = self.characterObject;
    
//    [changedIndexSetObject release];
}

- (void)replaceBytesInRange:(NSRange)range withBytes:(unsigned char *)byte
{
    NSLog( @"Audio Ana: Unimplemented: replaceBytesInRange: %@ withByte 0x%x", NSStringFromRange(range), *byte);
}

- (void) applyAllEdits
{
    NSRange editRange;
    NSInteger shift;
    
    /* clear out modified data index set*/
    if (self.changedIndexes == nil) {
        self.changedIndexes = [[[NSMutableIndexSet alloc] init] autorelease];
    }
    
    [self.changedIndexes removeAllIndexes];
    
    for (AnalyzerEdit *edit in [representedObject edits])
    {
        [self.frameBuffer replaceBytesInRange:NSMakeRange(edit.location, edit.length) withBytes:[edit.data bytes] length:[edit.data length]];
        
        editRange.location = edit.location / sizeof(float);
        editRange.length = edit.length / sizeof(float);
        
        shift = editRange.length - ([edit.data length] / sizeof(float));
        
        [self.changedIndexes addIndexesInRange:editRange];
        [self.changedIndexes shiftIndexesStartingAtIndex:editRange.location+editRange.length by:shift];        
    }
}

- (void) reloadChachedAudioFrames
{
    self.frameBuffer = [[self.cachedframeBuffer  mutableCopy] autorelease];
    [self applyInvert];
    [self applyAmplify];
    [self applyDCBlocking];
    [self applyAllEdits];
}

- (void) applyAmplify
{
    StAnalyzer *theAna = self.representedObject;
    NSInteger amplify = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController.amplify"] integerValue];
    
    if( amplify != 0 )
    {
        if( amplify > 100 ) amplify *= 5.0;
        
        float *frames = (float *)[self.frameBuffer bytes];
        NSUInteger length = [self.frameBuffer length] / sizeof(float);
        float divisor = amplify/100.0;
        
        vDSP_vsmul( frames, 1, &divisor, frames, 1, length );
    }
}

- (void) applyInvert
{
    StAnalyzer *theAna = self.representedObject;
    BOOL invert = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController.invert"] boolValue];
    
    if( invert )
    {
        float *frames = (float *)[self.frameBuffer bytes];
        NSUInteger length = [self.frameBuffer length] / sizeof(float);
        float divisor = -1.0;
        
        vDSP_vsmul( frames, 1, &divisor, frames, 1, length );
    }
}

- (void) applyDCBlocking
{
    StAnalyzer *theAna = self.representedObject;
    Boolean dcblock = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController.dcblocking"] boolValue];
    
    if( dcblock )
    {
        float *frames = (float *)[self.frameBuffer bytes];
        NSUInteger length = [self.frameBuffer length] / sizeof(float);

        for( NSUInteger i=0; i<length; i++ )
            frames[i] = DCBlockFloat(frames[i]);
    }
}

- (void) updateWaveFormForCharacter:(NSUInteger)idx
{
    StAnalyzer *theAna = self.representedObject;
    
    /* get max of current wave form */
    NSDictionary *optionsDictionary = [theAna valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController"];
    NSRange *characters = (NSRange *)[self.charactersObject mutableBytes];
    NSMutableData *audioFramesObject = self.frameBuffer;
    AudioSampleType *audioFrames = [audioFramesObject mutableBytes];
    AudioSampleType *frameStart = audioFrames + characters[idx].location;
    AudioSampleType maxValue = [[optionsDictionary objectForKey:@"averagedMaximumSample"] floatValue];
    NSData *previousDataObject = [NSData dataWithBytes:frameStart length:sizeof(AudioSampleType) * characters[idx].length];
    
    /* calculate waveform buffer size */
    unsigned char *character = [self.characterObject mutableBytes];
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
//    unsigned long delta = totalLength - characters[idx].length;
//    NSMutableIndexSet *previousChangedSet = [self.changedIndexes mutableCopy];
//    [self.changedIndexes shiftIndexesStartingAtIndex:characters[idx+1].location by:delta];
    
    /* adjust characters accounting */
//    characters[idx].length = totalLength;
//    for( unsigned long i = idx+1; i < [self.characterObject length]; i++ )
//        characters[i].location += delta;
    
    /* add newley generated waveform to changed set */
    [self.changedIndexes addIndexesInRange:characters[idx]];

    /* setup undo */
//    NSManagedObjectContext *parentContext = [theAna managedObjectContext];
//    NSUndoManager *um = [parentContext undoManager];
//    NSDictionary *previousState = [NSDictionary dictionaryWithObjectsAndKeys:previousDataObject, @"data", newRangeValue, @"range", previousChangedSet, @"indexSet", nil];
//    [previousChangedSet release];
//    [um registerUndoWithTarget:self selector:@selector(setPreviousState:) object:previousState];
//    [um setActionName:@"Byte Change"];
    
    /* post edit to analyzer */
    [theAna postEdit:newByteWaveFormObject atLocation:oldRange.location withLength:oldRange.length];
}

- (void) setPreviousState:(NSDictionary *)previousState
{
    StAnalyzer *theAna = self.representedObject;
    NSMutableData *frameBufferObject = self.frameBuffer;
    
    /* setup redo */
    NSValue *priorRange = [previousState objectForKey:@"range"];
    NSMutableIndexSet *previousChangedSet = [previousState objectForKey:@"indexSet"];
    
    NSRange range = [priorRange rangeValue];
    NSData *priorData = [frameBufferObject subdataWithRange:range];
    NSManagedObjectContext *parentContext = [theAna managedObjectContext];
    NSDictionary *priorState = [NSDictionary dictionaryWithObjectsAndKeys:priorData, @"data", priorRange, @"range", [[self.changedIndexes mutableCopy] autorelease], @"indexSet", nil];
    
    /* register redo */
    [[parentContext undoManager] registerUndoWithTarget:self selector:@selector(setPreviousState:) object:priorState];
    [[parentContext undoManager] setActionName:@"Change"];
    
    /* apply previous state */
    NSData *previousSamplesObject = [previousState objectForKey:@"data"];
    [frameBufferObject replaceBytesInRange:range withBytes:[previousSamplesObject bytes] length:[previousSamplesObject length]];
    self.changedIndexes = previousChangedSet;
    
    /* re analyze */
    [self analyzeAudioData];
}

- (void) determineFrequencyOrigin:(NSUInteger)origin width:(NSUInteger)width
{
    NSMutableData *frameBufferObject = self.frameBuffer;
    AudioSampleType *audioFrames = [frameBufferObject mutableBytes];
    NSUInteger crossingCount;
    StAnalyzer *theAna = self.representedObject;
    BOOL interpolate = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController.interpolate"] boolValue];
    float *zero_crossings = FindZeroCrossings( audioFrames+origin, width, interpolate, &crossingCount );
    
    double sampleRate = [[theAna valueForKeyPath:@"optionsDictionary.AudioAnalyzerViewController.sampleRate"] doubleValue];
    double diff1, diff2, diff3, diff4, diff5;
    double movingAverage1, movingAverage2, movingAverage3, movingAverage4, movingAverageHigh, movingAverageLow;
    diff1 = diff2 = diff3 = diff4 = diff5 = 0.0;
    movingAverage1 = movingAverage2 = movingAverage3 = movingAverage4 = 0;
    
    for( unsigned long i=1; i<crossingCount/4; i++ )
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

    [theAna setValue:[NSNumber numberWithFloat:movingAverageLow] forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.lowCycle"];
    [theAna setValue:[NSNumber numberWithFloat:movingAverageHigh] forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.highCycle"];
    [theAna setValue:[NSNumber numberWithFloat:movingAverageLow/2.0] forKeyPath:@"optionsDictionary.AudioAnalyzerViewController.resyncThreashold"];
   
    free( zero_crossings );
}

- (void) zeroSamplesOrigin:(NSUInteger)origin width:(NSUInteger)width
{
    StAnalyzer *theAna = [self representedObject];
    float *frames = (float *)[self.frameBuffer bytes];
    float divisor = 0.0;
    
    vDSP_vsmul( frames, 1, &divisor, &(frames[origin]), 1, width );
    
    NSData *zeros = [NSData dataWithBytes:&(frames[origin]) length:width * sizeof(float)]; 
    [theAna postEdit:zeros range:NSMakeRange(origin * sizeof(float), width * sizeof(float))];
    
    [self willChangeValueForKey:@"frameBuffer"];
    [self analyzeAudioData];
    [theAna.parentStream regenerateAllBlocks];
    [self.changedIndexes addIndexesInRange:NSMakeRange(origin, width)];
    [self didChangeValueForKey:@"frameBuffer"];
}

- (void) suspendObservations
{
}

- (void) resumeObservations
{
}

+ (NSArray *)analyzerUTIs
{
    return [NSArray arrayWithObject:@"public.audio"];
}

+ (NSString *)analyzerName
{
    return @"CoCo Audio Analyzer";
}

+ (NSString *)analyzerKey
{
    return @"AudioAnalyzerViewController";
}

- (Class)viewControllerClass
{
    return [AudioAnalyzerViewController class];
}

+ (NSString *)AnalyzerPopoverAccessoryViewNib
{
    return @"AudioAnalyzer";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:@"0", @"frameCount", [NSNumber numberWithFloat:1094.68085106384f], @"lowCycle", [NSNumber numberWithFloat:2004.54545454545f], @"highCycle", [NSNumber numberWithFloat:NAN], @"scale", [NSNumber numberWithFloat:0], @"scrollOrigin", [NSNumber numberWithFloat:300.0],@"resyncThreashold", @"1", @"audioChannel", [NSArray arrayWithObject:@"1"], @"audioChannelList", [NSNull null], @"sampleRate", [NSNull null], @"channelCount", [NSNumber numberWithFloat:0.75], @"averagedMaximumSample", [NSNumber numberWithInteger:100], @"amplify", [NSNumber numberWithBool:NO], @"selected", [NSNumber numberWithBool:NO], @"interpolate", [NSNumber numberWithBool:NO], @"dcblocking", [NSNumber numberWithBool:NO], @"invert", nil] autorelease];
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

//float DCBlockFloat( float inSample )
//{
//    float result;
//    if( inSample < -1.0 ) inSample = -1.0;
//    if( inSample > 1.0 ) inSample = 1.0;
//    
//    result = DCBlocking( inSample * 16383.0 );
//    result /= 16383.0;
//    
//    return result;
//}

float DCBlockFloat( float inSample )
{
    float result;
    static float lastInput = 0, lastOutput = 0;
    
    result = inSample - lastInput + 0.995 * lastOutput;

    lastInput  = inSample;
    lastOutput = result;
    
    return result;
}


unsigned short DCBlocking( unsigned short inSample )
{
    // let's say sizeof(short) = 2 (16 bits) and sizeof(long) = 4 (32 bits)
    
    static long acc = 0, prev_x = 0, prev_y = 0;
    long A;
    double pole;
    short outSample;
    
    pole = 0.9999;
    
    A = (long)(32768.0*(1.0 - pole));
    
    acc   -= prev_x;
    prev_x = (long)inSample<<15;
    acc   += prev_x;
    acc   -= A*prev_y;
    prev_y = acc>>15;               // quantization happens here
    outSample   = (short)prev_y;    // acc has y[n] in upper 17 bits and -e[n] in lower 15 bits
    
    return outSample;
}

BOOL hi_to_low_at(NSUInteger i, float zero_crossings[], AudioSampleType audioFrames[])
{
    AudioSampleType nowSample = audioFrames[(int)zero_crossings[i]];
    AudioSampleType pastSample = audioFrames[(int)zero_crossings[i-1]];
    
    return pastSample > nowSample;
}
