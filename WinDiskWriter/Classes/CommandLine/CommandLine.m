//
//  CommandLine.m
//  windiskwriter
//
//  Created by Macintosh on 26.01.2023.
//  Copyright © 2023 TechUnRestricted. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommandLine.h"

@implementation CommandLine

+ (CommandLineData *_Nullable)execute: (NSString *)executable
                            arguments: (NSArray *_Nullable)arguments
                            exception: (NSException *_Nullable *_Nullable)nsException {
    @try {
        NSTask *task = [[NSTask alloc] init];
                
        NSPipe *standartPipe = [NSPipe pipe];
        [task setStandardOutput: standartPipe];
        
        NSPipe *errorPipe = [NSPipe pipe];
        [task setStandardError: errorPipe];
        
        [task setLaunchPath: executable];
        
        if (arguments) {
            [task setArguments: arguments];
        }
        
        NSFileHandle *fileHandleStandardPipe = [standartPipe fileHandleForReading];
        NSFileHandle *fileHandleErrorPipe = [errorPipe fileHandleForReading];
        
        dispatch_group_t pipeGroup = dispatch_group_create();
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        __block NSData *standardData = nil;
        __block NSData *errorData = nil;
        
        dispatch_group_async(pipeGroup, queue, ^{
            standardData = [fileHandleStandardPipe readDataToEndOfFile];
        });
        
        dispatch_group_async(pipeGroup, queue, ^{
            errorData = [fileHandleErrorPipe readDataToEndOfFile];
        });
        
        [task launch];
        [task waitUntilExit];
        dispatch_group_wait(pipeGroup, DISPATCH_TIME_FOREVER);
        
        CommandLineData *commandLineData = [[CommandLineData alloc] initWithProcessIdentifier: [task processIdentifier]
                                                                            terminationStatus: [task terminationStatus]
                                                                            terminationReason: [task terminationReason]
                                                                                 standardData: standardData
                                                                                    errorData: errorData];
        
        fileHandleStandardPipe = NULL;
        fileHandleErrorPipe = NULL;
        
        return commandLineData;
    } @catch (NSException *exception) {
        /* An error occurred while executing a terminal command */
        if (nsException) {
            *nsException = exception;
        }
    }
    
    return NULL;
}

@end
