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
        NSInteger viewheight = [self frame].size.height - 32.0f;
        
        float origin = dirtyRect.origin.x;
        float width = dirtyRect.size.width;
        
        Float32 *viewFloats = malloc(sizeof(Float32)*width);
        int offset = origin*scale;
        SamplesSamples( viewFloats, &(audioFrames[offset]), scale, width, frameCount );
        
        
        [[NSColor colorWithCalibratedWhite:0.95 alpha:1.0] set];
        NSRectFill(dirtyRect);
        NSRect rect;
        [[NSColor blackColor] set];
        rect = NSMakeRect(dirtyRect.origin.x, 32+(viewheight/2), dirtyRect.size.width, 1);
        NSRectFill(rect);
        
        int i;
        for( i=0; i<width; i++ )
        {
            rect = NSMakeRect(i+origin, 32+(viewFloats[i]*viewheight), 1, 1);
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
        }
        
        outBuffer[i] = (curValue-128)/128.0;
    }
}
