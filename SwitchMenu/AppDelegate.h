//
//  AppDelegate.h
//  SwitchMenu
//
//  Created by HatanoKenta on 2016/11/15.
//  Copyright © 2016年 Nita. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>

@property(weak, nonatomic) IBOutlet NSMenu *switchMenu;

@end

