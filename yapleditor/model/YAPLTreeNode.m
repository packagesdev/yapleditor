//
//  DISPlistTreeNode.m
//  PlistEditor
//
//  Created by stephane on 2/20/19.
//

#import "YAPLTreeNode.h"

#import "NSArray+WBExtensions.h"

@implementation YAPLRepresentedObject

+ (YAPLObjectType)typeOfObject:(id)inObject
{
	if ([inObject isKindOfClass:[NSDictionary class]]==YES)
		return YAPLObjectTypeDictionary;
	
	if ([inObject isKindOfClass:[NSArray class]]==YES)
		return YAPLObjectTypeArray;
	
	if ([inObject isKindOfClass:[NSString class]]==YES)
		return YAPLObjectTypeString;
	
	if ([inObject isKindOfClass:[NSNumber class]]==YES)
	{
		if (inObject==@(YES) || inObject==@(NO))
			return YAPLObjectTypeBoolean;
		
		return YAPLObjectTypeNumber;
	}
	
	if ([inObject isKindOfClass:[NSDate class]]==YES)
		return YAPLObjectTypeDate;
	
	return YAPLObjectTypeUnknown;
}

- (id)copyWithZone:(NSZone *)zone
{
	return nil;
}

@end

@interface YAPLTreeNode ()
{
	
	id<NSCopying> _representedObject;
	
	NSMutableArray * _children;
}

@property (readwrite) YAPLTreeNode * parent;

@end


@implementation YAPLTreeNode

+ (instancetype)treeNode
{
	return [[self alloc] init];
}

+ (instancetype)treeNodeWithRepresentedObject:(id)inRepresentedObject children:(NSArray *)inChildren
{
	return [[self alloc] initWithRepresentedObject:inRepresentedObject children:inChildren];
}

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		_parent=nil;
		_children=[NSMutableArray array];
	}
	
	return self;
}

- (instancetype)initWithRepresentedObject:(id)inRepresentedObject children:(NSArray *)inChildren
{
	self=[super init];
	
	if (self!=nil)
	{
		_representedObject=inRepresentedObject;
		_parent=nil;
		
		if (inChildren!=nil)
		{
			_children=[inChildren mutableCopy];
			
			[_children makeObjectsPerformSelector:@selector(setParent:) withObject:self];
		}
		else
		{
			_children=[NSMutableArray array];
		}
	}
	
	return self;
}

- (id)initWithKey:(NSString *)inKey value:(id)inValue error:(out NSError **)outError
{
	if (inKey==nil && inValue==nil)
		return nil;
	
	self=[super init];
	
	if (self!=nil)
	{
		_parent=nil;
		_children=[NSMutableArray array];
		
		YAPLRepresentedObject * tRepresentedRootObject=[YAPLRepresentedObject new];
		
		tRepresentedRootObject.key=inKey;
		
		YAPLObjectType tType=[YAPLRepresentedObject typeOfObject:inValue];
		
		if (tType==YAPLObjectTypeUnknown)
			return nil;
		
		tRepresentedRootObject.type=tType;
		
		_representedObject=tRepresentedRootObject;
		
		switch(tType)
		{
			case YAPLObjectTypeDictionary:
			{
				NSDictionary * tDictionary=(NSDictionary *)inValue;
				
				[tDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * bKey, id bObject, BOOL *bOutStop) {
					
					YAPLTreeNode * tChildNode=[[YAPLTreeNode alloc] initWithKey:bKey
																		  value:tDictionary[bKey]
																		  error:NULL];
					[_children addObject:tChildNode];
				}];
				 
				[_children makeObjectsPerformSelector:@selector(setParent:) withObject:self];
				
				[self sortChildrenUsingComparator:^NSComparisonResult(YAPLTreeNode * bChildNode, YAPLTreeNode * bOtherChildNode) {
					
					return [((YAPLRepresentedObject *)bChildNode.representedObject).key compare:((YAPLRepresentedObject *)bOtherChildNode.representedObject).key options:NSCaseInsensitiveSearch|NSNumericSearch];
				}];
				
				break;
			}
			case YAPLObjectTypeArray:
			{
				NSArray * tArray=(NSArray *)inValue;
				
				[tArray enumerateObjectsUsingBlock:^(NSString * bValue, NSUInteger bIndex, BOOL *bOutStop) {
					
					YAPLTreeNode * tChildNode=[[YAPLTreeNode alloc] initWithKey:nil
																		  value:bValue
																		  error:NULL];
					[_children addObject:tChildNode];
				}];
				
				[_children makeObjectsPerformSelector:@selector(setParent:) withObject:self];
				
				break;
			}
			case YAPLObjectTypeBoolean:
			case YAPLObjectTypeData:
			case YAPLObjectTypeDate:
			case YAPLObjectTypeNumber:
			case YAPLObjectTypeString:
				
				tRepresentedRootObject.value=[inValue copy];
				
				break;
				
			default:
				
				return nil;
		}
	}
	
	return self;
}

