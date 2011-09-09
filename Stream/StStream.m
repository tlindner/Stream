//
//  Stream.m
//  Stream
//
//  Created by tim lindner on 8/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "StStream.h"

@implementation StStream

@dynamic bytesCache;
@dynamic customeSortOrder;
@dynamic displayName;
@dynamic modificationDateofURL;
@dynamic parentBlock;
@dynamic sourceURL;
@dynamic sourceUTI;
@dynamic streamTransform;
@dynamic anaylizers;
@dynamic blocks;
@dynamic childStreams;
@dynamic parentStream;

- (NSData *)dataOfBlockNamed:(NSString *)name
{
    NSData *result = nil;
    
    if( [name isEqualToString:@"stream"] )
    {
        NSOrderedSet *anaylizers = [self.anaylizers reversedOrderedSet];
        
        for (StAnaylizer *anAna in anaylizers)
        {
            if( anAna.resultingData != nil )
            {
                result = anAna.resultingData;
            }
        }
        
        if( result == nil )
            result = self.bytesCache;
        
        return result;
    }
    else
    {
        /* find block and returned it's data */
        return [[self blockNamed:name] getData];
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
        else
            NSAssert(YES==NO, @"blockNamed: zero, or more than one blocks found: %@", resultBlockArray);
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

- (void) setBlock:(StBlock *)theBlock withData:(NSData *)theData
{
    NSUInteger index, length = [theData length];
    unsigned char *bytes = (unsigned char *)[theData bytes];
    
    for( index = 0; index<length; index ++ )
    {
        [theBlock writeByte:bytes[index] atOffset:index];
    }
}












@end
