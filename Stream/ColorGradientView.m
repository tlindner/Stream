//
//  MyClass.m
//  Stream
//
//  Created by tim lindner on 7/28/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ColorGradientView.h"
#import "Analyzation.h"

@implementation ColorGradientView

// Automatically create accessor methods
@synthesize startingColor;
@synthesize endingColor;
@synthesize angle;
@synthesize newConstraints;
@synthesize actionPopOverNib;
@synthesize popupArrayController;
@synthesize subMOC;
@synthesize subObjectValue;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        [self setStartingColor:[NSColor colorWithCalibratedWhite:1.0 alpha:1.0]];
        [self setEndingColor:nil];
        [self setAngle:270];
    }
    
    return self;
}

- (void)awakeFromNib
{
    [self setStartingColor:[NSColor colorWithCalibratedRed:0.92f green:0.93f blue:0.98f alpha:1.0f]];
    [self setEndingColor:[NSColor colorWithCalibratedRed:0.74f green:0.76f blue:0.83f alpha:1.0f]];
    [self setAngle:270];
    
    [self updateConstraints];
    [super awakeFromNib];
}


- (void)updateConstraints {
    if( newConstraints == nil )
    {
        self.newConstraints = [[[NSMutableArray alloc] init] autorelease];
        NSDictionary *views = NSDictionaryOfVariableBindings(tlDisclosure, tlTitle, tlAction);
        [newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-3-[tlDisclosure]-0-[tlTitle]-0-[tlAction(==25)]-3-|" options:0 metrics:nil views:views]];
        [newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[tlDisclosure]-0-|" options:0 metrics:nil views:views]];
        [newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[tlTitle]-0-|" options:0 metrics:nil views:views]];
        [newConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[tlAction]-0-|" options:0 metrics:nil views:views]];
        [self removeConstraints:[self constraints]];
        [self addConstraints:newConstraints];
    }
    
    [super updateConstraints];
}

- (BOOL)isOpaque
{
    return true;
}

- (void)drawRect:(NSRect)rect {
    if (endingColor == nil || [startingColor isEqual:endingColor]) {
        // Fill view with a standard background color
        [startingColor set];
        NSRectFill(rect);
    }
    else {
        // Fill view with a top-down gradient
        // from startingColor to endingColor
        NSGradient* aGradient = [[[NSGradient alloc]
                                 initWithStartingColor:startingColor
                                 endingColor:endingColor] autorelease];
        [aGradient drawInRect:[self bounds] angle:angle];
    }
}

- (IBAction)doPopOver:(id)sender
{
    if( self.subMOC == nil )
    {
        self.subMOC = [[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType] autorelease];
        
        //NSLog( @"?: %lu", [[(NSPersistentDocument *)[[[self window] windowController] document] managedObjectContext] concurrencyType]);
              
        [subMOC setParentContext:[(NSPersistentDocument *)[[[self window] windowController] document] managedObjectContext]];
    }
    
    if( self.subObjectValue != nil )
    {
        [utiTextField unbind:@"value"];
        [editorPopup unbind:@"contentObjects"];
        [editorPopup unbind:@"selectedObject"];
    }
    
    NSManagedObjectID *objectValueID = [[[self superview] valueForKey:@"objectValue"] objectID];
    NSError *err;
    self.subObjectValue = [subMOC existingObjectWithID:objectValueID error:&err];

    if( self.actionPopOverNib == nil )
    {
        self.actionPopOverNib = [[[NSNib alloc] initWithNibNamed:@"AnaylizerSettingPopover" bundle:nil] autorelease];
        
        if (![self.actionPopOverNib instantiateNibWithOwner:self topLevelObjects:nil])
        {
            NSLog(@"Warning! Could not load nib file.\n");
        }

        self.popupArrayController = [[[NSArrayController alloc] init] autorelease];
        NSArray *stuff = [[Analyzation sharedInstance] anaylizersforUTI:[self.subObjectValue valueForKeyPath:@"parentStream.sourceUTI"]];
        [self.popupArrayController addObjects:stuff];
    }
    
    [utiTextField bind:@"value" toObject:self.subObjectValue withKeyPath:@"parentStream.sourceUTI" options:nil];
    
    [editorPopup bind:@"content" toObject:self.popupArrayController withKeyPath:@"arrangedObjects" options:nil];
    [editorPopup bind:@"selectedObject" toObject:self.subObjectValue withKeyPath:@"currentEditorView" options:nil];
    
    [actionPopOver showRelativeToRect:[tlAction bounds] ofView:tlAction preferredEdge:NSMaxYEdge];
}

- (IBAction)popOverOK:(id)sender
{
    NSError *err;
    
    [subMOC save:&err];
    [actionPopOver performClose:self];
}

- (IBAction)popOverCancel:(id)sender
{
    [actionPopOver performClose:self];
}

- (void)dealloc {
    
    if (utiTextField) {
        [utiTextField unbind:@"value"];
    }
    
    if (editorPopup) {
        [editorPopup unbind:@"contentObjects"];
        [editorPopup unbind:@"selectedObject"];
    }
    
    self.subObjectValue = nil;
    self.subMOC = nil;
    self.popupArrayController = nil;
    self.newConstraints = nil;
    self.actionPopOverNib = nil;
    [super dealloc];
}
@end