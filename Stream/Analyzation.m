//
//  Analyzation.m
//  Stream
//
//  Created by tim lindner on 8/1/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "Analyzation.h"
#import "HexFiendAnaylizer.h"

static Analyzation *sharedSingleton;
static BOOL initialized = NO;

@implementation Analyzation

@synthesize classList;
@synthesize nameLookup;

+ (void)initialize
{
    if ( self == [Analyzation class] )
    {
        if(!initialized)
        {
            sharedSingleton = [[Analyzation alloc] init];
            initialized = YES;
            [sharedSingleton addAnalyzer:@"CoCoAudioAnaylizer"];
            [sharedSingleton addAnalyzer:@"BlockerDataAnaylizer"];
            [sharedSingleton addAnalyzer:@"BlockAttributeAnaylizer"];
            [sharedSingleton addAnalyzer:@"HexFiendAnaylizer"];
            [sharedSingleton addAnalyzer:@"TextAnaylizer"];
            [sharedSingleton addAnalyzer:@"DisasemblerAnaylizer"];
        }
    }
}

+ (Analyzation *)sharedInstance
{
    if (initialized) {
        if (sharedSingleton != nil) {
            return sharedSingleton;
        }
    }

    NSLog( @"Anaylization singleton does not exist" );
    return nil;
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
    
    if (self.nameLookup == nil)
    {
        self.nameLookup = [[[NSMutableDictionary alloc] init] autorelease];
    }
    
    [self.classList addObject:anaylizer];
    
    Class theClass = NSClassFromString(anaylizer);
    [self.nameLookup setObject:theClass forKey:[theClass anayliserName]];

}

- (NSArray*)anaylizersforUTI:(NSString *)inUTI
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
                    BOOL conforms;
                    conforms = UTTypeConformsTo((CFStringRef)inUTI, (CFStringRef)aUTI);
                    
                    if( conforms )
                        [resultArray addObject:[theClass anayliserName]];
                }
            }
            else
                NSLog( @"Anaylizer %@ returned zero conformable UTIs", anaylizer );
        }
        else
            NSLog( @"Shared Anaylizer error: Can not find class %@", anaylizer );
    }
    
    if( [resultArray count] == 0 )
        [resultArray addObject:[HexFiendAnaylizer anayliserName]];
    
    return [resultArray autorelease];
}

- (Class)anaylizerClassforName:(NSString *)inName
{
    return [nameLookup objectForKey:inName];
}

- (void)dealloc {
    self.classList = nil;
    self.nameLookup = nil;

    [super dealloc];
}
@end
