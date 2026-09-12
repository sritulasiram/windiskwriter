//
//  MainWindow.m
//  WinDiskWriter GUI
//
//  Created by Macintosh on 30.08.2023.
//  Copyright © 2023 TechUnRestricted. All rights reserved.
//

#import "MainWindow.h"
#import "FrameLayout.h"
#import "LabelView.h"
#import "LogView.h"
#import "VibrantTableView.h"

#import "ButtonView.h"
#import "PickerView.h"
#import "TextInputView.h"
#import "CheckBoxView.h"
#import "AdvancedTextView.h"
#import "ProgressBarView.h"

#import "LocalizedStrings.h"

#import "SynchronizedAlertData.h"
#import "NSFileManager+Common.h"
#import "SimpleDownloadManager.h"
#import "NSColor+Common.h"
#import "NSString+Common.h"
#import "NSError+Common.h"

#import "Constants.h"

#import "DiskManagerProcessor.h"
#import "DiskWriter.h"

#import "HelperFunctions.h"

#define WriteExitForce()                \
[self setEnabledUIState: YES];          \
return;

#define WriteExitConditionally()      \
if (self.isScheduledForStop) {        \
WriteExitForce();                     \
}

@implementation MainWindow {
    TextInputView *windowsImageInputView;
    ButtonView *chooseWindowsImageButtonView;
    
    PickerView *devicePickerView;
    ButtonView *updateDeviceListButtonView;
    
    CheckBoxView *patchInstallerRequirementsCheckboxView;
    CheckBoxView *installLegacyBootCheckBoxView;
    NSSegmentedControl *filesystemPickerSegmentedControl;
    NSSegmentedControl *partitionSchemePickerSegmentedControl;
    
    LogView *logsView;
    ButtonView *toggleLogButtonView;
    FrameLayoutVertical *mainVerticalLayout;
    BOOL isLogExpanded;
    
    ButtonView *startStopButtonView;
    
    LabelView *currentOperationLabelView;
    LabelView *currentProgressDetailsLabelView;
    ProgressBarView *currentOperationProgressBarView;
    
    LabelView *totalOperationLabelView;
    LabelView *totalProgressDetailsLabelView;
    ProgressBarView *totalOperationProgressBarView;
    
    /* Initialized in -init */
    NSMenuItem *quitMenuItem;
    NSMenuItem *closeMenuItem;

    NSMenuItem *scanAllWholeDisksMenuItem;
    
    ModernWindow *aboutWindow;
}

- (instancetype)initWithNSRect: (NSRect)nsRect
                         title: (NSString *)title
                       padding: (CGFloat)padding
        paddingIsTitleBarAware: (BOOL)paddingIsTitleBarAware
                   aboutWindow: (AboutWindow *)aboutWindow
                  quitMenuItem: (NSMenuItem *)quitMenuItem
                 closeMenuItem: (NSMenuItem *)closeMenuItem
     scanAllWholeDisksMenuItem: (NSMenuItem *)scanAllWholeDisksMenuItem {
    
    self = [super initWithNSRect: nsRect
                           title: title
                         padding: padding
          paddingIsTitleBarAware: paddingIsTitleBarAware];
    
    // TODO: Replace with some kind of container
    self->aboutWindow = aboutWindow;
    self->quitMenuItem = quitMenuItem;
    self->closeMenuItem = closeMenuItem;
    self->scanAllWholeDisksMenuItem = scanAllWholeDisksMenuItem;
    [scanAllWholeDisksMenuItem setTarget: self];
    
    NSButton *windowZoomButton = [self standardWindowButton: NSWindowZoomButton];
    [windowZoomButton setEnabled: NO];
    
    [self setOnCloseSelector: @selector(quitApplication)
                      target: [HelperFunctions class]];
    
    [self setupViews];
    
    return self;
}

- (void)resetProgress {
    [self setCurrentProgressWithWrittenBytes: 0
                               fileSizeBytes: 0];
    [self setTotalProgressWithWrittenBytes: 0
                                totalBytes: 0];
    [self setCurrentProgressTitle: [LocalizedStrings progressTitleReadyForAction]];
    
    [currentOperationProgressBarView resetProgressSynchronously];
    [totalOperationProgressBarView resetProgressSynchronously];
}

