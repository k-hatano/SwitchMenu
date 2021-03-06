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
@property (weak) IBOutlet NSMenuItem *miMenuTitleAllIcon;
@property (weak) IBOutlet NSMenuItem *miMenuTitleAllIconMono;
@property (weak) IBOutlet NSMenuItem *miAppIconLarge;
@property (weak) IBOutlet NSMenuItem *miAppIconSmall;
@property (weak) IBOutlet NSMenuItem *miAppIconSmallMono;
@property (weak) IBOutlet NSMenuItem *miOrderAppName;
@property (weak) IBOutlet NSMenuItem *miOrderLaunchTime;
@property (weak) IBOutlet NSMenuItem *miShowNumberOfWindows;
@property (weak) IBOutlet NSMenuItem *miShow32BitOnly;

@property (assign) NSInteger iMenuTitle;
@property (assign) NSInteger iIconSmall;
@property (assign) NSInteger iOrder;
@property (assign) NSInteger iShowNumberOfWindows;
@property (assign) NSInteger iShow32BitOnly;

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
                    self.sbItem.title = [self appName:app];
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
                    self.sbItem.title = [self appName:app];
                    self.sbItem.image = [AppDelegate resizeImage:app.icon small:YES
                                                      monochrome:NO translucent:NO];
                    break;
                }
                case 4: {
                    self.sbItem.title = [self appName:app];
                    self.sbItem.image = [AppDelegate resizeImage:app.icon small:YES
                                                      monochrome:YES translucent:NO];
                    break;
                }
                case 5: {
                    self.sbItem.title = @"";
                    self.sbItem.image = [self makeAllAppsImageMonochrome:NO];
                    break;
                }
                case 6: {
                    self.sbItem.title = @"";
                    self.sbItem.image = [self makeAllAppsImageMonochrome:YES];
                    break;
                }
                default:
                    break;
            }
            
            self.sbItem.toolTip = [NSString stringWithFormat:@"%@ - SwitchMenu", app.localizedName];
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
    NSArray *menuItems = [[fileManager contentsOfDirectoryAtPath:folderPath error:NULL] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString * obj2) {
        NSStringCompareOptions compareOptions = (NSCaseInsensitiveSearch);
        return [obj1 compare:obj2 options:compareOptions];
    }];
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
        
        NSString *title = [self appName:app];
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
            if (app.isHidden) {
                title = [NSString stringWithFormat:@"%@ (-)",title];
            } else {
                title = [NSString stringWithFormat:@"%@ (%ld)",title,numWindows];
            }
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
        NSString *arch;
        switch (app.executableArchitecture) {
            case NSBundleExecutableArchitectureI386:
                arch = @"i386";
                break;
            case NSBundleExecutableArchitectureX86_64:
                arch = @"x86_64";
                break;
            default:
                arch = @"N/A";
        }
        [tooltip appendFormat:@"\nExecutable Architecture:\n%@\n", arch];
        // [tooltip appendFormat:@"\nBundle Identifier:\n%@\n",app.bundleIdentifier];
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
    NSUInteger modifierFlags = [NSEvent modifierFlags];
    
    NSMenuItem *item = sender;
    NSInteger tag = item.tag;
    
    NSRunningApplication *app = [self.apps objectAtIndex:tag];
    if ((modifierFlags & NSAlternateKeyMask) && (modifierFlags & NSCommandKeyMask)) {
        NSInteger shownApps = 0;
        for (NSRunningApplication *anApp in self.apps) {
            if (![anApp isEqual:app] && ![anApp isHidden]) {
                shownApps++;
            }
        }
        
        if (shownApps <= 0) {
            for (NSRunningApplication *anApp in self.apps) {
                [anApp unhide];
            }
        } else {
            [app activateWithOptions:NSApplicationActivateIgnoringOtherApps];
            
            for (NSRunningApplication *anApp in self.apps) {
                if (![anApp isEqual:app]) {
                    [anApp hide];
                }
            }
        }
    } else if (modifierFlags & NSAlternateKeyMask) {
        NSRunningApplication *currentApp = [NSRunningApplication currentApplication];
        
        for (NSRunningApplication *anApp in self.apps) {
            if (anApp.ownsMenuBar) {
                currentApp = anApp;
                break;
            }
        }
        
        [app activateWithOptions:NSApplicationActivateIgnoringOtherApps];
        [currentApp hide];
    } else if (modifierFlags & NSCommandKeyMask) {
        [[NSWorkspace sharedWorkspace] selectFile:[app.bundleURL path]
                         inFileViewerRootedAtPath:[[app.bundleURL path] stringByDeletingLastPathComponent]];
    } else {
        [app activateWithOptions:NSApplicationActivateIgnoringOtherApps];
    }
    
    if (modifierFlags & NSControlKeyMask) {
        [app activateWithOptions:NSApplicationActivateIgnoringOtherApps];
        
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/open";
        task.arguments = @[@"-a", @"mission control", @"--args", @"2"];
        [task launch];
    }
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

