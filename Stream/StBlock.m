//
//  StBlock.m
//  Stream
//
//  Created by tim lindner on 8/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "StBlock.h"
#import "StStream.h"
#import "Analyzation.h"
#import "HexFiendAnaylizer.h"

@implementation StBlock
@dynamic anaylizerKind;
@dynamic expectedSize;
@dynamic name;
@dynamic type;
@dynamic offset;
@dynamic length;
@dynamic valueTransformer;
@dynamic uiName;
@dynamic checkBytes;
@dynamic source;
@dynamic index;
@dynamic parentStream;
@dynamic parentBlock;
@dynamic blocks;
@dynamic sourceUTI;
@dynamic currentEditorView;
@dynamic optionsDictionary;
@dynamic isFail;
@dynamic isEdit;
@dynamic canChangeEditor;
@dynamic markForDeletion;

@dynamic data;
@dynamic dataForUI;
@dynamic checkBytesForUI;
@dynamic attributeColor;
@dynamic editSet;

- (void)awakeFromInsert
{
    self.optionsDictionary = [[[NSMutableDictionary alloc] init] autorelease];
}

- (NSObject *)anaylizerObject
{
    Class anaObjectClass = [[Analyzation sharedInstance] anaylizerClassforName:self.currentEditorView];
    
    if( anaObjectClass == nil )
        anaObjectClass = [HexFiendAnaylizer class];
    
    if( anaylizerObject == nil )
    {
        anaylizerObject = [[anaObjectClass alloc] init];
        [anaylizerObject setRepresentedObject:self];
    }
    else if( ![[anaylizerObject class] isSubclassOfClass:[[Analyzation sharedInstance] anaylizerClassforName:self.currentEditorView]] )
    {
        [anaylizerObject setRepresentedObject:nil];
        [anaylizerObject release];
        
        anaylizerObject = [[anaObjectClass alloc] init];
        [anaylizerObject setRepresentedObject:self];
    }
    
    return anaylizerObject;
}

- (void)dealloc
{
    if( anaylizerObject != nil )
    {
        [anaylizerObject setRepresentedObject:nil];
        [anaylizerObject release];
    }
    
    [super dealloc];
}

- (void) addSubOptionsDictionary:(NSString *)subOptionsID withDictionary:(NSMutableDictionary *)newOptions
{
    NSMutableDictionary *ourOptDict = self.optionsDictionary;
    
    if( [ourOptDict valueForKey:subOptionsID] == nil )
    {
        [ourOptDict setObject:newOptions forKey:subOptionsID];
        return;
    }
    
    NSMutableDictionary *dict = [ourOptDict objectForKey:subOptionsID];
    
    for (NSString *key in [newOptions allKeys])
    {
        id value = [dict objectForKey:key];
        
        if( value == nil )
            [dict setObject:[newOptions objectForKey:key] forKey:key];
    }
}

- (NSData *)data
{
    return [self getData];
}

- (StStream *)getStream
{
    if( self.parentStream != nil )
        return self.parentStream;
    else
        return [self.parentBlock getStream];
}

- (void) resetCounters
{
    dataIndex = attrIndex = depIndex = 0;
}

- (void) addAttributeRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name
{
    [self addAttributeRange:blockName start:start length:length name:name verification:nil transformation:nil];
}

- (void) addAttributeRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify
{
    [self addAttributeRange:blockName start:start length:length name:name verification:verify transformation:nil];
}