- (void)setupViews {
    NSView *spacerView = [[NSView alloc] init];
    
    [self showWindow];
    
    mainVerticalLayout = (FrameLayoutVertical *)self.containerView;
    isLogExpanded = NO;
    
    [mainVerticalLayout setSpacing: MAIN_CONTENT_SPACING];
    
    FrameLayoutVertical *isoPickerVerticalLayout = [[FrameLayoutVertical alloc] init]; {
        [mainVerticalLayout addView:isoPickerVerticalLayout width:INFINITY height:0];
        
        [isoPickerVerticalLayout setHugHeightFrame: YES];
        
        [isoPickerVerticalLayout setSpacing: CHILD_CONTENT_SPACING];
        
        LabelView *isoPickerLabelView = [[LabelView alloc] init]; {
            [isoPickerVerticalLayout addView:isoPickerLabelView width:INFINITY height:isoPickerLabelView.cell.cellSize.height];
            
            [isoPickerLabelView setStringValue: [LocalizedStrings labelviewTitleWindowsImage]];
            
            [isoPickerLabelView setWantsLayer: YES];
        }
        
        FrameLayoutHorizontal *isoPickerHorizontalLayout = [[FrameLayoutHorizontal alloc] init]; {
            [isoPickerVerticalLayout addView:isoPickerHorizontalLayout width:INFINITY height:0];
            
            [isoPickerHorizontalLayout setHugHeightFrame: YES];
            
            [isoPickerHorizontalLayout setVerticalAlignment: FrameLayoutVerticalCenter];
            
            [isoPickerHorizontalLayout setSpacing: CHILD_CONTENT_SPACING];
            
            windowsImageInputView = [[TextInputView alloc] init]; {
                [isoPickerHorizontalLayout addView:windowsImageInputView width:INFINITY height:windowsImageInputView.cell.cellSize.height];
                
                if (@available(macOS 10.10, *)) {
                    [windowsImageInputView setPlaceholderString: [LocalizedStrings inputviewPlaceholderImageFileOrDirectory]];
                }
            }
            
            chooseWindowsImageButtonView = [[ButtonView alloc] init]; {
                [isoPickerHorizontalLayout addView:chooseWindowsImageButtonView minWidth:80 maxWidth:100 minHeight:0 maxHeight:INFINITY];
                
                [chooseWindowsImageButtonView setTitle: [LocalizedStrings buttonTitleChoose]];
                [chooseWindowsImageButtonView setTarget: self];
                [chooseWindowsImageButtonView setAction: @selector(chooseImageAction)];
            }
        }
    }
    
    FrameLayoutVertical *devicePickerVerticalLayout = [[FrameLayoutVertical alloc] init]; {
        [mainVerticalLayout addView:devicePickerVerticalLayout width:INFINITY height:0];
        
        [devicePickerVerticalLayout setHugHeightFrame: YES];
        
        [devicePickerVerticalLayout setSpacing: CHILD_CONTENT_SPACING];
        
        
        LabelView *devicePickerLabelView = [[LabelView alloc] init]; {
            [devicePickerVerticalLayout addView:devicePickerLabelView width:INFINITY height:devicePickerLabelView.cell.cellSize.height];
            
            [devicePickerLabelView setStringValue: [LocalizedStrings labelviewTitleTargetDevice]];
        }
        
        FrameLayoutHorizontal *devicePickerHorizontalLayout = [[FrameLayoutHorizontal alloc] init]; {
            [devicePickerVerticalLayout addView:devicePickerHorizontalLayout width:INFINITY height:0];
            
            [devicePickerHorizontalLayout setSpacing: 6];
                
            [devicePickerHorizontalLayout setHugHeightFrame:YES];
            
            devicePickerView = [[PickerView alloc] init]; {
                [devicePickerHorizontalLayout addView:devicePickerView minWidth:0 maxWidth:INFINITY minHeight:0 maxHeight:devicePickerView.cell.cellSize.height];
                
                [self updateDeviceListWithWholeDiskFiltrationEnabled];
            }
            
            updateDeviceListButtonView = [[ButtonView alloc] init]; {
                [devicePickerHorizontalLayout addView:updateDeviceListButtonView minWidth:80 maxWidth:100 minHeight:0 maxHeight:INFINITY];
                
                [updateDeviceListButtonView setTitle: [LocalizedStrings buttonTitleUpdate]];
                [updateDeviceListButtonView setTarget: self];
                [updateDeviceListButtonView setAction: @selector(updateDeviceListWithWholeDiskFiltrationEnabled)];
            }
        }
    }
    
    [mainVerticalLayout addView:spacerView width:INFINITY height: 3];
    
    patchInstallerRequirementsCheckboxView = [[CheckBoxView alloc] init]; {
        [mainVerticalLayout addView:patchInstallerRequirementsCheckboxView width:INFINITY height:patchInstallerRequirementsCheckboxView.cell.cellSize.height];
        
        [patchInstallerRequirementsCheckboxView setTitle: [LocalizedStrings checkboxviewTitlePatchInstallerRequirements]];
        [patchInstallerRequirementsCheckboxView setToolTip: [LocalizedStrings checkboxviewTooltipPatchInstallerRequirements]];
        
        [patchInstallerRequirementsCheckboxView setState: NSOffState];
    }
    
    installLegacyBootCheckBoxView = [[CheckBoxView alloc] init]; {
        [mainVerticalLayout addView:installLegacyBootCheckBoxView width:INFINITY height:installLegacyBootCheckBoxView.cell.cellSize.height];
        
        [installLegacyBootCheckBoxView setTitle: [LocalizedStrings checkboxviewTitleInstallLegacyBootSector]];
        [installLegacyBootCheckBoxView setToolTip: [LocalizedStrings checkboxviewTooltipInstallLegacyBootSector]];
        
        [installLegacyBootCheckBoxView setState: [HelperFunctions hasElevatedRights]];

        if (![HelperFunctions hasElevatedRights]) {
            [installLegacyBootCheckBoxView setAction: @selector(requireRestartAsRoot)];
        }
    }
    
    [mainVerticalLayout addView:spacerView width:INFINITY height: 3];
    
    FrameLayoutVertical *formattingSectionVerticalLayout = [[FrameLayoutVertical alloc] init]; {
        [mainVerticalLayout addView:formattingSectionVerticalLayout width:INFINITY height:0];
        
        [formattingSectionVerticalLayout setToolTip: [LocalizedStrings tooltipFramelayoutFormattingSection]];
        
        [formattingSectionVerticalLayout setHugHeightFrame: YES];
        [formattingSectionVerticalLayout setSpacing: CHILD_CONTENT_SPACING];
        
        FrameLayoutVertical *fileSystemPickerVerticalLayout = [[FrameLayoutVertical alloc] init]; {
            [formattingSectionVerticalLayout addView:fileSystemPickerVerticalLayout width:INFINITY height:0];
            [fileSystemPickerVerticalLayout setHugHeightFrame: YES];
            
            [fileSystemPickerVerticalLayout setSpacing:CHILD_CONTENT_SPACING];
            
            LabelView *filesystemLabelView = [[LabelView alloc] init]; {
                [fileSystemPickerVerticalLayout addView:filesystemLabelView width:INFINITY height:filesystemLabelView.cell.cellSize.height];
                
                [filesystemLabelView setStringValue: [LocalizedStrings labelviewTitleFilesystem]];
            }
            
            filesystemPickerSegmentedControl = [[NSSegmentedControl alloc] init]; {
                [filesystemPickerSegmentedControl setSegmentCount:2];
                
                [filesystemPickerSegmentedControl setLabel:FILESYSTEM_TYPE_FAT32_TITLE forSegment:0];
                [filesystemPickerSegmentedControl setLabel:FILESYSTEM_TYPE_EXFAT_TITLE forSegment:1];
                
                [filesystemPickerSegmentedControl setSelectedSegment:0];
                
                [fileSystemPickerVerticalLayout addView:filesystemPickerSegmentedControl width:INFINITY height:filesystemPickerSegmentedControl.cell.cellSize.height];
            }
        }
    }
    
    FrameLayoutVertical *operationMonitoringVerticalLayout = [[FrameLayoutVertical alloc] init]; {
        [mainVerticalLayout addView:operationMonitoringVerticalLayout width:INFINITY height:0];
        
        [operationMonitoringVerticalLayout setHugHeightFrame: YES];
        
        [operationMonitoringVerticalLayout setSpacing: 3];
        
        // Section 1: Current Operation
        FrameLayoutHorizontal *currentTextInfoHorizontalLayout = [[FrameLayoutHorizontal alloc] init]; {
            [operationMonitoringVerticalLayout addView:currentTextInfoHorizontalLayout width:INFINITY height:0];
            
            [currentTextInfoHorizontalLayout setAlphaValue: 0.85];
            [currentTextInfoHorizontalLayout setHugHeightFrame: YES];
            [currentTextInfoHorizontalLayout setSpacing: 4];
            
            currentOperationLabelView = [[LabelView alloc] init]; {
                [currentOperationLabelView.cell setLineBreakMode: NSLineBreakByTruncatingMiddle];
                [currentTextInfoHorizontalLayout addView:currentOperationLabelView width:INFINITY height:currentOperationLabelView.cell.cellSize.height];
            }
            
            currentProgressDetailsLabelView = [[LabelView alloc] init]; {
                [currentProgressDetailsLabelView setAlignment: NSTextAlignmentRight];
                if (@available(macOS 10.15, *)) {
                    [currentProgressDetailsLabelView setFont: [NSFont monospacedDigitSystemFontOfSize: [NSFont smallSystemFontSize] weight: NSFontWeightRegular]];
                } else {
                    [currentProgressDetailsLabelView setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
                }
                [currentTextInfoHorizontalLayout addView: currentProgressDetailsLabelView
                                               minWidth: 100
                                               maxWidth: 220
                                              minHeight: currentOperationLabelView.cell.cellSize.height
                                              maxHeight: currentOperationLabelView.cell.cellSize.height];
            }
        }
        
        currentOperationProgressBarView = [[ProgressBarView alloc] init]; {
            [operationMonitoringVerticalLayout addView:currentOperationProgressBarView width:INFINITY height:12];
        }
        
        [operationMonitoringVerticalLayout addView:spacerView width:INFINITY height:4];
        
        // Section 2: Total Progress
        FrameLayoutHorizontal *totalTextInfoHorizontalLayout = [[FrameLayoutHorizontal alloc] init]; {
            [operationMonitoringVerticalLayout addView:totalTextInfoHorizontalLayout width:INFINITY height:0];
            
            [totalTextInfoHorizontalLayout setAlphaValue: 0.85];
            [totalTextInfoHorizontalLayout setHugHeightFrame: YES];
            [totalTextInfoHorizontalLayout setSpacing: 4];
            
            totalOperationLabelView = [[LabelView alloc] init]; {
                [totalOperationLabelView setStringValue: @"Total Progress"];
                [totalTextInfoHorizontalLayout addView:totalOperationLabelView width:INFINITY height:totalOperationLabelView.cell.cellSize.height];
            }
            
            totalProgressDetailsLabelView = [[LabelView alloc] init]; {
                [totalProgressDetailsLabelView setAlignment: NSTextAlignmentRight];
                if (@available(macOS 10.15, *)) {
                    [totalProgressDetailsLabelView setFont: [NSFont monospacedDigitSystemFontOfSize: [NSFont smallSystemFontSize] weight: NSFontWeightRegular]];
                } else {
                    [totalProgressDetailsLabelView setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
                }
                [totalTextInfoHorizontalLayout addView: totalProgressDetailsLabelView
                                             minWidth: 100
                                             maxWidth: 220
                                            minHeight: totalOperationLabelView.cell.cellSize.height
                                            maxHeight: totalOperationLabelView.cell.cellSize.height];
            }
        }
        
        totalOperationProgressBarView = [[ProgressBarView alloc] init]; {
            [operationMonitoringVerticalLayout addView:totalOperationProgressBarView width:INFINITY height:12];
        }
    }
    
    FrameLayoutVertical *startStopVerticalLayout = [[FrameLayoutVertical alloc] init]; {
        [mainVerticalLayout addView:startStopVerticalLayout width:INFINITY height:0];
        
        [startStopVerticalLayout setHorizontalAlignment: FrameLayoutHorizontalCenter];
        [startStopVerticalLayout setVerticalAlignment: FrameLayoutVerticalCenter];
        [startStopVerticalLayout setHugHeightFrame: YES];
        [startStopVerticalLayout setSpacing: 6];
        
        startStopButtonView = [[ButtonView alloc] init]; {
            [startStopVerticalLayout addView:startStopButtonView minWidth:100 maxWidth:180 minHeight:startStopButtonView.cell.cellSize.height maxHeight:startStopButtonView.cell.cellSize.height];
            
            [startStopButtonView setTarget: self];
        }
        
        toggleLogButtonView = [[ButtonView alloc] init]; {
            [toggleLogButtonView setControlSize: NSControlSizeSmall];
            [toggleLogButtonView setFont: [NSFont systemFontOfSize: [NSFont smallSystemFontSize]]];
            [toggleLogButtonView setTitle: [LocalizedStrings buttonTitleShowLog]];
            [toggleLogButtonView setTarget: self];
            [toggleLogButtonView setAction: @selector(toggleLogVisibility)];
            
            [startStopVerticalLayout addView:toggleLogButtonView minWidth:70 maxWidth:130 minHeight:toggleLogButtonView.cell.cellSize.height maxHeight:toggleLogButtonView.cell.cellSize.height];
        }
    }
    
    logsView = [[LogView alloc] init];
    
    [self setEnabledUIState: YES];
}

- (void)toggleLogVisibility {
    [self setLogExpanded: !isLogExpanded animate: YES];
}

- (void)setLogExpanded: (BOOL)expanded animate: (BOOL)animate {
    if (isLogExpanded == expanded) {
        return;
    }
    
    isLogExpanded = expanded;
    const CGFloat deltaHeight = 160.0f;
    NSRect currentFrame = self.frame;
    NSRect newFrame = currentFrame;
    
    if (isLogExpanded) {
        [toggleLogButtonView setTitle: [LocalizedStrings buttonTitleHideLog]];
        
        [mainVerticalLayout addView:logsView minWidth:0 maxWidth:INFINITY minHeight:120 maxHeight:INFINITY];
        
        newFrame.size.height += deltaHeight;
        newFrame.origin.y -= deltaHeight;
        
        NSScreen *screen = self.screen ?: [NSScreen mainScreen];
        if (screen && newFrame.origin.y < screen.visibleFrame.origin.y) {
            newFrame.origin.y = screen.visibleFrame.origin.y;
        }
        
        [self setMinSize: NSMakeSize(340, 540)];
        [self setFrame: newFrame display: YES animate: animate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self->logsView.tableViewInstance.numberOfRows > 0) {
                [self->logsView.tableViewInstance scrollRowToVisible: self->logsView.tableViewInstance.numberOfRows - 1];
            }
        });
    } else {
        [toggleLogButtonView setTitle: [LocalizedStrings buttonTitleShowLog]];
        
        [mainVerticalLayout removeView:logsView];
        
        newFrame.size.height -= deltaHeight;
        newFrame.origin.y += deltaHeight;
        
        [self setMinSize: NSMakeSize(340, 380)];
        [self setFrame: newFrame display: YES animate: animate];
    }
    
    [mainVerticalLayout setNeedsDisplay: YES];
}

