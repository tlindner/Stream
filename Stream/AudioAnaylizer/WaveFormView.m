//
//  WaveFormView.m
//  Stream
//
//  Created by tim lindner on 7/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "WaveFormView.h"

void SamplesSamples_max( Float32 *outBuffer, AudioSampleType *inBuffer, NSInteger sampleSize, NSInteger viewWidth, NSUInteger maxOffset );
void SamplesSamples_avg( Float32 *outBuffer, AudioSampleType *inBuffer, NSInteger sampleSize, NSInteger viewWidth, NSUInteger maxOffset );
void SamplesSamples_1to1(Float32 *outBuffer, AudioSampleType *inBuffer, NSInteger sampleSize, NSInteger viewWidth, NSUInteger maxOffset );

@implementation WaveFormView

@synthesize audioFrames;
@synthesize frameCount;
@synthesize sampleRate;

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

        NSAffineTransform *at = [NSAffineTransform transform];
        [at scaleXBy:scale yBy:1.0f];
        [at concat];
        
        NSInteger viewheight = [self frame].size.height;
        
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
        rect = NSMakeRect(dirtyRect.origin.x/scale, (viewheight/2), dirtyRect.size.width/scale, 1);
        NSRectFill(rect);
        
        if (scale<3)
        {
            CGFloat lastHeight = 0, thisHeight;
            for( int i=0; i<width; i++ )
            {
                thisHeight = (viewheight/2)+(viewFloats[i]*(viewheight/2));
                if (thisHeight > lastHeight) {
                    rect = NSMakeRect(i+origin, lastHeight, 1, thisHeight - lastHeight);
                } else {
                    rect = NSMakeRect(i+origin, thisHeight, 1, lastHeight - thisHeight);
                }
                
                NSRectFill(rect);
                lastHeight = thisHeight;
            }
        }
        else
        {
            for( int i=0; i<width; i++ )
            {
                rect = NSMakeRect(i+origin, (viewheight/2) - (viewFloats[i]*(viewheight/2)), 1, (viewFloats[i]*(viewheight)) );
                NSRectFill(rect);
            }
        }

        free(viewFloats);
        [at invert];
        [at concat];
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