- (id)initWithPropertyList:(id)inPropertyList rootItemLabel:(NSString *)inRootLabel error:(out NSError **)outError
{
	if (inPropertyList==nil)
	{
		if (outError!=NULL)
            ;   // A COMPLETER
		
		return nil;
	}
	
	self=[self initWithKey:inRootLabel value:inPropertyList error:NULL];
	
	return self;
}

- (id)initWithPropertyList:(id)inPropertyList error:(out NSError **)outError
{
	return [self initWithPropertyList:inPropertyList rootItemLabel:@"Root" error:outError];
}

- (id)propertyList
{
	// A COMPLETER
	
	return nil;
}

#pragma mark -

- (Class)representedObjectClassForRepresentation:(NSDictionary *)inRepresentation
{
	NSLog(@"You need to define the class of the represented object");
	
	return nil;
}

#pragma mark -

- (NSIndexPath *)indexPath
{
	YAPLTreeNode * tParent=self.parent;
	
	if (tParent==nil)
		return nil;
	
	NSIndexPath * tParentIndexPath=[tParent indexPath];
	
	NSUInteger tIndex=[[tParent children] indexOfObject:self];
	
	if (tParentIndexPath==nil)
		return [NSIndexPath indexPathWithIndex:tIndex];
	
	return [tParentIndexPath indexPathByAddingIndex:tIndex];
}

- (NSUInteger)numberOfChildren
{
	return _children.count;
}

- (NSArray *)children
{
	return [_children copy];
}

- (BOOL)isDescendantOfNode:(YAPLTreeNode *)inTreeNode
{
	YAPLTreeNode * tParent = [self parent];
	
	while (tParent)
	{
		if (tParent == inTreeNode)
			return YES;
		
		tParent = [tParent parent];
	}
	
	return NO;
}

- (BOOL)isDescendantOfNodeInArray:(NSArray *)inTreeNodes
{
	for (YAPLTreeNode * tTreeNode in inTreeNodes)
	{
		if ([self isDescendantOfNode:tTreeNode]==YES)
			return YES;
	}
	
	return NO;
}

- (YAPLTreeNode *)childNodeAtIndex:(NSUInteger)inIndex
{
	if (inIndex>=_children.count)
		return nil;
	
	return [_children objectAtIndex:inIndex];
}

- (YAPLTreeNode *)childNodeMatching:(BOOL (^)(id bTreeNode))inBlock
{
	if (inBlock==nil)
		return nil;
	
	for(YAPLTreeNode * tChild in _children)
	{
		if (inBlock(tChild)==YES)
			return tChild;
	}
	
	return nil;
}

#pragma mark -

- (NSUInteger)indexOfChildIdenticalTo:(YAPLTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return NSNotFound;
	
	return [_children indexOfObjectIdenticalTo:inTreeNode];
}

