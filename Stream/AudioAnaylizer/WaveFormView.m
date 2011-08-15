//
//  WaveFormView.m
//  Stream
//
//  Created by tim lindner on 7/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WaveFormView.h"
#import "AudioAnaylizer.h"
#import "Accelerate/Accelerate.h"
#import "AudioToolbox/AudioConverter.h"

void SamplesSamples_max( Float64 sampleRate, Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, NSUInteger maxOffset );
void SamplesSamples_avg( Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, NSUInteger maxOffset );
void SamplesSamples_1to1(Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, NSUInteger maxOffset );
CGFloat XIntercept( vDSP_Length x1, double y1, vDSP_Length x2, double y2 );

@implementation WaveFormView

@synthesize audioFrames;
@synthesize frameCount;
@synthesize sampleRate;
@synthesize characters;
@synthesize character;
@synthesize char_count;
@synthesize coalescedCharacters;
@synthesize coa_char_count;
@synthesize previousBoundsWidth;
@synthesize previousFrameWidth;
@synthesize previousOffset;
@synthesize previousBuffer;
@synthesize lowCycle;
@synthesize highCycle;
@synthesize resyncThresholdHertz;
@synthesize cachedAnaylizer;
@synthesize anaylizationError;
@synthesize errorString;
@synthesize needsAnaylyzation;

//- (id)initWithFrame:(NSRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        //NSLog( @"init Frame: %@", NSStringFromRect(frame ));
//        // Initialization code here.
//    }
//    
//    return self;
//}

//- (void) setFrame:(NSRect)frameRect
//{
//    NSLog( @"set Frame: %@", NSStringFromRect(frameRect ));
//    [super setFrame:frameRect];
//}

