//
//  AppDelegate.m
//  SwitchMenu
//
//  Created by HatanoKenta on 2016/11/15.
//  Copyright © 2016年 Nita. All rights reserved.
//

#import "AppDelegate.h"
#import "NSImage+Grayscale.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSMenuItem *miActions;
@property (weak) IBOutlet NSMenuItem *miHideApp;
@property (weak) IBOutlet NSMenuItem *miHideOthers;
@property (weak) IBOutlet NSMenuItem *miShowAll;
@property (weak) IBOutlet NSMenuItem *miQuitApp;
@property (weak) IBOutlet NSMenuItem *miOptions;
@property (weak) IBOutlet NSMenuItem *miMenuTitleAppName;
@property (weak) IBOutlet NSMenuItem *miMenuTitleIcon;
@property (weak) IBOutlet NSMenuItem *miMenuTitleIconMono;
@property (weak) IBOutlet NSMenuItem *miMenuTitleAppNameIcon;
@property (weak) IBOutlet NSMenuItem *miMenuTitleAppNameIconMono;
@property (weak) IBOutlet NSMenuItem *miAppIconLarge;
@property (weak) IBOutlet NSMenuItem *miAppIconSmall;
@property (weak) IBOutlet NSMenuItem *miAppIconSmallMono;

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
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(applicationDidActive:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)applicationDidActive:(NSNotification *)notification
{
    [self createSubmenuOfSwitchMenu];
    [self changeMenuTitle];
}

- (void)menuWillOpen:(NSMenu *)menu {
    if (menu == self.switchMenu)  {
        [self createSubmenuOfSwitchMenu];
    }
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
                    self.sbItem.image = [AppDelegate resizeImage:app.icon small:YES
                                                      monochrome:NO translucent:NO];
                    break;
                }
                case 2: {
                    self.sbItem.title = @"";
                    self.sbItem.image = [AppDelegate resizeImage:app.icon small:YES
                                                      monochrome:YES translucent:NO];
                    break;
                }
                case 3: {
                    self.sbItem.title = app.localizedName;
                    self.sbItem.image = [AppDelegate resizeImage:app.icon small:YES
                                                      monochrome:NO translucent:NO];
                    break;
                }
                case 4: {
                    self.sbItem.title = app.localizedName;
                    self.sbItem.image = [AppDelegate resizeImage:app.icon small:YES
                                                      monochrome:YES translucent:NO];
                    break;
                }
                default:
                    break;
            }
            break;
        }
    }
}

- (void)createSubmenuOfSwitchMenu {
    NSMenuItem *actions = self.miActions;
    NSMenuItem *options = self.miOptions;
    BOOL enableShowAll = NO;
    BOOL enableHideOthers = NO;
    
    [self.switchMenu removeAllItems];
    
    self.apps = [[NSMutableArray alloc] init];
    
    NSArray *apps = [[NSWorkspace sharedWorkspace] runningApplications];
    NSRunningApplication *currentApp = [NSRunningApplication currentApplication];
    NSInteger selection = -1;
    
    NSInteger i = 0;
    
    for (NSRunningApplication *app in apps) {
        if (app.activationPolicy != NSApplicationActivationPolicyRegular){
            continue;
        }
        if (app.ownsMenuBar){
            currentApp = app;
            selection = i;
        } else {
            if (app.isHidden) {
                enableShowAll = YES;
            } else {
                enableHideOthers = YES;
            }
        }
        
        NSMenuItem *item = [[NSMenuItem alloc] init];
        item.title = app.localizedName;
        item.tag = i;
        
        BOOL translucent = NO;
        if (app.isHidden) {
            translucent = YES;
        }
        
        switch (self.iIconSmall) {
            case 0: {
                item.image = [AppDelegate resizeImage:app.icon small:NO
                                           monochrome:NO translucent:translucent];
                break;
            }
            case 1: {
                item.image = [AppDelegate resizeImage:app.icon small:YES
                                           monochrome:NO translucent:translucent];
                break;
            }
            case 2: {
                item.image = [AppDelegate resizeImage:app.icon small:YES
                                           monochrome:YES translucent:translucent];
                break;
            }
            default:
                break;
        }
        
        item.action = @selector(menuSelected:);
        if (app.ownsMenuBar) {
            item.state = NSOnState;
        } else {
            item.state = NSOffState;
        }
        
        [self.apps addObject:app];
        [self.switchMenu addItem:item];
        
        i++;
    }
    
    self.miHideApp.title = [NSString stringWithFormat:@"Hide %@", currentApp.localizedName];
    self.miQuitApp.title = [NSString stringWithFormat:@"Quit %@", currentApp.localizedName];
    
    [self.switchMenu addItem:[NSMenuItem separatorItem]];
    [self.switchMenu addItem:actions];
    [self.switchMenu addItem:options];
    
    if (enableHideOthers) {
        self.miHideOthers.action = @selector(actionHideOthers:);
    } else {
        self.miHideOthers.action = nil;
    }
    
    if (enableShowAll) {
        self.miShowAll.action = @selector(actionShowAll:);
    } else {
        self.miShowAll.action = nil;
    }
    
}