- (void)displayWarningAlertWithTitle: (NSString *)title
                            subtitle: (NSString *_Nullable)subtitle
                                icon: (NSImageName)icon {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self->isLogExpanded) {
            [self setLogExpanded: YES animate: YES];
        }
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText: title];
        
        if (subtitle) {
            [alert setInformativeText: subtitle];
        }
        
        [alert setIcon: [NSImage imageNamed: icon]];
        
        [alert beginSheetModalForWindow: self
                          modalDelegate: NULL
                         didEndSelector: NULL
                            contextInfo: NULL];
    });
}

- (void)alertActionStopPromptDidEnd: (NSAlert *)alert
                         returnCode: (NSInteger)returnCode
                        contextInfo: (void *)contextInfo {
    if (returnCode == NSAlertSecondButtonReturn) {
        [startStopButtonView setTitle: [LocalizedStrings buttonTitleStopping]];
        
        [startStopButtonView setEnabled: NO];
        
        [self setIsScheduledForStop: YES];
    }
}

- (void)alertWarnAboutErrorDuringWriting: (NSAlert *)alert
                              returnCode: (NSInteger)returnCode
                             contextInfo: (void *)contextInfo {
    SynchronizedAlertData *synchronizedAlertData = (__bridge SynchronizedAlertData *)(contextInfo);
    [synchronizedAlertData setResultCode:returnCode];
    
    dispatch_semaphore_signal(synchronizedAlertData.semaphore);
}