- (void)drawRect:(NSRect)dirtyRect
{
    AudioAnaylizer *aa = (AudioAnaylizer *)[[[self superview] superview] superview];
    [aa.objectValue setValue:[NSNumber numberWithFloat:[[self superview] bounds].origin.x] forKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.scrollOrigin"];
    
    if( needsAnaylyzation ) [self anaylizeAudioDataWithOptions:nil];
    
    // Drawing code here.
    if( anaylizationError == YES )
    {
        if (errorString == nil) self.errorString = @"No error message set!";

        [errorString drawInRect:dirtyRect withAttributes:nil];
        
        [[NSColor grayColor] set];
        NSRectFill(dirtyRect);
    }
    
    if( audioFrames != nil )
    {
        CGFloat currentBoundsWidth = [[self superview] bounds].size.width;
        CGFloat currentFrameWidth = [[self superview] frame].size.width;
        CGFloat scale = currentBoundsWidth/currentFrameWidth;
        //NSLog( @"%f", scale );
        
        NSAffineTransform *at = [NSAffineTransform transform];
        [at scaleXBy:scale yBy:1.0f];
        [at concat];
        
        NSInteger viewheight = [self frame].size.height-25;
        
        float origin = dirtyRect.origin.x / scale;
        float width = dirtyRect.size.width / scale;
        
        /* Create sub-sample array */
        
        Float32 *viewFloats;
        int offset = dirtyRect.origin.x;

        if( (previousOffset == offset) && (previousBoundsWidth == currentBoundsWidth) && (previousFrameWidth == currentFrameWidth) )
        {
            viewFloats = previousBuffer;
        }
        else
        {
            free( previousBuffer );
            viewFloats = malloc(sizeof(Float32)*width);
            SamplesSamples_max( sampleRate, viewFloats, &(audioFrames[offset]), scale, width, frameCount-offset);
            previousBuffer = viewFloats;
            previousOffset = offset;
            previousBoundsWidth = currentBoundsWidth;
            previousFrameWidth = currentFrameWidth;
        }

        /* Blank background */
        NSRect rect;
        [[NSColor colorWithCalibratedWhite:0.95 alpha:1.0] set];
        rect = NSMakeRect(dirtyRect.origin.x/scale, dirtyRect.origin.y, dirtyRect.size.width/scale, dirtyRect.size.height);
        NSRectFill(rect);
        
        /* decoded data values and data regions */
        int i = 0;
        if( ((sampleRate / 2400.0) * 8 / scale) > 9.5)
        {
            /* we're zoomed enought to draw segemented frames around byte groups and actual values */
            while ( i< char_count && characters[i].start < dirtyRect.origin.x) i++;
            
            if( i>0 ) i--;
            
            NSColor *lightColor = [NSColor colorWithCalibratedWhite:0.4 alpha:0.5];
            NSColor *darkColor = [NSColor colorWithCalibratedWhite:0.6 alpha:0.5];
            while( i < char_count && characters[i].start < dirtyRect.origin.x+dirtyRect.size.width )
            {
                /* Draw decoded values */
                [[NSColor blackColor] set];
                NSString *string = [NSString stringWithFormat:@"%2.2X" , character[i]];
                NSSize charWidth = [string sizeWithAttributes:nil];
                NSPoint thePoint = NSMakePoint((characters[i].start+(characters[i].length/2)-(charWidth.width/2))/scale, 11);
                [string drawAtPoint:thePoint withAttributes:nil];
                
                /* Draw byte grouping */
                if (i & 0x1 )
                    [lightColor set];
                else
                    [darkColor set];
                
                NSBezierPath* aPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect((characters[i].start)/scale, 25.0, ((characters[i].length)/scale), viewheight-1) xRadius:5.0*scale yRadius:5.0];
                [aPath fill];
                i++;
            }
        }
        else
        {
            /* we're zoomed too far out to see detial */
            while ( (i < coa_char_count) && (coalescedCharacters[i].start < dirtyRect.origin.x)) i++;
            
            if( i>0 ) i--;
            
            while( (i < coa_char_count) && (coalescedCharacters[i].start < dirtyRect.origin.x+dirtyRect.size.width) )
            {
                /* Draw backound grouping */
                [[NSColor lightGrayColor] set];
                rect = NSMakeRect((coalescedCharacters[i].start)/scale, 25.0, ((coalescedCharacters[i].length)/scale), viewheight-1);
                NSRectFill(rect);
                
                /* Draw value bar */
                rect.origin.y = 14;
                rect.size.height = 10;
                NSRectFill(rect);
                i++;
            }
        }
        
        /* Draw zero line */
        [[NSColor blackColor] set];
        rect = NSMakeRect(dirtyRect.origin.x/scale, (viewheight/2)+25, dirtyRect.size.width/scale, 1);
        NSRectFill(rect);
        
        /* Draw wave form */
        [[NSColor blackColor] set];
        
        if( scale < 3.0 )
        {
            /* Near 1:1 zoom, draw vertical lines connecting points to points */
            CGFloat lastHeight = (viewheight/2)+25, thisHeight;
            for( i=0; i<width; i++ )
            {
                thisHeight = (viewheight/2)+(viewFloats[i]*(viewheight/2));

                if (thisHeight > lastHeight)
                    rect = NSMakeRect(i+origin, lastHeight+25, 1, thisHeight - lastHeight);
                else
                    rect = NSMakeRect(i+origin, thisHeight+25, 1, lastHeight - thisHeight);
                
                NSRectFill(rect);
                lastHeight = thisHeight;
            }
            
        }
        else
        {
            /* Zoomed out, draw maxed values, reflected across zero */
            for( i=0; i<width; i++ )
            {
                rect = NSMakeRect(i+origin, (viewheight/2) - (viewFloats[i]*(viewheight/2))+25, 1, (viewFloats[i]*(viewheight)) );
                NSRectFill(rect);
            }
        }
    }
    else
    {
        /* No data, draw black rectangle */
        [[NSColor blackColor] set];
        NSRectFill(dirtyRect);
    }
}

