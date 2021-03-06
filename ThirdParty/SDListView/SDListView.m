//
//  SDListView.m
//  SingleListExample
//
//  Created by Steven Degutis on 10/26/09.
//

#import "SDListView.h"

#import <QuartzCore/QuartzCore.h>

#import "SDListViewItem.h"

#import "SDListViewItem+Private.h"

#import <objc/runtime.h>
@interface SDFlippedClipView : NSClipView
@end

@interface SDListView ()

- (void) _init;

- (void) _beginObservingContent;
- (void) _contentDidChange;

- (void) _rebuildContent;
- (void) _sortContent;
- (void) _layout;

- (SDListViewItem*) _itemAtPoint:(NSPoint)point;

- (void) _moveSelectionInDirection:(int)direction;

@end


@implementation SDListView

@synthesize content;
@synthesize prototypeItem;
@synthesize sortDescriptors;

@synthesize topPadding;
@synthesize bottomPadding;

@synthesize selectable;
@synthesize allowsMultipleSelection;
@synthesize liveResize;

@dynamic selectionIndexes;

// MARK: -
// MARK: Begin Code

+ (void) initialize {
	if (self == [SDListView class]) {
		[self exposeBinding:@"selectionIndexes"];
		[self exposeBinding:@"content"];
	}
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self _init];
    }
    return self;
}

- (id)initWithFrame:(NSRect)frame {
	if (self = [super initWithFrame:frame]) {
        [self _init];
	}
	return self;
}

- (void) dealloc {
	[self removeObserver:self forKeyPath:@"content"];
    [self removeObserver:self forKeyPath:@"sortDescriptors"];
    
	[sortDescriptors release], sortDescriptors = nil;
	[content release], content = nil;
	[listViewItems release];
	[viewsThatShouldOnlyFadeIn release];
	
	[super dealloc];
}

- (void) awakeFromNib {
	NSClipView *clipView = [[self enclosingScrollView] contentView];
	object_setClass(clipView, [SDFlippedClipView class]);
	
	dispatch_async(dispatch_get_main_queue(), ^{
		[self _rebuildContent];
		[self _sortContent];
		[self _layout];
	});
}

- (void) _init {
    listViewItems = [[NSMutableArray array] retain];
    viewsThatShouldOnlyFadeIn = [[NSMutableArray array] retain];
    selectionFellOfSide = 1;
    
    [self _beginObservingContent];
}

// MARK: -
// MARK: Dynamic Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    #pragma unused(object)
    #pragma unused(change)
    #pragma unused(context)
    if ([keyPath isEqualToString:@"content"]) {
        [[self class] cancelPreviousPerformRequestsWithTarget:self
                                                     selector:@selector(_contentDidChange)
                                                       object:nil];
        
        [self performSelector:@selector(_contentDidChange)
                   withObject:nil
                   afterDelay:0.15];
    }
    else if ([keyPath isEqualToString:@"sortDescriptors"]) {
        [self _sortContent];
        [self _layout];
    }
}

- (void) _beginObservingContent {
    [self addObserver:self
           forKeyPath:@"content"
              options:0
              context:nil];
    [self addObserver:self
           forKeyPath:@"sortDescriptors"
              options:0
              context:nil];
}

- (void) suspendObservations
{
    [listViewItems makeObjectsPerformSelector:@selector(suspendObservations)];
}

- (void) resumeObservations
{
    [listViewItems makeObjectsPerformSelector:@selector(resumeObservations)];
}

// MARK: -
// MARK: Rebuilding content and layout

- (void) _contentDidChange {
	[self _rebuildContent];
	[self _sortContent];
	[self _layout];
}

/* steps:
 * (1) cache any items whose repObject are still there
 * (2) create any new items for new repObjects
 * (3) build arrays from steps 1-2 into a new array
 * (4) add their subviews to self
 * (N-1) ??????
 * (N) profit
 */
