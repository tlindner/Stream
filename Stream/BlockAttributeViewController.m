//
//  BlockAttributeViewController.m
//  Stream
//
//  Created by tim lindner on 8/31/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BlockAttributeViewController.h"
#import "StBlock.h"

@implementation BlockAttributeViewController
@synthesize tableView;
@synthesize arrayController;
@synthesize blockFormatter;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)loadView
{
    [super loadView];
    
    StBlock *theBlock = [self representedObject];
    [theBlock addSubOptionsDictionary:[BlockAttributeViewController anaylizerKey] withDictionary:[BlockAttributeViewController defaultOptions]];
    NSString *currentMode = [theBlock valueForKeyPath:@"optionsDictionary.BlockAttributeViewController.numericDisplay"];
    blockFormatter.mode = currentMode;
    
    [theBlock addObserver:self forKeyPath:@"optionsDictionary.BlockAttributeViewController.numericDisplay" options:NSKeyValueChangeSetting context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //NSLog( @"Observied: kp: %@, object: %@, change: %@", keyPath, object, change );
    if( [keyPath isEqualToString:@"optionsDictionary.BlockAttributeViewController.numericDisplay"] )
    {
        StBlock *theBlock = [self representedObject];
        NSString *currentMode = [theBlock valueForKeyPath:@"optionsDictionary.BlockAttributeViewController.numericDisplay"];
        blockFormatter.mode = currentMode;
        [tableView reloadData];
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (void)dealloc {
    [[self representedObject] removeObserver:self forKeyPath:@"optionsDictionary.BlockAttributeViewController.numericDisplay"];
    
    [super dealloc];
}

+ (NSArray *)anaylizerUTIs
{
    return [NSArray arrayWithObject:@"org.macmess.stream.attribute"];
}

+ (NSString *)anayliserName
{
    return @"Block Attribute View";
}

/* Used for KVC and KVO in anaylizer options dictionary */
+ (NSString *)anaylizerKey
{
    return @"BlockAttributeViewController";
}

+ (NSString *)AnaylizerPopoverAccessoryViewNib
{
    return @"BlockAttributeViewAccessory";
}

-(NSString *)nibName
{
    return @"BlockAttributeViewController";
}

+ (NSMutableDictionary *)defaultOptions
{
    return [[[NSMutableDictionary alloc] initWithObjectsAndKeys:@"Hexadecimal", @"numericDisplay", [NSArray arrayWithObjects:@"Hexadecimal", @"Decimal", nil], @"numericDisplayOptions", nil] autorelease];
}

@end