- (void)dealloc
{

    [self.cachedAnaylizer unbind:@"optionsDictionary.ColorComputerAudioAnaylizer.lowCycle"];
    [self.cachedAnaylizer unbind:@"optionsDictionary.ColorComputerAudioAnaylizer.highCycle"];
    [self.cachedAnaylizer unbind:@"optionsDictionary.ColorComputerAudioAnaylizer.resyncThreashold"];
    
    if( audioFrames != nil )
        free( audioFrames );
    
    if( characters != nil )
        free( characters );
    
    if( character != nil )
        free( character );
    
    if( coalescedCharacters != nil )
        free( coalescedCharacters );
    
    if( previousBuffer != nil )
        free( previousBuffer );
    
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //NSLog( @"Observied: kp: %@, object: %@, change: %@", keyPath, object, change );
    
    if ([keyPath isEqualToString:@"optionsDictionary.ColorComputerAudioAnaylizer.lowCycle"])
    {
        if ([[change objectForKey:@"new"] floatValue] != lowCycle)
        {
            self.needsAnaylyzation= YES;
            [self setNeedsDisplay:YES];
        }
        
        return;
    }
    
    if ([keyPath isEqualToString:@"optionsDictionary.ColorComputerAudioAnaylizer.highCycle"])
    {
        if ([[change objectForKey:@"new"] floatValue] != highCycle)
        {
            self.needsAnaylyzation= YES;
            [self setNeedsDisplay:YES];
        }
        
        return;
    }
    
    if ([keyPath isEqualToString:@"optionsDictionary.ColorComputerAudioAnaylizer.resyncThreashold"])
    {
        if ([[change objectForKey:@"new"] floatValue] != resyncThresholdHertz)
        {
            self.needsAnaylyzation= YES;
            [self setNeedsDisplay:YES];
        }
        
        return;
    }

    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void) anaylizeAudioDataWithOptions:(StAnaylizer *)anaylizer
{
    needsAnaylyzation = NO;
    anaylizationError = NO;
    
    if( self.cachedAnaylizer == nil && anaylizer != nil)
        self.cachedAnaylizer = anaylizer;
    else if( self.cachedAnaylizer == nil && anaylizer == nil )
    {
        NSLog( @"anaylizeAudioDataWithOptions: no anaylizer avaiable" );
        return;
    }
    
    /* setup observations */
    [self.cachedAnaylizer addObserver:self forKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.lowCycle" options:NSKeyValueChangeSetting context:nil];
    [self.cachedAnaylizer addObserver:self forKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.highCycle" options:NSKeyValueChangeSetting context:nil];
    [self.cachedAnaylizer addObserver:self forKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.resyncThreashold" options:NSKeyValueChangeSetting context:nil];

    lowCycle = [[self.cachedAnaylizer valueForKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.lowCycle"] floatValue];
    highCycle = [[self.cachedAnaylizer valueForKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.highCycle"] floatValue];
    vDSP_Length i;
    int zc_count;
    
    unsigned long max_possible_zero_crossings = (frameCount / 2) + 1;
    float *zero_crossings = malloc(sizeof(float)*max_possible_zero_crossings);
    zc_count = 0;
    
    /* Create temporary array of zero crossing points */
    for( i=1; i<frameCount; i++ )
    {
        vDSP_Length crossing;
        vDSP_Length total;
        
        vDSP_nzcros(audioFrames+i, 1, 1, &crossing, &total, frameCount-i);
        
        if( crossing == 0 ) break;
        
        zero_crossings[zc_count++] = i+crossing;
        //zero_crossings[zc_count++] = XIntercept(i+crossing-1, audioFrames[i+crossing-1], i+crossing, audioFrames[i+crossing]);
        
        i += crossing-1;
    }
    
    /* removed unused space in zero crossing array */
    zero_crossings = realloc(zero_crossings, sizeof(float)*zc_count);
    
    /* Scan zero crossings looking for valid data */
    
    if( self.characters != nil )
        free(self.characters);
    
    if( self.character != nil )
        free(self.character);
    
    if( self.coalescedCharacters != nil )
        free(self.coalescedCharacters);
    
    int max_possible_characters = (zc_count*2*8)+1;
    self.characters = malloc( sizeof(charRef)*max_possible_characters );
    self.character = malloc( sizeof(unsigned char)*max_possible_characters );
    self.char_count = 0;
    
    zc_count -= 1;
    unsigned short even_parity = 0, odd_parity = 0;
    double dataThreashold = ((sampleRate/lowCycle) + (sampleRate/highCycle)) / 2.0, test1, test2;
    resyncThresholdHertz = [[self.cachedAnaylizer valueForKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.resyncThreashold"] floatValue];
    
    if( resyncThresholdHertz > lowCycle/2.0 )
    {
        self.errorString = @"Resynchronization threshold cannot be larger than half of the low frequency target.";
        self.anaylizationError = YES;
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
        if( (even_parity & 0xff0f) == 0x3c05 || (odd_parity & 0xff0f) == 0x3c05 )
        {
            if( (odd_parity & 0xff0f) == 0x3c05 )
            {
                /* adjust position one zero crossing into the future */
                i++;
                even_parity = odd_parity;
            }
            
            /* capture (0x0f & 0x05) sync byte */
            characters[char_count].start = zero_crossings[i-(16*2)];
            characters[char_count].length = zero_crossings[i-(8*2)] - zero_crossings[i-(16*2)];
            character[char_count] = even_parity & 0x00ff;
            char_count++;
            
            /* capture 0x3c sync byte */
            characters[char_count].start = zero_crossings[i-(8*2)];
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
                    characters[char_count].start = zero_crossings[i-2];
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
                        characters[char_count].length = zero_crossings[i-1] - characters[char_count].start + resyncThreshold;
                    else
                        characters[char_count].length = zero_crossings[i] - characters[char_count].start;
                    character[char_count] = even_parity >> 8;
                    char_count++;
                    bit_count = 0;
                }
                else if( test1 > resyncThreshold )
                {
                    /* lost sync, finish off last byte, break out of loop to try to re-synchronize */
                    characters[char_count].length = zero_crossings[i-1] - characters[char_count].start + resyncThreshold;
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
            characters[char_count].length = frameCount - characters[char_count].start;
            character[char_count] = even_parity >> 8;
            char_count++;
        }
    }

    free(zero_crossings);

    /* shirnk buffers to actual size */
    self.characters = realloc(characters, sizeof(charRef)*char_count);
    self.character = realloc(character, sizeof(unsigned char)*char_count);
    
    self.coalescedCharacters = malloc( sizeof(charRef)*char_count );
    coalescedCharacters[0] = characters[0];
    self.coa_char_count = 1;
    
    /* coalesce nearby found byte rectangles into single continous rectangle */
    /* this greatly speeds up the "found data" tint when zoomed out */
    for( i=1; i<char_count; i++ )
    {
        if( characters[i].start-5.0 <= coalescedCharacters[coa_char_count-1].start + coalescedCharacters[coa_char_count-1].length )
            coalescedCharacters[coa_char_count-1].length += characters[i].length - (coalescedCharacters[coa_char_count-1].start + coalescedCharacters[coa_char_count-1].length - characters[i].start);
        else
            coalescedCharacters[coa_char_count++] = characters[i];
    }
    
    /* shirnk buffer to actual size */
    self.coalescedCharacters = realloc(coalescedCharacters, sizeof(charRef)*coa_char_count);
}

@end

CGFloat XIntercept( vDSP_Length x1, double y1, vDSP_Length x2, double y2 )
{
    /*  m=(Y1-Y2)/(X1-X2) */
    double m = ((double)y1 - (double)y2)/((double)x1-(double)x2);
    /*  b = Y-mX */
    double b = (double)y1 - (m * (double)x1);
    
    return (-b)/m;
}

OSStatus EncoderDataProc(AudioConverterRef inAudioConverter, UInt32* ioNumberDataPackets, AudioBufferList* ioData, AudioStreamPacketDescription**	outDataPacketDescription, void* inUserData);

typedef struct
{
	AudioSampleType *inBuffer;
    UInt32 count;
    BOOL done;
} AudioFileIO;

void SamplesSamples_max( Float64 sampleRate, Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, NSUInteger maxOffset )
{
    if (sampleSize < 1.0)
    {
        /* resample data to fit in the view width */
        AudioConverterRef inAudioRef;
        
        AudioStreamBasicDescription inSourceFormat;
        AudioStreamBasicDescription inDestinationFormat;
        
        UInt32 ioOutputDataPacketSize = (UInt32)viewWidth;
        AudioBufferList outOutputData;
        AudioStreamPacketDescription outPacketDescription;
        
        inSourceFormat.mSampleRate = sampleRate;
        SetCanonical(&inSourceFormat, 1, false);
        
        inDestinationFormat.mSampleRate = sampleRate / sampleSize;
        SetCanonical(&inDestinationFormat, 1, false);

        OSStatus myErr = AudioConverterNew( &inSourceFormat, &inDestinationFormat, &inAudioRef );
        
        if( myErr != noErr )
            fprintf(stderr, "Error in AudioConverterNew: %d", myErr );
        
        outOutputData.mNumberBuffers = 1;
        outOutputData.mBuffers[0].mNumberChannels = 1;
        outOutputData.mBuffers[0].mDataByteSize = sizeof(Float32)*(unsigned int)viewWidth;
        outOutputData.mBuffers[0].mData = outBuffer;

        outPacketDescription.mStartOffset = 0;
        outPacketDescription.mVariableFramesInPacket = 0;
        outPacketDescription.mDataByteSize = sizeof(Float32)*(unsigned int)viewWidth;
        
        AudioFileIO afio;
        afio.inBuffer = inBuffer;
        afio.count = viewWidth / sampleSize;
        afio.done = NO;
        
        if( afio.count >= maxOffset ) afio.count = (UInt32)maxOffset;
        
        myErr = AudioConverterFillComplexBuffer( inAudioRef,
                                                EncoderDataProc,
                                                &afio,
                                                &ioOutputDataPacketSize,
                                                &outOutputData,
                                                &outPacketDescription);

        if( myErr != noErr )
            fprintf(stderr, "Error in AudioConverterFillComplexBuffer: %d", myErr );

        myErr = AudioConverterDispose( inAudioRef );

        if( myErr != noErr )
            fprintf(stderr, "Error in AudioConverterDispose: %d", myErr );
    }
    else
    {
        /* find maximum sample in each group */
        for( int i=0; i<viewWidth; i++ )
        {
            int j = i*sampleSize;
            
            if( j+sampleSize < maxOffset )
                vDSP_maxv( &(inBuffer[j]), 1, &(outBuffer[i]), sampleSize );
            else
            {
                NSLog( @"reading past array" );
                outBuffer[i] = 0;
            }
            
        }
    }
}

/* Data provider for resampling routine in SamplesSamples_max() */
OSStatus EncoderDataProc(AudioConverterRef inAudioConverter, UInt32* ioNumberDataPackets, AudioBufferList* ioData, AudioStreamPacketDescription**	outDataPacketDescription, void* inUserData)
{
	AudioFileIO* afio = (AudioFileIO*)inUserData;
    
    if( afio->done == YES )
    {
        *ioNumberDataPackets = 0;
//        ioData->mNumberBuffers = 0;
//        ioData->mBuffers[0].mData = 0;
//        ioData->mBuffers[0].mDataByteSize = 0;
//        ioData->mBuffers[0].mNumberChannels = 0;
//        if (outDataPacketDescription) *outDataPacketDescription = NULL;
    }
    else
    {   /* Provide all data in one shot */
        *ioNumberDataPackets = afio->count;
        ioData->mNumberBuffers = 1;
        ioData->mBuffers[0].mData = afio->inBuffer;
        ioData->mBuffers[0].mDataByteSize = sizeof(Float32) * (afio->count);
        ioData->mBuffers[0].mNumberChannels = 1;
        if (outDataPacketDescription) *outDataPacketDescription = NULL;
        afio->done = YES;
    }
    
    return noErr;
}

void SamplesSamples_avg( Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, NSUInteger maxOffset )
{
    int i, j;
    
    for( i=0; i<viewWidth; i++ )
    {
        AudioSampleType curValue = 0.0;
        for( j=0; j<sampleSize; j++ )
        {
            NSUInteger bufPointer = i*sampleSize+j;
            
            if( bufPointer < maxOffset )
            {
                curValue += inBuffer[bufPointer];
            }
        }
        
        outBuffer[i] = curValue/sampleSize;
    }
}

void SamplesSamples_1to1(Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, NSUInteger maxOffset )
{
    for( int i = 0; i<viewWidth; i++ )
    {
        outBuffer[i] = inBuffer[i];
    }
}