- (void) addAttributeRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify transformation:(NSString *)transform
{
    StBlock *attributeBlock = [self subBlockNamed:@"attributes"];
    StBlock *newBlock = [attributeBlock subBlockAtIndex:attrIndex];
    
    if( newBlock != nil )
    {
        newBlock.markForDeletion = NO;
        newBlock.isEdit = NO;
        newBlock.isFail = NO;
    }
    else
    {
        newBlock = [NSEntityDescription insertNewObjectForEntityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
        [attributeBlock addBlocksObject:newBlock];
    }
    
    newBlock.name = [NSString stringWithFormat:@"%d: %@, %d, %d", attrIndex, blockName, start, length];
    newBlock.source = blockName;
    newBlock.uiName = name;
    newBlock.offset = start;
    newBlock.length = length;
    newBlock.index = attrIndex++;
    newBlock.checkBytes = verify;
    newBlock.valueTransformer = transform;

    [self checkEdited:newBlock];
    [self checkFail:newBlock];
}

- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length
{
    [self addDataRange:blockName start:start length:length name:nil verification:nil transformation:nil];
}

- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name
{
    [self addDataRange:blockName start:start length:length name:name verification:nil transformation:nil];
}

- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify
{
    [self addDataRange:blockName start:start length:length name:name verification:verify transformation:nil];
}

- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name transformation:(NSString *)transform
{
    [self addDataRange:blockName start:start length:length name:name verification:nil transformation:transform];
}

- (void) addDataRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify transformation:(NSString *)transform
{
    StBlock *dataBlock = [self subBlockNamed:@"data"];
    StBlock *newBlock = [dataBlock subBlockAtIndex:dataIndex];
    
    if( newBlock != nil )
    {
        newBlock.markForDeletion = NO;
        newBlock.isEdit = NO;
        newBlock.isFail = NO;
    }
    else
    {
        newBlock = [NSEntityDescription insertNewObjectForEntityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
        [dataBlock addBlocksObject:newBlock];
        
        if( name != nil || verify != nil || transform != nil )
        {
            dataBlock.sourceUTI = @"org.macmess.stream.attribute";
            dataBlock.currentEditorView = @"Block Attribute View";
        }
    }
    
    newBlock.name = [NSString stringWithFormat:@"%d: %@, %d, %d", dataIndex, blockName, start, length];
    newBlock.uiName = name;
    newBlock.source = blockName;
    newBlock.offset = start;
    newBlock.length = length;
    newBlock.index = dataIndex++;
    newBlock.checkBytes = verify;
    newBlock.valueTransformer = transform;
    
    [dataBlock addBlocksObject:newBlock];
    self.expectedSize += length;
    
    [self checkEdited:newBlock];
    [self checkFail:newBlock];
}

- (void) addDependenciesRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify transformation:(NSString *)transform;
{
    StBlock *depBlock = [self subBlockNamed:@"dependencies"];
    StBlock *newBlock = [depBlock subBlockAtIndex:depIndex];
    
    if( newBlock != nil )
    {
        newBlock.markForDeletion = NO;
        newBlock.isEdit = NO;
        newBlock.isFail = NO;
    }
    else
    {
        newBlock = [NSEntityDescription insertNewObjectForEntityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
        [depBlock addBlocksObject:newBlock];
    }
    
    newBlock.name = [NSString stringWithFormat:@"%d: %@, %d, %d", dataIndex, blockName, start, length];
    newBlock.uiName = name;
    newBlock.source = blockName;
    newBlock.offset = start;
    newBlock.length = length;
    newBlock.index = depIndex++;
    newBlock.checkBytes = verify;
    newBlock.valueTransformer = transform;
    [depBlock addBlocksObject:newBlock];
    self.expectedSize += length;

    [self checkEdited:newBlock];
    [self checkFail:newBlock];
}

- (void) checkEdited:(StBlock *)newBlock
{
    if( [newBlock.source isEqualToString:@"stream"] )
    {
        if( [[[self getStream] lastFilterAnayliser] streamEditedInRange:NSMakeRange(newBlock.offset, newBlock.length)] )
        {
            [newBlock smartSetEdit];
        }
    }
    else if( [[self getStream] isBlockEdited:newBlock.source] )
    {
        [newBlock smartSetEdit];
    }
}

- (void) checkFail:(StBlock *)newBlock
{
    if( newBlock.checkBytes != nil )
    {
        if( ![newBlock.checkBytes isEqualToData:[newBlock getData]] )
        {
            [newBlock smartSetFail];
        }
    }
    
    if( ![newBlock.source isEqualToString:@"stream"] )
    {
        if( [[self getStream] isBlockFailed:newBlock.source] )
        {
            [newBlock smartSetFail];
        }
    }
}

- (StBlock *)subBlockNamed:(NSString *)inName
{
    void *predicate = ^(id obj, BOOL *stop)
    {
        StBlock *test = (StBlock *)obj;
        
        if ([test.name isEqualToString:inName])
        {
            *stop = YES;
            return YES;
        }
        
        return NO;
    };
    
    NSSet *dataBlockSet = [self.blocks objectsPassingTest:predicate];
    NSAssert( [dataBlockSet count] == 1, @"StBlock: blockNamed: could not find block named: %@", inName );
    return [dataBlockSet anyObject];
}

- (StBlock *)subBlockAtIndex:(NSInteger)theIndex
{
    for (StBlock *aBlock in [self blocks])
    {
        if( aBlock.index == theIndex )
            return aBlock;
    }

    return nil;
}

- (NSData *)getData
{
    NSMutableData *result;
    
    if( self.source == nil )
    {
        if( self.parentStream != nil )
        {
            /* This is a top level block, return data from data block */
            return [[self subBlockNamed:@"data"] getData];
        }
        else
        {
            /* This is a midlevel block, return it's accumulated blocks */
            
            StStream *ourStream = [self getStream];
            result = [[[NSMutableData alloc] init] autorelease];
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
            NSArray *subBlocks = [self.blocks sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            
            for (StBlock *theBlock in subBlocks)
            {
                NSData *blockData = [ourStream dataOfBlockNamed:theBlock.source];
                NSUInteger useLength;
                
                if( theBlock.length == 0 )
                {
                    /* length of zero means "to the end of the block" */
                    useLength = [blockData length] - theBlock.offset;
                }
                else
                    useLength = theBlock.length;
                
                NSRange theRange = NSMakeRange(theBlock.offset, useLength);
                [result appendData:[blockData subdataWithRange:theRange]];
            }
        }
    }
    else
    {
        /* This is a leaf block */
        StStream *ourStream = [self getStream];
        NSData *blockData = [ourStream dataOfBlockNamed:self.source];
        NSUInteger useLength;
        
        if( self.length == 0 )
        {
            /* length of zero means "to the end of the block" */
            useLength = [blockData length] - self.offset;
        }
        else
            useLength = self.length;
        
        NSRange theRange = NSMakeRange(self.offset, useLength);
        result = [[blockData subdataWithRange:theRange] mutableCopy];
        [result autorelease];
    }
    
    return result;
}

- (NSArray *)getArrayOfBlocks
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    if( self.source == nil )
    {
        if( self.parentStream != nil )
        {
            /* This is a top level block, return blocks from data block */
            [result addObjectsFromArray:[[self subBlockNamed:@"data"] getArrayOfBlocks]];
        }
        else
        {
            /* This is a midlevel block, return it's accumulated blocks */
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
            NSArray *subBlocks = [self.blocks sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            
            for (StBlock *aBlock in subBlocks)
            {
                [result addObjectsFromArray:[aBlock getArrayOfBlocks]];
            }
        }
    }
    else
    {
        /* This is a leaf block */
        [result addObject:self];
    }
    
    return [result autorelease];
}

- (NSString *)description
{
    if( self.source == nil )
    {
        if( self.parentStream != nil )
        {
            return [NSString stringWithFormat:@"%p: Top level block named: %@", self, [self name]];
        }
        else
        {
            return [NSString stringWithFormat:@"%p: Mid level block:%@, named: %@", self, [[self parentBlock] name], [self name]];
        }
    }
    else
    {
        return [NSString stringWithFormat:@"%p: Leaf block: %@, named: %@, index: %d, source: %@, start: %d, lenth: %d", self, [[[self parentBlock] parentBlock] name], [[self parentBlock] name], [self index], [self source], self.offset, self.length];
    }
}

- (BOOL) writeByte:(unsigned char)byte atOffset:(NSUInteger)offset
{
    NSArray *blockArray = [self getArrayOfBlocks];
    NSUInteger place = 0;
    BOOL byteWritten = NO;
    
    [self smartSetEdit];
    
    for (StBlock *aBlock in blockArray)
    {
        if( offset < place + aBlock.length )
        {
            /* we found the block to write to */
            if( [aBlock.source isEqualToString:@"stream"] )
            {
                /* writing to stream */
                [[[self getStream] lastFilterAnayliser] writebyte:byte atOffset:aBlock.offset + (offset - place)];
                byteWritten = YES;
                break;
            }
            else
            {
                StBlock *subBlock = [[self getStream] blockNamed:aBlock.source];
                byteWritten = [subBlock writeByte:byte atOffset:offset - place];
            }
        }
        else
            place += aBlock.length;
    }
    
    NSAssert(byteWritten == YES, @"Tried writing byte past end of block: %@, offset: %d", [self source], [self offset]);
    return byteWritten;
}

- (void) smartSetEdit
{
    if( self.source == nil )
    {
        if( self.parentStream != nil )
        {
            /* top-level block */
            self.isEdit = YES;
        }
        else
        {
            /* mid-level block */
            self.isEdit = self.parentBlock.isEdit = YES;
        }
    }
    else
    {
        /* leaf block */
        self.isEdit = self.parentBlock.isEdit = self.parentBlock.parentBlock.isEdit = YES;
    }
}

- (void) smartSetFail
{
    if( self.source == nil )
    {
        if( self.parentStream != nil )
        {
            /* top-level block */
            self.isFail = YES;
        }
        else
        {
            /* mid-level block */
            self.isFail = self.parentBlock.isFail = YES;
        }
    }
    else
    {
        /* leaf block */
        self.isFail = self.parentBlock.isFail = self.parentBlock.parentBlock.isFail = YES;
        
        if( [self.source isEqualToString:@"stream"] )
        {
            NSRange range = {self.offset, self.length};
            [[[self getStream] lastFilterAnayliser].failIndexSet addIndexesInRange:range];
        }

    }
}

+ (NSSet *)keyPathsForValuesAffectingDataForUI
{
    return [NSSet setWithObjects:@"data", @"valueTransformer", nil];
}

- (NSDictionary *)dataForUI
{
    NSDictionary *result = nil;
    
    if( self.data != nil )
        result = [NSDictionary dictionaryWithObjectsAndKeys: self.data, @"value", self.valueTransformer, @"valueTransformer", @"data", @"key", [self objectID], @"objectID", nil];
    
    return result;
}

- (void) setDataForUI:(NSDictionary *)dictionary
{
    /* parse string and pass change up the block chain */
    NSString *mode = [dictionary objectForKey:@"mode"];
    id value = [dictionary objectForKey:@"value"];
    
    NSValueTransformer *vt = [NSValueTransformer valueTransformerForName:self.valueTransformer];
    
    if( [[[vt class] transformedValueClass] isSubclassOfClass:[NSNumber class]] )
    {
        NSString *string = value;
        
        if( [string hasPrefix:@"0x"] )
            mode = @"Hexadecimal";
        
        NSUInteger result = 0;
        
        if( [mode isEqualToString:@"Hexadecimal"] )
        {
            /* convert number from hexidecimal to decimal */
            unsigned long long tempResult;
            [[NSScanner scannerWithString: string] scanHexLongLong:&tempResult];
            value = [NSNumber numberWithUnsignedLongLong:tempResult];
        }
        else
        {
            result = [value integerValue];
            value = [NSNumber numberWithUnsignedInteger:result];
        }
    }
    
    NSData *theData = [vt reverseTransformedValue:value ofSize:[self length]];
    
    [[self getStream] setBlock:self withData:theData];
}

+ (NSSet *)keyPathsForValuesAffectingCheckBytesForUI
{
    return [NSSet setWithObjects:@"checkBytes", @"valueTransformer", nil];
}

- (NSDictionary *)checkBytesForUI
{
    NSDictionary *result = nil;
    
    if( self.checkBytes != nil )
        result = [NSDictionary dictionaryWithObjectsAndKeys: self.checkBytes, @"value", self.valueTransformer, @"valueTransformer", @"checkBytes", @"key", [self objectID], @"objectID", nil];
    
    return result;
}

+ (NSSet *)keyPathsForValuesAffectingAttributeColor
{
    return [NSSet setWithObjects:@"isEdit", @"isFail", nil];
}

- (NSColor *)attributeColor
{
    if( self.isEdit && self.isFail )
        return [NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.0 alpha:0.5];
    else if( self.isEdit )
        return [NSColor colorWithCalibratedRed:0.0 green:1.0 blue:0.0 alpha:0.5];
    else if( self.isFail )
        return [NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0.0 alpha:0.5];
    
    return nil;
}

- (NSMutableIndexSet *)editSet
{
    NSMutableIndexSet *indexSet = [[NSMutableIndexSet alloc] init];
    
    if( self.source == nil )
    {
        if( self.parentStream != nil )
        {
            /* top level block */
            [indexSet addIndexes:[[self subBlockNamed:@"data"] editSet]];
        }
        else
        {
            /* mid level block */
            NSInteger shiftAmount = 0;
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"index" ascending:YES];
            NSArray *subBlocks = [self.blocks sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            
            for (StBlock *aBlock in subBlocks)
            {
                NSMutableIndexSet *set = [aBlock editSet];
                [set shiftIndexesStartingAtIndex:0 by:shiftAmount];
                [indexSet addIndexes:set];
                shiftAmount += aBlock.length;
            }
        }
    }
    else
    {
        /* leaf block */
        if( [self.source isEqualToString:@"stream"] )
        {
            NSRange range = {self.offset, self.length};
            StAnaylizer *lastFilterAnaylizer = [[self getStream] lastFilterAnayliser];
            NSIndexSet *set = lastFilterAnaylizer.editIndexSet;
            NSMutableIndexSet *setInRange = [[set indexesInRange:range options:0 passingTest:^(NSUInteger idx, BOOL *stop){ return YES; }] mutableCopy];
            [setInRange shiftIndexesStartingAtIndex:0 by:-self.offset];
            [indexSet addIndexes:setInRange];
            [setInRange release];
        }
        else
        {
            NSRange range = {self.offset, self.length};
            NSMutableIndexSet *set = [[[self getStream] blockNamed:self.source] editSet];
            NSMutableIndexSet *setInRange = [[set indexesInRange:range options:0 passingTest:^(NSUInteger idx, BOOL *stop){ return YES; }] mutableCopy];
            [setInRange shiftIndexesStartingAtIndex:0 by:-self.offset];
            [indexSet addIndexes:setInRange];
            [setInRange release];
        }
    }
    
    return [indexSet autorelease];
}

- (void)willTurnIntoFault
{
    if( anaylizerObject != nil)
    {
        [anaylizerObject setRepresentedObject:nil];
    }
}

- (BOOL) canChangeEditor
{
    return YES;
}

@end

@implementation StBlockFormatter

@synthesize mode;

- (NSString *)stringForObjectValue:(id)anObject
{
    id result;
    
    if( [anObject isKindOfClass:[NSDictionary class]] )
    {
        NSDictionary *inDict = anObject;
        NSString *valueTransformerString = [inDict objectForKey:@"valueTransformer"];
        
        if( valueTransformerString == nil )
        {
            /* a dictionary without a value transformer is from the reverse formatter */
            result = [inDict objectForKey:@"value"];
        }
        else
        {
            /* a dictionary with no value transformer is straight from the block object */
            NSValueTransformer *vt = [NSValueTransformer valueTransformerForName:valueTransformerString];
            result = [vt transformedValue:[inDict objectForKey:@"value"]];
            
            if( ![result isKindOfClass:[NSString class]] )
            {
                if( [self.mode isEqualToString:@"Decimal"] )
                    result = [result stringValue];
                else
                {
                    result = [NSString stringWithFormat:@"0x%x", [result intValue]];
                }
            }
        }
    }
    else if( [anObject isKindOfClass:[NSString class]] )
    {
        result = anObject;
    }
    else
        result = nil;
    
    return result;
}

- (BOOL)getObjectValue:(id *)anObject forString:(NSString *)string errorDescription:(NSString **)error
{
    if( [[string class] isSubclassOfClass:[NSString class]] )
    {
        /* just send the string back, we'll parse in the StBlock */
        *anObject = [NSDictionary dictionaryWithObjectsAndKeys:mode, @"mode", string, @"value", nil];
        return YES;
    }
    else
    {
        NSLog( @"Incomming string not string: %@", string );
        return NO;
    }
}

@end
