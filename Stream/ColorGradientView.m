//
//  MyClass.m
//  Stream
//
//  Created by tim lindner on 7/28/11.
//  Copyright 2011 org.macmess. All rights reserved.
//

#import "ColorGradientView.h"
#import "BlockerDataViewController.h"
#import "Analyzation.h"
#import "StAnaylizer.h"
#import "StBlock.h"

void AbleAllControlsInView( NSView *inView, BOOL able );

@implementation ColorGradientView
@synthesize tlTitle;
@synthesize acceptsTextField;
@synthesize labelUTI;
@synthesize labelEditor;
@synthesize viewOwner;

// Automatically create accessor methods
@synthesize startingColor;
@synthesize endingColor;
@synthesize angle;
@synthesize additionalConstraints;
@synthesize actionPopOverNib;
@synthesize popupArrayController;
@synthesize avc;
@synthesize blockTreeController;
@synthesize boundAndObserved;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        self.startingColor = [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
        self.endingColor = nil;
        [self setAngle:270];
        boundAndObserved = NO;
    }
    
    return self;
}

- (void)awakeFromNib
{
    self.startingColor = [NSColor colorWithCalibratedRed:0.92f green:0.93f blue:0.98f alpha:1.0f];
    self.endingColor = [NSColor colorWithCalibratedRed:0.74f green:0.76f blue:0.83f alpha:1.0f];
    [self setAngle:270];
    boundAndObserved = NO;
//    [self updateConstraints];
    [super awakeFromNib];
}

- (BOOL)isOpaque
{
    return true;
}

