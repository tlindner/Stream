//
//  WaveFormView.m
//  Stream
//
//  Created by tim lindner on 7/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WaveFormView.h"
#import "Accelerate/Accelerate.h"

#define MAX_CHARACTERS 1000000

void SamplesSamples_max( Float32 *outBuffer, AudioSampleType *inBuffer, NSInteger sampleSize, NSInteger viewWidth, NSUInteger maxOffset );
void SamplesSamples_avg( Float32 *outBuffer, AudioSampleType *inBuffer, NSInteger sampleSize, NSInteger viewWidth, NSUInteger maxOffset );
void SamplesSamples_1to1(Float32 *outBuffer, AudioSampleType *inBuffer, NSInteger sampleSize, NSInteger viewWidth, NSUInteger maxOffset );
CGFloat XIntercept( vDSP_Length x1, double y1, vDSP_Length x2, double y2 );

@implementation WaveFormView

@synthesize audioFrames;
@synthesize frameCount;
@synthesize sampleRate;
@synthesize characters;
@synthesize character;
@synthesize char_count;

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
    CGFloat scale;
    
    // Drawing code here.
    if( audioFrames != nil )
    {
        scale = [[self superview] bounds].size.width/[[self superview] frame].size.width;
        //NSLog( @"%f", scale );
        
        NSAffineTransform *at = [NSAffineTransform transform];
        [at scaleXBy:scale yBy:1.0f];
        [at concat];
        
        NSInteger viewheight = [self frame].size.height-25;
        
        float origin = dirtyRect.origin.x / scale;
        float width = dirtyRect.size.width / scale;

        Float32 *viewFloats = malloc(sizeof(Float32)*width);
        int offset = origin*scale;
        SamplesSamples_max(viewFloats, &(audioFrames[offset]), scale, width, frameCount-offset);
        
        
        NSRect rect;
        [[NSColor colorWithCalibratedWhite:0.95 alpha:1.0] set];
        rect = NSMakeRect(dirtyRect.origin.x/scale, dirtyRect.origin.y, dirtyRect.size.width/scale, dirtyRect.size.height);
        NSRectFill(rect);
        [[NSColor blackColor] set];
        rect = NSMakeRect(dirtyRect.origin.x/scale, (viewheight/2)+25, dirtyRect.size.width/scale, 1);
        NSRectFill(rect);
        
        int i = 0;
        while( i < char_count && characters[i].start < dirtyRect.origin.x+dirtyRect.size.width )
        {
            
            if( scale <2.7)
            {
                [[NSColor blackColor] set];
                NSString *string = [NSString stringWithFormat:@"%2.2X" , character[i]];
                NSSize charWidth = [string sizeWithAttributes:nil];
                NSPoint thePoint = NSMakePoint((characters[i].start+(charWidth.width))/scale, 15);
                [string drawAtPoint:thePoint withAttributes:nil];
                
                [[NSColor lightGrayColor] set];
                
                NSBezierPath* aPath = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect((characters[i].start+1.0)/scale, 40.0, (characters[i].length-1.0)/scale, viewheight-25.0) xRadius:5.0/scale yRadius:5.0];
                [aPath fill];
            }
            else
            {
                rect = NSMakeRect(characters[i].start/scale, 15, characters[i].length/scale, 20);
                NSRectFill(rect);
            }
            
            i++;
        }

        [[NSColor blackColor] set];
        if (scale<3)
        {
            CGFloat lastHeight = 0, thisHeight;
            for( i=0; i<width; i++ )
            {
                thisHeight = (viewheight/2)+(viewFloats[i]*(viewheight/2));
                if (thisHeight > lastHeight) {
                    rect = NSMakeRect(i+origin, lastHeight+25, 1, thisHeight - lastHeight);
                } else {
                    rect = NSMakeRect(i+origin, thisHeight+25, 1, lastHeight - thisHeight);
                }
                
                NSRectFill(rect);
                lastHeight = thisHeight;
            }
           
        }
        else
        {
             
           for( i=0; i<width; i++ )
            {
                rect = NSMakeRect(i+origin, (viewheight/2) - (viewFloats[i]*(viewheight/2))+25, 1, (viewFloats[i]*(viewheight)) );
                NSRectFill(rect);
            }
        }

        free(viewFloats);
//        [at invert];
//        [at concat];
    }
    else
    {
        [[NSColor blackColor] set];
        NSRectFill(dirtyRect);
    }
}

- (void)dealloc
{    
    if( audioFrames != nil )
        free( audioFrames );

    if( characters != nil )
        free( characters );
    
    if( character != nil )
        free( character );
    
    [super dealloc];
}

