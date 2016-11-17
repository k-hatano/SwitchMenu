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
@property (weak) IBOutlet NSMenuItem *miOptions;

@property (assign) NSInteger iMenuTitle;
@property (assign) NSInteger iIconSmall;

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
    
    [self changeMenuTitle];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(notify:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
}

- (void)notify:(NSNotification *)notification
{
    [self changeMenuTitle];
}

- (void)changeMenuTitle
{
    for (NSRunningApplication *app in self.apps) {
        if (app.ownsMenuBar) {
           
            switch (self.iMenuTitle) {
                case 0: {
                    self.sbItem.title = app.localizedName;
                    self.sbItem.image = nil;
                    break;
                }
                case 1: {
                    self.sbItem.title = @"";
                    self.sbItem.image = [AppDelegate resizeImage:app.icon small:YES monochrome:NO translucent:NO];
                    break;
                }
                case 2: {
                    self.sbItem.title = @"";
                    self.sbItem.image = app.icon;
                    break;
                }
                case 3: {
                    self.sbItem.title = app.localizedName;
                    self.sbItem.image = [AppDelegate resizeImage:app.icon small:YES monochrome:NO translucent:NO];
                    break;
                }
                case 4: {
                    self.sbItem.title = app.localizedName;
                    self.sbItem.image = app.icon;
                    break;
                }
                default:
                    break;
            }
            break;
        }
    }
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
    NSMenuItem *options = self.miOptions;
    
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
        
        if (self.iIconSmall) {
            item.image = [AppDelegate resizeImage:app.icon small:YES monochrome:NO translucent:NO];
        } else {
            item.image = app.icon;
        }
        item.action = @selector(menuSelected:);
        if (app.ownsMenuBar) {
            item.state = NSOnState;
        } else if (app.isHidden) {
            item.state = NSMixedState;
        } else {
            item.state = NSOffState;
        }
        
        [self.apps addObject:app];
        [self.switchMenu addItem:item];
        
        i++;
    }
    
    [self.switchMenu addItem:[NSMenuItem separatorItem]];
    [self.switchMenu addItem:options];
}

- (void)menuSelected:(id)sender {
    NSMenuItem *item = sender;
    NSInteger tag = item.tag;
    
    NSRunningApplication *app = [self.apps objectAtIndex:tag];
    [app activateWithOptions:NSApplicationActivateIgnoringOtherApps];
}

- (IBAction)setMenuTitle:(NSMenuItem *)sender {
    self.iMenuTitle = sender.tag;
    [self changeMenuTitle];
    [self createSubmenuOfSwitchMenu];
}

- (IBAction)setIconSmall:(NSMenuItem *)sender {
    self.iIconSmall = sender.tag;
    [self changeMenuTitle];
    [self createSubmenuOfSwitchMenu];
}

+ (NSImage *)resizeImage:(NSImage *)image small:(BOOL)small monochrome:(BOOL)monochrome translucent:(BOOL)translucent {
    NSImage *resultImage = [image copy];
    
    if (small) {
        NSImage *tmpImage = [[NSImage alloc] initWithSize:NSMakeSize(20, 20)];
        [tmpImage lockFocus];
        [resultImage drawInRect:NSMakeRect(0, 0, tmpImage.size.width, tmpImage.size.height)];
        [tmpImage unlockFocus];
        resultImage = tmpImage;
    }
    
    return resultImage;
}

@end
