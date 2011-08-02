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
    [self setStartingColor:[NSColor colorWithCalibratedWhite:0.85 alpha:1.0]];
    [self setEndingColor:[NSColor colorWithCalibratedWhite:0.75 alpha:1.0]];
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
    if( self.actionPopOverNib == nil )
    {
        self.actionPopOverNib = [[[NSNib alloc] initWithNibNamed:@"AnaylizerSettingPopover" bundle:nil] autorelease];

        if (![self.actionPopOverNib instantiateNibWithOwner:self topLevelObjects:nil])
        {
            NSLog(@"Warning! Could not load nib file.\n");
        }

        [utiTextField bind:@"value" toObject:[self superview] withKeyPath:@"objectValue.parentStream.sourceUTI" options:nil];
        
        NSArrayController *EditorsPopupController = [[NSArrayController alloc] init];
        NSArray *stuff = [[Analyzation sharedInstance] anaylizersforUTI:[[self superview] valueForKeyPath:@"objectValue.parentStream.sourceUTI"]];
        [EditorsPopupController addObjects:stuff];
        
        [editorPopup bind:@"content" toObject:EditorsPopupController withKeyPath:@"arrangedObjects" options:nil];
        [editorPopup bind:@"selectedObject" toObject:[self superview] withKeyPath:@"objectValue.currentEditorView" options:nil];
        
    }

    [actionPopOver showRelativeToRect:[tlAction bounds] ofView:tlAction preferredEdge:NSMaxYEdge];
}


- (void)dealloc {
    
    if (utiTextField) {
        [utiTextField unbind:@"value"];
    }
    
    if (editorPopup) {
        [editorPopup unbind:@"contentObjects"];
        [editorPopup unbind:@"selectedObject"];
    }
    
    self.newConstraints = nil;
    self.actionPopOverNib = nil;
    [super dealloc];
}
@end