- (NSUInteger)indexOfChildMatching:(BOOL (^)(id bTreeNode))inBlock
{
	if (inBlock==nil)
		return NSNotFound;
	
	__block NSUInteger tChildIndex=NSNotFound;
	
	[_children enumerateObjectsUsingBlock:^(YAPLTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
		
		if (inBlock(bTreeNode)==YES)
		{
			tChildIndex=bIndex;
			*bOutStop=YES;
		}
		
	}];
	
	return tChildIndex;
}

#pragma mark -

- (void)addChild:(YAPLTreeNode *)inChild
{
	inChild.parent=self;
	[_children addObject:inChild];
}

- (void)addChildren:(NSArray *)inChildren
{
	[inChildren makeObjectsPerformSelector:@selector(setParent:) withObject:self];
	[_children addObjectsFromArray:inChildren];
}

- (BOOL)mergeDescendantsOfNode:(YAPLTreeNode *)inTreeNode usingComparator:(NSComparator)inComparator representedObjectMergeHandler:(BOOL (^)(id bOriginalTreeNode,id bModifiedTreeNode))inMergeHandler
{
	if (inTreeNode==nil)
		return NO;
	
	__block BOOL tDidAddDescendantsOrMergedRepresentedObjects=NO;
	
	for(YAPLTreeNode * tDescendant in inTreeNode.children)
	{
		__block BOOL tMatched=NO;
		
		[_children enumerateObjectsUsingBlock:^(YAPLTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
			
			NSComparisonResult tComparisonResult=inComparator(tDescendant,bTreeNode);
			
			if (tComparisonResult==NSOrderedSame)
			{
				tMatched=YES;
				
				if (inMergeHandler!=nil)
				{
					tDidAddDescendantsOrMergedRepresentedObjects|=inMergeHandler(bTreeNode,tDescendant);
				}
				
				// Checked with the descendants
				
				tDidAddDescendantsOrMergedRepresentedObjects|=[bTreeNode mergeDescendantsOfNode:tDescendant usingComparator:inComparator representedObjectMergeHandler:inMergeHandler];
				
				*bOutStop=YES;
			}
		}];
		
		if (tMatched==NO)
		{
			tDidAddDescendantsOrMergedRepresentedObjects=YES;
			[tDescendant insertAsSiblingOfChildren:_children ofNode:self sortedUsingComparator:inComparator];
		}
	}
	
	return tDidAddDescendantsOrMergedRepresentedObjects;
}

- (YAPLTreeNode *)filterRecursivelyUsingBlock:(BOOL (^)(id bTreeNode))inBlock
{
	return [self filterRecursivelyUsingBlock:inBlock maximumDepth:NSNotFound];
}

- (YAPLTreeNode *)filterRecursivelyUsingBlock:(BOOL (^)(id bTreeNode))inBlock maximumDepth:(NSUInteger)inMaximumDepth
{
	if (inBlock==nil)
		return self;
	
	if (inMaximumDepth>0)
	{
		if (inMaximumDepth!=NSNotFound)
			inMaximumDepth--;
		
		NSUInteger tCount=_children.count;
		
		for(NSUInteger tIndex=tCount;tIndex>0;tIndex--)
		{
			YAPLTreeNode * tResult=[_children[tIndex-1] filterRecursivelyUsingBlock:inBlock maximumDepth:inMaximumDepth];
			
			if (tResult==nil)
				[_children removeObjectAtIndex:tIndex-1];
		}
	}
	
	if (inBlock(self)==NO)
		return nil;
	
	return self;
}

- (void)insertChild:(YAPLTreeNode *)inChild atIndex:(NSUInteger)inIndex
{
	if (inChild==nil || inIndex>_children.count)
		return;
	
	inChild.parent=self;
	[_children insertObject:inChild atIndex:inIndex];
}

- (void)insertChildren:(NSArray *)inChildren atIndex:(NSUInteger)inIndex
{
	if (inChildren.count==0 || inIndex>_children.count)
		return;
	
	[inChildren makeObjectsPerformSelector:@selector(setParent:) withObject:self];
	[_children insertObjects:inChildren atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(inIndex, inChildren.count)]];
}