- (void)stopAction {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: [LocalizedStrings alertTitleStopProcess]];
    [alert setInformativeText: [LocalizedStrings alertSubtitleStopProcess]];
    [alert addButtonWithTitle: [LocalizedStrings buttonTitleDismiss]];
    [alert addButtonWithTitle: [LocalizedStrings buttonTitleCancellationSchedule]];
    
    [alert beginSheetModalForWindow: self
                      modalDelegate: self
                     didEndSelector: @selector(alertActionStopPromptDidEnd:returnCode:contextInfo:)
                        contextInfo: NULL];
}

// MARK: - Restart as Root -
- (void)alertActionRestartAsRootDidEnd: (NSAlert *)alert
                            returnCode: (NSInteger)returnCode
                           contextInfo: (void *)contextInfo {
    NSError *restartError = NULL;
    
    if (returnCode == NSAlertFirstButtonReturn) {
        [HelperFunctions restartAppWithElevatedPermissions: YES
                                                     error: &restartError];
    }
    
    if (restartError != NULL) {
        [self displayWarningAlertWithTitle: [LocalizedStrings alertTitleFailedToRestart]
                                  subtitle: [restartError stringValue]
                                      icon: NSImageNameCaution];
    }
}

- (void)requireRestartAsRoot {
    [installLegacyBootCheckBoxView setState: NSOffState];

    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: [LocalizedStrings alertTitleRequireRestartAsRoot]];
    [alert setInformativeText: [LocalizedStrings alertSubtitleRequireRestartAsRoot]];
    [alert addButtonWithTitle: [LocalizedStrings buttonTitleRelaunch]];
    [alert addButtonWithTitle: [LocalizedStrings buttonTitleDismiss]];
    
    [alert beginSheetModalForWindow: self
                      modalDelegate: self
                     didEndSelector: @selector(alertActionRestartAsRootDidEnd:returnCode:contextInfo:)
                        contextInfo: NULL];
}

// MARK: - Need To Download Grub4Dos -
- (void)showNeedToDownloadGrub4DosFilesAlert {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: [LocalizedStrings alertTitleLegacyBootSupport]];
    [alert setInformativeText: [LocalizedStrings alertSubtitleLegacyBootSupport]];
    
    [alert addButtonWithTitle: [LocalizedStrings genericContinue]];
    [alert addButtonWithTitle: [LocalizedStrings genericCancel]];
    
    [alert beginSheetModalForWindow: self
                      modalDelegate: self
                     didEndSelector: @selector(alertNeedToDownloadGrub4DosFilesDidEnd:returnCode:contextInfo:)
                        contextInfo: NULL];
}

- (void)alertNeedToDownloadGrub4DosFilesDidEnd: (NSAlert *)alert
                                    returnCode: (NSInteger)returnCode
                                   contextInfo: (void *)contextInfo {
    if (returnCode == NSAlertSecondButtonReturn) {
        return;
    }
    
    [self writeAction];
}

// MARK: - Action Start -
- (void)alertActionStartPromptDidEnd: (NSAlert *)alert
                          returnCode: (NSInteger)returnCode
                         contextInfo: (void *)contextInfo {
    
    if (returnCode == NSAlertSecondButtonReturn) {
        return;
    }
    
    if (installLegacyBootCheckBoxView.state == NSControlStateValueOn && [HelperFunctions requiresLegacyBootloaderFilesDownload]) {
        [self showNeedToDownloadGrub4DosFilesAlert];
        return;
    }
    
    [self writeAction];
}

- (void)startAction {
    NSString *imagePath = [windowsImageInputView.stringValue copy];
    
    if (imagePath.length == 0) {
        [self displayWarningAlertWithTitle: [LocalizedStrings alertTitleForgotSomething]
                                  subtitle: [LocalizedStrings alertSubtitlePathFieldIsEmpty]
                                      icon: NSImageNameCaution];
        
        [logsView appendRow: [LocalizedStrings alertSubtitlePathFieldIsEmpty]
                    logType: ASLogTypeAssertionError];
        
        WriteExitForce();
    }

    BOOL imagePathIsDirectory = NO;
    BOOL imageExists = [[NSFileManager defaultManager] fileExistsAtPath: imagePath
                                                            isDirectory: &imagePathIsDirectory];
    
    if (!imageExists) {
        [self displayWarningAlertWithTitle: [LocalizedStrings alertTitleCheckDataCorrectness]
                                  subtitle: [LocalizedStrings alertSubtitlePathDoesNotExist]
                                      icon: NSImageNameCaution];
        
        [logsView appendRow: [LocalizedStrings alertSubtitlePathDoesNotExist]
                    logType: ASLogTypeAssertionError];
        
        WriteExitForce();
    }

    if ([devicePickerView numberOfItems] <= 0) {
        [self displayWarningAlertWithTitle: [LocalizedStrings alertTitleNoWritableDevices]
                                  subtitle: [LocalizedStrings alertSubtitlePressUpdateButton]
                                      icon: NSImageNameCaution];
        
        [logsView appendRow: [LocalizedStrings alertTitleNoWritableDevices]
                    logType: ASLogTypeAssertionError];
        
        WriteExitForce();
    }
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText: [LocalizedStrings alertTitlePromptStartProcess]];
    [alert setInformativeText: [LocalizedStrings alertSubtitlePromptStartProcess]];

    [alert addButtonWithTitle: [LocalizedStrings buttonTitleStart]];
    [alert addButtonWithTitle: [LocalizedStrings buttonTitleCancel]];

    [alert beginSheetModalForWindow: self
                      modalDelegate: self
                     didEndSelector: @selector(alertActionStartPromptDidEnd:returnCode:contextInfo:)
                        contextInfo: NULL];
}

- (void)setCurrentProgressWithWrittenBytes: (UInt64)writtenBytes
                             fileSizeBytes: (UInt64)fileSizeBytes {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (fileSizeBytes == 0) {
            [self->currentProgressDetailsLabelView setStringValue: @""];
            [self->currentOperationProgressBarView resetProgressSynchronously];
            return;
        }
        
        UInt64 percent = (writtenBytes >= fileSizeBytes) ? 100 : (UInt64)((writtenBytes * 100) / fileSizeBytes);
        NSString *progressText = [NSString stringWithFormat:@"%@ / %@ (%llu%%)",
                                  [HelperFunctions unitFormattedSizeFor: writtenBytes],
                                  [HelperFunctions unitFormattedSizeFor: fileSizeBytes],
                                  percent];
        [self->currentProgressDetailsLabelView setStringValue: progressText];
        
        [self->currentOperationProgressBarView setMinValue: 0.0];
        [self->currentOperationProgressBarView setMaxValue: (double)fileSizeBytes];
        [self->currentOperationProgressBarView setDoubleValue: (double)writtenBytes];
    });
}

