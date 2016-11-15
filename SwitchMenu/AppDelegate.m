//
//  AppDelegate.m
//  SwitchMenu
//
//  Created by HatanoKenta on 2016/11/15.
//  Copyright © 2016年 Nita. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@property (strong, retain) NSStatusItem *sbItem;
@property (strong, retain) NSMutableArray *apps;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSStatusBar *bar = [NSStatusBar systemStatusBar];
    
    {
        self.sbItem = [bar statusItemWithLength:NSVariableStatusItemLength];
        
        self.sbItem.title = @"SwitchMenu";
        self.sbItem.toolTip = @"SwitchMenu";
        self.sbItem.highlightMode = YES;
        
        self.sbItem.menu = self.switchMenu;
    }
    
    self.switchMenu.delegate = self;
    
    [self createSubmenuOfSwitchMenu];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)menuWillOpen:(NSMenu *)menu {
    if (menu == self.switchMenu)  {
        [self createSubmenuOfSwitchMenu];
    }
}

- (void)createSubmenuOfSwitchMenu {
    [self.switchMenu removeAllItems];
    
    self.apps = [[NSMutableArray alloc] init];
    
    NSArray *apps = [[NSWorkspace sharedWorkspace] runningApplications];
    NSInteger selection = -1;
    
    NSInteger i = 0;
    
    for (NSRunningApplication *app in apps) {
        if (app.activationPolicy != NSApplicationActivationPolicyRegular){
            continue;
        }
        if (app.ownsMenuBar){
            selection = i;
        }
        
        NSMenuItem *item = [[NSMenuItem alloc] init];
        item.title = app.localizedName;
        item.tag = i;
        item.image = app.icon;
        item.action = @selector(menuSelected:);
        
        [self.apps addObject:app];
        [self.switchMenu addItem:item];
        
        i++;
    }
    
    [self.switchMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *item = [[NSMenuItem alloc] init];
    item.title = @"Quit SwitchMenu";
    item.target = [NSApplication sharedApplication];
    item.action = @selector(terminate:);
    
    [self.switchMenu addItem:item];
}

- (void)menuSelected:(id)sender {
    NSMenuItem *item = sender;
    NSInteger tag = item.tag;
    
    NSRunningApplication *app = [self.apps objectAtIndex:tag];
    NSString *identifier = app.bundleIdentifier;
    app = [NSRunningApplication runningApplicationsWithBundleIdentifier:identifier][0];
    [app activateWithOptions:0];
}

@end