- (void) _rebuildContent {
	id pool = [NSAutoreleasePool new];
	
	NSArray *oldItems = [NSArray arrayWithArray:listViewItems];
	
	NSMutableArray *oldItemsToSave = [NSMutableArray array];
	NSMutableArray *oldItemsToDiscard = [NSMutableArray array];
	NSMutableArray *newlyCreatedItems = [NSMutableArray array];
	
	for (SDListViewItem *oldItem in oldItems) {
		if ([self.content containsObject: oldItem.representedObject])
			[oldItemsToSave addObject:oldItem];
	}
	
	[oldItemsToDiscard addObjectsFromArray:oldItems];
	[oldItemsToDiscard removeObjectsInArray:oldItemsToSave];
	
	// we now have 2 halves of "listViewItems"
	// (1) saved
	// (2) discarded
	
	
	// now lets create items for the ones we dont have
	
	NSArray *oldContentObjects = [oldItemsToSave valueForKey:@"representedObject"];
	
	for (id newContentObject in self.content) {
		if ([oldContentObjects containsObject: newContentObject] == NO) {
			SDListViewItem *newlyCreatedItem = [[self newItemForRepresentedObject:newContentObject] autorelease];
			[newlyCreatedItems addObject: newlyCreatedItem];
		}
	}
	
	// lets remove stale items from "oldItemsToDiscard"
	for (SDListViewItem *item in oldItemsToDiscard)
		[listViewItems removeObject:item];
	
	[listViewItems addObjectsFromArray:newlyCreatedItems];
	
	// CHECKPOINT: listViewItems is now officially ready for doing stuff with!
	
	// now lets remove views from the discarded items.
	
	for (NSView *oldView in [oldItemsToDiscard valueForKey:@"view"]) {
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0.5];
		
		[[oldView animator] setAlphaValue:0.0];
		
		[NSAnimationContext endGrouping];
		
		[oldView performSelector:@selector(removeFromSuperview)
					  withObject:nil
					  afterDelay:0.5];
	}
	
	for (SDListViewItem *newItem in newlyCreatedItems) {
		NSView *view = newItem.view;
		
		[viewsThatShouldOnlyFadeIn addObject:view];
		[view setAlphaValue:0.0];
		
		CABasicAnimation *anim = [view animationForKey:@"frameSize"];
		anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
		[view setAnimations:[NSDictionary dictionaryWithObjectsAndKeys:
							 anim, @"frameSize",
							 nil]];
		[self addSubview:view];
	}
	
	[pool drain];
}

- (void) _sortContent {
	if ([self.sortDescriptors count] > 0) {
		[content autorelease];
		content = [[content sortedArrayUsingDescriptors:self.sortDescriptors] copy];
	}
	
	// (because i suck at this sort of algorithm...) heh heh, get it? "sort" of algorith? heh heh heh heh heh heh....
	NSMutableArray *sortedListViewItems = [NSMutableArray array];
	
	NSArray *listViewItemRepObjects = [listViewItems valueForKey:@"representedObject"];
	
	for (id contentObject in content) {
		NSUInteger index = [listViewItemRepObjects indexOfObject: contentObject];
		SDListViewItem *item = [listViewItems objectAtIndex:index];
		[sortedListViewItems addObject:item];
	}
	
	[listViewItems setArray:sortedListViewItems];
}

/* steps:
 * (1) ask for each subview's height based on our own width
 * (2) set our own height based on these (sum)
 * (3) find each of their origins based on their predecessors' heights
 * (4) set their new locations (using -animator proxy)
 */
- (void) _layout {
// TODO: Call layout when scroller style changes
    NSScrollView *scrollView = [self enclosingScrollView];
	CGFloat scrollViewWidth = [scrollView frame].size.width;
    CGFloat width = scrollViewWidth;
    
    // calculate vertical scroller size
    NSScroller *verticalScroller = [[self enclosingScrollView] verticalScroller];
    Class scrollerClass = [verticalScroller class];
    if ([scrollerClass respondsToSelector:@selector(scrollerWidthForControlSize:scrollerStyle:)]) { // >= OS X 10.7
        NSScrollerStyle scrollerStyle = [verticalScroller scrollerStyle];
        if (scrollerStyle != NSScrollerStyleOverlay) { // don't shrink a view if the scroller is an overlay
            width -= [scrollerClass scrollerWidthForControlSize:[verticalScroller controlSize]
                                                  scrollerStyle:scrollerStyle];
        }
    }
    else { // < OS X 10.7
        width -= [scrollerClass  scrollerWidthForControlSize:[verticalScroller controlSize]];
    }
	
	CGFloat *heights = malloc(sizeof(CGFloat) * [listViewItems count]);
	
    __block CGFloat totalHeight = 0.0;
    [listViewItems enumerateObjectsUsingBlock: ^ (SDListViewItem *item, NSUInteger i, BOOL *stop) {
        #pragma unused(stop)
        heights[i] = [item heightForGivenWidth:width];
        totalHeight += heights[i];
    }];
	
	totalHeight += self.topPadding + self.bottomPadding;
	
	[super setFrameSize:NSMakeSize(scrollViewWidth, totalHeight)];
	
    // layout subviews (cells)
    NSRect visibleRect = [scrollView documentVisibleRect];
    __block CGFloat y = 0.0 + self.bottomPadding;
    
    [NSAnimationContext beginGrouping];
    [listViewItems enumerateObjectsUsingBlock: ^ (SDListViewItem *item, NSUInteger i, BOOL *stop) {
        #pragma unused(stop)
        CGFloat height = heights[i];
        NSRect newItemFrame = NSMakeRect(0.0, y, width, height);
        
        if ([self inLiveResize] || [self liveResize] ||
            y+height < visibleRect.origin.y || 
            y > visibleRect.origin.y+visibleRect.size.height) {
            item.view.frame = newItemFrame; // don't animate views when in live resize mode or views that are not visible
            item.view.alphaValue = 1.0; // make sure new items are visible
        }
        else {
            if ([viewsThatShouldOnlyFadeIn containsObject:item.view]) {
                item.view.frame = newItemFrame;
                [[item.view animator] setAlphaValue:1.0]; // new items should just fade in
            }
            
            [[item.view animator] setFrame:newItemFrame];
        }
        
        y += height;
    }];
    [NSAnimationContext endGrouping];
    
	free(heights);
	
	[viewsThatShouldOnlyFadeIn removeAllObjects];
}

