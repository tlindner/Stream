//
//  WaveFormView.m
//  Stream
//
//  Created by tim lindner on 7/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WaveFormView.h"

void SamplesSamples( Float32 *outBuffer, uint8 *inBuffer, NSInteger sampleSize, NSInteger viewWidth, NSUInteger maxBuf );

@implementation WaveFormView

@synthesize audioFrames;
@synthesize frameCount;
@synthesize scale;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    if( audioFrames != nil )
    {
 //       NSInteger viewWidth = [self frame].size.width;
        
        float origin = dirtyRect.origin.x;
        float width = dirtyRect.size.width;
        
        Float32 *viewFloats = malloc(sizeof(Float32)*width);
        int offset = origin*scale;
        SamplesSamples( viewFloats, &(audioFrames[offset]), scale, width, frameCount );
        
        [[NSColor whiteColor] set];
        NSRectFill(dirtyRect);
        
        [[NSColor blackColor] set];
        
        int i;
        NSRect rect;
        for( i=0; i<width; i++ )
        {
            rect = NSMakeRect(i+origin, 32+(viewFloats[i]*120), 1, 3);
            NSRectFill(rect);
        }
        
        free(viewFloats);
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

    [super dealloc];
}

@end

void SamplesSamples( Float32 *outBuffer, uint8 *inBuffer, NSInteger sampleSize, NSInteger viewWidth, NSUInteger maxBuf )
{
    int i, j;
    
    for( i=0; i<viewWidth; i++ )
    {
        uint8 curValue = 0;
        for( j=0; j<sampleSize; j++ )
        {
            NSUInteger bufPointer = i*sampleSize+j;
            
            if( bufPointer < maxBuf )
            {
                if( inBuffer[bufPointer] > curValue )
                    curValue = inBuffer[bufPointer];
            }
            else
                curValue = 0;
        }
        
        outBuffer[i] = curValue/256.0f;
    }
}
