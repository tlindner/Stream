//
//  Analyzation.m
//  Stream
//
//  Created by tim lindner on 8/1/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Analyzation.h"
#import "WaveFormView.h"
#import "HFTextView.h"

static Analyzation *sharedSingleton;

@implementation Analyzation

@synthesize classList;

+ (void)initialize
{
    static BOOL initialized = NO;
    if(!initialized)
    {
        initialized = YES;
        sharedSingleton = [[Analyzation alloc] init];
        [sharedSingleton addAnalyzer:@"WaveFormView"];
        [sharedSingleton addAnalyzer:@"HFTextView"];
        [sharedSingleton addAnalyzer:@"NSTextView"];
    }
}

+ (Analyzation *)sharedInstance
{
    return sharedSingleton;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void) addAnalyzer:(NSString *)anaylizer
{
    if (self.classList == nil)
    {
        self.classList = [[[NSMutableArray alloc] init] autorelease];
    }
    
    [self.classList addObject:anaylizer];
}

- (NSArray *)anaylizersforUTI:(NSString *)inUTI
{
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    
    for (NSString *anaylizer in self.classList)
    {
        Class theClass = NSClassFromString(anaylizer);
        
        if (theClass != nil)
        {
            NSArray *classUTIs = [theClass anaylizerUTIs];
            
            if( (classUTIs != nil) && ([classUTIs count] > 0) )
            {
                for( NSString *aUTI in classUTIs )
                {
                    Boolean conforms;
                    conforms = UTTypeConformsTo((CFStringRef)aUTI, (CFStringRef)inUTI );
                    
                    if( conforms )
                        [resultArray addObject:anaylizer];
                }
            }
            else
                NSLog( @"Anaylizer %@ returned zero conformable UTIs", anaylizer );
        }
        else
            NSLog( @"Shared Anaylizer error: Can not find class %@", anaylizer );
    }
    return [resultArray autorelease];
              
}

@end
