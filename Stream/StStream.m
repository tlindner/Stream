//
//  StStream.m
//  temp
//
//  Created by tim lindner on 5/8/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "StStream.h"
#import "StAnaylizer.h"
#import "StBlock.h"
#import "StStream.h"


@implementation StStream

@dynamic customSortOrder;
@dynamic displayName;
@dynamic modificationDateofURL;
@dynamic regeneratingBlocks;
@dynamic sourceURL;
@dynamic sourceUTI;
@dynamic streamTransform;
@dynamic topLevelBlocks;
@dynamic anaylizers;
@dynamic blocks;
@dynamic childStreams;
@dynamic parentStream;
@dynamic sourceBlock;

- (NSMutableDictionary *)topLevelBlocks
{
    NSMutableDictionary *_topLevelBlocks = [self primitiveTopLevelBlocks];
    
    if (_topLevelBlocks == nil) {
        _topLevelBlocks = [[[NSMutableDictionary alloc] init] autorelease];
        
        for (StBlock *tlb in self.blocks) {
            [_topLevelBlocks setObject:tlb forKey:tlb.name];
        }
        
        [self setPrimitiveTopLevelBlocks:_topLevelBlocks];
    }
    
    return _topLevelBlocks;
}

- (NSData *)dataOfTopLevelBlockNamed:(NSString *)name
{
    NSData *result = nil;
    
    if( [name isEqualToString:@"stream"] )
    {
        result = [[self lastFilterAnayliser] resultingData];
    }
    else
    {
        /* find block and returned it's data */
        result = [[self topLevelBlockNamed:name] resultingData];
    }
    
    return result;
}

- (StBlock *)topLevelBlockNamed:(NSString *)theName
{
    StBlock *result = [self.topLevelBlocks objectForKey:theName];
    
    if (result == nil && [theName rangeOfString:@"*"].length != 0) {
        /* let's look for wild cards */
        NSSet *matchingKeys = [self.topLevelBlocks keysOfEntriesPassingTest:^(id key, id obj, BOOL *stop) {
            #pragma unused(obj, stop)
            return [key isLike:theName];
        }];
        
        if ([matchingKeys count] > 0) {
            result = [self.topLevelBlocks objectForKey:[matchingKeys anyObject]];
        }
    }
    
    return result;
}

- (StBlock *)startNewBlockNamed:(NSString *)name owner:(NSString *)owner
{
    if( [name isEqualToString:@"stream"] )
    {
        NSLog( @"StStream: Can not create block named: stream" );
        return nil;
    }
    
    StBlock *newBlock = [self topLevelBlockNamed:name];
    
    if( regeneratingBlocks == YES )
    {
        if( newBlock != nil )
        {
            /* reset block */
            [newBlock resetCounters];
            newBlock.anaylizerKind = owner;
            newBlock.markForDeletion = NO;
            newBlock.isEdit = NO;
            newBlock.isFail = NO;
            
            StBlock *dataSubBlock = [newBlock subBlockNamed:@"data"];
            dataSubBlock.markForDeletion = NO;
            dataSubBlock.isEdit = NO;
            dataSubBlock.isFail = NO;
            //            dataSubBlock.currentEditorView = @"Hex Editor";
            //            dataSubBlock.sourceUTI = @"public.data";
            
            StBlock *attributSubBlock = [newBlock subBlockNamed:@"attributes"];
            attributSubBlock.markForDeletion = NO;
            attributSubBlock.isEdit = NO;
            attributSubBlock.isFail = NO;
            //            attributSubBlock.currentEditorView = @"Block Attribute View";
            //            attributSubBlock.sourceUTI = @"org.macmess.stream.attribute";
            
            StBlock *depSubBlock = [newBlock subBlockNamed:@"dependencies"];
            depSubBlock.markForDeletion = NO;
            depSubBlock.isEdit = NO;
            depSubBlock.isFail = NO;
            //            depSubBlock.currentEditorView = @"Hex Editor";
            //            depSubBlock.sourceUTI = @"public.data";
            
            StBlock *intrinsicSubBlock = [newBlock subBlockNamed:@"intrinsic"];
            intrinsicSubBlock.markForDeletion = NO;
            intrinsicSubBlock.isEdit = NO;
            intrinsicSubBlock.isFail = NO;
            //            intrinsicSubBlock.currentEditorView = @"Hex Editor";
            //            intrinsicSubBlock.sourceUTI = @"public.data";
            
        }
        else
        {
            /* make new block */
            newBlock = [self makeNewBlockNamed:name owner:owner];
        }
    }
    else
    {
        if( newBlock == nil )
        {
            /* make new block */
            newBlock = [self makeNewBlockNamed:name owner:owner];
        }
        else
        {
            NSLog( @"startNewBlockNamed: error, block already exists: %@", name );
            newBlock = nil;
        }
    }
    
    return newBlock;
}

