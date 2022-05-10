//
//  AppDelegate.m
//  PlistEditor
//
//  Created by stephane on 2/20/19.
//  Copyright (c) 2019 WhiteBox. All rights reserved.
//

#import "AppDelegate.h"

#import "YAPLEditorViewController.h"

@interface AppDelegate ()
{
	YAPLEditorViewController * controller;
}

    @property (weak) IBOutlet NSWindow *window;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	controller=[YAPLEditorViewController new];
	controller.editable=YES;
	
    NSDictionary * tDictionary = nil;
    
	/*NSDictionary * tDictionary=@{@"row1":@[@(1),@"tutu"],
								 @"row2":@{@"tutu":[NSDate date]},
								 @"row3":@(YES)};*/
	
	NSData * tData=[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Property List" ofType:@"plist"]];
	
	tDictionary=[NSPropertyListSerialization propertyListWithData:tData options:NSPropertyListMutableContainersAndLeaves format:NULL error:NULL];
	
	
	
	controller.propertyList=tDictionary;
	
	controller.view.frame=[self.window.contentView bounds];
	
	[self.window.contentView addSubview:controller.view];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
	// Insert code here to tear down your application
}

@end
