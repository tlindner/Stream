//
//  StStream.m
//  temp
//
//  Created by tim lindner on 5/8/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "StStream.h"
#import "StAnalyzer.h"
#import "StBlock.h"
#import "StStream.h"
#import "Blockers.h"

@implementation StStream

@dynamic customSortOrder;
@dynamic displayName;
@dynamic modificationDateofURL;
@dynamic regeneratingBlocks;
@dynamic sourceURL;
@dynamic sourceUTI;
@dynamic streamTransform;
@dynamic topLevelBlocks;
@dynamic analyzers;
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
        result = [[[self lastFilterAnalyzer] analyzerObject] resultingData];
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
            newBlock.analyzerKind = owner;
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
        newBlock.analyzerKind = owner;
       
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

- (StAnalyzer *)lastFilterAnalyzer
{
    for (StAnalyzer *anAnalyzer in [[self analyzers] reversedOrderedSet])
    {
        if( ![anAnalyzer.currentEditorView isEqualToString:@"Blocker View"] )
        {
            return anAnalyzer;
        }
    }
    
    NSLog( @"StStream: lastFilterAnalyzer did not find a last filter analyzer" );
    return nil;
}

- (StAnalyzer *)previousAnalyzer:(StAnalyzer *)inAna
{
    NSUInteger theIndex = [[self analyzers] indexOfObject:inAna];
    
    if( theIndex == 0 )
        return nil;
    else
        return [[self analyzers] objectAtIndex:theIndex - 1];
}

- (NSArray *)blocksWithAnalyzerKey:(NSString *)key
{
    NSMutableArray *result = [[[NSMutableArray alloc] init] autorelease];
    
    for (StBlock *aBlock in self.blocks) {
        if ([aBlock.analyzerKind isEqualToString:key]) {
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
    StAnalyzer *lastAaylizer = [self lastFilterAnalyzer];
    
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
    [self markTopLevelBlocksForDeletion];
    self.topLevelBlocks = nil;
    
    /* reset fail index set */
    [[[self lastFilterAnalyzer] failIndexSet] removeAllIndexes];
    
    [self willChangeValueForKey:@"blocks"];
    [[[self analyzers] array] makeObjectsPerformSelector:@selector(suspendObservations)];

    /* Regenerate blocks using blockers */
    for( StAnalyzer *anAna in [self analyzers] )
    {
        if( [anAna.currentEditorView isEqualToString:@"Blocker View"] )
        {
            Class blockerClass = NSClassFromString([anAna valueForKey:@"analyzerKind"]);
            
            if (blockerClass != nil )
            {
                Blockers *blocker = [[blockerClass alloc] init];
                anAna.errorString = [blocker makeBlocks:self withAnalyzer:anAna];
                [blocker release];
            }
            else
            {
                NSAssert(YES==NO, @"Stream: regernerating blocks, blocker class %@ not found", [anAna valueForKey:@"analyzerKind"]);
            }
        }
    }
    
    /* delete any blocks still marked for deletion */
    [self deleteTopLevelBlocksMarkedForDeletion];
    
    [[[self analyzers] array] makeObjectsPerformSelector:@selector(resumeObservations)];
    [self didChangeValueForKey:@"blocks"];
}

- (void) markTopLevelBlocksForDeletion
{
    regeneratingBlocks = YES;
    
    /* recursive mark all blocks for deletion */
    [[self.blocks allObjects] makeObjectsPerformSelector:@selector(makeMarkForDeletion)];
}

- (void) deleteTopLevelBlocksMarkedForDeletion
{
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"markForDeletion == YES" ];
    [request setPredicate:predicate];
    NSError *error = nil;
    NSArray *resultBlockArray = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if( error == nil )
    {
        if( resultBlockArray != nil)
        {
            /* notify blocker views of impending deletes */
            for( StAnalyzer *anAna in [self analyzers] )
            {
                if( [anAna.currentEditorView respondsToSelector:@selector(notifyOfImpendingDeletion:)] )
                {
                    [anAna.viewController setRepresentedObject:resultBlockArray];
                }
            }
            
            /* delete marked blocks */
            [self removeBlocks:[NSSet setWithArray:resultBlockArray]];
            
            for (StBlock *aBlock in resultBlockArray) {
                [[self managedObjectContext] deleteObject:aBlock];
            }
        }
        
        for (StBlock *block in self.blocks) {
            [block cleanUpSubBlocks];
        }
        
        self.topLevelBlocks = nil;
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
