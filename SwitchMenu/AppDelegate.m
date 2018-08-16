//
//  AppDelegate.m
//  SwitchMenu
//
//  Created by HatanoKenta on 2016/11/15.
//  Copyright © 2016年 Nita. All rights reserved.
//

#import "AppDelegate.h"
#import "NSImage+Grayscale.h"

#define SMALL_ICON_WIDTH 19

#define SWITCHMENU_ITEMS_FOLDER_PATH @"~/Library/SwitchMenu Items/"

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
@property (weak) IBOutlet NSMenuItem *miOrderAppName;
@property (weak) IBOutlet NSMenuItem *miOrderLaunchTime;
@property (weak) IBOutlet NSMenuItem *miShowNumberOfWindows;

@property (assign) NSInteger iMenuTitle;
@property (assign) NSInteger iIconSmall;
@property (assign) NSInteger iOrder;
@property (assign) NSInteger iShowNumberOfWindows;

@property (strong, retain) NSStatusItem *sbItem;
@property (strong, retain) NSMutableArray *apps;
@property (strong, retain) NSMutableArray *items;


@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self loadUserDefaults];
    
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
    [self recheckMenuItems];
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

- (NSMenuItem *)menuItemForFileName:(NSString *)fileName FilePath:(NSString *)path tag:(NSInteger)tag {
    NSMenuItem *item = [[NSMenuItem alloc] init];
    item.title = fileName;
    item.tag = tag;
    item.target = self;
    item.action = @selector(selectSwitchMenuFolderItem:);
    
    item.image = [AppDelegate resizeImage:[[NSWorkspace sharedWorkspace] iconForFile:path]
                                    small:(self.iIconSmall == 1 || self.iIconSmall == 2 ? YES : NO)
                               monochrome:(self.iIconSmall == 2 ? YES : NO)
                              translucent:NO];
    
    NSMutableString *tooltip = [[NSMutableString alloc] init];
    [tooltip appendFormat:@"Full Path:\n%@\n",path];
    item.toolTip = tooltip;
    
    return item;
}