- (void)insertAsSiblingOfChildren:(NSMutableArray *)inChildren ofNode:(YAPLTreeNode *)inParent sortedUsingComparator:(NSComparator)inComparator
{
	if (inChildren==nil || inComparator==nil)
		return;
	
	if ([inChildren isKindOfClass:NSMutableArray.class]==NO)
		return;
	
	if (inChildren.count==0)
	{
		self.parent=inParent;
		[inChildren addObject:self];
		return;
	}
	
	__block BOOL tInserted=NO;
	
	[inChildren enumerateObjectsUsingBlock:^(YAPLTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
		
		if (inComparator(self,bTreeNode)!=NSOrderedDescending)
		{
			self.parent=inParent;
			[inChildren insertObject:self atIndex:bIndex];
			tInserted=YES;
			*bOutStop=YES;
		}
	}];
	
	if (tInserted==0)
	{
		self.parent=inParent;
		[inChildren addObject:self];
		return;
	}
}

- (void)insertAsSiblingOfChildren:(NSMutableArray *)inChildren ofNode:(YAPLTreeNode *)inParent sortedUsingSelector:(SEL)inSelector
{
	if (inChildren==nil || inSelector==nil)
		return;
	
	if ([inChildren isKindOfClass:NSMutableArray.class]==NO)
		return;
	
	NSInvocation * tInvocation=[NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:inSelector]];
	tInvocation.target=self;
	tInvocation.selector=inSelector;
	
	__block BOOL tInserted=NO;
	
	[inChildren enumerateObjectsUsingBlock:^(YAPLTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
		
		NSComparisonResult tComparisonResult;
		
		[tInvocation setArgument:&bTreeNode atIndex:2];
		[tInvocation invoke];
		[tInvocation getReturnValue:&tComparisonResult];
		
		if (tComparisonResult!=NSOrderedDescending)
		{
			self.parent=inParent;
			[inChildren insertObject:self atIndex:bIndex];
			tInserted=YES;
			*bOutStop=YES;
		}
	}];
	
	if (tInserted==0)
	{
		self.parent=inParent;
		[inChildren addObject:self];
		return;
	}
}

- (void)insertChild:(YAPLTreeNode *)inChild sortedUsingComparator:(NSComparator)inComparator
{
	if (inChild==nil || inComparator==nil)
		return;
	
	__block BOOL tDone=NO;
	
	[_children enumerateObjectsUsingBlock:^(YAPLTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
		
		if (inComparator(inChild,bTreeNode)!=NSOrderedDescending)
		{
			inChild.parent=self;
			[self->_children insertObject:inChild atIndex:bIndex];
			
			tDone=YES;
			*bOutStop=YES;
		}
	}];
	
	if (tDone==YES)
		return;
	
	inChild.parent=self;
	[_children addObject:inChild];
}


- (void)insertChild:(YAPLTreeNode *)inChild sortedUsingSelector:(SEL)inSelector
{
	if (inChild==nil || inSelector==nil)
		return;
	
	NSInvocation * tInvocation=[NSInvocation invocationWithMethodSignature:[inChild methodSignatureForSelector:inSelector]];
	tInvocation.target=inChild;
	tInvocation.selector=inSelector;
	
	__block BOOL tDone=NO;
	
	[_children enumerateObjectsUsingBlock:^(YAPLTreeNode * bTreeNode,NSUInteger bIndex,BOOL * bOutStop){
		
		NSComparisonResult tComparisonResult;
		
		[tInvocation setArgument:&bTreeNode atIndex:2];
		[tInvocation invoke];
		[tInvocation getReturnValue:&tComparisonResult];
		
		if (tComparisonResult!=NSOrderedDescending)
		{
			inChild.parent=self;
			[self->_children insertObject:inChild atIndex:bIndex];
			
			tDone=YES;
			*bOutStop=YES;
		}
	}];
	
	if (tDone==YES)
		return;
	
	inChild.parent=self;
	[_children addObject:inChild];
}