- (void)setTotalProgressWithWrittenBytes: (UInt64)writtenBytes
                              totalBytes: (UInt64)totalBytes {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (totalBytes == 0) {
            [self->totalProgressDetailsLabelView setStringValue: @""];
            [self->totalOperationProgressBarView resetProgressSynchronously];
            return;
        }
        
        UInt64 percent = (writtenBytes >= totalBytes) ? 100 : (UInt64)((writtenBytes * 100) / totalBytes);
        NSString *progressText = [NSString stringWithFormat:@"%@ / %@ (%llu%%)",
                                  [HelperFunctions unitFormattedSizeFor: writtenBytes],
                                  [HelperFunctions unitFormattedSizeFor: totalBytes],
                                  percent];
        [self->totalProgressDetailsLabelView setStringValue: progressText];
        
        [self->totalOperationProgressBarView setMinValue: 0.0];
        [self->totalOperationProgressBarView setMaxValue: (double)totalBytes];
        [self->totalOperationProgressBarView setDoubleValue: (double)writtenBytes];
    });
}

- (void)setCurrentProgressTitle: (NSString *)progressTitle {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self->currentOperationLabelView setStringValue: progressTitle];
    });
}

- (BOOL)downloadLegacyBootloaderFiles {
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    
    NSArray<NSString *> *filesNeedToDownload = [HelperFunctions notDownloadedGrub4DosFilesArray];
    if (filesNeedToDownload.count == 0) {
        return YES;
    }
    
    NSString *applicationGrub4DosFolder = [HelperFunctions applicationGrub4DosFolder];
    
    NSString *temporaryDirectoryPathForAtomicMoving = [NSString pathWithComponents: @[
        [HelperFunctions applicationTempFolder],
        [NSString stringWithFormat: @"grub4dos-atomic-%@", [HelperFunctions randomStringWithLength: 8]]
    ]];
    
    // Creating directories at Application Folder path in order to store app files
    for (NSString *currentDirectoryPath in @[temporaryDirectoryPathForAtomicMoving, applicationGrub4DosFolder]) {
        BOOL currentDirectoryExists = [fileManager folderExistsAtPath: currentDirectoryPath];

        if (currentDirectoryExists) {
            continue;
        }
        
        NSString *createDirectoryLogString = [LocalizedStrings logviewRowCreateDirectoryAtAppFolderPathWithArgument1: currentDirectoryPath];
        [logsView appendRow:createDirectoryLogString logType:ASLogTypeStart];
        
        NSError *createDirectoryError = NULL;
        [fileManager createDirectoryAtPath: currentDirectoryPath
               withIntermediateDirectories: YES
                                attributes: NULL
                                     error: &createDirectoryError];
        
        if (createDirectoryError != NULL) {
            NSString *createDirectoryErrorLogString = [createDirectoryLogString stringByAppendingString:
                                                       [LocalizedStrings placeholderErrorWithArgument1: createDirectoryError.stringValue]
            ];
            
            [logsView appendRow:createDirectoryErrorLogString logType:ASLogTypeFatal];
            
            return NO;
        }
        
        [logsView appendRow:createDirectoryLogString logType:ASLogTypeSuccess];
    }
    
    // Checking which bootloader files we need to download from Web
    for (NSString *fileName in filesNeedToDownload) {
        NSString *sourcePath = [[HelperFunctions grub4DosDownloadLinkBase] stringByAppendingPathComponent: fileName];
        NSString *destinationPath = [applicationGrub4DosFolder stringByAppendingPathComponent: fileName];
        
        SimpleDownloadManager *downloadManager = [[SimpleDownloadManager alloc] initWithSourceURL: [NSURL URLWithString: sourcePath]
                                                                                  destinationPath: destinationPath
                                                                                temporaryFilePath: temporaryDirectoryPathForAtomicMoving];
        
        BOOL fileDownloadSuccess = [downloadManager downloadFileSynchronouslyWithCallback: ^BOOL(SDMMessage message, SDMMessageType messageType, void * _Nonnull SDMCallbackStruct, NSError * _Nullable error) {
            switch (message) {
                case SDMMessageDidReceiveResponse: {
                    SDMCallbackStructDidReceiveResponse *castedCallbackStruct = SDMCallbackStruct;
                    NSURLResponse *urlResponse = castedCallbackStruct->urlResponse;
                    
                    NSString *operationName = @"[SDMMessageDownloadDidReceiveResponse]";
                    
                    NSString *logString = [LocalizedStrings sdmMessageDownloadDidReceiveResponseWithArgument1: operationName
                                                                                                    argument2: urlResponse.URL
                                                                                                    argument3: [HelperFunctions unitFormattedSizeFor: urlResponse.expectedContentLength]];
                    
                    [self->logsView appendRow:logString logType:ASLogTypeLog];
                    
                    break;
                }
                case SDMMessageDidReceiveData: {
                    SDMCallbackStructDidReceiveData *castedCallbackStruct = SDMCallbackStruct;
                    NSData *data = castedCallbackStruct->data;
                    UInt64 downloadedBytesSize = castedCallbackStruct->downloadedBytesSize;
                    UInt64 chunkNumber = castedCallbackStruct->chunkNumber;
                    
                    NSString *operationName = @"[SDMMessageDownloadDidReceiveData]";
                    
                    NSString *logString = [LocalizedStrings sdmMessageDownloadDidReceiveDataWithArgument1: operationName
                                                                                                argument2: [HelperFunctions unitFormattedSizeFor: data.length]
                                                                                                argument3: [HelperFunctions unitFormattedSizeFor: downloadedBytesSize]
                                                                                                argument4: chunkNumber];
       
                    [self->logsView appendRow:logString logType:ASLogTypeLog];
                    
                    break;
                }
                case SDMMessageDidFinishLoading: {
                    SDMCallbackStructDidFinishLoading *castedCallbackStruct = SDMCallbackStruct;
                    UInt64 downloadedBytesSize = castedCallbackStruct->downloadedBytesSize;
                    UInt64 expectedFileSize = castedCallbackStruct->expectedFileSize;
                    
                    NSString *operationName = @"[SDMMessageDidFinishLoading]";
                    
                    NSString *logString = [LocalizedStrings sdmMessageDidFinishLoadingWithArgument1: operationName
                                                                                          argument2: [HelperFunctions unitFormattedSizeFor: downloadedBytesSize]
                                                                                          argument3: [HelperFunctions unitFormattedSizeFor: expectedFileSize]];
                    [self->logsView appendRow:logString logType:ASLogTypeLog];
                    
                    break;
                }
                case SDMMessageDidFailWithError: {
                    SDMCallbackStructDidFailWithError *castedCallbackStruct = SDMCallbackStruct;
                    NSURLRequest *urlRequest = castedCallbackStruct->urlRequest;
                                        
                    NSString *operationName = @"[SDMMessageDidFailWithError]";
                    NSString *logString = [NSString stringWithFormat: @"%@ -> [URL: %@]",
                                           operationName,
                                           urlRequest.URL
                    ];
                    
                    [self->logsView appendRow:logString logType:ASLogTypeFatal];
                }
            }
            
            if (error != NULL) {
                NSString *errorString = [NSString stringWithFormat: @"[File Download Error]: %@", error.stringValue];
                
                [self->logsView appendRow:errorString logType:ASLogTypeFatal];

                [self displayWarningAlertWithTitle: [LocalizedStrings errorTextBootloaderFilesCantBeDownloaded]
                                          subtitle: error.stringValue
                                              icon: NSImageNameCaution];
                
                return NO;
            }
            
            return YES;
        }];
                
        if (!fileDownloadSuccess) {
            return NO;
        }
    }
    
    return YES;
}

