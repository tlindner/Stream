//
//  WaveFormView.m
//  Stream
//
//  Created by tim lindner on 7/31/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "WaveFormView.h"
#import "AudioAnaylizer.h"
#import "Accelerate/Accelerate.h"
#import "AudioToolbox/AudioConverter.h"

#define WFVSelection 0
#define WFVPan 1
#define WFVLupe 2

#define DOT_HANDLE_SCALE 0.5
#define DATA_SPACE 19.0

void SamplesSamples_max( Float64 sampleRate, vDSP_Stride stride, Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, NSUInteger maxOffset );
void SamplesSamples_avg( Float64 sampleRate, vDSP_Stride stride, Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, NSUInteger maxOffset );
void SamplesSamples_1to1( Float64 sampleRate, vDSP_Stride stride, Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, NSUInteger maxOffset );
void SamplesSamples_resample( Float64 sampleRate, vDSP_Stride stride, Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, NSUInteger maxOffset );
CGFloat XIntercept( vDSP_Length x1, double y1, vDSP_Length x2, double y2 );
OSStatus EncoderDataProc(AudioConverterRef inAudioConverter, UInt32* ioNumberDataPackets, AudioBufferList* ioData, AudioStreamPacketDescription**	outDataPacketDescription, void* inUserData);
double CubicHermite(double t, double p0, double p1, double m0, double m1);
double Interpolate( double timeToAccel, double timeCruising, double timeToDecel, double finalPosition, double currentTime);

typedef struct
{
	AudioSampleType *inBuffer;
    UInt32 count;
    BOOL done;
    vDSP_Stride stride;
} AudioFileIO;

@implementation WaveFormView

@synthesize audioFrames;
@synthesize frameCount;
@synthesize sampleRate;
@synthesize characters;
@synthesize character;
@synthesize char_count;
@synthesize coalescedCharacters;
@synthesize coa_char_count;
@synthesize channelCount;
@synthesize currentChannel;
@synthesize previousCurrentChannel;
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

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //NSLog( @"init Frame: %@", NSStringFromRect(frame ));
        // Initialization code here.
    }
    
    selectedSample = NSUIntegerMax;
    selectedSampleLength = 1;
    
    return self;
}

//- (void) setFrame:(NSRect)frameRect
//{
//    NSLog( @"set Frame: %@", NSStringFromRect(frameRect ));
//    [super setFrame:frameRect];
//}