- (void)createSubmenuOfSwitchMenu {
    NSMenuItem *actions = self.miActions;
    NSMenuItem *options = self.miOptions;
    BOOL enableShowAll = NO;
    BOOL enableHideOthers = NO;
    
    NSMutableArray *submenus = [[NSMutableArray alloc] init];
    NSMutableArray *submenuPaths = [[NSMutableArray alloc] init];
    
    [self.switchMenu removeAllItems];
    
    self.items = [[NSMutableArray alloc] init];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *folderPath = [SWITCHMENU_ITEMS_FOLDER_PATH stringByExpandingTildeInPath];
    NSArray *menuItems = [fileManager contentsOfDirectoryAtPath:folderPath error:NULL];
    NSInteger tag = 0;
    if (menuItems && [menuItems count] > 0) {
        for (NSString *fileName in menuItems) {
            if ([fileName rangeOfString:@"."].location == 0) {
                continue;
            }
            NSString *path = [[folderPath stringByAppendingString:@"/"] stringByAppendingString:fileName];
            
            NSMenuItem *item = [self menuItemForFileName:fileName FilePath:path tag:tag];
            
            BOOL isDirectory;
            [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
            if (isDirectory) {
                NSMenu *menu = [[NSMenu alloc] init];
                item.submenu = menu;
                [submenuPaths addObject:path];
                [submenus addObject:menu];
            }
            
            [self.items addObject:path];
            [self.switchMenu addItem:item];
            tag++;
        }
        
        while ([submenus count] > 0) {
            NSString *folderPath = submenuPaths[0];
            NSMenu *submenu = submenus[0];
            
            [submenus removeObjectAtIndex:0];
            [submenuPaths removeObjectAtIndex:0];
            
            NSArray *menuItems = [fileManager contentsOfDirectoryAtPath:folderPath error:NULL];
            if (menuItems && [menuItems count] > 0) {
                for (NSString *fileName in menuItems) {
                    if ([fileName rangeOfString:@"."].location == 0) {
                        continue;
                    }
                    NSString *path = [[folderPath stringByAppendingString:@"/"] stringByAppendingString:fileName];
                    
                    NSMenuItem *item = [self menuItemForFileName:fileName FilePath:path tag:tag];
                    
                    BOOL isDirectory;
                    [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
                    if (isDirectory) {
                        NSMenu *menu = [[NSMenu alloc] init];
                        item.submenu = menu;
                        [submenuPaths addObject:path];
                        [submenus addObject:menu];
                    }
                    
                    [self.items addObject:path];
                    [submenu addItem:item];
                    tag++;
                }
            } else {
                NSMenuItem *item = [[NSMenuItem alloc] init];
                item.title = @"No Items";
                [submenu addItem:item];
            }
        }
        
        if ([self.items count] > 0) {
            [self.switchMenu addItem:[NSMenuItem separatorItem]];
        }
    }
    
    self.apps = [[NSMutableArray alloc] init];
    
    NSArray *apps = [[NSWorkspace sharedWorkspace] runningApplications];
    NSRunningApplication *currentApp = [NSRunningApplication currentApplication];
    NSInteger selection = -1;
    
    NSInteger i = 0;
    
    switch (self.iOrder) {
        case 0:
            apps = [apps sortedArrayUsingComparator:^NSComparisonResult(NSRunningApplication *obj1, NSRunningApplication * obj2) {
                NSStringCompareOptions compareOptions = (NSCaseInsensitiveSearch);
                return [[obj1 localizedName] compare:[obj2 localizedName] options:compareOptions];
            }];
            break;
        case 1:
            apps = [apps sortedArrayUsingComparator:^NSComparisonResult(NSRunningApplication *obj1, NSRunningApplication * obj2) {
                return [obj1 launchDate].timeIntervalSince1970 > [obj2 launchDate].timeIntervalSince1970;
            }];
            break;
        default:
            break;
    }
    
    CFArrayRef windowList = CGWindowListCopyWindowInfo((kCGWindowListOptionOnScreenOnly|kCGWindowListExcludeDesktopElements), kCGNullWindowID);
    CFDictionaryRef windowDictionary;
    
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
        
        NSString *title = app.localizedName;
        NSMutableArray *windows = [[NSMutableArray alloc] init];
        
        NSInteger numWindows = 0;
        
        for (CFIndex i = 0; i < CFArrayGetCount(windowList); i++){
            windowDictionary = CFArrayGetValueAtIndex(windowList, i);
            if ((int)CFDictionaryGetValue(windowDictionary, kCGWindowLayer) > 1000) {
                continue;
            }
            
            if ([(__bridge NSString *)CFDictionaryGetValue(windowDictionary, kCGWindowOwnerPID) integerValue]
                == app.processIdentifier) {
                NSString *windowTitle = (NSString *)CFDictionaryGetValue(windowDictionary, kCGWindowName);
                if ([windowTitle length] <= 0) {
                    windowTitle = @"(untitled)";
                }
                if ([windowTitle length] > 32) {
                    windowTitle = [NSString stringWithFormat:@"%@...", [windowTitle substringWithRange:NSMakeRange(0, 32)]];
                }
                [windows addObject:windowTitle];
                numWindows++;
            }
        }
        
        if (self.iShowNumberOfWindows > 0) {
            title = [NSString stringWithFormat:@"%@ (%ld)",title,numWindows];
        }
        
        NSMenuItem *item = [[NSMenuItem alloc] init];
        item.title = title;
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
        
        NSMutableString *tooltip = [[NSMutableString alloc] init];
        [tooltip appendFormat:@"Full Path:\n%@\n",[app.bundleURL path]];
        [tooltip appendFormat:@"\nBundle Identifier:\n%@\n",app.bundleIdentifier];
        if (app.launchDate) {
            [tooltip appendFormat:@"\nLaunch Date/Time:\n%@\n",app.launchDate];
        } else {
            [tooltip appendFormat:@"\nLaunch Date/Time:\n%@\n", @"N/A"];
        }
        if ([windows count] > 0) {
            [tooltip appendFormat:@"\nWindows:\n%@\n", [windows componentsJoinedByString:@"\n"]];
        }
        item.toolTip = tooltip;
        
        [self.apps addObject:app];
        [self.switchMenu addItem:item];
        
        i++;
    }
    
    CFBridgingRelease(windowList);
    
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
        tmpImage = [[NSImage alloc] initWithSize:NSMakeSize(SMALL_ICON_WIDTH, SMALL_ICON_WIDTH)];
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

#pragma mark - User Defaults

#define UD [NSUserDefaults standardUserDefaults]
#define UDMenuTitle @"MenuTitle"
#define UDIconSmall @"IconSmall"
#define UDOrder @"Order"
#define UDShowNumberOfWindows @"ShowNumberOfWindows"

- (void)loadUserDefaults {
    self.iMenuTitle = [UD integerForKey:UDMenuTitle];
    self.iIconSmall = [UD integerForKey:UDIconSmall];
    self.iOrder = [UD integerForKey:UDOrder];
    self.iShowNumberOfWindows = [UD integerForKey:UDShowNumberOfWindows];
}

- (void)saveUserDefaults {
    [UD setInteger:self.iMenuTitle forKey:UDMenuTitle];
    [UD setInteger:self.iIconSmall forKey:UDIconSmall];
    [UD setInteger:self.iOrder forKey:UDOrder];
    [UD setInteger:self.iShowNumberOfWindows forKey:UDShowNumberOfWindows];
}

- (void)recheckMenuItems {
    self.miMenuTitleAppName.state           = self.iMenuTitle == 0 ? NSOnState : NSOffState;
    self.miMenuTitleIcon.state              = self.iMenuTitle == 1 ? NSOnState : NSOffState;
    self.miMenuTitleIconMono.state          = self.iMenuTitle == 2 ? NSOnState : NSOffState;
    self.miMenuTitleAppNameIcon.state       = self.iMenuTitle == 3 ? NSOnState : NSOffState;
    self.miMenuTitleAppNameIconMono.state   = self.iMenuTitle == 4 ? NSOnState : NSOffState;
    
    self.miAppIconLarge.state       = self.iIconSmall == 0 ? NSOnState : NSOffState;
    self.miAppIconSmall.state       = self.iIconSmall == 1 ? NSOnState : NSOffState;
    self.miAppIconSmallMono.state   = self.iIconSmall == 2 ? NSOnState : NSOffState;
    
    self.miOrderAppName.state      = self.iOrder == 0 ? NSOnState : NSOffState;
    self.miOrderLaunchTime.state   = self.iOrder == 1 ? NSOnState : NSOffState;
    
    self.miShowNumberOfWindows.state  = self.iShowNumberOfWindows > 0 ? NSOnState : NSOffState;
}


#pragma mark - IBAction

- (IBAction)setMenuTitle:(NSMenuItem *)sender {
    self.iMenuTitle = sender.tag;
    
    [self changeMenuTitle];
    [self recheckMenuItems];
    [self createSubmenuOfSwitchMenu];
    [self saveUserDefaults];
}

- (IBAction)setIconSmall:(NSMenuItem *)sender {
    self.iIconSmall = sender.tag;
    
    [self changeMenuTitle];
    [self recheckMenuItems];
    [self createSubmenuOfSwitchMenu];
    [self saveUserDefaults];
}

- (IBAction)setOrder:(NSMenuItem *)sender {
    self.iOrder = sender.tag;
    
    [self changeMenuTitle];
    [self recheckMenuItems];
    [self createSubmenuOfSwitchMenu];
    [self saveUserDefaults];
}

- (IBAction)setShowNumberOfWindows:(NSMenuItem *)sender {
    self.iShowNumberOfWindows = sender.state == NSOnState ? 0 : 1;
    
    [self changeMenuTitle];
    [self recheckMenuItems];
    [self createSubmenuOfSwitchMenu];
    [self saveUserDefaults];
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

- (IBAction)openSwitchMenuItemsFolder:(id)sender {
    NSString *folderPath = [SWITCHMENU_ITEMS_FOLDER_PATH stringByExpandingTildeInPath];
    BOOL result = [[NSFileManager defaultManager] fileExistsAtPath:folderPath];
    
    if (result) {
        [[NSWorkspace sharedWorkspace] openFile:folderPath];
    } else {
        NSAlert *alert = [NSAlert alertWithMessageText:@"SwitchMenu Items Folder doesn't exist."
                                         defaultButton:@"OK"
                                       alternateButton:@"Cancel"
                                           otherButton:nil
                             informativeTextWithFormat:@"Would you like to make new SwitchMenu Items Folder?"];
        
        NSInteger result = [alert runModal];
        
        if (result == NSAlertDefaultReturn) {
            [[NSFileManager defaultManager] createDirectoryAtPath:folderPath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:NULL];
            
            [[NSWorkspace sharedWorkspace] openFile:folderPath];
        }
    }
}

- (IBAction)selectSwitchMenuFolderItem:(id)sender {
    NSString *folderPath = [SWITCHMENU_ITEMS_FOLDER_PATH stringByExpandingTildeInPath];
    
    NSInteger tag = ((NSMenuItem *)sender).tag;
    NSString *filePath = self.items[tag];
    [[NSWorkspace sharedWorkspace] openFile:filePath];
}


@end
