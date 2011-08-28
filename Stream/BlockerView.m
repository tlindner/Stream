//
//  BlockerView.m
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockerView.h"
#import "Analyzation.h"
#import "AppDelegate.h"

@implementation BlockerView
@synthesize dataViewController;
@synthesize treeController;
@synthesize baseView;
@synthesize objectValue;
@dynamic managedObjectContext;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setAutoresizesSubviews:YES];
        [self setAutoresizingMask:(NSViewWidthSizable|NSViewHeightSizable)];

        [NSBundle loadNibNamed:@"BlockerView" owner:self];
        [baseView setFrame:NSMakeRect(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:baseView];        
    }
    
    return self;
}

- (void)dealloc
{
    [baseView removeFromSuperview];
    self.baseView = nil;
    self.treeController = nil;
    
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
}

- (void)setRepresentedObject:(id)representedObject
{
    self.objectValue = representedObject;

    if( [[self.objectValue valueForKey:@"initializedOD"] boolValue] == YES )
    {
    }
    else
    {
        Class <BlockerProtocol> class = NSClassFromString([self.objectValue valueForKey:@"anaylizerKind"]);
        
        if (class != nil )
        {
            [class makeBlocks:self.objectValue.parentStream];

            [self.objectValue setValue:[NSNumber numberWithBool:YES] forKey:@"initializedOD"];

            NSSortDescriptor *nameDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedStandardCompare:)];
            NSArray *sortDescriptors = [NSArray arrayWithObject:nameDescriptor];
            [treeController setSortDescriptors:(NSArray *)sortDescriptors];
            [treeController prepareContent];
            [dataViewController startObserving];
        }
        else
            NSLog( @"Could not create class: %@", [self.objectValue valueForKey:@"anaylizerKind"] );

    }
}

- (NSManagedObjectContext *)managedObjectContext
{
    NSManagedObjectContext *result = [(NSPersistentDocument *)[[[self window] windowController] document] managedObjectContext];
    return result;
}

//- (void)viewDidMoveToWindow
//{
//    NSSortDescriptor *nameDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedStandardCompare:)];
//    NSArray *sortDescriptors = [NSArray arrayWithObject:nameDescriptor];
//    [treeController setSortDescriptors:(NSArray *)sortDescriptors];
//    [treeController prepareContent];
//}

+ (NSArray *)anaylizerUTIs
{
    return [NSArray arrayWithObject:@"public.data"];
}

+ (NSString *)anayliserName
{
    return @"Blocker View";
}

/* Used for KVC and KVO in anaylizer options dictionary */
+ (NSString *)anaylizerKey;
{
    return @"BlockerView";
}

+ (NSString *)AnaylizerPopoverAccessoryViewNib
{
    return @"BlockerViewAccessory";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] init] autorelease];
}

@end
