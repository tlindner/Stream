//
//  Analyzation.m
//  Stream
//
//  Created by tim lindner on 8/1/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "Analyzation.h"
#import "HexFiendAnalyzer.h"

static Analyzation *sharedSingleton;
static BOOL initialized = NO;

@implementation Analyzation

@synthesize classList;
@synthesize nameLookup;
@synthesize utiList;

+ (void)initialize
{
    if ( self == [Analyzation class] )
    {
        if(!initialized)
        {
            sharedSingleton = [[Analyzation alloc] init];
            initialized = YES;
            sharedSingleton.utiList = [NSMutableArray array];
            [sharedSingleton addAnalyzer:@"CoCoAudioAnalyzer"];
            [sharedSingleton addAnalyzer:@"BlockerDataAnalyzer"];
            [sharedSingleton addAnalyzer:@"BlockAttributeAnalyzer"];
            [sharedSingleton addAnalyzer:@"HexFiendAnalyzer"];
            [sharedSingleton addAnalyzer:@"TextAnalyzer"];
            [sharedSingleton addAnalyzer:@"DisassemblerAnalyzer"];
            [sharedSingleton addAnalyzer:@"DMKProcessSingleDensity"];
            [sharedSingleton addAnalyzer:@"CoCoDeTokenBinaryBASIC"];
            [sharedSingleton addAnalyzer:@"OS9DirectoryFile"];
            [sharedSingleton addAnalyzer:@"RawBitmapAnalyzer"];
//            [sharedSingleton addAnalyzer:@"XXX"];
//            [sharedSingleton addAnalyzer:@"XXX"];
//            [sharedSingleton addAnalyzer:@"XXX"];
//            [sharedSingleton addAnalyzer:@"XXX"];
//            [sharedSingleton addAnalyzer:@"XXX"];
//            [sharedSingleton addAnalyzer:@"XXX"];
//            [sharedSingleton addAnalyzer:@"XXX"];
//            [sharedSingleton addAnalyzer:@"XXX"];
//            [sharedSingleton addAnalyzer:@"XXX"];
//            [sharedSingleton addAnalyzer:@"XXX"];
            
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

    NSLog( @"Analyzation singleton does not exist" );
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

- (void) addAnalyzer:(NSString *)analyzer
{
    if (self.classList == nil)
    {
        self.classList = [[[NSMutableArray alloc] init] autorelease];
    }
    
    if (self.nameLookup == nil)
    {
        self.nameLookup = [[[NSMutableDictionary alloc] init] autorelease];
    }
    
    [self.classList addObject:analyzer];
    
    Class theClass = NSClassFromString(analyzer);
    [self.nameLookup setObject:theClass forKey:[theClass analyzerName]];

    /* build uti list for user interface */
    for (NSString *uti in [theClass analyzerUTIs]) {
        if (![self.utiList containsObject:uti]) {
            [self.utiList addObject:uti];
        }
    }
    
    [self.utiList sortUsingSelector:@selector(compare:)];
}

- (NSArray*)analyzersforUTI:(NSString *)inUTI
{
    NSMutableArray *resultArray = [[NSMutableArray alloc] init];
    
    for (NSString *analyzer in self.classList)
    {
        Class theClass = NSClassFromString(analyzer);
        
        if (theClass != nil)
        {
            NSArray *classUTIs = [theClass analyzerUTIs];
            
            if( (classUTIs != nil) && ([classUTIs count] > 0) )
            {
                for( NSString *aUTI in classUTIs )
                {
                    BOOL conforms;
                    conforms = UTTypeConformsTo((CFStringRef)inUTI, (CFStringRef)aUTI);
                    
                    if( conforms )
                        [resultArray addObject:[theClass analyzerName]];
                }
            }
            else
                NSLog( @"Analyzer %@ returned zero conformable UTIs", analyzer );
        }
        else
            NSLog( @"Shared Analyzer error: Can not find class %@", analyzer );
    }
    
    if( [resultArray count] == 0 )
        [resultArray addObject:[HexFiendAnalyzer analyzerName]];
    
    return [resultArray autorelease];
}

- (Class)analyzerClassforName:(NSString *)inName
{
    return [nameLookup objectForKey:inName];
}

- (void)dealloc {
    self.utiList = nil;
    self.classList = nil;
    self.nameLookup = nil;

    [super dealloc];
}
@end