// TODO: make more efficient (only this one item is needing a size change).
// Giving this a try - tjl;

- (void) noteHeightChangedForItem:(SDListViewItem*)listItem {
    #pragma unused(listItem)
    [self _layout];
}


// MARK: -
// MARK: Drawing

- (void) drawRect:(NSRect)dirtyRect {
    #pragma unused(dirtyRect)
	if ([self.content count] == 0)
		return;
}

- (void) setFrameSize:(NSSize)newSize {
    #pragma unused(newSize)
    [self _layout]; // this method will call super's -setFrameSize:
}

// MARK: -
// MARK: NSCollectionView-compatibility

- (SDListViewItem*) newItemForRepresentedObject:(id)object {
	SDListViewItem *newItem = [self.prototypeItem copy];
	newItem.representedObject = object;
	newItem.listView = self;
	return newItem;
}

- (NSUInteger) indexOfItem:(SDListViewItem*)item {
	return [listViewItems indexOfObject:item];
}

- (SDListViewItem*) itemAtIndex:(NSUInteger)index {
	return [listViewItems objectAtIndex:index];
}

- (NSIndexSet*) selectionIndexes {
	NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
	
	for (NSUInteger index = 0; index < [listViewItems count]; index++) {
		SDListViewItem *item = [listViewItems objectAtIndex:index];
		if (item.selected)
			[indexSet addIndex:index];
	}
	
	return indexSet;
}

- (void) setSelectionIndexes:(NSIndexSet*)indexSet {
	for (NSUInteger index = 0; index < [listViewItems count]; index++) {
		SDListViewItem *item = [listViewItems objectAtIndex:index];
		item.selected = [indexSet containsIndex:index];
	}
}

// MARK: -
// MARK: Mouse support (for selection)

/* Logic for single selection only:
 * 
 *     soon as the mouse is down, selection begins on that spot.
 *     if the mouse is dragged, the selection moves with the mouse.
 *     on mouse-up, just do nothing.
 * 
 *     to sum up: item-selection happens mostly in
 *     -mouseDragged: (and once in -mouseDown:)
 * 
 * Logic for multiple selection:
 * 
 *     on mouse-down, we save the initial index. when dragging,
 *     we set the selected range as the currently-dragged-over index
 *     to the initial index. note: this might not be fully thought out!
 *     TODO: think this over a little more.
 */

- (void) mouseDown:(NSEvent*)theEvent {
	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	// TODO: if holding shift, or Cmd, we ADD to the selection, not replace it! (shit.)
	
	if (self.allowsMultipleSelection == NO) {
		// just pass it on to mouseDragged
		[self mouseDragged:theEvent];
	}
	else {
		SDListViewItem *item = [self _itemAtPoint:point];
		
		initialDraggingIndex = [listViewItems indexOfObject:item];
		
		if (initialDraggingIndex != NSNotFound)
			self.selectionIndexes = [NSIndexSet indexSetWithIndex:initialDraggingIndex];
	}
}