- (void) anaylizeAudioDataWithOptions:(NSDictionary *)options
{
    float lowCycle = [[options objectForKey:@"low cycle"] floatValue];
    float highCycle = [[options objectForKey:@"high cycle"] floatValue];
    vDSP_Length i;
    int zc_count;
    
    float *zero_crossings = malloc(sizeof(float)*frameCount);
    zc_count = 0;

    for( i=1; i<frameCount; i++ )
    {
        vDSP_Length crossing;
        vDSP_Length total;

        vDSP_nzcros(audioFrames+i, 1, 1, &crossing, &total, frameCount-i);
        
        if( crossing == 0 ) break;
        
        zero_crossings[zc_count++] = i+crossing-1;
        //zero_crossings[zc_count++] = XIntercept(i+crossing-2, audioFrames[i+crossing-2], i+crossing-1, audioFrames[i+crossing-1]);
   
        i += crossing-1;
    }
    
    /* Scan zero crossings for 0x553c */
    
    if( self.characters != nil )
        free(self.characters);
    
    if( self.character != nil )
        free(self.character);
    
    self.characters = malloc( sizeof(charRef)*MAX_CHARACTERS );
    self.character = malloc( sizeof(unsigned char)*MAX_CHARACTERS );
    self.char_count = 0;
    
    zc_count -= 1;
    unsigned short even_parity = 0, odd_parity = 0;
    double threashold = ((sampleRate/lowCycle) + (sampleRate/highCycle)) / 2.0, test1, test2;
    
    for (i=2; i<zc_count; i+=2)
    {
        even_parity <<= 1;
        test1 = (zero_crossings[i] - zero_crossings[i-2]);
        if( test1 < threashold )
            even_parity++;
        
        odd_parity <<= 1;
        test2 = (zero_crossings[i+1] - zero_crossings[i-1]);
        if( test2 < threashold )
            odd_parity++;

        if( (odd_parity & 0x3fff) == 0x2a3c )
        {
            even_parity = odd_parity;
            i++;
        }
        
        if( (even_parity & 0x3fff) == 0x2a3c )
        {
            characters[char_count].start = zero_crossings[i-(15*2)];
            characters[char_count].length = zero_crossings[i-(8*2)] - zero_crossings[i-(15*2)];
            character[char_count] = even_parity>>8;
            char_count++;
            
            characters[char_count].start = zero_crossings[i-(7*2)];
            characters[char_count].length = zero_crossings[i] - zero_crossings[i-(7*2)];
            character[char_count] = even_parity & 0x00ff;
            char_count++;
            
            i+=2;
            
            int bit_count = 0;
            for( ; i<zc_count; i+=2 )
            {
                even_parity <<= 1;
                test1 = (zero_crossings[i] - zero_crossings[i-2]);
                if( test1 < threashold )
                    even_parity++;
                bit_count++;
                
                if( bit_count == 7 )
                {
                    characters[char_count].start = zero_crossings[i-(7*2)];
                    characters[char_count].length = zero_crossings[i] - zero_crossings[i-(7*2)];
                    character[char_count] = even_parity & 0x00ff;
                    char_count++;
                    bit_count = 0;
                }
                
                if( test1 > threashold * 3.0 )
                    break;
            }
        }
   }
    
    //NSLog( @"characters found: %lu", char_count );
    NSAssert( char_count < MAX_CHARACTERS, @"Overflowed character buffer" );
    free(zero_crossings);
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithFloat:1094.68085106384f], @"low cycle", [NSNumber numberWithFloat:2004.54545454545f], @"high cycle", nil] autorelease];
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

void SamplesSamples_max( Float32 *outBuffer, AudioSampleType *inBuffer, NSInteger sampleSize, NSInteger viewWidth, NSUInteger maxOffset )
{
    int i, j;
    
    for( i=0; i<viewWidth; i++ )
    {
        AudioSampleType curValue = negativeInfinity;
        for( j=0; j<sampleSize; j++ )
        {
            NSUInteger bufPointer = i*sampleSize+j;
            
            if( bufPointer < maxOffset)
            {
                if( inBuffer[bufPointer] > curValue )
                {
                    curValue = inBuffer[bufPointer];
                }
            }
            else
                NSLog( @"reading past array" );
        }
        
        outBuffer[i] = curValue;
    }
}

void SamplesSamples_avg( Float32 *outBuffer, AudioSampleType *inBuffer, NSInteger sampleSize, NSInteger viewWidth, NSUInteger maxOffset )
{
    int i, j;
    
    for( i=0; i<viewWidth; i++ )
    {
        AudioSampleType curValue = 0.0;
        for( j=0; j<sampleSize; j++ )
        {
            NSUInteger bufPointer = i*sampleSize+j;
            
            if( bufPointer < maxOffset
               )
            {
                curValue += inBuffer[bufPointer];
            }
        }
        
        outBuffer[i] = curValue/sampleSize;
    }
}

void SamplesSamples_1to1(Float32 *outBuffer, AudioSampleType *inBuffer, NSInteger sampleSize, NSInteger viewWidth, NSUInteger maxOffset )
{
    for( int i = 0; i<viewWidth; i++ )
    {
        outBuffer[i] = inBuffer[i];
    }
}