- (void)writeAction {
    [self setIsScheduledForStop: NO];
    [self setEnabledUIState: NO];
    
    // Saved information from the last device scanning operation
    DiskInfo *destinationSavedDiskInfo = [(IdentifiableMenuItem *)devicePickerView.selectedItem diskInfo];
    
    // Making sure that the selected BSD Device name is still available
    DiskManagerProcessor *secondVerifyingStageDiskManager = [[DiskManagerProcessor alloc] initWithBSDName:destinationSavedDiskInfo.BSDName];
    DiskInfo *secondVerifyingStageDiskInfo = [secondVerifyingStageDiskManager diskInfo];

    if (secondVerifyingStageDiskManager == NULL || !destinationSavedDiskInfo.isDeviceUnit) {
        [self displayWarningAlertWithTitle: [LocalizedStrings alertTitleBsdDeviceIsNoLongerAvailable]
                                  subtitle: [LocalizedStrings alertSubtitlePressUpdateButton]
                                      icon: NSImageNameCaution];
        
        [logsView appendRow: [LocalizedStrings alertTitleBsdDeviceIsNoLongerAvailable]
                    logType: ASLogTypeFatal];
        
        WriteExitForce();
    }
    
    /* !!DATA-LOSS PREVENTION!!
    - We need to make sure that we will format exactly the device that was selected in the list
    of available devices, and not the one that managed to occupy the vacated BSD Name.
    - The most adequate way in this case is to verify the initialization date of the bsd device. */
    
    if (destinationSavedDiskInfo.appearanceTime.doubleValue != secondVerifyingStageDiskInfo.appearanceTime.doubleValue) {
        [self displayWarningAlertWithTitle: [LocalizedStrings alertTitleBsdDeviceInfoIsOutdatedOrInvalid]
                                  subtitle: [LocalizedStrings alertSubtitlePressUpdateButton]
                                      icon: NSImageNameCaution];
        
        [logsView appendRow: [LocalizedStrings alertTitleBsdDeviceInfoIsOutdatedOrInvalid]
                    logType: ASLogTypeFatal];
        
        WriteExitForce();
    }
    
    NSError *imageMountError = NULL;
    NSString *mountedImagePath = [HelperFunctions windowsSourceMountPath: windowsImageInputView.stringValue
                                                                   error: &imageMountError];
    if (imageMountError != NULL) {
        NSString *errorSubtitle = imageMountError.stringValue;
        NSString *logText = [NSString stringWithFormat:@"%@ (%@)", [LocalizedStrings alertTitleImageVerificationError], errorSubtitle];
        
        [self displayWarningAlertWithTitle: [LocalizedStrings alertTitleImageVerificationError]
                                  subtitle: errorSubtitle
                                      icon: NSImageNameCaution];
        
        [logsView appendRow: logText
                    logType: ASLogTypeFatal];
        
        WriteExitForce();
    }
    
    Filesystem selectedFileSystem;
    if (filesystemPickerSegmentedControl.selectedSegment == 0) {
        selectedFileSystem = FilesystemFAT32;
    } else {
        selectedFileSystem = FilesystemExFAT;
    }
    
    /*
     ! We don't need anything other than MBR !
     
     [Reason №1]: If GPT is selected, diskutil creates an additional EFI partition for UEFI system.
     But there is a problem: Windows Installer is very buggy.
     If the installation media has a EFI partition, it will just crash with an error:
     "Windows could not prepare the computer to boot into the next phase of installation".
     
     [Reason №2]: Why GPT? There is no any benefit from it.
     It less compatible with some firmwares/operating systems.
     For example, my Lenovo Q67 motherboard can't even boot from GPT-formatted disks in UEFI mode.
     */
    
    PartitionScheme selectedPartitionScheme = PartitionSchemeMBR;
     
    [logsView appendRow: [NSString stringWithFormat: @"%@: %@", [LocalizedStrings logviewRowTitleImageMountSuccess], mountedImagePath]
                                            logType: ASLogTypeSuccess];
    
    NSString *newPartitionName = [NSString stringWithFormat: @"WDW_%@", [HelperFunctions randomStringWithLength: 7]];
    [logsView appendRow: [NSString stringWithFormat: @"%@: %@", [LocalizedStrings logviewRowTitleGeneratedPartitionName], newPartitionName]
                                            logType: ASLogTypeLog];
    
    NSString *targetPartitionPath = [NSString stringWithFormat: @"/Volumes/%@", newPartitionName];
    [logsView appendRow: [NSString stringWithFormat: @"%@: %@", [LocalizedStrings logviewRowTitleTargetPartitionPath], targetPartitionPath]
                                            logType: ASLogTypeLog];
    
    BOOL patchInstallerRequirements = patchInstallerRequirementsCheckboxView.state == NSOnState;
    BOOL installLegacyBoot = installLegacyBootCheckBoxView.state == NSOnState;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (installLegacyBoot) {
            BOOL bootloaderLegacyFilesDownloaded = [self downloadLegacyBootloaderFiles];
            if (bootloaderLegacyFilesDownloaded) {
                [self->logsView appendRow:[LocalizedStrings logviewRowFoundLegacyBootloaderFiles] logType:ASLogTypeSuccess];
            } else {
                [self->logsView appendRow:[LocalizedStrings logviewRowLegacyBootloaderFilesNotFound] logType:ASLogTypeFatal];
                
                WriteExitForce();
            }
        }

        NSString *diskEraseOperationText = [LocalizedStrings logviewRowTitleDiskEraseOperationOptionsWithArgument1: destinationSavedDiskInfo.BSDName
                                                                                                         argument2: destinationSavedDiskInfo.deviceVendor
                                                                                                         argument3: destinationSavedDiskInfo.deviceModel
                                                                                                         argument4: newPartitionName
                                                                                                         argument5: selectedPartitionScheme
                                                                                                         argument6: selectedFileSystem
                                                                                                         argument7: patchInstallerRequirements
                                                                                                         argument8: installLegacyBoot];
        
        [self->logsView appendRow: diskEraseOperationText
                    logType: ASLogTypeLog];
        
        [self setCurrentProgressTitle: [LocalizedStrings progressTitleFormattingTheDrive]];
        [self->totalOperationProgressBarView startIndeterminateAnimationSynchronously];
        
        NSError *diskEraseError = NULL;
        [secondVerifyingStageDiskManager diskUtilEraseDiskWithPartitionScheme: selectedPartitionScheme
                                                                   filesystem: selectedFileSystem
                                                                      newName: newPartitionName
                                                                        error: &diskEraseError];
        
        if (diskEraseError != NULL) {
            [self->totalOperationProgressBarView stopIndeterminateAnimationSynchronously];
            
            [self displayWarningAlertWithTitle: [LocalizedStrings alertTitleDiskEraseFailure]
                                      subtitle: diskEraseError.stringValue
                                          icon: NSImageNameCaution];
                        
            [self->logsView appendRow: [[LocalizedStrings alertTitleDiskEraseFailure] stringByAppendingFormat:
                                        @" %@", [LocalizedStrings logviewRowPartialTitleErrorMessageWithArgument1: diskEraseError.stringValue]]
                              logType: ASLogTypeFatal];
            
            [HelperFunctions detachMountedImageAtMountPoint: mountedImagePath error: NULL];
            WriteExitForce();
        }
        
        [self setCurrentProgressTitle: [LocalizedStrings progressTitleDiskEraseSuccess]];
        
        [self->logsView appendRow: [LocalizedStrings progressTitleDiskEraseSuccess]
                          logType: ASLogTypeSuccess];
        
        WriteExitConditionally();
        
        DWFilesContainer *filesContainer = [DWFilesContainer containerFromContainerPath: mountedImagePath
                                                                               callback: ^enum DWAction(DWFile * _Nonnull fileInfo, enum DWFilesContainerMessage message) {
            if (self.isScheduledForStop) {
                return DWActionStop;
            }
            
            return DWActionContinue;
        }];
        
        WriteExitConditionally();
            UInt64 totalISOBlobBytes = [filesContainer sizeOfFiles];
        [self->totalOperationProgressBarView stopIndeterminateAnimationSynchronously];
        [self setTotalProgressWithWrittenBytes: 0 totalBytes: totalISOBlobBytes];
        
        DiskWriter *diskWriter = [[DiskWriter alloc] initWithDWFilesContainer: filesContainer
                                                              destinationPath: targetPartitionPath
                                                        destinationDiskManager: secondVerifyingStageDiskManager
        ];
        
        [diskWriter setDestinationFilesystem: selectedFileSystem];
        [diskWriter setPatchInstallerRequirements: patchInstallerRequirements];
        [diskWriter setInstallLegacyBoot: installLegacyBoot];
        
        NSError *writeError = NULL;
        __block UInt64 totalBytesCompletedBeforeCurrentFile = 0;
        
        [diskWriter startWritingWithError: &writeError
                         progressCallback: ^DWAction(DWFile * _Nonnull dwFile, uint64 copiedBytes, DWOperationType operationType, DWOperationResult operationResult, NSError *_Nullable error) {
            if (self.isScheduledForStop) {
                return DWActionStop;
            }
            
            UInt64 currentOverallBytes = totalBytesCompletedBeforeCurrentFile + copiedBytes;
            if (currentOverallBytes > totalISOBlobBytes) {
                currentOverallBytes = totalISOBlobBytes;
            }
            
            // This way we can determine that we are starting a new operation. (We can also use a DWOperationResultStart for it.)
            if (copiedBytes == 0) {
                [self->currentOperationProgressBarView resetProgressSynchronously];
                
                [self setCurrentProgressTitle: [dwFile.sourcePath lastPathComponent]];
            }
            
            [self setCurrentProgressWithWrittenBytes: copiedBytes
                                       fileSizeBytes: dwFile.size];
            [self setTotalProgressWithWrittenBytes: currentOverallBytes
                                        totalBytes: totalISOBlobBytes];
            
            NSString *destinationCurrentFilePath = [targetPartitionPath stringByAppendingPathComponent: dwFile.sourcePath];
            NSMutableString *onscreenLogText = [NSMutableString string];
            
            switch (operationType) {
                case DWOperationTypeCreateDirectory:
                    [onscreenLogText appendString: [LocalizedStrings progressTitleCreateDirectory]];
                    break;
                case DWOperationTypeWriteFile:
                    [onscreenLogText appendString: [LocalizedStrings progressTitleWriteFile]];
                    break;
                case DWOperationTypeSplitWindowsImage:
                    [onscreenLogText appendString: [LocalizedStrings progressTitleSplitImage]];
                    break;
                case DWOperationTypeExtractWindowsBootloader:
                    [onscreenLogText appendString: [LocalizedStrings progressTitleExtractBootloader]];
                    break;
                case DWOperationTypePatchWindowsInstallerRequirements:
                    [onscreenLogText appendString: [LocalizedStrings progressTitlePatchInstallerRequirements]];
                    break;
                case DWOperationTypeSetFilePermissions:
                    [onscreenLogText appendString: [LocalizedStrings progressTitleSetFilePermissions]];
                    break;
                case DWOperationTypeInstallLegacyBootSector:
                    [onscreenLogText appendString: [LocalizedStrings progressTitleInstallLegacyBootloader]];
                    break;
            }
            
            [onscreenLogText appendString: [NSString stringWithFormat: @": %@", destinationCurrentFilePath]];
                        
            switch (operationResult) {
                case DWOperationResultStart:
                    [self->logsView appendRow:onscreenLogText logType:ASLogTypeStart];
                    break;
                case DWOperationResultProcess:
                    // Don't need to do anything ¯\_(ツ)_/¯
                    break;
                case DWOperationResultSuccess:
                    [self->logsView appendRow:onscreenLogText logType:ASLogTypeSuccess];
                    
                    totalBytesCompletedBeforeCurrentFile += dwFile.size;
                    if (totalBytesCompletedBeforeCurrentFile > totalISOBlobBytes) {
                        totalBytesCompletedBeforeCurrentFile = totalISOBlobBytes;
                    }
                    [self setTotalProgressWithWrittenBytes: totalBytesCompletedBeforeCurrentFile
                                                totalBytes: totalISOBlobBytes];
                    break;
                case DWOperationResultFailure:
                    if (error != NULL) {
                        [onscreenLogText appendString: [NSString stringWithFormat: @" %@", [LocalizedStrings logviewRowPartialTitleErrorMessageWithArgument1: error.stringValue]]];
                    }
                    
                    [self->logsView appendRow:onscreenLogText logType:ASLogTypeFailure];
                    break;
                case DWOperationResultSkipped:
                    [self->logsView appendRow:onscreenLogText logType:ASLogTypeSkipped];
                    break;
            }
            
            // Handling a situation when an error occurred during writing
            if (operationResult == DWOperationResultFailure) {
                /*
                 Old Cocoa is crap.
                 Can't do anything better ¯\_(ツ)_/¯.
                 I need to support old OS X releases and maintain the modern look.
                 */
                
                SynchronizedAlertData *synchronizedAlertData = [[SynchronizedAlertData alloc] initWithSemaphore: dispatch_semaphore_create(0)];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    // Closing the currently displayed alert (if required).
                    [self removeAttachedSheetWithReturnCode: NSAlertFirstButtonReturn];
                    
                    NSAlert *alert = [[NSAlert alloc] init];
                    [alert setMessageText: [LocalizedStrings alertTitleWriteFileProblemOccurred]];
                    
                    NSMutableString *alertSubtitleString = [NSMutableString stringWithString: [LocalizedStrings alertSubtitleWriteFileProblemOccurred]];
                    
                    if (error != NULL) {
                        [alertSubtitleString appendFormat: @"\n%@", [LocalizedStrings placeholderReasonWithArgument1: [error stringValue]]];
                    }
                    
                    [alertSubtitleString appendFormat: @"\n[%@]", destinationCurrentFilePath];
                    
                    [alert setInformativeText: alertSubtitleString];
                    
                    [alert addButtonWithTitle: [LocalizedStrings alertButtonTitleStopWriting]];
                    [alert addButtonWithTitle: [LocalizedStrings alertButtonTitleSkipFile]];
                    
                    [alert setIcon: [NSImage imageNamed: NSImageNameCaution]];
                    
                    [alert beginSheetModalForWindow: self
                                      modalDelegate: self
                                     didEndSelector: @selector(alertWarnAboutErrorDuringWriting:returnCode:contextInfo:)
                                        contextInfo: (__bridge void * _Nullable)(synchronizedAlertData)];
                });
                
                // Using semaphores in order to get this in sync with this thread.
                dispatch_semaphore_wait(synchronizedAlertData.semaphore, DISPATCH_TIME_FOREVER);
                
                if (synchronizedAlertData.resultCode == NSAlertFirstButtonReturn) {
                    [self setIsScheduledForStop: YES];
                    
                    return DWActionStop;
                } else {
                    return DWActionSkip;
                }
            }
            
            return DWActionContinue;
        }];
        
        WriteExitConditionally();
        
        if (writeError) {
            [self displayWarningAlertWithTitle: [LocalizedStrings alertTitleImageWritingFailure]
                                      subtitle: writeError.stringValue
                                          icon: NSImageNameCaution];
            
            [self->logsView appendRow:writeError.stringValue logType:ASLogTypeFatal];
            
            [HelperFunctions detachMountedImageAtMountPoint: mountedImagePath error: NULL];
            WriteExitForce();
        }
        
        [self setTotalProgressWithWrittenBytes: totalISOBlobBytes totalBytes: totalISOBlobBytes];
        [self setCurrentProgressWithWrittenBytes: 0 fileSizeBytes: 0];
        [self setCurrentProgressTitle: [LocalizedStrings alertTitleImageWritingSuccess]];
        
        [self displayWarningAlertWithTitle: [LocalizedStrings alertTitleImageWritingSuccess]
                                  subtitle: [LocalizedStrings alertSubtitleImageWritingSuccess]
                                      icon: NULL];
        
        [self->logsView appendRow:[LocalizedStrings alertTitleImageWritingSuccess] logType:ASLogTypeSuccess];
        
        [HelperFunctions detachMountedImageAtMountPoint: mountedImagePath error: NULL];
        WriteExitForce();
    });
    
}