- (void)drawRect:(NSRect)dirtyRect
{
    AudioAnaylizer *aa = (AudioAnaylizer *)[[[self superview] superview] superview];
    
    currentChannel = [[aa.objectValue valueForKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.audioChannel"] intValue];
    
    if( currentChannel > channelCount ) currentChannel = channelCount;
    if( currentChannel < 1 ) currentChannel = 1;
    
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
        
        NSAffineTransform *at = [NSAffineTransform transform];
        [at scaleXBy:scale yBy:1.0f];
        [at concat];
        
        CGFloat viewHeight = [self frame].size.height;
        CGFloat viewWaveHeight = viewHeight - DATA_SPACE;
        CGFloat viewWaveHalfHeight = viewWaveHeight / 2.0;
        
        float origin = dirtyRect.origin.x / scale;
        float width = dirtyRect.size.width / scale;
        
        /* Create sub-sample array */
        
        Float32 *viewFloats;
        int offset = dirtyRect.origin.x;
        if( offset < 0 ) offset = 0;
        AudioSampleType *frameStart = audioFrames + (offset * channelCount) + (currentChannel-1); // Interleaved samples
        
        if( toolMode == WFVSelection && mouseDown == YES ) goto resample;
        
        if( (previousOffset == offset) && (previousBoundsWidth == currentBoundsWidth) && (previousFrameWidth == currentFrameWidth) && (previousCurrentChannel == currentChannel) )
        {
            viewFloats = previousBuffer;
        }
        else
        {
        resample:   free( previousBuffer );
            viewFloats = malloc(sizeof(Float32)*width);
            SamplesSamples_max( sampleRate, channelCount, viewFloats, frameStart, scale, width, frameCount-offset);
            previousBuffer = viewFloats;
            previousOffset = offset;
            previousBoundsWidth = currentBoundsWidth;
            previousFrameWidth = currentFrameWidth;
            previousCurrentChannel = currentChannel;
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
            while ( i < char_count && characters[i].start < dirtyRect.origin.x) i++;
            
            if( i>0 ) i--;
            
            NSColor *lightColor = [NSColor colorWithCalibratedWhite:0.8 alpha:0.5];
            NSColor *darkColor = [NSColor colorWithCalibratedWhite:0.65 alpha:0.5];
            while( i < char_count && characters[i].start < dirtyRect.origin.x+dirtyRect.size.width )
            {
                /* Draw decoded values */
                [[NSColor blackColor] set];
                NSString *string = [NSString stringWithFormat:@"%2.2X" , character[i]];
                NSSize charWidth = [string sizeWithAttributes:nil];
                NSPoint thePoint = NSMakePoint((characters[i].start+(characters[i].length/2)-(charWidth.width/2))/scale, viewHeight-(DATA_SPACE)+1.0);
                [string drawAtPoint:thePoint withAttributes:nil];
                
                /* Draw byte grouping */
                if (i & 0x1 )
                    [lightColor set];
                else
                    [darkColor set];
                
                NSBezierPath* aPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect((characters[i].start)/scale, 0.0, ((characters[i].length)/scale), viewWaveHeight) xRadius:5.0 yRadius:5.0];
                [aPath fill];
                i++;
            }
        }
        else
        {
            /* we're zoomed too far out to see detial */
            while ( (i < coa_char_count) && (coalescedCharacters[i].start < dirtyRect.origin.x)) i++;
            
            if( i>0 ) i--;
            
            NSColor *aLightGrey = [NSColor colorWithCalibratedWhite:0.85 alpha:1.0];
            [aLightGrey set];
            
            while( (i < coa_char_count) && (coalescedCharacters[i].start < dirtyRect.origin.x+dirtyRect.size.width) )
            {
                /* Draw backound grouping */
                rect = NSMakeRect((coalescedCharacters[i].start)/scale, 0, ((coalescedCharacters[i].length)/scale), viewWaveHeight);
                NSRectFill(rect);
                
                /* Draw value bar */
                rect.origin.y = viewWaveHeight+2.0;
                rect.size.height = 13;
                NSRectFill(rect);
                i++;
            }
        }
        
        /* Draw zero line */
        [[NSColor grayColor] set];
        rect = NSMakeRect(dirtyRect.origin.x/scale, viewWaveHalfHeight, dirtyRect.size.width/scale, 1);
        NSRectFill(rect);
        
        /* Draw wave form */
        [[NSColor blackColor] set];
        
        if( scale < 3.0 )
        {
            /* Near 1:1 zoom, draw vertical lines connecting points to points */
            CGFloat lastHeight = viewWaveHalfHeight, thisHeight;
            for( i=0; i<width; i++ )
            {
                thisHeight = viewWaveHalfHeight+(viewFloats[i]*viewWaveHalfHeight);
                
                if (thisHeight > lastHeight)
                    rect = NSMakeRect(i+origin, lastHeight, 1, thisHeight - lastHeight);
                else
                    rect = NSMakeRect(i+origin, thisHeight, 1, lastHeight - thisHeight);
                
                NSRectFill(rect);
                lastHeight = thisHeight;
            }
            
            /* draw handles */
            if( scale <= DOT_HANDLE_SCALE )
            {
                CGFloat x = floor(origin);
                i = 0;
                
                while( x<(origin+width) )
                {
                    if( selectedSample == NSUIntegerMax)
                    {
                        /* no selected samples, draw all normally */
                        rect = NSMakeRect(x-1.0, (viewWaveHalfHeight+(frameStart[i]*viewWaveHalfHeight))-1.0, 3.0, 3.0);
                        NSRectFill(rect);
                    }
                    else if( offset+i >= selectedSample && offset+i < selectedSample+selectedSampleLength )
                    {
                        /* this is a selected sample, draw outline frame */
                        rect = NSMakeRect(x-2.0, (viewWaveHalfHeight+(frameStart[i]*viewWaveHalfHeight))-2.0, 4.0, 4.0);
                        [[NSBezierPath bezierPathWithRect:rect] stroke];
                    }
                    else
                    {
                        /* non selected sample, filled square */
                        rect = NSMakeRect(x-1.0, (viewWaveHalfHeight+(frameStart[i]*viewWaveHalfHeight))-1.0, 3.0, 3.0);
                        NSRectFill(rect);
                    }
                    
                    x += 1.0/scale;
                    i += channelCount;
                }
            }
        }
        else
        {
            /* Zoomed out, draw maxed values, reflected across zero */
            for( i=0; i<width; i++ )
            {
                rect = NSMakeRect(i+origin, viewWaveHalfHeight - (viewFloats[i]*viewWaveHalfHeight), 1, (viewFloats[i]*(viewWaveHeight)) );
                NSRectFill(rect);
            }
        }
        
        /* Draw lupe & selection rect */
        
        if( mouseDownOnPoint == NO )
        {
            if( (toolMode == WFVSelection || toolMode == WFVLupe) && mouseDown == YES )
            {
                NSDottedFrameRect(NSMakeRect(dragRect.origin.x/scale, dragRect.origin.y, dragRect.size.width/scale, dragRect.size.height));
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
    [self.cachedAnaylizer removeObserver:self forKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.lowCycle"];
    [self.cachedAnaylizer removeObserver:self forKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.highCycle"];
    [self.cachedAnaylizer removeObserver:self forKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.resyncThreashold"];
    [self.cachedAnaylizer removeObserver:self forKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.audioChannel"];
    
    if( panMomentumTimer != nil )
    {
        [panMomentumTimer invalidate];
        [panMomentumTimer release];
    }
    
    if( storedSamples != nil )
        free( storedSamples );
    
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
    
    id newObject;
    
    if ([keyPath isEqualToString:@"optionsDictionary.ColorComputerAudioAnaylizer.lowCycle"])
    {
        newObject = [change objectForKey:@"new"];
        if ([newObject respondsToSelector:@selector(floatValue)] && [newObject floatValue] != lowCycle)
        {
            self.needsAnaylyzation = YES;
            [self setNeedsDisplay:YES];
        }
        
        return;
    }
    
    if ([keyPath isEqualToString:@"optionsDictionary.ColorComputerAudioAnaylizer.highCycle"])
    {
        newObject = [change objectForKey:@"new"];
        if ([newObject respondsToSelector:@selector(floatValue)] && [newObject floatValue] != highCycle)
        {
            self.needsAnaylyzation = YES;
            [self setNeedsDisplay:YES];
        }
        
        return;
    }
    
    if ([keyPath isEqualToString:@"optionsDictionary.ColorComputerAudioAnaylizer.resyncThreashold"])
    {
        newObject = [change objectForKey:@"new"];
        if ([newObject respondsToSelector:@selector(floatValue)] && [newObject floatValue] != resyncThresholdHertz)
        {
            self.needsAnaylyzation = YES;
            [self setNeedsDisplay:YES];
        }
        
        return;
    }
    
    if ([keyPath isEqualToString:@"optionsDictionary.ColorComputerAudioAnaylizer.audioChannel"])
    {
        newObject = [change objectForKey:@"new"];
        if ([newObject respondsToSelector:@selector(intValue)] && [newObject intValue] != currentChannel)
        {
            self.needsAnaylyzation = YES;
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
    
    currentChannel = [[self.cachedAnaylizer valueForKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.audioChannel"] intValue];
    
    if( currentChannel > channelCount ) currentChannel = channelCount;
    if( currentChannel < 1 ) currentChannel = 1;
    
    /* setup observations */
    [self.cachedAnaylizer addObserver:self forKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.lowCycle" options:NSKeyValueChangeSetting context:nil];
    [self.cachedAnaylizer addObserver:self forKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.highCycle" options:NSKeyValueChangeSetting context:nil];
    [self.cachedAnaylizer addObserver:self forKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.resyncThreashold" options:NSKeyValueChangeSetting context:nil];
    [self.cachedAnaylizer addObserver:self forKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.audioChannel" options:NSKeyValueChangeSetting context:nil];
    
    lowCycle = [[self.cachedAnaylizer valueForKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.lowCycle"] floatValue];
    highCycle = [[self.cachedAnaylizer valueForKeyPath:@"optionsDictionary.ColorComputerAudioAnaylizer.highCycle"] floatValue];
    vDSP_Length i;
    int zc_count;
    
    AudioSampleType *frameStart = audioFrames + (currentChannel-1);
    
    unsigned long max_possible_zero_crossings = (frameCount / 2) + 1;
    float *zero_crossings = malloc(sizeof(float)*max_possible_zero_crossings);
    zc_count = 0;
    
    /* Create temporary array of zero crossing points */
    for( i=1; i<frameCount; i++ )
    {
        vDSP_Length crossing;
        vDSP_Length total;
        const vDSP_Length findOneCrossing = 1;
        
        vDSP_nzcros(frameStart+(i*channelCount), channelCount, findOneCrossing, &crossing, &total, frameCount-i);
        
        if( crossing == 0 ) break;
        
        zero_crossings[zc_count++] = i+crossing;
        //zero_crossings[zc_count++] = XIntercept(i+crossing-1, frameStart[i+crossing-1], i+crossing, frameStart[i+crossing]);
        
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

- (IBAction)chooseTool:(id)sender
{
    NSSegmentedControl *seggy = sender;
    
    toolMode = [seggy selectedSegment];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void) mouseDown:(NSEvent *)theEvent
{
    mouseDown = YES;
    mouseDownOnPoint = NO;
    locationPrevious = locationNow = locationMouseDown = [self convertPoint:[theEvent locationInWindow] fromView:[self superview]];
    startOrigin = [[self superview] bounds].origin;
    
    if( panMomentumTimer != nil )
    {
        [panMomentumTimer invalidate];
        [panMomentumTimer release];
        panMomentumTimer = nil;
    }
    
    CGFloat currentBoundsWidth = [[self superview] bounds].size.width;
    CGFloat currentFrameWidth = [[self superview] frame].size.width;
    CGFloat scale = currentBoundsWidth/currentFrameWidth;
    
    if( toolMode == WFVSelection && scale < DOT_HANDLE_SCALE )
    {
        /* Find sample under mouse click */
        NSPoint locationNowSelf = [self convertPoint:locationNow fromView:nil];
        selectedSampleUnderMouse = locationNowSelf.x;
        
        CGFloat viewHeight = [self frame].size.height;
        CGFloat viewWaveHeight = viewHeight - DATA_SPACE;
        CGFloat viewWaveHalfHeight = viewWaveHeight / 2.0;
        
        AudioSampleType *frameStart = audioFrames + (selectedSampleUnderMouse * channelCount) + (currentChannel-1); // Interleaved samples
        CGFloat thePoint = viewWaveHalfHeight+(frameStart[0]*viewWaveHalfHeight);
        NSRect sampleRect = NSMakeRect(selectedSampleUnderMouse-6.0, thePoint-6.0, 12, 12);
        
        /* Check if a sample is near the mouse down */
        if (NSPointInRect(locationNowSelf, sampleRect))
        {
            mouseDownOnPoint = YES;
            
            /* check if mouse down sample is in selection */
            if( (selectedSampleUnderMouse >= selectedSample) && (selectedSampleUnderMouse < selectedSample + selectedSampleLength) )
            {
                /* yes, mouse down in selection */
            }
            else
            {
                /* nope, select this one sample */
                selectedSample = selectedSampleUnderMouse;
                selectedSampleLength = 1;
            }
            
            /* make copy of selected samples */
            if( storedSamples != nil ) free( storedSamples );
            
            AudioSampleType *frameStart = audioFrames + (selectedSample * channelCount) + (currentChannel-1); // Interleaved samples
            storedSamples = malloc( sizeof(AudioSampleType)*selectedSampleLength );
            
            for( unsigned long i = 0; i<selectedSampleLength; i++ )
            {
                storedSamples[i] = frameStart[i*channelCount];
            }
        }
    }
    else if( toolMode == WFVSelection && scale > DOT_HANDLE_SCALE )
        mouseDown = NO; /* no selecting samples if zoomed out too far */
}

- (void) mouseDragged:(NSEvent *)theEvent
{
    locationPrevious = locationNow;
    locationNow = [self convertPoint:[theEvent locationInWindow] fromView:[self superview]];
    
    if( toolMode == WFVPan )
    {
        CGFloat currentBoundsWidth = [[self superview] bounds].size.width;
        CGFloat currentFrameWidth = [[self superview] frame].size.width;
        CGFloat scale = currentBoundsWidth/currentFrameWidth;
        
        [self scrollPoint:NSMakePoint(startOrigin.x+((locationMouseDown.x-locationNow.x)*scale), startOrigin.y)];
    }
    else if( toolMode == WFVLupe )
    {
        NSPoint locationMouseDownSelf = [self convertPoint:locationMouseDown fromView:nil];
        NSPoint locationNowSelf = [self convertPoint:locationNow fromView:nil];
        NSRect rectA = NSMakeRect(locationMouseDownSelf.x, startOrigin.y + locationMouseDownSelf.y, 1, 1);
        NSRect rectB = NSMakeRect(locationNowSelf.x, startOrigin.y + locationNowSelf.y, 1, 1);
        
        dragRect = NSUnionRect(rectA, rectB);
        
        [self setNeedsDisplay:YES];
    }
    else if( toolMode == WFVSelection )
    {
        if( mouseDownOnPoint == YES )
        {
            NSPoint locationMouseDownSelf = [self convertPoint:locationMouseDown fromView:nil];
            NSPoint locationNowSelf = [self convertPoint:locationNow fromView:nil];
            
            cancelDrag = NO;
            
            CGFloat viewHeight = [self frame].size.height;
            CGFloat viewWaveHeight = viewHeight - DATA_SPACE;
            CGFloat viewWaveHalfHeight = viewWaveHeight / 2.0;
            
            AudioSampleType *frameStart = audioFrames + (selectedSample * channelCount) + (currentChannel-1); // Interleaved samples
            
            AudioSampleType delta = (locationNowSelf.y - locationMouseDownSelf.y) / viewWaveHalfHeight;
            
            /* adjust sample up or down depending on mouse */
            for( unsigned long i=0; i<selectedSampleLength; i++ )
            {
                frameStart[i*channelCount] = storedSamples[i] + delta;
                
                /* Check for clipping, and possible canceling */
                if( frameStart[i*channelCount] > 1.5 )
                    cancelDrag = YES;
                else if( frameStart[i*channelCount] > 1.0 )
                    frameStart[i*channelCount] = 1.0;
                
                if( frameStart[i*channelCount] < -1.5 )
                    cancelDrag = YES;
                else if( frameStart[i*channelCount] < -1.0 )
                    frameStart[i*channelCount] = -1.0;
            }
            
            if( cancelDrag )
            {
                /* reset all samples */
                for( unsigned long i=0; i<selectedSampleLength; i++ )
                {
                    frameStart[i*channelCount] = storedSamples[i];
                }
            }
            
            [self setNeedsDisplay:YES];
        }
        else if( mouseDown == YES)
        {
            NSPoint locationMouseDownSelf = [self convertPoint:locationMouseDown fromView:nil];
            NSPoint locationNowSelf = [self convertPoint:locationNow fromView:nil];
            NSRect rectA = NSMakeRect(locationMouseDownSelf.x-0.5, startOrigin.y + locationMouseDownSelf.y-0.5, 1, 1);
            NSRect rectB = NSMakeRect(locationNowSelf.x-0.5, startOrigin.y + locationNowSelf.y-0.5, 1, 1);
            
            dragRect = NSUnionRect(rectA, rectB);
            
            selectedSample = ceil(dragRect.origin.x);
            selectedSampleLength = dragRect.size.width + 0.25;
            
            [self setNeedsDisplay:YES];
        }
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    NSPoint locationUp = [self convertPoint:[theEvent locationInWindow] fromView:[self superview]];
    panMomentumValue = locationPrevious.x - locationUp.x;
    
    if( (toolMode == WFVPan) && (fabs(panMomentumValue) > 10.0) )
    {
        panMomentumTimer = [[NSTimer scheduledTimerWithTimeInterval:0.030 target:self selector:@selector(mouseMomentum:) userInfo:nil repeats:YES] retain];
    }
    else if( toolMode == WFVLupe )
    {
        if( locationUp.x == locationPrevious.x ) /* no dragging, just simple click */
        {
            NSView *clipView = [self superview];
            CGFloat currentBoundsWidth = [clipView bounds].size.width;
            CGFloat currentFrameWidth = [clipView frame].size.width;
            CGFloat scale = currentBoundsWidth/currentFrameWidth;
            NSUInteger flags = [theEvent modifierFlags] & NSDeviceIndependentModifierFlagsMask;
            
            float delta;
            
            if( flags == NSAlternateKeyMask )
                delta = 1000.0*scale;
            else
                delta = -1000.0*scale;
            
            NSPoint point = [[clipView superview] convertPoint:locationUp fromView:nil];
            point.x *= scale;
            float ratio = 1.0 / (point.x / currentBoundsWidth);
            
            dragRect = [clipView bounds];
            float width = dragRect.size.width;
            float newWidth = width + delta;
            dragRect.size.width = newWidth;
            dragRect.origin.x += (width - newWidth) / ratio;
            
            NSRect currentBounds = [clipView bounds];
            double timeToAccel = ZOOM_FRAMES/3.0;
            double timeCruising = ZOOM_FRAMES/3.0;
            double timeToDecel = ZOOM_FRAMES/3.0;
            double finalPositionOrigin = dragRect.origin.x - currentBounds.origin.x;
            double finalPositionWidth = dragRect.size.width - currentBounds.size.width;
            
            for( int currentTime=0; currentTime<ZOOM_FRAMES; currentTime++ )
            {
                originFrames[currentTime] = currentBounds.origin.x + Interpolate( timeToAccel, timeCruising, timeToDecel, finalPositionOrigin, currentTime);
                sizeFrames[currentTime] = currentBounds.size.width + Interpolate( timeToAccel, timeCruising, timeToDecel, finalPositionWidth, currentTime);
            }
            
            currentFrame = 0;
            panMomentumTimer = [[NSTimer scheduledTimerWithTimeInterval:0.035 target:self selector:@selector(mouseMomentum:) userInfo:nil repeats:YES] retain];
        }
        else /* drag lupe */
        {
            NSRect currentBounds = [[self superview] bounds];
            double timeToAccel = ZOOM_FRAMES/3.0;
            double timeCruising = ZOOM_FRAMES/3.0;
            double timeToDecel = ZOOM_FRAMES/3.0;
            double finalPositionOrigin = dragRect.origin.x - currentBounds.origin.x;
            double finalPositionWidth = dragRect.size.width - currentBounds.size.width;
            
            for( int currentTime=0; currentTime<ZOOM_FRAMES; currentTime++ )
            {
                originFrames[currentTime] = currentBounds.origin.x + Interpolate( timeToAccel, timeCruising, timeToDecel, finalPositionOrigin, currentTime);
                sizeFrames[currentTime] = currentBounds.size.width + Interpolate( timeToAccel, timeCruising, timeToDecel, finalPositionWidth, currentTime);
            }
            
            currentFrame = 0;
            panMomentumTimer = [[NSTimer scheduledTimerWithTimeInterval:0.035 target:self selector:@selector(mouseMomentum:) userInfo:nil repeats:YES] retain];
        }
    }
    else if( toolMode == WFVSelection && mouseDownOnPoint == NO )
    {
        if( locationUp.x == locationPrevious.x ) /* no dragging, just simple click */
        {
            selectedSample = NSUIntegerMax;
            selectedSampleLength = 1;
        }
        
        [self setNeedsDisplay:YES];
    }
    else if( toolMode == WFVSelection && mouseDownOnPoint == YES )
    {   
        if( cancelDrag == NO )
        {
            NSManagedObjectContext *parentContext = [(NSPersistentDocument *)[[[self window] windowController] document] managedObjectContext];
            NSData *previousSamples = [NSData dataWithBytes:storedSamples length:sizeof(AudioSampleType)*selectedSampleLength];
            NSDictionary *previousState = [NSDictionary dictionaryWithObjectsAndKeys:previousSamples, @"data", [NSNumber numberWithUnsignedInteger:selectedSample], @"selectedSample", [NSNumber numberWithUnsignedInteger:selectedSampleLength], @"selectedSampleLength", [NSNumber numberWithUnsignedInteger:currentChannel], @"currentChannel", nil];
            
            [[parentContext undoManager] registerUndoWithTarget:self selector:@selector(setPreviousState:) object:previousState];
            
            if( selectedSampleLength == 1 )
                [[parentContext undoManager] setActionName:@"Move Sample"];
            else
                [[parentContext undoManager] setActionName:@"Move Samples"];
            
            needsAnaylyzation = YES;
            [self setNeedsDisplay:YES];
        }
    }
    
    mouseDown = NO;
}

- (void)mouseMomentum:(NSTimer*)theTimer
{
    if( toolMode == WFVPan )
    {
        startOrigin = [[self superview] bounds].origin;
        CGFloat currentBoundsWidth = [[self superview] bounds].size.width;
        CGFloat currentFrameWidth = [[self superview] frame].size.width;
        CGFloat scale = currentBoundsWidth/currentFrameWidth;
        [self scrollPoint:NSMakePoint(startOrigin.x+(panMomentumValue*scale), startOrigin.y)];
        
        panMomentumValue /= 1.1;
        
        if (fabs(panMomentumValue) < 2.0)
        {
            panMomentumValue = 0;
            [theTimer invalidate];
        }
    }
    else if( toolMode == WFVLupe )
    {
        AudioAnaylizer *aa = (AudioAnaylizer *)[[[self superview] superview] superview];
        NSRect currentBounds = [[self superview] bounds];
        
        if (currentFrame == ZOOM_FRAMES)
        {
            [theTimer invalidate];
            return;
        }
        
        currentBounds.origin.x = originFrames[currentFrame];
        currentBounds.size.width = sizeFrames[currentFrame];
        [aa updateBounds:currentBounds];
        
        currentFrame++;
    }
}

- (void) setPreviousState:(NSDictionary *)previousState
{
    AudioSampleType *previousSamples = (AudioSampleType *)[[previousState objectForKey:@"data"] bytes];
    NSUInteger storedSelectedSample = [[previousState objectForKey:@"selectedSample"] unsignedIntegerValue];
    NSUInteger storedSelectedSampleLength = [[previousState objectForKey:@"selectedSampleLength"] unsignedIntegerValue];
    NSUInteger storedCurrentChannel = [[previousState objectForKey:@"currentChannel"] unsignedIntegerValue];
    
    AudioSampleType *frameStart = audioFrames + (storedSelectedSample * channelCount) + (storedCurrentChannel-1); // Interleaved samples
    
    for( unsigned long i = 0; i < storedSelectedSampleLength; i++ )
    {
        frameStart[i*channelCount] = previousSamples[i];
    }
    
    previousOffset = !previousOffset; /* force resample */
    needsAnaylyzation = YES;
    [self setNeedsDisplay:YES];
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

void SamplesSamples_max( Float64 sampleRate, vDSP_Stride stride, Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, NSUInteger maxOffset )
{
    if (sampleSize < 1.0)
    {
        SamplesSamples_resample( sampleRate, stride, outBuffer, inBuffer, sampleSize, viewWidth, maxOffset );
    }
    else if (sampleSize == 1.0 )
    {
        SamplesSamples_1to1( sampleRate, stride, outBuffer, inBuffer, sampleSize, viewWidth, maxOffset );
    }
    else
    {
        /* find maximum sample in each group */
        for( int i=0; i<viewWidth; i++ )
        {
            int j = (i*stride)*sampleSize;
            j += (j % stride);
            
            if( j+(sampleSize*stride) < (maxOffset*stride) )
                vDSP_maxv( &(inBuffer[j]), stride, &(outBuffer[i]), sampleSize );
            else
            {
                NSLog( @"reading past array" );
                outBuffer[i] = 0;
            }
        }
    }
}

void SamplesSamples_avg( Float64 sampleRate, vDSP_Stride stride, Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, NSUInteger maxOffset )
{
    if (sampleSize < 1.0)
    {
        SamplesSamples_resample( sampleRate, stride, outBuffer, inBuffer, sampleSize, viewWidth, maxOffset );
    }
    else if (sampleSize == 1.0 )
    {
        SamplesSamples_1to1( sampleRate, stride, outBuffer, inBuffer, sampleSize, viewWidth, maxOffset );
    }
    else
    {
        /* find average sample in each group */
        for( int i=0, j; i<viewWidth; i++ )
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
        
        // Should move to this: Vector mean magnitude; single precision.
        // vDSP_meamgv( float * __vDSP_A, vDSP_Stride __vDSP_I float * __vDSP_C, vDSP_Length __vDSP_N);
    }
}

void SamplesSamples_resample( Float64 sampleRate, vDSP_Stride stride, Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, NSUInteger maxOffset )
{
    /* De-stride input */
    
    vDSP_Length inputLength = viewWidth / sampleSize;
    AudioSampleType *destrideBuffer = malloc(sizeof(AudioSampleType)*inputLength);
    
    for( int i=0; i<inputLength; i++ )
    {
        destrideBuffer[i] = inBuffer[i*stride];
    }
    
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
    afio.inBuffer = destrideBuffer;
    afio.count = (UInt32)inputLength;
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
    
    free( destrideBuffer );    
}

/* Data provider for resampling routine in SamplesSamples_resample() */
OSStatus EncoderDataProc(AudioConverterRef inAudioConverter, UInt32* ioNumberDataPackets, AudioBufferList* ioData, AudioStreamPacketDescription**	outDataPacketDescription, void* inUserData)
{
	AudioFileIO* afio = (AudioFileIO*)inUserData;
    
    if( afio->done == YES )
    {
        *ioNumberDataPackets = 0;
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

void SamplesSamples_1to1( Float64 sampleRate, vDSP_Stride stride, Float32 *outBuffer, AudioSampleType *inBuffer, double sampleSize, NSInteger viewWidth, NSUInteger maxOffset )
{
    for( int i = 0; i<viewWidth; i++ )
    {
        outBuffer[i] = inBuffer[i*stride];
    }
}

/* Credit to Roman Zenka, Stackover question #3367308 */
double CubicHermite(double t, double p0, double p1, double m0, double m1)
{
    double t2 = t*t;
    double t3 = t2*t;
    return (2.0*t3 - 3.0*t2 + 1.0)*p0 + (t3-2.0*t2+t)*m0 + (-2.0*t3+3.0*t2)*p1 + (t3-t2)*m1;
}

double Interpolate( double timeToAccel, double timeCruising, double timeToDecel, double finalPosition, double currentTime)
{    
    double t1 = timeToAccel;
    double t2 = timeCruising;
    double t3 = timeToDecel;
    double x = finalPosition;
    double t = currentTime;
    
    double v = x / (t1/2.0 + t2 + t3/2.0);
    double x1 = v * t1 / 2.0;
    double x2 = v * t2;
    //    double x3 = v * t3 / 2.0;
    
    if(t <= t1)
    {
        // Acceleration
        return CubicHermite(t/t1, 0.0, x1, 0.0, x2/t2*t1);
    }
    else if(t <= t1+t2)
    {
        // Cruising
        return x1 + x2 * (t-t1) / t2;
    }
    else
    {
        // Deceleration
        return CubicHermite((t-t1-t2)/t3, x1+x2, x, x2/t2*t3, 0.0);
    }
}