- (void)menuSelected:(id)sender {
    NSMenuItem *item = sender;
    NSInteger tag = item.tag;
    
    NSRunningApplication *app = [self.apps objectAtIndex:tag];
    [app activateWithOptions:NSApplicationActivateIgnoringOtherApps];
}

+ (NSImage *)resizeImage:(NSImage *)image small:(BOOL)small
              monochrome:(BOOL)monochrome translucent:(BOOL)translucent {
    NSImage *resultImage = [image copy];
    NSImage *tmpImage;
    
    if (small) {
        tmpImage = [[NSImage alloc] initWithSize:NSMakeSize(20, 20)];
    } else {
        tmpImage = [[NSImage alloc] initWithSize:NSMakeSize(image.size.width, image.size.height)];
    }
    
    [tmpImage lockFocus];
    [resultImage drawInRect:NSMakeRect(0, 0, tmpImage.size.width, tmpImage.size.height)
                   fromRect:NSMakeRect(0, 0, resultImage.size.width, resultImage.size.height)
                  operation:NSCompositeSourceOver
                   fraction:translucent ? 0.3f : 1.0f];
    [tmpImage unlockFocus];
    resultImage = tmpImage;
    
    if (monochrome) {
        resultImage = [resultImage grayscaleImage];
    }
    
    return resultImage;
}


#pragma mark - IBAction

- (IBAction)setMenuTitle:(NSMenuItem *)sender {
    self.iMenuTitle = sender.tag;
    
    self.miMenuTitleAppName.state           = self.iMenuTitle == 0 ? NSOnState : NSOffState;
    self.miMenuTitleIcon.state              = self.iMenuTitle == 1 ? NSOnState : NSOffState;
    self.miMenuTitleIconMono.state          = self.iMenuTitle == 2 ? NSOnState : NSOffState;
    self.miMenuTitleAppNameIcon.state       = self.iMenuTitle == 3 ? NSOnState : NSOffState;
    self.miMenuTitleAppNameIconMono.state   = self.iMenuTitle == 4 ? NSOnState : NSOffState;
    
    [self changeMenuTitle];
    [self createSubmenuOfSwitchMenu];
}

- (IBAction)setIconSmall:(NSMenuItem *)sender {
    self.iIconSmall = sender.tag;
    
    self.miAppIconLarge.state       = self.iIconSmall == 0 ? NSOnState : NSOffState;
    self.miAppIconSmall.state       = self.iIconSmall == 1 ? NSOnState : NSOffState;
    self.miAppIconSmallMono.state   = self.iIconSmall == 2 ? NSOnState : NSOffState;
    
    [self changeMenuTitle];
    [self createSubmenuOfSwitchMenu];
}

- (IBAction)actionHideApp:(id)sender {
    for (NSRunningApplication *app in self.apps) {
        if (app.ownsMenuBar) {
            [app hide];
            break;
        }
    }
}

- (IBAction)actionHideOthers:(id)sender {
    for (NSRunningApplication *app in self.apps) {
        if (!app.ownsMenuBar) {
            [app hide];
        }
    }
}

- (IBAction)actionShowAll:(id)sender {
    for (NSRunningApplication *app in self.apps) {
        [app unhide];
    }
}

- (IBAction)actionQuitApp:(id)sender {
    for (NSRunningApplication *app in self.apps) {
        if (app.ownsMenuBar) {
            [app terminate];
            break;
        }
    }
}

@end
