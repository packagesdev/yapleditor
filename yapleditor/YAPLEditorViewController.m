/*
 Copyright (c) 2019, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "YAPLEditorViewController.h"

#import "YAPLTreeNode.h"

#import "YAPLCheckboxTableCellView.h"
#import "YAPLDatePickerTableCellView.h"
#import "YAPLPopUpButtonTableCellView.h"

#import "NSArray+WBExtensions.h"

@interface YAPLEditorViewController () <NSOutlineViewDataSource,NSOutlineViewDelegate>
{
	YAPLTreeNode * _rootNode;
	
	IBOutlet NSView * _bottomToolbarView;
	
	IBOutlet NSButton * _deleteButton;
}

@property (readwrite) IBOutlet NSOutlineView * outlineView;

+ (NSDateFormatter *)dateFormatter;

- (IBAction)setKey:(NSTextField *)sender;

- (IBAction)setBooleanValue:(NSButton *)sender;

- (IBAction)setDataValue:(NSButton *)sender;

- (IBAction)setDateValue:(NSButton *)sender;

- (IBAction)setNumberValue:(NSButton *)sender;

- (IBAction)setStringValue:(NSButton *)sender;

- (IBAction)switchItemType:(id)sender;

- (IBAction)addItem:(id)sender;
- (IBAction)delete:(id)sender;

@end

@implementation YAPLEditorViewController

+ (NSDateFormatter *)dateFormatter
{
	static NSDateFormatter * sDateFormatter=nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		sDateFormatter=[NSDateFormatter new];
		sDateFormatter.dateStyle=NSDateFormatterMediumStyle;
		sDateFormatter.timeStyle=NSDateFormatterMediumStyle;
		
	});
	
	return sDateFormatter;
}

- (NSString *)nibName
{
	return @"YAPLEditorViewController";
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	if (self.isEditable==NO)
	{
		_bottomToolbarView.hidden=YES;
		self.outlineView.enclosingScrollView.frame=self.view.bounds;
	}
	
	// A COMPLETER
}

- (void)viewDidAppear
{
	[super viewDidAppear];
	
	if (_rootNode!=nil)
		[self.outlineView expandItem:[self.outlineView itemAtRow:0]];
	
	// A COMPLETER
}

#pragma mark -

- (void)setEditable:(BOOL)inEditable
{
	if (_editable==inEditable)
		return;
	
	_editable=inEditable;
	
	if (_bottomToolbarView==nil)
		return;
	
	_bottomToolbarView.hidden=(inEditable==NO);
	
	NSRect tFrame=self.view.bounds;
	
	if (_editable==YES)
	{
		NSRect tBottomRect=_bottomToolbarView.frame;
		
		tFrame.origin.y=NSMaxY(tBottomRect);
		tFrame.size.height-=NSHeight(tBottomRect);
	}
	
	self.outlineView.enclosingScrollView.frame=tFrame;
	
	[self.outlineView reloadData];
}

- (id)propertyList
{
	// A COMPLETER
	
	return nil;
}

- (void)setPropertyList:(id)inPropertyList
{
	_rootNode=[[YAPLTreeNode alloc] initWithPropertyList:inPropertyList error:NULL];
	
	if (self.outlineView!=nil)
	{
		[self.outlineView reloadData];
	
		if (_rootNode!=nil)
			[self.outlineView expandItem:[self.outlineView itemAtRow:0]];
	}
}

#pragma mark -

- (BOOL)validateMenuItem:(NSMenuItem *)inMenuItem
{
	SEL tAction=inMenuItem.action;
	
	if (tAction==@selector(delete:))
	{
		if (self.isEditable==NO)
			return NO;
		
		NSIndexSet * tIndexSet=[self.outlineView selectedRowIndexes];
		
		if (tIndexSet.count==0)
		{
			return NO;
		}
		
		return ([tIndexSet containsIndex:0]==NO);
	}
	
	return YES;
}

- (IBAction)setKey:(NSTextField *)sender
{
	NSUInteger tEditedRow=[self.outlineView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	YAPLTreeNode * tTreeNode=[self.outlineView itemAtRow:tEditedRow];
	
	YAPLRepresentedObject * tRepresentedObject=tTreeNode.representedObject;
	
	NSString * tNewKey=sender.stringValue;
	
	if ([tNewKey isEqualToString:tRepresentedObject.key]==YES)
		return;
	
	// Check that the key is not already defined for another child
	
	if ([tTreeNode.parent childNodeMatching:^BOOL(YAPLTreeNode * bChildTreeNode) {
		
		if (bChildTreeNode==tTreeNode)
			return NO;
		
		return [((YAPLRepresentedObject *)bChildTreeNode.representedObject).key isEqualToString:tNewKey];
		
	}]!=nil)
	{
		NSBeep ();
		
		[self.outlineView editColumn:[self.outlineView columnWithIdentifier:@"item.key"]
							 row:tEditedRow
					   withEvent:nil
						  select:YES];
		
		return;
	}
	
	tRepresentedObject.key=tNewKey;
	
	[tTreeNode.parent sortChildrenUsingComparator:^NSComparisonResult(YAPLTreeNode * bChildNode, YAPLTreeNode * bOtherChildNode) {
		
		return [((YAPLRepresentedObject *)bChildNode.representedObject).key compare:((YAPLRepresentedObject *)bOtherChildNode.representedObject).key options:NSCaseInsensitiveSearch|NSNumericSearch];
	}];
	
	[self.outlineView reloadData];
	
	NSInteger tNewSelectedRow=[self.outlineView rowForItem:tTreeNode];
	
	[self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:tNewSelectedRow] byExtendingSelection:NO];
}

- (IBAction)switchItemType:(NSPopUpButton *)sender
{
	NSUInteger tEditedRow=[self.outlineView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	YAPLTreeNode * tTreeNode=[self.outlineView itemAtRow:tEditedRow];
	
	YAPLObjectType tNewType=[sender selectedTag];
	
	YAPLRepresentedObject * tRepresentedObject=tTreeNode.representedObject;
	
	if (tNewType==tRepresentedObject.type)
		return;
	
	tRepresentedObject.type=tNewType;
	
	[tTreeNode removeAllChildren];
	
	switch(tNewType)
	{
		case YAPLObjectTypeArray:
		case YAPLObjectTypeDictionary:
			
			tRepresentedObject.value=nil;
			break;
			
		case YAPLObjectTypeBoolean:
			
			tRepresentedObject.value=@(YES);
			break;
			
		case YAPLObjectTypeData:
			
			tRepresentedObject.value=[NSData data];
			break;
			
		case YAPLObjectTypeDate:
			
			tRepresentedObject.value=[NSDate date];
			break;
			
		case YAPLObjectTypeNumber:
			
			tRepresentedObject.value=@(0);
			break;
			
		case YAPLObjectTypeString:
			
			tRepresentedObject.value=@"";
			break;
			
		default:
			
			break;
	}
	
	[self.outlineView reloadData];
}

- (IBAction)setBooleanValue:(NSButton *)sender
{
	NSUInteger tEditedRow=[self.outlineView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	YAPLRepresentedObject * tRepresentedObject=((YAPLTreeNode *)[self.outlineView itemAtRow:tEditedRow]).representedObject;
	
	NSNumber * tNewBoolValue=(sender.state==NSOnState)? @(YES) : @(NO);
	
	if (tNewBoolValue==tRepresentedObject.value)
		return;
	
	tRepresentedObject.value=tNewBoolValue;
}

- (IBAction)setDataValue:(NSTextField *)sender
{
	// A COMPLETER
}

- (IBAction)setDateValue:(NSTextField *)sender
{
	NSUInteger tEditedRow=[self.outlineView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	YAPLRepresentedObject * tRepresentedObject=((YAPLTreeNode *)[self.outlineView itemAtRow:tEditedRow]).representedObject;
	
	tRepresentedObject.value=sender.objectValue;
}

- (IBAction)setNumberValue:(NSTextField *)sender
{
	NSUInteger tEditedRow=[self.outlineView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	YAPLRepresentedObject * tRepresentedObject=((YAPLTreeNode *)[self.outlineView itemAtRow:tEditedRow]).representedObject;
	
	NSNumberFormatter * tFormatter=[NSNumberFormatter new];
	tFormatter.numberStyle=NSNumberFormatterDecimalStyle;
	
	NSNumber * tNumber=[tFormatter numberFromString:sender.stringValue];
	
	if ([tFormatter numberFromString:sender.stringValue]==nil)
	{
		NSBeep ();
		
		[self.outlineView editColumn:[self.outlineView columnWithIdentifier:@"item.value"]
							 row:tEditedRow
					   withEvent:nil
						  select:YES];
		
		return;
	}
	
	tRepresentedObject.value=tNumber;
}

- (IBAction)setStringValue:(NSTextField *)sender
{
	NSUInteger tEditedRow=[self.outlineView rowForView:sender];
	
	if (tEditedRow==-1)
		return;
	
	YAPLRepresentedObject * tRepresentedObject=((YAPLTreeNode *)[self.outlineView itemAtRow:tEditedRow]).representedObject;
	
	tRepresentedObject.value=sender.stringValue;
}

- (IBAction)addItem:(id)sender
{
	NSInteger tSelectedRow=[self.outlineView selectedRow];
	
	if (tSelectedRow==-1)
		return;
	
	YAPLTreeNode * tSelectedTreeNode=[self.outlineView itemAtRow:tSelectedRow];
	YAPLTreeNode * tParentTreeNode=nil;
	
	BOOL tIsExpanded=[self.outlineView isItemExpanded:tSelectedTreeNode];
	
	YAPLRepresentedObject * tRepresentedObject=[YAPLRepresentedObject new];
	tRepresentedObject.key=@"";
	tRepresentedObject.type=YAPLObjectTypeString;
	tRepresentedObject.value=@"";
	
	YAPLTreeNode * tNewNode=[YAPLTreeNode treeNodeWithRepresentedObject:tRepresentedObject children:[NSMutableArray array]];
	
	NSUInteger tInsertionIndex=0;
	
	if (tIsExpanded==YES || tSelectedRow==0)
	{
		tParentTreeNode=tSelectedTreeNode;
		
		tInsertionIndex=0;
	}
	else
	{
		tParentTreeNode=tSelectedTreeNode.parent;
		
		tInsertionIndex=[tParentTreeNode indexOfChildIdenticalTo:tSelectedTreeNode]+1;
	}
	
	YAPLRepresentedObject * tParentRepresentedObject=tParentTreeNode.representedObject;
	
	// => It's either an array or a dictionary
	
	if (tParentRepresentedObject.type==YAPLObjectTypeArray)
	{
		tRepresentedObject.key=nil;
	}
	else
	{
		NSArray * tInterestingChildren=tParentTreeNode.children;
		
		NSString * tSuggestedKey=@"New item";
		
		__block BOOL tFound=NO;
		
		tInterestingChildren=[tInterestingChildren WB_filteredArrayUsingBlock:^BOOL(YAPLTreeNode * bChildTreeNode, NSUInteger bIndex) {
			
			YAPLRepresentedObject * tChildRepresentedObject=bChildTreeNode.representedObject;
			
			if ([tChildRepresentedObject.key hasPrefix:tSuggestedKey]==NO)
				return NO;
			
			if ([tChildRepresentedObject.key isEqualToString:tSuggestedKey]==YES)
			{
				tFound=YES;
				
				return NO;
			}
			
			return YES;
		}];
		
		if (tFound==YES)
		{
			NSString * tKeyFormat=[tSuggestedKey stringByAppendingString:@" - %lu"];
			NSUInteger tIndex=2;
			
			do
			{
				tFound=NO;
				
				tSuggestedKey=[NSString stringWithFormat:tKeyFormat,(unsigned long)tIndex];
				
				[tInterestingChildren enumerateObjectsUsingBlock:^(YAPLTreeNode * bChildTreeNode, NSUInteger bIndex, BOOL *bOutStop) {
					
					YAPLRepresentedObject * tChildRepresentedObject=bChildTreeNode.representedObject;
					
					if ([tChildRepresentedObject.key isEqualToString:tSuggestedKey]==YES)
					{
						tFound=YES;
						
						*bOutStop=YES;
						
						return;
					}
					
					
				}];
				
				tIndex++;
			}
			while (tFound==YES);
		}
		
		tRepresentedObject.key=tSuggestedKey;
	}
	
	[tParentTreeNode insertChild:tNewNode atIndex:tInsertionIndex];
	
	[self.outlineView reloadData];
	
	if (tIsExpanded==NO && tParentTreeNode==tSelectedTreeNode)
		[self.outlineView expandItem:tSelectedTreeNode];
	
	NSInteger tNewSelectedRow=[self.outlineView rowForItem:tNewNode];
	
	[self.outlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:tNewSelectedRow] byExtendingSelection:NO];
	
	[self.outlineView editColumn:[self.outlineView columnWithIdentifier:(tParentRepresentedObject.type==YAPLObjectTypeArray) ? @"item.value" : @"item.key"]
						 row:tNewSelectedRow
				   withEvent:nil
					  select:YES];
}

- (IBAction)delete:(id)sender
{
	NSIndexSet * tIndexSet=[self.outlineView selectedRowIndexes];
	
	NSMutableArray * tSelectedItems=[NSMutableArray array];
	
	[tIndexSet enumerateIndexesUsingBlock:^(NSUInteger bIndex, BOOL *bOutStop) {
		
		if (bIndex==0)
			return;
		
		id tItem=[self.outlineView itemAtRow:bIndex];
		
		[tSelectedItems addObject:tItem];
	}];
	
	NSArray * tMinimumCover=[YAPLTreeNode minimumNodeCoverFromNodesInArray:tSelectedItems];
	
	[tMinimumCover enumerateObjectsUsingBlock:^(YAPLTreeNode * bTreeNode, NSUInteger bIndex, BOOL *bOutStop) {
		
		[bTreeNode removeFromParent];
	}];
	
	[self.outlineView reloadData];
}

#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)inOutlineView numberOfChildrenOfItem:(YAPLTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return 1;
	
	return inTreeNode.numberOfChildren;
}

- (id)outlineView:(NSOutlineView *)inOutlineView child:(NSInteger)inIndex ofItem:(YAPLTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return _rootNode;
	
	return [inTreeNode childNodeAtIndex:inIndex];
}

- (BOOL)outlineView:(NSOutlineView *)inOutlineView isItemExpandable:(YAPLTreeNode *)inTreeNode
{
	if (inTreeNode==nil)
		return YES;
	
	YAPLRepresentedObject * tRepresentedObject=inTreeNode.representedObject;
	
	YAPLObjectType tType=tRepresentedObject.type;
	
	return (tType==YAPLObjectTypeArray || tType==YAPLObjectTypeDictionary);
}

#pragma mark - NSOutlineViewDelegate

- (NSView *)outlineView:(NSOutlineView *)inOutlineView viewForTableColumn:(NSTableColumn *)inTableColumn item:(YAPLTreeNode *)inTreeNode
{
	if (self.outlineView!=inOutlineView)
		return nil;
		
	NSString * tTableColumnIdentifier=inTableColumn.identifier;
	
	
	YAPLRepresentedObject * tRepresentedObject=inTreeNode.representedObject;
	
	if ([tTableColumnIdentifier isEqualToString:@"item.key"]==YES)
	{
		NSTableCellView * tTableCellView=[self.outlineView makeViewWithIdentifier:tTableColumnIdentifier owner:self];
		
		NSTextField * tTextField=tTableCellView.textField;
		
		YAPLTreeNode * tParentNode=inTreeNode.parent;
		
		YAPLObjectType tType=((YAPLRepresentedObject *)tParentNode.representedObject).type;
		
		tTextField.editable=(tType==YAPLObjectTypeDictionary);
		
		if (tRepresentedObject.key!=nil)
		{
			tTextField.stringValue=tRepresentedObject.key;
		}
		else
		{
			tTextField.stringValue=[NSString stringWithFormat:NSLocalizedString(@"Item %lu",@""),[tParentNode indexOfChildIdenticalTo:inTreeNode]];
		}
		
		return tTableCellView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"item.type"]==YES)
	{
		YAPLPopUpButtonTableCellView * tTableCellView=[self.outlineView makeViewWithIdentifier:(inTreeNode.parent==nil) ? @"item.type.root" : @"item.type.nonroot" owner:self];
		
		tTableCellView.popUpButton.enabled=self.isEditable;
		
		[tTableCellView.popUpButton selectItemWithTag:tRepresentedObject.type];
		
		return tTableCellView;
	}
	
	if ([tTableColumnIdentifier isEqualToString:@"item.value"]==YES)
	{
		if (tRepresentedObject.type==YAPLObjectTypeBoolean)
		{
			YAPLCheckboxTableCellView * tTableCellView=[self.outlineView makeViewWithIdentifier:@"item.value.bool" owner:self];
			
			tTableCellView.checkbox.enabled=self.isEditable;
			tTableCellView.checkbox.state=([tRepresentedObject.value boolValue]==YES)? NSOnState : NSOffState;
			
			return tTableCellView;
		}
		else
		{
			NSTableCellView * tTableCellView=[self.outlineView makeViewWithIdentifier:@"item.value.string" owner:self];
		
			NSTextField * tTextField=tTableCellView.textField;
			
			tTextField.formatter=nil;
			
			if (tRepresentedObject.type==YAPLObjectTypeDictionary ||
				tRepresentedObject.type==YAPLObjectTypeArray)
			{
				unsigned long tNumberOfChildren=(unsigned long)inTreeNode.numberOfChildren;
				
				tTextField.editable=NO;
				tTextField.textColor=[NSColor secondaryLabelColor];
				
				NSString * tFormat=nil;
				
				switch(tNumberOfChildren)
				{
					case 0:
						
						tFormat=NSLocalizedString(@"(%lu items)",@"");
						
						break;
						
					case 1:
						
						tFormat=NSLocalizedString(@"(%lu item)",@"");
						
						break;
					
					default:
						
						tFormat=NSLocalizedString(@"(%lu items)",@"");
						
						break;
				}
				
				tTextField.stringValue=[NSString stringWithFormat:tFormat,tNumberOfChildren];
			}
			else
			{
				tTextField.editable=self.isEditable;
				tTextField.textColor=[NSColor controlTextColor];
				
				switch(tRepresentedObject.type)
				{
					case YAPLObjectTypeData:
						
						tTextField.action=@selector(setDataValue:);
						
						break;
						
					case YAPLObjectTypeDate:
						
						tTextField.action=@selector(setDateValue:);
						tTextField.formatter=[YAPLEditorViewController dateFormatter];
						
						break;
						
					case YAPLObjectTypeNumber:
						
						tTextField.action=@selector(setNumberValue:);
						
						break;
						
					case YAPLObjectTypeString:
						
						tTextField.action=@selector(setStringValue:);
						
						break;
						
					default:
						break;
				}
				
				tTextField.objectValue=tRepresentedObject.value;
			}
		
			return tTableCellView;
		}
	}
	
	return nil;
}

#pragma mark -

- (void)outlineViewSelectionDidChange:(NSNotification *)inNotification
{
	NSIndexSet * tIndexSet=[self.outlineView selectedRowIndexes];
	
	if (tIndexSet.count==0)
	{
		_deleteButton.enabled=NO;
	}
	else
	{
		_deleteButton.enabled=([tIndexSet containsIndex:0]==NO);
	}
}

@end