- (void)chooseImageAction {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel setCanChooseFiles: YES];
    [openPanel setCanChooseDirectories: YES];
    [openPanel setAllowsMultipleSelection: NO];
    [openPanel setAllowedFileTypes: @[@"iso"]];
    
    [openPanel runModal];
    
    NSString *path = openPanel.URL.path;
    if (path == NULL) {
        return;
    }
    
    [windowsImageInputView setStringValue:path];
    
}

// Quick message for selector
- (void)updateDeviceListWithWholeDiskFiltrationEnabled {
    [self updateDeviceListWithWholeDiskFiltrationEnabled: YES];
}

// Quick message for selector
- (void)updateDeviceListWithWholeDiskFiltrationDisabled {
    [self updateDeviceListWithWholeDiskFiltrationEnabled: NO];
}

- (void)updateDeviceListWithWholeDiskFiltrationEnabled: (BOOL)wholeDiskFiltrationEnabled {
    [logsView appendRow: [LocalizedStrings logviewRowTitleClearingDevicePickerList] logType:ASLogTypeLog];

    [devicePickerView removeAllItems];
        
    NSArray<NSString *> *bsdNames = [DiskManagerProcessor BSDDrivesNames];
    
    NSString *textLog = [NSString stringWithFormat: @"%@: %@", [LocalizedStrings logviewRowPartialTitleFoundDevices], [bsdNames componentsJoinedByString:@", "]];
    [logsView appendRow:textLog logType:ASLogTypeLog];
    
    for (NSString *bsdName in bsdNames) {
        DiskManagerProcessor *diskManager = [[DiskManagerProcessor alloc] initWithBSDName: bsdName];
        DiskInfo *diskInfo = [diskManager diskInfo];
                
        // We only need to show the whole drives. So partitions (volumes / slices) are ignored.
        if (!diskInfo.isWholeDrive) {
            continue;
        }
        
        if (wholeDiskFiltrationEnabled) {
            if (diskInfo.isNetworkVolume || diskInfo.isInternal ||
                !diskInfo.isDeviceUnit || !diskInfo.isWritable) {
                continue;
            }
        }
                
        IdentifiableMenuItem *identifiableMenuItem = [[IdentifiableMenuItem alloc] initWithDiskInfo:diskInfo];
        
        [devicePickerView.menu addItem:identifiableMenuItem];
    }
}

