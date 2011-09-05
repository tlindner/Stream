//
//  MyClass.m
//  Stream
//
//  Created by tim lindner on 7/28/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "ColorGradientView.h"
#import "AnaylizerTableViewCellView.h"
#import "BlockerDataViewController.h"
#import "Analyzation.h"
#import "StAnaylizer.h"
#import "StBlock.h"

@implementation ColorGradientView
@synthesize labelUTI;
@synthesize labelEditor;

// Automatically create accessor methods
@synthesize startingColor;
@synthesize endingColor;
@synthesize angle;
@synthesize newConstraints;
@synthesize actionPopOverNib;
@synthesize popupArrayController;
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
    StAnaylizer *anaylizer = [[self superview] valueForKey:@"objectValue"];
    
    if( self.actionPopOverNib == nil )
    {
        self.actionPopOverNib = [[[NSNib alloc] initWithNibNamed:@"AnaylizerSettingPopover" bundle:nil] autorelease];
        
        if (![self.actionPopOverNib instantiateNibWithOwner:self topLevelObjects:nil])
        {
            NSLog(@"Warning! Could not load nib file.\n");
            return;
        }
    }
    
    NSArray *stuff = nil;
    id ro = nil;
    
    if( [anaylizer.currentEditorView isEqualToString:@"Blocker View"] )
    {
        [self.labelUTI setStringValue:@"Block UTI:"];
        [self.labelEditor setStringValue:@"Block Editor:"];
        
        AnaylizerTableViewCellView *anaTableViewCell = (AnaylizerTableViewCellView *)[self superview];
        BlockerDataViewController *blockerController = (BlockerDataViewController *)anaTableViewCell.editorController;
        NSArray *selectedObjects = [blockerController.treeController selectedObjects];
        
        if( [selectedObjects count] == 1 )
        {
            StBlock *theBlock = [selectedObjects objectAtIndex:0];
            observableSourceUTI = observableEditorView = theBlock;
            stuff = [[Analyzation sharedInstance] anaylizersforUTI:[theBlock valueForKey:@"sourceUTI"]];
            ro = theBlock;
        }
        else
        {
            NSLog( @"Multiple selection! Ohy, vey!" );
            observableEditorView = nil;
            observableSourceUTI = nil; 
        }
    }
    else
    {
        observableEditorView = anaylizer;
        observableSourceUTI = anaylizer.parentStream;
        stuff = [[Analyzation sharedInstance] anaylizersforUTI:[anaylizer valueForKey:@"sourceUTI"]];
        ro = anaylizer;
    }
    
    self.popupArrayController = [[[NSArrayController alloc] init] autorelease];
    [self.popupArrayController addObjects:stuff];
    
    [utiTextField bind:@"value" toObject:observableSourceUTI withKeyPath:@"sourceUTI" options:nil];
    [editorPopup bind:@"content" toObject:self.popupArrayController withKeyPath:@"arrangedObjects" options:nil];
    [editorPopup bind:@"selectedObject" toObject:observableEditorView withKeyPath:@"currentEditorView" options:nil];
    
    [observableEditorView addObserver:self forKeyPath:@"currentEditorView" options:NSKeyValueChangeSetting context:nil];
    [observableSourceUTI addObserver:self forKeyPath:@"sourceUTI" options:NSKeyValueChangeSetting context:nil];
    
    /* Editview changed, update UI */
    [[accessoryView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    /* ask current anaylization the name of it accessory nib */
    NSString *editorPopupTitle = [editorPopup titleOfSelectedItem];
    Class anaClass = [[Analyzation sharedInstance] anaylizerClassforName:editorPopupTitle];
    
    NSAssert(anaClass != nil, @"Do Popover: Returned class is nil");
    [anaylizer addSubOptionsDictionary:[anaClass anaylizerKey]  withDictionary:[anaClass defaultOptions]];
    
    NSString *nibName = [anaClass AnaylizerPopoverAccessoryViewNib];
    
    NSRect accessoryFrame = [accessoryView frame];
    CGFloat currentAVHeight = accessoryFrame.size.height;
    CGFloat newSubViewHeight;
    
    if( nibName != nil && ![nibName isEqualToString:@""] )
    {
        if( self.avc != nil )
            [self.avc setRepresentedObject:nil];
        
        self.avc = [[[AnaylizerSettingPopOverAccessoryViewController alloc] initWithNibName:nibName bundle:nil] autorelease];
        [self.avc setRepresentedObject:ro];
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
    
    NSViewController *editorController = [[self superview] valueForKey:@"editorController"];
    if( [editorController isKindOfClass:anaClass] )
    {
        if( [editorController respondsToSelector:@selector(prepareAccessoryView:)] )
            [editorController prepareAccessoryView:[self.avc view]];
    }
    
    [actionPopOver showRelativeToRect:[tlAction bounds] ofView:tlAction preferredEdge:NSMaxYEdge];
    NSSize contentsize = [actionPopOver contentSize];
    contentsize.height += newSubViewHeight - currentAVHeight;
    [actionPopOver setContentSize:contentsize];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    id objectValue = [[self superview] valueForKey:@"objectValue"];
    
    //NSLog( @"Observied: kp: %@, object: %@, change: %@", keyPath, object, change );
    if( [keyPath isEqualToString:@"currentEditorView"] )
    {
        if( [[objectValue class] isSubclassOfClass:[StBlock class]] )
        {
            AnaylizerTableViewCellView *anaTableViewCell = (AnaylizerTableViewCellView *)[self superview];
            BlockerDataViewController *blockerController = (BlockerDataViewController *)anaTableViewCell.editorController;
            NSArray *selectedObjects = [blockerController.treeController selectedObjects];
            
            if( [selectedObjects count] == 1 )
            {
                StBlock *theBlock = [selectedObjects objectAtIndex:0];
                [self.avc setRepresentedObject:theBlock];
            }
            
            return;
        }
        else
        {
            StAnaylizer *anaylizer = objectValue;
            
            /* Editview changed, update UI */
            [[accessoryView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
            
            /* ask current anaylization the name of it accessory nib */
            Class anaClass = [[Analyzation sharedInstance] anaylizerClassforName:[editorPopup titleOfSelectedItem]];
            //NSLog( @"anaClass: %@", anaClass );
            NSAssert(anaClass != nil, @"Do Popover: Returned class is nil");
            [anaylizer addSubOptionsDictionary:[anaClass anaylizerKey]  withDictionary:[anaClass defaultOptions]];
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
                [self.avc setRepresentedObject:anaylizer];
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
            
            NSViewController *editorController = [[self superview] valueForKey:@"editorController"];
            if( [editorController isKindOfClass:anaClass] )
            {
                if( [editorController respondsToSelector:@selector(prepareAccessoryView:)] )
                    [editorController prepareAccessoryView:[self.avc view]];
            }
            
            return;
        }
    }
    else if( [keyPath isEqualToString:@"sourceUTI"] )
    {
        [self.popupArrayController removeObjects:[self.popupArrayController arrangedObjects]];
        NSArray *stuff = [[Analyzation sharedInstance] anaylizersforUTI:[objectValue valueForKey:@"sourceUTI"]];
        [self.popupArrayController addObjects:stuff];
        
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (IBAction)popOverOK:(id)sender
{
    [utiTextField unbind:@"value"];
    [editorPopup unbind:@"contentObjects"];
    [editorPopup unbind:@"selectedObject"];
    
    [observableEditorView removeObserver:self forKeyPath:@"currentEditorView"];
    [observableSourceUTI removeObserver:self forKeyPath:@"sourceUTI"];
    
    [actionPopOver performClose:self];
}

- (IBAction)popOverCancel:(id)sender
{
    [utiTextField unbind:@"value"];
    [editorPopup unbind:@"contentObjects"];
    [editorPopup unbind:@"selectedObject"];
    
    [observableEditorView removeObserver:self forKeyPath:@"currentEditorView"];
    [observableSourceUTI removeObserver:self forKeyPath:@"sourceUTI"];
    
    [actionPopOver performClose:self];
    
}

- (void)dealloc {
    
    //    if (utiTextField) {
    //        [utiTextField unbind:@"value"];
    //    }
    //    
    //    if (editorPopup) {
    //        [editorPopup unbind:@"contentObjects"];
    //        [editorPopup unbind:@"selectedObject"];
    //    }
    
    self.popupArrayController = nil;
    self.newConstraints = nil;
    self.actionPopOverNib = nil;
    self.avc = nil;
    [super dealloc];
}
@end