- (void)removeChildAtIndex:(NSUInteger)inIndex
{
	if (inIndex>=_children.count)
		return;
	
	YAPLTreeNode * tTreeNode=_children[inIndex];
	
	tTreeNode.parent=nil;
	
	[_children removeObjectAtIndex:inIndex];
}

- (void)removeChildrenAtIndexes:(NSIndexSet *)inIndexSet
{
	if (inIndexSet==nil || inIndexSet.lastIndex>=_children.count)
		return;
	
	[_children enumerateObjectsAtIndexes:inIndexSet options:0 usingBlock:^(YAPLTreeNode *bTreeNode,__attribute__((unused))NSUInteger bIndex,__attribute__((unused))BOOL * boutStop){
		
		bTreeNode.parent=nil;
	}];
	
	[_children removeObjectsAtIndexes:inIndexSet];
}

- (void)removeChild:(YAPLTreeNode *)inChild
{
	if (inChild==nil)
		return;
	
	NSUInteger tIndex=[_children indexOfObjectIdenticalTo:inChild];
	
	if (tIndex==NSNotFound)
		return;
	
	inChild.parent=nil;
	[_children removeObjectAtIndex:tIndex];
}

- (void)removeChildrenInArray:(NSArray *)inArray
{
	NSMutableIndexSet * tIndexSet=[NSMutableIndexSet indexSet];
	
	[inArray enumerateObjectsUsingBlock:^(YAPLTreeNode * bObject, NSUInteger bIndex, BOOL *bOutStop) {
		
		NSUInteger tFoundIndex=[self->_children indexOfObject:bObject];
		
		if (tFoundIndex!=NSNotFound)
		{
			[tIndexSet addIndex:tFoundIndex];
			
			bObject.parent=nil;
		}
	}];
	
	[_children removeObjectsAtIndexes:tIndexSet];
}

- (void)removeAllChildren
{
	[_children makeObjectsPerformSelector:@selector(setParent:) withObject:nil];
	[_children removeAllObjects];
}

- (void)removeFromParent
{
	[self.parent removeChild:self];
}

- (void)sortChildrenUsingComparator:(NSComparator)inComparator
{
	if (inComparator==nil)
		return;
	
	[_children sortUsingComparator:inComparator];
}

#pragma mark -

/* Code from the Apple Sample Code */

+ (NSArray *)minimumNodeCoverFromNodesInArray:(NSArray *)inArray
{
	NSMutableArray *tMinimumNodeCover = [NSMutableArray array];
	NSMutableArray * tNodeQueue = [NSMutableArray arrayWithArray:inArray];
	YAPLTreeNode *tTreeNode = nil;
	
	while (tNodeQueue.count)
	{
		tTreeNode = tNodeQueue[0];
		[tNodeQueue removeObjectAtIndex:0];
		
		YAPLTreeNode *tTreeNodeParent=tTreeNode.parent;
		
		while (tTreeNodeParent && [tNodeQueue indexOfObjectIdenticalTo:tTreeNodeParent]!=NSNotFound)
		{
			[tNodeQueue removeObjectIdenticalTo: tTreeNode];
			tTreeNode = tTreeNodeParent;
			tTreeNodeParent=tTreeNode.parent;
		}
		
		if (![tTreeNode isDescendantOfNodeInArray: tMinimumNodeCover])
			[tMinimumNodeCover addObject: tTreeNode];
		
		[tNodeQueue removeObjectIdenticalTo: tTreeNode];
	}
	
	return [tMinimumNodeCover copy];
}

#pragma mark -

- (void)enumerateChildrenUsingBlock:(void(^)(id bTreeNode,BOOL *))block
{
	[_children enumerateObjectsUsingBlock:^(id bChild, NSUInteger bIndex, BOOL *bOutStop) {
		
		block(bChild,bOutStop);
	}];
}

@end
