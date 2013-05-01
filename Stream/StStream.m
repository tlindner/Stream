//
//  Stream.m
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "StStream.h"
#import "BlockerProtocol.h"
#import "Analyzation.h"

@implementation StStream

@dynamic bytesCache;
@dynamic customeSortOrder;
@dynamic displayName;
@dynamic modificationDateofURL;
@dynamic sourceURL;
@dynamic sourceUTI;
@dynamic streamTransform;
@dynamic anaylizers;
@dynamic edits;
@dynamic blocks;
@dynamic childStreams;
@dynamic parentStream;
@dynamic sourceBlock;

- (NSData *)dataOfBlockNamed:(NSString *)name
{
    NSData *result = nil;
    
    if( [name isEqualToString:@"stream"] )
    {
        result = [[self lastFilterAnayliser] resultingData];
    }
    else
    {
        /* find block and returned it's data */
        result = [[self blockNamed:name] getData];
    }
    
    return result;
}

- (StBlock *)blockNamed:(NSString *)theName
{
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(parentStream == %@) AND (name == %@)", self, theName ];
    [request setPredicate:predicate];
    NSError *error = nil;
    NSArray *resultBlockArray = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if( error == nil )
    {
        if( resultBlockArray != nil && [resultBlockArray count] == 1 )
        {
            return [resultBlockArray objectAtIndex:0];
        }
        else if( resultBlockArray != nil && [resultBlockArray count] > 1 )
        {
            NSAssert(YES==NO, @"blockNamed: more than one blocks named: %@ found: %@", theName, resultBlockArray);
        }
    }
    else
        NSAssert(YES==NO, @"blockNamed: Error fetching block: %@", error);
    
    return nil;
}

- (StBlock *)startNewBlockNamed:(NSString *)name owner:(NSString *)owner
{
    if( [name isEqualToString:@"stream"] )
    {
        NSLog( @"StStream: Can not create block named: stream" );
        return nil;
    }
    
    StBlock *newBlock = [self blockNamed:name];
    
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

            [newBlock subBlockNamed:@"data"].markForDeletion = NO;
            [newBlock subBlockNamed:@"data"].isEdit = NO;
            [newBlock subBlockNamed:@"data"].isFail = NO;
//            [newBlock subBlockNamed:@"data"].currentEditorView = @"Hex Editor";
//            [newBlock subBlockNamed:@"data"].sourceUTI = @"public.data";
            
            [newBlock subBlockNamed:@"attributes"].markForDeletion = NO;
            [newBlock subBlockNamed:@"attributes"].isEdit = NO;
            [newBlock subBlockNamed:@"attributes"].isFail = NO;
//            [newBlock subBlockNamed:@"attributes"].currentEditorView = @"Block Attribute View";
//            [newBlock subBlockNamed:@"attributes"].sourceUTI = @"org.macmess.stream.attribute";
            
            [newBlock subBlockNamed:@"dependencies"].markForDeletion = NO;
            [newBlock subBlockNamed:@"dependencies"].isEdit = NO;
            [newBlock subBlockNamed:@"dependencies"].isFail = NO;
//            [newBlock subBlockNamed:@"dependencies"].currentEditorView = @"Hex Editor";
//            [newBlock subBlockNamed:@"dependencies"].sourceUTI = @"public.data";
            
            [newBlock subBlockNamed:@"intrinsic"].markForDeletion = NO;
            [newBlock subBlockNamed:@"intrinsic"].isEdit = NO;
            [newBlock subBlockNamed:@"intrinsic"].isFail = NO;
//            [newBlock subBlockNamed:@"intrinsic"].currentEditorView = @"Hex Editor";
//            [newBlock subBlockNamed:@"intrinsic"].sourceUTI = @"public.data";
            
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
    
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(parentStream == %@) AND (name == %@)", self, name ];
    [request setPredicate:predicate];
    NSError *error = nil;
    NSArray *result = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if( error == nil )
    {
        if( result != nil && [result count] == 0 )
        {
            /* ok, create new block */
            StBlock *newBlock = [NSEntityDescription insertNewObjectForEntityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
            newBlock.name = name;
            newBlock.anaylizerKind = owner;
            [self addBlocksObject:newBlock];
            
            StBlock *newDataBlock = [NSEntityDescription insertNewObjectForEntityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
            newDataBlock.name = @"data";
            newDataBlock.sourceUTI = @"public.data";
            [newBlock addBlocksObject:newDataBlock];
            
            StBlock *newAttributeBlock = [NSEntityDescription insertNewObjectForEntityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
            newAttributeBlock.name = @"attributes";
            newAttributeBlock.sourceUTI = @"org.macmess.stream.attribute";
            newAttributeBlock.currentEditorView = @"Block Attribute View";
            [newBlock addBlocksObject:newAttributeBlock];
            
            StBlock *newdependenciesBlock = [NSEntityDescription insertNewObjectForEntityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
            newdependenciesBlock.name = @"dependencies";
            newdependenciesBlock.sourceUTI = @"public.data";
            [newBlock addBlocksObject:newdependenciesBlock];
            
            StBlock *newIntrinsicsBlock = [NSEntityDescription insertNewObjectForEntityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
            newIntrinsicsBlock.name = @"intrinsic";
            newIntrinsicsBlock.sourceUTI = @"public.data";
            [newBlock addBlocksObject:newIntrinsicsBlock];
            
            return newBlock;
        }
        else
            NSLog( @"startNewBlockNamed: block already exists: %@", name );
    }
    else
        NSLog(@"startNewBlockNamed: fetch error: %@", error);
    
    return nil;
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

- (NSArray *)blocksWithKey:(NSString *)key
{
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
    [request setEntity:entity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(parentStream == %@) AND (anaylizerKind == %@)", self, key ];
    [request setPredicate:predicate];
    NSError *error = nil;
    NSArray *result = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if( error == nil )
        return result;
    else
    {
        NSLog( @"Error during blocksWithKey fetch: %@", key );
        return nil;
    }    
}

- (void)setBlock:(StBlock *)theBlock withData:(NSData *)theData
{
    [self setBlock:theBlock withData:theData inRange:NSMakeRange(0, [theData length])];
}

- (void) setBlock:(StBlock *)theBlock withData:(NSData *)theData inRange:(NSRange)range
{
    NSUInteger index, end = NSMaxRange(range);
    unsigned char *bytes = (unsigned char *)[theData bytes];
    const unsigned char *orginalBytes = [[theBlock getData] bytes];
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
                [blockerClass makeBlocks:self];
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
         StBlock *theBlock = obj;
         [theBlock setMarkForDeletion:YES];
         
         NSMutableSet *subBlocks = [theBlock mutableSetValueForKey:@"blocks"];
         [subBlocks enumerateObjectsUsingBlock:^(id obj, BOOL *stop)
          {
              StBlock *theSubBlock = obj;
              [theSubBlock setMarkForDeletion:YES];
              
              NSMutableSet *subSubBlocks = [theSubBlock mutableSetValueForKey:@"blocks"];
              [subSubBlocks enumerateObjectsUsingBlock:^(id obj, BOOL *stop)
               {
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
    StBlock *aBlock = [self blockNamed:blockName];
    return [aBlock isEdit];
}

- (BOOL)isBlockFailed:(NSString *)blockName
{
    StBlock *aBlock = [self blockNamed:blockName];
    return [aBlock isFail];
}

@end
