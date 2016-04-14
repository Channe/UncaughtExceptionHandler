//
//  UncaughtExceptionHandler.m
//  SyntaxHighlight
//
//  Created by QianLei on 16/4/13.
//  Copyright © 2016年 ichanne. All rights reserved.
//

#import "UncaughtExceptionHandler.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>

NSString * const kMySignalExceptionName = @"kMySignalExceptionName";
NSString * const kMySignalKey = @"kMySignalKey";
NSString * const kMyBackTraceKey = @"kMyBackTraceKey";

volatile int32_t UncaughtExceptionCount = 0;
const int32_t UncaughtExceptionMaximum = 10;

const NSInteger kMyFirstTraceCount = 4;
const NSInteger kMyTotalTraceCount = 5;

@implementation UncaughtExceptionHandler

+ (NSString *)signalNameWithID:(int)signalID {
    NSString *signalName = @"";
    switch (signalID) {
        case 1:
            signalName = @"SIGHUP";
            break;
        case 2:
            signalName = @"SIGINT";
            break;
        case 3:
            signalName = @"SIGQUIT";
            break;
        case 4:
            signalName = @"SIGILL";
            break;
        case 5:
            signalName = @"SIGTRAP";
            break;
        case 6:
            signalName = @"SIGABRT";
            break;
        case 7:
            signalName = @"SIGPOLL";
            break;
        case 11:
            signalName = @"SIGSEGV";
            break;
        case 12:
            signalName = @"SIGSYS";
            break;
        default:
            signalName = [@(signalID) stringValue];
            break;
    }
    return signalName;
}

+ (NSArray *)backtrace
{
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    //记录kMyFirstTraceCount层到kMyFirstTraceCount + kMyTotalTraceCount层的堆栈信息
    for (i = kMyFirstTraceCount; i < kMyFirstTraceCount + kMyTotalTraceCount; i++)
    {
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    
    return backtrace;
}

//保存应用临时数据
- (void)validateAndSaveCriticalApplicationData
{
    
}

- (void)handleException:(NSException *)exception
{
    [self validateAndSaveCriticalApplicationData];

    NSString *message = [NSString stringWithFormat:
                         @"点击<继续>,应用可能不稳定.\n崩溃原因:\n%@\n崩溃堆栈:\n%@\n\n设备信息:\n%@",
                         [exception reason],
                         [[exception userInfo] objectForKey:kMyBackTraceKey],
                         [self getAppInfo]];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"未处理的异常" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"继续" style:UIAlertActionStyleDestructive
                               handler:^(UIAlertAction * action) {
                                   //do something
                               }];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:@"退出"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction *action) {
                                       _isDismissed = YES;
                                   }];
    [alert addAction:okAction];
    [alert addAction:cancelAction];
    
    [[UIApplication sharedApplication].keyWindow.rootViewController
     presentViewController:alert animated:YES completion:nil];
    
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
    
    //点击『继续』会一直在循环内，点击"退出"就不再进入循环，进入系统的崩溃处理->闪退
    while (!_isDismissed)
    {
        for (NSString *mode in (__bridge NSArray *)allModes)
        {
            CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
        }
    }
    
    CFRelease(allModes);
    
    //If the user selects "Quit" we want the crash to be logged
    //remove all the exception handlers and re-raise the exception or resend the signal.
    NSSetUncaughtExceptionHandler(NULL);
    
    signal(SIGABRT, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    
    if ([[exception name] isEqual:kMySignalExceptionName]) {
        /*
         int kill(pid_t pid, int sig);
         The kill() function sends the signal specified by sig to pid, a process
         or a group of processes.
         */
        kill(getpid(), [[exception userInfo][kMySignalKey] intValue]);
    } else {
        [exception raise];
    }
}

- (NSString *)getAppInfo
{
    NSString *appInfo = [NSString stringWithFormat:@"App名称:%@ %@(%@)\n设备:%@\niOS版本:%@ %@",
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"],
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"],
                         [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
                         [UIDevice currentDevice].model,
                         [UIDevice currentDevice].systemName,
                         [UIDevice currentDevice].systemVersion];
//    NSLog(@"发生崩溃!!!! %@", appInfo);
    return appInfo;
}

@end

#pragma mark -

void MyHandleException(NSException *exception)
{
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    //最多捕获 UncaughtExceptionMaximum 次崩溃
    if (exceptionCount > UncaughtExceptionMaximum) {
        return;
    }
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
    
    NSArray *callStack = [UncaughtExceptionHandler backtrace];
    userInfo[kMyBackTraceKey] = callStack;
    
    NSException *exc = [NSException exceptionWithName:[exception name]
                                               reason:[exception reason]
                                             userInfo:userInfo];
    
    UncaughtExceptionHandler *hander = [[UncaughtExceptionHandler alloc] init];
    [hander performSelectorOnMainThread:@selector(handleException:)
                             withObject:exc
                          waitUntilDone:YES];
}

void MySignalHandler(int signal)
{
    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    if (exceptionCount > UncaughtExceptionMaximum) {
        return;
    }
    
    NSMutableDictionary *userInfo = [@{kMySignalKey:@(signal)} mutableCopy];
    
    NSArray *callStack = [UncaughtExceptionHandler backtrace];
    userInfo[kMyBackTraceKey] = callStack;
    
    NSString *reason = [NSString stringWithFormat:@"信号%@ 被触发.",
                        [UncaughtExceptionHandler signalNameWithID:signal]];
    NSException *exc = [NSException exceptionWithName:kMySignalExceptionName
                                               reason:reason
                                             userInfo:userInfo];
    
    UncaughtExceptionHandler *hander = [[UncaughtExceptionHandler alloc] init];
    [hander performSelectorOnMainThread:@selector(handleException:)
                             withObject:exc
                          waitUntilDone:YES];
}

//There are two signals which cannot be caught: SIGKILL and SIGSTOP. These are sent to your application to end it or suspend it without notice
//gdb will interfere with signal handling
//When you're debugging, the SIGBUS and SIGSEGV signals may not get called.
void InstallUncaughtExceptionHandler() 
{
    //为什么点击继续按钮，下面两种崩溃处理会轮流调用？
    
    //Changes the top-level error handler.
    //Sets the top-level error-handling function where you can perform last-minute logging before the program terminates.
    //install a handler for uncaught Objective-C exceptions.
    NSSetUncaughtExceptionHandler(&MyHandleException);
    
    //simplified software signal facilities
    //install handlers for BSD signals.
    signal(SIGABRT, MySignalHandler);
    signal(SIGILL, MySignalHandler);
    signal(SIGSEGV, MySignalHandler);
    signal(SIGFPE, MySignalHandler);
    signal(SIGBUS, MySignalHandler);
    signal(SIGPIPE, MySignalHandler);
}