- (NSImage *)makeAllAppsImageMonochrome:(BOOL)monochrome {
    NSImage *tmpImage = [[NSImage alloc] initWithSize:NSMakeSize(SMALL_ICON_WIDTH * [self.apps count], SMALL_ICON_WIDTH)];
    [tmpImage lockFocus];
    
    NSInteger appIndex = 0;
    for (NSRunningApplication *app in self.apps) {
        NSImage *appImage = app.icon;
        BOOL translucent = [app isHidden];
        
        [appImage drawInRect:NSMakeRect(SMALL_ICON_WIDTH * appIndex, 0, SMALL_ICON_WIDTH, SMALL_ICON_WIDTH)
                    fromRect:NSMakeRect(0, 0, appImage.size.width, appImage.size.height)
                   operation:NSCompositeSourceOver
                    fraction:translucent ? 0.3f : 1.0f];
        
        if ([app ownsMenuBar]) {
            [[NSColor blackColor] set];
            NSRectFill(NSMakeRect(SMALL_ICON_WIDTH * appIndex, 0, SMALL_ICON_WIDTH, 1));
        }
        
        appIndex++;
    }
    [tmpImage unlockFocus];
    
    if (monochrome) {
        tmpImage = [tmpImage grayscaleImage];
    }
    
    return tmpImage;
}

- (NSString *)appName:(NSRunningApplication *)app {
    if (self.iShow32BitOnly && [app executableArchitecture] == NSBundleExecutableArchitectureI386) {
        return [app.localizedName stringByAppendingString:@" (32-bit)"];
    } else {
        return app.localizedName;
    }
}

#pragma mark - User Defaults

#define UD [NSUserDefaults standardUserDefaults]
#define UDMenuTitle @"MenuTitle"
#define UDIconSmall @"IconSmall"
#define UDOrder @"Order"
#define UDShowNumberOfWindows @"ShowNumberOfWindows"
#define UDShow32BitOnly @"Show32BitOnly"

- (void)loadUserDefaults {
    self.iMenuTitle = [UD integerForKey:UDMenuTitle];
    self.iIconSmall = [UD integerForKey:UDIconSmall];
    self.iOrder = [UD integerForKey:UDOrder];
    self.iShowNumberOfWindows = [UD integerForKey:UDShowNumberOfWindows];
    self.iShow32BitOnly = [UD integerForKey:UDShowNumberOfWindows];
}

- (void)saveUserDefaults {
    [UD setInteger:self.iMenuTitle forKey:UDMenuTitle];
    [UD setInteger:self.iIconSmall forKey:UDIconSmall];
    [UD setInteger:self.iOrder forKey:UDOrder];
    [UD setInteger:self.iShowNumberOfWindows forKey:UDShowNumberOfWindows];
    [UD setInteger:self.iShow32BitOnly forKey:UDShow32BitOnly];
}

- (void)recheckMenuItems {
    self.miMenuTitleAppName.state           = self.iMenuTitle == 0 ? NSOnState : NSOffState;
    self.miMenuTitleIcon.state              = self.iMenuTitle == 1 ? NSOnState : NSOffState;
    self.miMenuTitleIconMono.state          = self.iMenuTitle == 2 ? NSOnState : NSOffState;
    self.miMenuTitleAppNameIcon.state       = self.iMenuTitle == 3 ? NSOnState : NSOffState;
    self.miMenuTitleAppNameIconMono.state   = self.iMenuTitle == 4 ? NSOnState : NSOffState;
    self.miMenuTitleAllIcon.state           = self.iMenuTitle == 5 ? NSOnState : NSOffState;
    self.miMenuTitleAllIconMono.state       = self.iMenuTitle == 6 ? NSOnState : NSOffState;
    
    self.miAppIconLarge.state       = self.iIconSmall == 0 ? NSOnState : NSOffState;
    self.miAppIconSmall.state       = self.iIconSmall == 1 ? NSOnState : NSOffState;
    self.miAppIconSmallMono.state   = self.iIconSmall == 2 ? NSOnState : NSOffState;
    
    self.miOrderAppName.state      = self.iOrder == 0 ? NSOnState : NSOffState;
    self.miOrderLaunchTime.state   = self.iOrder == 1 ? NSOnState : NSOffState;
    
    self.miShowNumberOfWindows.state  = self.iShowNumberOfWindows > 0 ? NSOnState : NSOffState;
    self.miShow32BitOnly.state  = self.iShow32BitOnly > 0 ? NSOnState : NSOffState;
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

- (IBAction)setShow32BitOnly:(NSMenuItem *)sender {
    self.iShow32BitOnly = sender.state == NSOnState ? 0 : 1;
    
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
    NSUInteger modifierFlags = [NSEvent modifierFlags];
    
    NSInteger tag = ((NSMenuItem *)sender).tag;
    NSString *filePath = self.items[tag];
    
    if (modifierFlags & NSCommandKeyMask) {
        [[NSWorkspace sharedWorkspace] selectFile:filePath
                         inFileViewerRootedAtPath:[filePath stringByDeletingLastPathComponent]];
    } else {
        [[NSWorkspace sharedWorkspace] openFile:filePath];
    }
}


@end
