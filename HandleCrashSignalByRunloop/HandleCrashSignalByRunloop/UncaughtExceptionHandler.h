//
//  UncaughtExceptionHandler.h
//  SyntaxHighlight
//
//  Created by QianLei on 16/4/13.
//  Copyright © 2016年 ichanne. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UncaughtExceptionHandler : NSObject {
    BOOL _isDismissed;
} 

@end

#pragma mark -
void InstallUncaughtExceptionHandler();