- (void)drawRect:(NSRect)rect
{
    if (endingColor == nil || [startingColor isEqual:endingColor])
    {
        // Fill view with a standard background color
        [startingColor set];
        NSRectFill(rect);
    }
    else
    {
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
    #pragma unused(sender)
    StAnaylizer *anaylizer = [viewOwner representedObject];

    [self unbindAndUnobserve];
   
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
        
        BlockerDataViewController *blockerController = (BlockerDataViewController *)self.viewOwner.editorController;
        blockTreeController = blockerController.treeController;
        NSArray *selectedObjects = [blockTreeController selectedObjects];
        
        if( [selectedObjects count] == 1 )
        {
            StBlock *theBlock = [selectedObjects objectAtIndex:0];
            observableSourceUTI = observableEditorView = theBlock;
            stuff = [[Analyzation sharedInstance] anaylizersforUTI:[theBlock valueForKey:@"sourceUTI"]];
            ro = theBlock;
            
            [blockTreeController addObserver:self forKeyPath:@"selectedObjects" options:0 context:nil];

            [utiTextField setEnabled:YES];
            [editorPopup setEnabled:YES];
            AbleAllControlsInView([self.avc groupBox], YES);

            /* Trigger creating this now, before the view is loaded */
            [theBlock anaylizerObject];
        }
        else
        {
            observableEditorView = nil;
            observableSourceUTI = nil;
            
            [blockTreeController addObserver:self forKeyPath:@"selectedObjects" options:0 context:nil];
            
            if (self.avc) {
                [utiTextField setEnabled:NO];
                [editorPopup setEnabled:NO];
                AbleAllControlsInView([self.avc groupBox], NO);
            }

            [actionPopOver showRelativeToRect:[tlAction bounds] ofView:tlAction preferredEdge:NSMaxYEdge];
//            NSSize contentsize = [actionPopOver contentSize];
//            contentsize.height += newSubViewHeight - currentAVHeight;
//            [actionPopOver setContentSize:contentsize];

            return;
        }
    }
    else
    {
        blockTreeController = nil;
        observableEditorView = anaylizer;
        observableSourceUTI = anaylizer.parentStream;
        stuff = [[Analyzation sharedInstance] anaylizersforUTI:[anaylizer valueForKey:@"sourceUTI"]];
        ro = anaylizer;
 
        [utiTextField setEnabled:YES];
        [editorPopup setEnabled:YES];
        AbleAllControlsInView([self.avc groupBox], YES);
}
    
    self.popupArrayController = [[[NSArrayController alloc] init] autorelease];
    [self.popupArrayController addObjects:stuff];
    
    [utiTextField bind:@"value" toObject:observableSourceUTI withKeyPath:@"sourceUTI" options:nil];
    [utiTextField bind:@"enabled" toObject:observableEditorView withKeyPath:@"canChangeEditor" options:nil];
    [editorPopup bind:@"content" toObject:self.popupArrayController withKeyPath:@"arrangedObjects" options:nil];
    [editorPopup bind:@"selectedObject" toObject:observableEditorView withKeyPath:@"currentEditorView" options:nil];
    [editorPopup bind:@"enabled" toObject:observableEditorView withKeyPath:@"canChangeEditor" options:nil];
    
    [observableEditorView addObserver:self forKeyPath:@"currentEditorView" options:NSKeyValueChangeSetting context:nil];
    [observableSourceUTI addObserver:self forKeyPath:@"sourceUTI" options:NSKeyValueChangeSetting context:nil];
    boundAndObserved = YES;
    
    /* Editview changed, update UI */
    [[accessoryView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    /* ask current anaylization the name of it's accessory nib */
    NSString *editorPopupTitle = [editorPopup titleOfSelectedItem];
    Class anaClass = [[Analyzation sharedInstance] anaylizerClassforName:editorPopupTitle];
    [acceptsTextField setStringValue: [[anaClass anaylizerUTIs] componentsJoinedByString:@", "]];
    
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
    
    NSViewController *editorController = self.viewOwner.editorController;
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
    id objectValue = self.viewOwner.representedObject; //[[self superview] valueForKey:@"objectValue"];
    
    //NSLog( @"Observied: kp: %@, object: %@, change: %@", keyPath, object, change );
    if( [keyPath isEqualToString:@"currentEditorView"] )
    {
        if( [[objectValue class] isSubclassOfClass:[StBlock class]] )
        {
            //AnaylizerTableViewCellView *anaTableViewCell = (AnaylizerTableViewCellView *)[self superview];
            BlockerDataViewController *blockerController = (BlockerDataViewController *)self.viewOwner.editorController; //anaTableViewCell.editorController;
            NSArray *selectedObjects = [blockerController.treeController selectedObjects];
            
            if( [selectedObjects count] == 1 )
            {
                StBlock *theBlock = [selectedObjects objectAtIndex:0];
                [self.avc setRepresentedObject:theBlock];
}
            [acceptsTextField setStringValue: @""];
           
            return;
        }
        else
        {
            StAnaylizer *anaylizer = objectValue;
            
            /* Editview changed, update UI */
            [[accessoryView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
            
            /* ask current anaylization the name of its accessory nib */
            Class anaClass = [[Analyzation sharedInstance] anaylizerClassforName:[editorPopup titleOfSelectedItem]];
            //NSLog( @"anaClass: %@", anaClass );
            NSAssert(anaClass != nil, @"Do Popover: Returned class is nil");
            [acceptsTextField setStringValue: [[anaClass anaylizerUTIs] componentsJoinedByString:@", "]];
            [anaylizer addSubOptionsDictionary:[anaClass anaylizerKey]  withDictionary:[anaClass defaultOptions]];
            NSString *nibName = [anaClass AnaylizerPopoverAccessoryViewNib];
            
            if( [anaylizer.currentEditorView isEqualToString:@"Blocker View"] )
            {
                BlockerDataViewController *blockerController = (BlockerDataViewController *)self.viewOwner.editorController;
                blockTreeController = blockerController.treeController;
                NSArray *selectedObjects = [blockTreeController selectedObjects];
                
                if( [selectedObjects count] == 1 )
                {
                    /* Trigger creating this now, before the view is loaded */
                    StBlock *theBlock = [selectedObjects objectAtIndex:0];
                    [theBlock anaylizerObject];
                    anaylizer = (StAnaylizer *)theBlock;
                }
            }

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
            
            NSViewController *editorController = self.viewOwner.editorController; // [[self superview] valueForKey:@"editorController"];
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
    else if ([keyPath isEqualToString:@"selectedObjects"]) {
        [self unbindAndUnobserve];
        [self doPopOver:self];
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (IBAction)popOverOK:(id)sender
{
    #pragma unused(sender)
    [self unbindAndUnobserve];
    [actionPopOver performClose:self];
}

- (IBAction)popOverCancel:(id)sender
{
    #pragma unused(sender)
    [self unbindAndUnobserve];
    [actionPopOver performClose:self];
}

- (void)unbindAndUnobserve
{
    if (boundAndObserved == YES) {
        [utiTextField unbind:@"value"];
        [utiTextField unbind:@"enabled"];
        [editorPopup unbind:@"contentObjects"];
        [editorPopup unbind:@"selectedObject"];
        [editorPopup unbind:@"enabled"];
        
        [observableEditorView removeObserver:self forKeyPath:@"currentEditorView"];
        [observableSourceUTI removeObserver:self forKeyPath:@"sourceUTI"];
                
        boundAndObserved = NO;
    }

    if (blockTreeController) {
        [blockTreeController removeObserver:self forKeyPath:@"selectedObjects"];
        blockTreeController = nil;
    }
}

- (void)dealloc
{
    [self unbindAndUnobserve];
    self.popupArrayController = nil;
    self.additionalConstraints = nil;
    self.actionPopOverNib = nil;
    self.avc = nil;
    [super dealloc];
}

@end

void AbleAllControlsInView( NSView *inView, BOOL able )
{
    NSArray *subViews = [inView subviews];
    
    for (NSView *view in subViews) {
        if ([[view class] isSubclassOfClass:[NSControl class]]) {
            NSControl *control = (NSControl *)view;
            [control setEnabled:able];
        }
        
        AbleAllControlsInView(view, able);
    }
}