- (StBlock *)makeNewBlockNamed:(NSString *)name owner:(NSString *)owner
{
    /* See if named block already exists */
    StBlock *result = [self.topLevelBlocks objectForKey:name];
    
    if ( result == nil) {
        /* ok, create new block */
        StBlock *newBlock = [NSEntityDescription insertNewObjectForEntityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
        newBlock.name = name;
        newBlock.anaylizerKind = owner;
       
//        StBlock *newDataBlock = [NSEntityDescription insertNewObjectForEntityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
//        newDataBlock.name = @"data";
//        newDataBlock.sourceUTI = @"public.data";
//        [newBlock addSubBlocksObject:newDataBlock];
//        
//        StBlock *newAttributeBlock = [NSEntityDescription insertNewObjectForEntityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
//        newAttributeBlock.name = @"attributes";
//        newAttributeBlock.sourceUTI = @"org.macmess.stream.attribute";
//        newAttributeBlock.currentEditorView = @"Block Attribute View";
//        [newBlock addSubBlocksObject:newAttributeBlock];
//        
//        StBlock *newdependenciesBlock = [NSEntityDescription insertNewObjectForEntityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
//        newdependenciesBlock.name = @"dependencies";
//        newdependenciesBlock.sourceUTI = @"public.data";
//        [newBlock addSubBlocksObject:newdependenciesBlock];
//        
//        StBlock *newIntrinsicsBlock = [NSEntityDescription insertNewObjectForEntityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
//        newIntrinsicsBlock.name = @"intrinsic";
//        newIntrinsicsBlock.sourceUTI = @"public.data";
//        [newBlock addSubBlocksObject:newIntrinsicsBlock];

        [self.topLevelBlocks setObject:newBlock forKey:name];
        [self addBlocksObject:newBlock];
        result = newBlock;
    }
    else
    {
        NSLog( @"startNewBlockNamed: block already exists: %@", name );
    }
    
    return result;
}

- (StAnaylizer *)lastFilterAnayliser
{
    for (StAnaylizer *anAnayliser in [[self anaylizers] reversedOrderedSet])
    {
        if( ![anAnayliser.currentEditorView isEqualToString:@"Blocker View"] )
        {
            return anAnayliser;
        }
    }
    
    NSLog( @"StStream: lastFilterAnayliser did not find a last filter anayliser" );
    return nil;
}

- (StAnaylizer *)previousAnayliser:(StAnaylizer *)inAna
{
    NSUInteger theIndex = [[self anaylizers] indexOfObject:inAna];
    
    if( theIndex == 0 )
        return nil;
    else
        return [[self anaylizers] objectAtIndex:theIndex - 1];
}

- (NSArray *)blocksWithAnaylizerKey:(NSString *)key
{
    NSMutableArray *result = [[[NSMutableArray alloc] init] autorelease];
    
    for (StBlock *aBlock in self.blocks) {
        if ([aBlock.anaylizerKind isEqualToString:key]) {
            [result addObject:aBlock];
        }
    }
    
    return result;
}

- (void)setBlock:(StBlock *)theBlock withData:(NSData *)theData
{
    [self setBlock:theBlock withData:theData inRange:NSMakeRange(0, [theData length])];
}

- (void) setBlock:(StBlock *)theBlock withData:(NSData *)theData inRange:(NSRange)range
{
    NSUInteger index, end = NSMaxRange(range);
    unsigned char *bytes = (unsigned char *)[theData bytes];
    const unsigned char *orginalBytes = [[theBlock resultingData] bytes];
    StAnaylizer *lastAaylizer = [self lastFilterAnayliser];
    
    [lastAaylizer willChangeValueForKey:@"resultingData"];
    
    for( index = range.location; index < end; index++ )
    {
        if( orginalBytes[index] != bytes[index] )
        {
            [theBlock writeByte:bytes[index] atOffset:index];
        }
    }
    
    [self regenerateAllBlocks];
    
    [lastAaylizer didChangeValueForKey:@"resultingData"];
}

- (void)regenerateAllBlocks
{   
    /* set all block to be marked for deletion */
    [self markBlocksForDeletion];
    
    /* reset fail index set */
    [[[self lastFilterAnayliser] failIndexSet] removeAllIndexes];
    
    [self willChangeValueForKey:@"blocks"];
    
    /* Regenerate blocks using blockers */
    for( StAnaylizer *anAna in [self anaylizers] )
    {
        if( [anAna.currentEditorView isEqualToString:@"Blocker View"] )
        {
            Class blockerClass = NSClassFromString([anAna valueForKey:@"anaylizerKind"]);
            
            if (blockerClass != nil )
            {
                [blockerClass makeBlocks:self withAnaylizer:anAna];
            }
            else
            {
                NSAssert(YES==NO, @"Stream: regernerating blocks, blocker class %@ not found", [anAna valueForKey:@"anaylizerKind"]);
            }
        }
    }
    
    /* delete any blocks still marked for deletion */
    [self deleteBlocksMarkedForDeletion];
    
    [self didChangeValueForKey:@"blocks"];
}

- (void) markBlocksForDeletion
{
    regeneratingBlocks = YES;
    
    /* mark all blocks for deletion */
    NSMutableSet *allBlocks = [self mutableSetValueForKey:@"blocks"];
    [allBlocks enumerateObjectsUsingBlock:^(id obj, BOOL *stop)
     {
#pragma unused(stop)
         StBlock *theBlock = obj;
         [theBlock setMarkForDeletion:YES];
         
         NSMutableSet *subBlocks = [theBlock mutableSetValueForKey:@"blocks"];
         [subBlocks enumerateObjectsUsingBlock:^(id obj, BOOL *stop)
          {
#pragma unused(stop)
              StBlock *theSubBlock = obj;
              [theSubBlock setMarkForDeletion:YES];
              
              NSMutableSet *subSubBlocks = [theSubBlock mutableSetValueForKey:@"blocks"];
              [subSubBlocks enumerateObjectsUsingBlock:^(id obj, BOOL *stop)
               {
#pragma unused(stop)
                   StBlock *theSubSubBlock = obj;
                   [theSubSubBlock setMarkForDeletion:YES];
               }];
          }];
     }];
}

- (void) deleteBlocksMarkedForDeletion
{
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"markForDeletion == YES", self ];
    [request setPredicate:predicate];
    NSError *error = nil;
    NSArray *resultBlockArray = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if( error == nil )
    {
        if( resultBlockArray != nil)
        {
            /* notify blocker views of impending deletes */
            for( StAnaylizer *anAna in [self anaylizers] )
            {
                if( [anAna.currentEditorView respondsToSelector:@selector(notifyOfImpendingDeletion:)] )
                {
                    [anAna.viewController setRepresentedObject:resultBlockArray];
                }
            }
            
            /* delete marked blocks */
            for (StBlock *aBlock in resultBlockArray)
            {
                if( aBlock.source == nil )
                {
                    if( aBlock.parentStream != nil )
                    {
                        /* This is a top level block */
                        NSMutableSet *parentStreamBlocks = [aBlock.parentStream mutableSetValueForKey:@"blocks"];
                        [parentStreamBlocks removeObject:aBlock];
                    }
                    else
                    {
                        /* This is a midlevel block */
                        NSMutableSet *parentBlockSet = [aBlock.parentBlock mutableSetValueForKey:@"blocks"];
                        [parentBlockSet removeObject:aBlock];
                    }
                }
                else
                {
                    /* This is a leaf block */
                    NSMutableSet *parentBlockSet = [aBlock.parentBlock mutableSetValueForKey:@"blocks"];
                    [parentBlockSet removeObject:aBlock];
                }
            }
        }
    }
    else
        NSAssert(YES==NO, @"deleteBlocksMarkedForDeletion: Error fetching marked for deletion block", error);
    
    regeneratingBlocks = NO;
}

- (BOOL)isBlockEdited:(NSString *)blockName
{
    StBlock *aBlock = [self topLevelBlockNamed:blockName];
    return [aBlock isEdit];
}

- (BOOL)isBlockFailed:(NSString *)blockName
{
    StBlock *aBlock = [self topLevelBlockNamed:blockName];
    return [aBlock isFail];
}

- (void)willTurnIntoFault
{
    self.topLevelBlocks = nil;
}

@end
