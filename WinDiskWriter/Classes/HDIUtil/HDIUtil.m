//
//  HDIUtil.m
//  windiskwriter
//
//  Created by Macintosh on 26.01.2023.
//  Copyright © 2023 TechUnRestricted. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocalizedStrings.h"
#import "NSString+Common.h"
#import "NSError+Common.h"
#import "CommandLine.h"
#import "Constants.h"
#import "HDIUtil.h"

@implementation HDIUtil {
    NSString *mountPoint;
    NSString *BSDEntry;
    NSString *volumeKind;
}

- (BOOL)attachImageWithArguments: (NSArray * _Nullable)arguments
                           error: (NSError *_Nullable *_Nullable)error {
    NSMutableArray *localArgumentsArray = [NSMutableArray arrayWithArray: @[
        @"attach",
        self.imagePath,
        @"-plist"]
    ];
    
    if (arguments != NULL) {
        /* Adding custom arguments to the HDIUtil attach command */
        [localArgumentsArray addObjectsFromArray:arguments];
    }
    
    NSException *imageMountException = NULL;
    
    CommandLineData *commandLineData = [CommandLine execute: self.hdiutilPath
                                                  arguments: localArgumentsArray
                                                  exception: &imageMountException];
    
    if (imageMountException != NULL) {
        if (error) {
            NSString *exceptionErrorString = [NSString stringWithFormat: @"%@ (%@)", [LocalizedStrings errorTextCommandLineExecuteFailure], imageMountException.reason];
            
            *error = [NSError errorWithStringValue: exceptionErrorString];
        }
        
        return NO;
    }
        
    if (commandLineData.terminationStatus != EXIT_SUCCESS) {
        NSString *errorString = [[NSString alloc] initWithData: commandLineData.errorData
                                                      encoding: NSUTF8StringEncoding].strip;
        
        NSString *finalErrorDescription = [NSString stringWithFormat:@"%@\n[%@]", [LocalizedStrings errorTextHdiutilStatusWasNotExitSuccess], errorString];
      
        if (error) {
            *error = [NSError errorWithStringValue: finalErrorDescription];
        }
        
        return NO;
    }
    
    NSString *plistLoadErrorDescription;
    NSDictionary *plist = [NSPropertyListSerialization
                           propertyListFromData: commandLineData.standardData
                           mutabilityOption: NSPropertyListImmutable
                           format: NULL
                           errorDescription: &plistLoadErrorDescription];
    
    if (plist == NULL) {
        if (error) {
            *error = [NSError errorWithStringValue: [LocalizedStrings errorTextCantParseHdiutilOutput]];
        }
        
        return NO;
    }
    
    /* Output from hdiutil was successfully parsed into NSDictionary */
    
    NSArray *systemEntities = [plist objectForKey:@"system-entities"];
    if (systemEntities == NULL) {
        if (error) {
            *error = [NSError errorWithStringValue: [LocalizedStrings errorTextPlistCantLoadSystemEntities]];
        }
        
        return NO;
    }
    
    if ([systemEntities count] == 0) {
        if (error) {
            *error = [NSError errorWithStringValue: [LocalizedStrings errorTextPlistSystemEntitiesIsEmpty]];
        }
        
        return NO;
    }
    
    NSDictionary *matchedEntity = NULL;
    for (NSDictionary *entity in systemEntities) {
        if ([entity objectForKey:@"mount-point"] != NULL) {
            matchedEntity = entity;
            break;
        }
    }
    
    if (matchedEntity == NULL) {
        matchedEntity = [systemEntities firstObject];
    }
    
    BSDEntry = [matchedEntity objectForKey:@"dev-entry"];
    mountPoint = [matchedEntity objectForKey:@"mount-point"];
    volumeKind = [matchedEntity objectForKey:@"volume-kind"];
    
    return YES;
}

- (BOOL)detachWithError: (NSError *_Nullable *_Nullable)error {
    NSString *target = mountPoint != NULL ? mountPoint : BSDEntry;
    if (target == NULL) {
        return YES;
    }
    
    NSException *detachException = NULL;
    CommandLineData *commandLineData = [CommandLine execute: self.hdiutilPath
                                                  arguments: @[@"detach", target, @"-force"]
                                                  exception: &detachException];
    
    if (detachException != NULL) {
        if (error) {
            *error = [NSError errorWithStringValue: detachException.reason];
        }
        return NO;
    }
    
    if (commandLineData.terminationStatus != EXIT_SUCCESS) {
        if (error) {
            NSString *errStr = [[NSString alloc] initWithData: commandLineData.errorData encoding: NSUTF8StringEncoding].strip;
            *error = [NSError errorWithStringValue: errStr];
        }
        return NO;
    }
    
    BSDEntry = NULL;
    mountPoint = NULL;
    volumeKind = NULL;
    return YES;
}

- (BOOL)attachImageWithError: (NSError *_Nullable *_Nullable)attachImageError {
    NSError *attachWithArgumentsError = NULL;
    
    [self attachImageWithArguments:NULL
                             error: &attachWithArgumentsError];
    
    if (attachImageError != NULL) {
        *attachImageError = attachWithArgumentsError;
    }
    
    return YES;
}

- (void)initDefaultProperties {
    _hdiutilPath = @"/usr/bin/hdiutil";
}

- (instancetype)initWithImagePath: (NSString *)imagePath {
    self = [super init];
    
    [self initDefaultProperties];
    
    _imagePath = imagePath;
    
    return self;
}

- (NSString *)BSDEntry {
    return BSDEntry;
}

- (NSString *)mountPoint {
    return mountPoint;
}

- (NSString *)volumeKind {
    return volumeKind;
}

@end

