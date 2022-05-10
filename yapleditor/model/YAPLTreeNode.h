//
//  DISPlistTreeNode.h
//  PlistEditor
//
//  Created by stephane on 2/20/19.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, YAPLObjectType)
{
	YAPLObjectTypeArray=0,
	YAPLObjectTypeDictionary=1,
	
	YAPLObjectTypeBoolean=2,
	YAPLObjectTypeData=3,
	YAPLObjectTypeDate=4,
	YAPLObjectTypeNumber=5,
	YAPLObjectTypeString=6,
	
	YAPLObjectTypeUnknown=NSNotFound
};

@interface YAPLRepresentedObject : NSObject <NSCopying>

    @property (copy) NSString * key;
    @property (nonatomic) YAPLObjectType type;
    @property id value;

+ (YAPLObjectType)typeOfObject:(id)inObject;

@end

@interface YAPLTreeNode : NSObject

@property id<NSCopying> representedObject;

@property (weak,readonly) YAPLTreeNode * parent;

+ (instancetype)treeNodeWithRepresentedObject:(id)inRepresentedObject children:(NSArray *)inChildren;


- (id)initWithPropertyList:(id)inPropertyList error:(out NSError **)outError;

- (id)initWithPropertyList:(id)inPropertyList rootItemLabel:(NSString *)inRootLabel error:(out NSError **)outError;

@property (nonatomic,readonly) NSIndexPath * indexPath;

@property (nonatomic,readonly) NSUInteger numberOfChildren;
@property (nonatomic,readonly) NSArray * children;

- (BOOL)isDescendantOfNode:(YAPLTreeNode *)inTreeNode;
- (BOOL)isDescendantOfNodeInArray:(NSArray *)inTreeNodes;

- (YAPLTreeNode *)childNodeAtIndex:(NSUInteger)inIndex;
- (YAPLTreeNode *)childNodeMatching:(BOOL (^)(id bTreeNode))inBlock;

- (NSUInteger)indexOfChildIdenticalTo:(YAPLTreeNode *)inTreeNode;
- (NSUInteger)indexOfChildMatching:(BOOL (^)(id bTreeNode))inBlock;

- (void)addChild:(YAPLTreeNode *)inChild;
- (void)addChildren:(NSArray *)inChildren;

- (void)insertChild:(YAPLTreeNode *)inChild atIndex:(NSUInteger)inIndex;
- (void)insertChildren:(NSArray *)inChildren atIndex:(NSUInteger)inIndex;

- (void)insertAsSiblingOfChildren:(NSMutableArray *)inChildren ofNode:(YAPLTreeNode *)inParent sortedUsingComparator:(NSComparator)inComparator;
- (void)insertAsSiblingOfChildren:(NSMutableArray *)inChildren ofNode:(YAPLTreeNode *)inParent sortedUsingSelector:(SEL)inSelector;

- (void)insertChild:(YAPLTreeNode *)inChild sortedUsingComparator:(NSComparator)inComparator;
- (void)insertChild:(YAPLTreeNode *)inChild sortedUsingSelector:(SEL)inComparator;

- (void)removeChildAtIndex:(NSUInteger)inIndex;
- (void)removeChildrenAtIndexes:(NSIndexSet *)inIndexSet;
- (void)removeChild:(YAPLTreeNode *)inChild;
- (void)removeChildrenInArray:(NSArray *)inArray;
- (void)removeAllChildren;
- (void)removeFromParent;

- (void)sortChildrenUsingComparator:(NSComparator)inComparator;

+ (NSArray *)minimumNodeCoverFromNodesInArray:(NSArray *)inArray;

- (void)enumerateChildrenUsingBlock:(void(^)(id bTreeNode,BOOL *bOutStop))block;

@end
