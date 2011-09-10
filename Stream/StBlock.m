//
//  StBlock.m
//  Stream
//
//  Created by tim lindner on 8/27/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "StBlock.h"
#import "StStream.h"


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

@dynamic data;
@dynamic dataForUI;
@dynamic checkBytesForUI;

- (void)awakeFromInsert
{
    self.optionsDictionary = [[[NSMutableDictionary alloc] init] autorelease];
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
    StBlock *newBlock = [NSEntityDescription insertNewObjectForEntityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
    newBlock.name = [NSString stringWithFormat:@"%d: %@, %d, %d", attrIndex, blockName, start, length];
    newBlock.source = blockName;
    newBlock.uiName = name;
    newBlock.offset = start;
    newBlock.length = length;
    newBlock.index = attrIndex++;
    newBlock.checkBytes = verify;
    newBlock.valueTransformer = transform;
    [attributeBlock addBlocksObject:newBlock];
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
    StBlock *newBlock = [NSEntityDescription insertNewObjectForEntityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
    newBlock.name = [NSString stringWithFormat:@"%d: %@, %d, %d", dataIndex, blockName, start, length];
    newBlock.uiName = name;
    newBlock.source = blockName;
    newBlock.offset = start;
    newBlock.length = length;
    newBlock.index = dataIndex++;
    newBlock.checkBytes = verify;
    newBlock.valueTransformer = transform;
    
    if( name != nil || verify != nil || transform != nil )
    {
        dataBlock.sourceUTI = @"org.macmess.stream.attribute";
        dataBlock.currentEditorView = @"Block Attribute View";
    }
    
    [dataBlock addBlocksObject:newBlock];
    self.expectedSize += length;
}

- (void) addDependenciesRange:(NSString *)blockName start:(NSUInteger)start length:(NSUInteger)length name:(NSString *)name verification:(NSData *)verify transformation:(NSString *)transform;
{
    StBlock *depBlock = [self subBlockNamed:@"dependencies"];
    StBlock *newBlock = [NSEntityDescription insertNewObjectForEntityForName:@"StBlock" inManagedObjectContext:self.managedObjectContext];
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
                NSRange theRange = NSMakeRange(theBlock.offset, theBlock.length);
                [result appendData:[blockData subdataWithRange:theRange]];
            }
        }
    }
    else
    {
        /* This is a leaf block */
        StStream *ourStream = [self getStream];
        NSData *blockData = [ourStream dataOfBlockNamed:self.source];
        NSRange theRange = NSMakeRange(self.offset, self.length);
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
            return [NSString stringWithFormat:@"Top level block named: %@", [self name]];
        }
        else
        {
            return [NSString stringWithFormat:@"Mid level block:%@, named: %@", [[self parentBlock] name], [self name]];
        }
    }
    else
    {
        return [NSString stringWithFormat:@"Leaf block: %@, named: %@, index: %d, source: %@, start: %d, lenth: %d", [[[self parentBlock] parentBlock] name], [[self parentBlock] name], [self index], [self source], self.offset, self.length];
    }
}

- (BOOL) writeByte:(unsigned char)byte atOffset:(NSUInteger)offset
{
    NSArray *blockArray = [self getArrayOfBlocks];
    NSUInteger place = 0;
    BOOL byteWritten = NO;
    
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
    
    NSAssert(byteWritten == YES, @"Tried writing byte past end of block: %@, offset: %d", [self name], [self offset]);
    return byteWritten;
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
            result = (NSUInteger)tempResult;
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

- (NSDictionary *)checkBytesForUI
{
    NSDictionary *result = nil;
    
    if( self.checkBytes != nil )
        result = [NSDictionary dictionaryWithObjectsAndKeys: self.checkBytes, @"value", self.valueTransformer, @"valueTransformer", @"checkBytes", @"key", [self objectID], @"objectID", nil];
    
    return result;
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
