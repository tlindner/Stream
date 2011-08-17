//
//  MyClass.m
//  Stream
//
//  Created by tim lindner on 7/28/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "ColorGradientView.h"
#import "Analyzation.h"
#import "StAnaylizer.h"

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
@synthesize avc;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        self.startingColor = [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
        self.endingColor = nil;
        [self setAngle:270];
    }
    
    return self;
}

- (void)awakeFromNib
{
    self.startingColor = [NSColor colorWithCalibratedRed:0.92f green:0.93f blue:0.98f alpha:1.0f];
    self.endingColor = [NSColor colorWithCalibratedRed:0.74f green:0.76f blue:0.83f alpha:1.0f];
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
    NSError *err;
    NSManagedObjectContext *parentContext = [(NSPersistentDocument *)[[[self window] windowController] document] managedObjectContext];;
    
    if( self.subMOC == nil )
    {
        self.subMOC = [[[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType] autorelease];
        [subMOC setParentContext:parentContext];
    }

    err = nil;

    if( [parentContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:[[self superview] valueForKey:@"objectValue"]] error:&err] == NO )
    {
        NSLog( @"obtainPermanentIDsForObjects Error: %@", err );
    }

    NSManagedObjectID *objectValueID = [[[self superview] valueForKey:@"objectValue"] objectID];
    

    self.subObjectValue = [subMOC existingObjectWithID:objectValueID error:&err];
    
    if( err != nil )
    {
        /* lets do this the hard way */
        NSLog( @"Doing it the hard way" );
        NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"StAnaylizer" inManagedObjectContext:subMOC];
        [request setEntity:entity];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self == %@", [[self superview] valueForKey:@"objectValue"]];
        [request setPredicate:predicate];
        
        err = nil;
        NSArray *array = [subMOC executeFetchRequest:request error:&err];
        if (array != nil && [array count] > 0)
        {
            self.subObjectValue = [array objectAtIndex:0];
        }
        else
        {
            NSLog( @"Could not get child managed object copy: %@", err );
            return;
        }
    }
    
    if( self.subObjectValue == [[self superview] valueForKey:@"objectValue"] )
    {
        NSLog(@"Tried to create editable child object, but they are the same object.");
    }
    
    if( self.actionPopOverNib == nil )
    {
        self.actionPopOverNib = [[[NSNib alloc] initWithNibNamed:@"AnaylizerSettingPopover" bundle:nil] autorelease];
        
        if (![self.actionPopOverNib instantiateNibWithOwner:self topLevelObjects:nil])
        {
            NSLog(@"Warning! Could not load nib file.\n");
            return;
        }

        self.popupArrayController = [[[NSArrayController alloc] init] autorelease];
        NSArray *stuff = [[Analyzation sharedInstance] anaylizersforUTI:[self.subObjectValue valueForKeyPath:@"parentStream.sourceUTI"]];
        [self.popupArrayController addObjects:stuff];
    }
    
    [utiTextField bind:@"value" toObject:self.subObjectValue withKeyPath:@"parentStream.sourceUTI" options:nil];
    [editorPopup bind:@"content" toObject:self.popupArrayController withKeyPath:@"arrangedObjects" options:nil];
    [editorPopup bind:@"selectedObject" toObject:self.subObjectValue withKeyPath:@"currentEditorView" options:nil];

    [self.subObjectValue addObserver:self forKeyPath:@"currentEditorView" options:NSKeyValueChangeSetting context:nil];
    [self.subObjectValue addObserver:self forKeyPath:@"parentStream.sourceUTI" options:NSKeyValueChangeSetting context:nil];
    
    /* Editview changed, update UI */
    for (NSView *aSubView in [accessoryView subviews])
    {
        [aSubView removeFromSuperview];
    }
    
    /* ask current anaylization the name of it accessory nib */
    Class anaClass = [[Analyzation sharedInstance] anaylizerClassforName:[editorPopup titleOfSelectedItem]];
    NSAssert(anaClass != nil, @"Do Popover: Returned class is nil");
    [[[self superview] valueForKey:@"objectValue"] addSubOptionsDictionary:[anaClass anaylizerKey]  withDictionary:[anaClass defaultOptions]];
    
    NSString *nibName = [anaClass AnaylizerPopoverAccessoryViewNib];
    
    NSRect accessoryFrame = [accessoryView frame];
    CGFloat currentAVHeight = accessoryFrame.size.height;
    CGFloat newSubViewHeight;
    
    if( nibName != nil && ![nibName isEqualToString:@""] )
    {
        if( self.avc != nil )
            [self.avc setRepresentedObject:nil];
        
        self.avc = [[[AnaylizerSettingPopOverAccessoryViewController alloc] initWithNibName:nibName bundle:nil] autorelease];
        //[self.avc setRepresentedObject:[[self superview] valueForKey:@"objectValue"]];
        [self.avc setRepresentedObject:self.subObjectValue];
        
        [self.avc loadView];
        
        newSubViewHeight = [[self.avc view] frame].size.height;
        accessoryFrame.size = [[self.avc view] frame].size;
        [accessoryView setFrame:accessoryFrame];
        [accessoryView addSubview:[self.avc view]];
    }
    else
    {
        accessoryFrame.size.height = 0;
        [accessoryView setFrame:accessoryFrame];
        newSubViewHeight = 0;
    }
    
    NSView *editorView = [[self superview] valueForKey:@"editorSubView"];
    if( [editorView isKindOfClass:anaClass] )
    {
        if( [editorView respondsToSelector:@selector(prepareAccessoryView:)] )
            [editorView prepareAccessoryView:[self.avc view]];
    }
    
    [actionPopOver showRelativeToRect:[tlAction bounds] ofView:tlAction preferredEdge:NSMaxYEdge];
    NSSize contentsize = [actionPopOver contentSize];
    contentsize.height += newSubViewHeight - currentAVHeight;
    [actionPopOver setContentSize:contentsize];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //NSLog( @"Observied: kp: %@, object: %@, change: %@", keyPath, object, change );
    if( [keyPath isEqualToString:@"currentEditorView"] )
    {
        /* Editview changed, update UI */
        for (NSView *aSubView in [accessoryView subviews])
        {
            [aSubView removeFromSuperview];
        }
        
        /* ask current anaylization the name of it accessory nib */
        Class anaClass = [[Analyzation sharedInstance] anaylizerClassforName:[editorPopup titleOfSelectedItem]];
        NSAssert(anaClass != nil, @"Do Popover: Returned class is nil");
        [[[self superview] valueForKey:@"objectValue"] addSubOptionsDictionary:[anaClass anaylizerKey]  withDictionary:[anaClass defaultOptions]];
        NSString *nibName = [anaClass AnaylizerPopoverAccessoryViewNib];
        
        /* record some geometry */
        NSRect accessoryFrame = [accessoryView frame];
        CGFloat currentAVHeight = accessoryFrame.size.height;
        CGFloat newSubViewHeight;
        
        if( nibName != nil && ![nibName isEqualToString:@""] )
        {
            /* load and link new nib view hirearchy */
            if( self.avc != nil )
                [self.avc setRepresentedObject:nil];
            
            self.avc = [[[AnaylizerSettingPopOverAccessoryViewController alloc] initWithNibName:nibName bundle:nil] autorelease];
            [self.avc setRepresentedObject:[[self superview] valueForKey:@"objectValue"]];
            [self.avc loadView];
            
            newSubViewHeight = [[self.avc view] frame].size.height;
            accessoryFrame.size = [[self.avc view] frame].size;
            [accessoryView setFrame:accessoryFrame];
            [accessoryView addSubview:[self.avc view]];
        }
        else
        {
            /* no new nib, collapse accressory frame */
            accessoryFrame.size.height = 0;
            [accessoryView setFrame:accessoryFrame];
            newSubViewHeight = 0;
        }
        
        /* calculate proper accessory view height */
        NSSize contentsize = [actionPopOver contentSize];
        contentsize.height += newSubViewHeight - currentAVHeight;
        [actionPopOver setContentSize:contentsize];

        NSView *editorView = [[self superview] valueForKey:@"editorSubView"];
        if( [editorView isKindOfClass:anaClass] )
        {
            if( [editorView respondsToSelector:@selector(prepareAccessoryView:)] )
                [editorView prepareAccessoryView:[self.avc view]];
        }
        
        return;
    }
    else if( [keyPath isEqualToString:@"parentStream.sourceUTI"] )
    {
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (IBAction)popOverOK:(id)sender
{
    NSError *err;
    
    [subMOC save:&err];

    [utiTextField unbind:@"value"];
    [editorPopup unbind:@"contentObjects"];
    [editorPopup unbind:@"selectedObject"];

    [self.subObjectValue removeObserver:self forKeyPath:@"currentEditorView"];
    [self.subObjectValue removeObserver:self forKeyPath:@"parentStream.sourceUTI"];
    
    [actionPopOver performClose:self];
}

- (IBAction)popOverCancel:(id)sender
{
    [utiTextField unbind:@"value"];
    [editorPopup unbind:@"contentObjects"];
    [editorPopup unbind:@"selectedObject"];

    [self.subObjectValue removeObserver:self forKeyPath:@"currentEditorView"];
    [self.subObjectValue removeObserver:self forKeyPath:@"parentStream.sourceUTI"];

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
    self.avc = nil;
    [super dealloc];
}
@end