- (void) mouseDragged:(NSEvent*)theEvent {
	//[super mouseDragged:theEvent];
	[self autoscroll:theEvent];
	
	NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	if (self.allowsMultipleSelection == NO) {
		// sure, mouseDown makes ME do all the heavy lifting... sheesh!
		
		SDListViewItem *item = [self _itemAtPoint:point];
		NSUInteger index = [listViewItems indexOfObject:item];
		
		if (index != NSNotFound)
			self.selectionIndexes = [NSIndexSet indexSetWithIndex:index];
	}
	else {
		SDListViewItem *item = [self _itemAtPoint:point];
		NSUInteger currentlyDraggingIndex = [listViewItems indexOfObject:item];
		
		if (currentlyDraggingIndex != NSNotFound && initialDraggingIndex != NSNotFound) {
			NSRange range = NSMakeRange(initialDraggingIndex, currentlyDraggingIndex - initialDraggingIndex + 1);
			if (currentlyDraggingIndex < initialDraggingIndex) {
				range.location = currentlyDraggingIndex;
				range.length = initialDraggingIndex - currentlyDraggingIndex + 1;
			}
			
			self.selectionIndexes = [NSIndexSet indexSetWithIndexesInRange:range];
		}
	}
}

- (void) mouseUp:(NSEvent*)theEvent {
    #pragma unused(theEvent)
	if (self.allowsMultipleSelection == NO) {
	}
	else {
	}
}

// MARK: -
// MARK: Keyboard support (for selection and navigation)

- (BOOL) acceptsFirstResponder {
	return YES;
}

- (BOOL) canBecomeKeyView {
	return YES;
}

- (void)keyDown:(NSEvent *)theEvent {
	[self interpretKeyEvents:[NSArray arrayWithObject:theEvent]];
}

- (void)keyUp:(NSEvent *)theEvent {
    #pragma unused(theEvent)
}

// for now, [space] moves down. in the future, we may want to make it deal with selection instead.
- (void) insertText:(id)insertString {
	if ([insertString isEqualToString:@" "])
		[[self enclosingScrollView] pageDown:self];
	else
		[super insertText:insertString];
}

// TODO: keep track of whether the index fell off the top or bottom, so we can recover easily

- (void) moveDown:(id)sender {
    #pragma unused(sender)
	if (self.allowsMultipleSelection == NO) {
		[self _moveSelectionInDirection:(1)];
	}
	else {
	}
}

- (void) moveUp:(id)sender {
    #pragma unused(sender)
	if (self.allowsMultipleSelection == NO) {
		[self _moveSelectionInDirection:(-1)];
	}
	else {
	}
}

// direction is either -1 or 1
- (void) _moveSelectionInDirection:(int)direction {
	// TODO: make this method smarter, more like NSCollectionView (spec it out, first)
	
	NSMutableIndexSet *newIndexSet = [NSMutableIndexSet indexSet];
	
	if ([self.selectionIndexes count] == 0) {
		if ([listViewItems count] > 0) {
			if (direction == -1 && selectionFellOfSide == -1) // bottom
				[newIndexSet addIndex:0],
				selectionFellOfSide = 0;
			if (direction == 1 && selectionFellOfSide == 1) // top
				[newIndexSet addIndex:([listViewItems count] - 1)],
				selectionFellOfSide = 0;
		}
	}
	else {
		NSInteger firstIndex = [self.selectionIndexes firstIndex];
		firstIndex -= direction;
		
		BOOL fellOffBottom = (firstIndex < 0);
        NSInteger countListViewItems = [listViewItems count];
		BOOL fellOffTop = (firstIndex >= countListViewItems);
		
		if (fellOffBottom) {
			selectionFellOfSide = -1;
		}
		else if (fellOffTop) {
			selectionFellOfSide = 1;
		}
		else {
			if (selectionFellOfSide) // we dont need this if(), but it feels infinitesimally faster
				selectionFellOfSide = 0;
			
			[newIndexSet addIndex:firstIndex];
		}
	}
	
	self.selectionIndexes = newIndexSet;
	
	if ([self.selectionIndexes count]) {
		NSUInteger itemIndex = [self.selectionIndexes firstIndex];
		NSRect itemFrame = [self frameForItemAtIndex:itemIndex];
		[self scrollRectToVisible:itemFrame];
	}
}

// MARK: -
// MARK: Private Helper Methods

- (NSRect) frameForItemAtIndex:(NSUInteger)index {
	return [[[listViewItems objectAtIndex:index] view] frame];
}

- (SDListViewItem*) _itemAtPoint:(NSPoint)point {
	for (SDListViewItem *item in listViewItems) {
		if (NSPointInRect(point, [[item view] frame]))
			return item;
	}
	return nil;
}

@end

@implementation SDFlippedClipView
- (BOOL) isFlipped { return YES; }
@end