- (void)setEnabledUIState: (BOOL)enabledUIState {
    dispatch_async(dispatch_get_main_queue(), ^{
        self->_enabledUIState = enabledUIState;
        
        [self->startStopButtonView setEnabled: YES];
        
        if (enabledUIState) {
            [self resetProgress];
            [self->currentOperationLabelView setStringValue: [LocalizedStrings progressTitleReadyForAction]];
            
            [self->quitMenuItem setAction: @selector(terminate:)];
            [self->closeMenuItem setAction: @selector(close)];
            
            [self->currentProgressDetailsLabelView setStringValue: @""];
            [self->totalProgressDetailsLabelView setStringValue: @""];
            [self->totalOperationLabelView setStringValue: @"Total Progress"];
            [self->totalOperationProgressBarView stopIndeterminateAnimationSynchronously];
            
            [self->startStopButtonView setTitle: [LocalizedStrings buttonTitleStart]];
            [self->startStopButtonView setAction: @selector(startAction)];
            [self->scanAllWholeDisksMenuItem setAction: @selector(updateDeviceListWithWholeDiskFiltrationDisabled)];
        } else {
            [self->quitMenuItem setAction: NULL];
            [self->closeMenuItem setAction: NULL];
            
            [self->startStopButtonView setTitle: [LocalizedStrings buttonTitleStop]];
            [self->startStopButtonView setAction: @selector(stopAction)];
            [self->scanAllWholeDisksMenuItem setAction: NULL];
        }
        
        [self->updateDeviceListButtonView setEnabled: enabledUIState];
        [self->patchInstallerRequirementsCheckboxView setEnabled: enabledUIState];
        [self->installLegacyBootCheckBoxView setEnabled: enabledUIState];
        [self->windowsImageInputView setEnabled: enabledUIState];
        [self->devicePickerView setEnabled: enabledUIState];
                
        [self->chooseWindowsImageButtonView setEnabled: enabledUIState];
        [self->filesystemPickerSegmentedControl setEnabled: enabledUIState];
        
        NSButton *windowCloseButton = [self standardWindowButton: NSWindowCloseButton];
        [windowCloseButton setEnabled: enabledUIState];
    });
}

@end
