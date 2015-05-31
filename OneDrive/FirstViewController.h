//
//  FirstViewController.h
//  OneDrive
//
//  Created by Dalibor Kozak on 31/05/15.
//  Copyright (c) 2015 Dalibor Kozak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LiveSDK/LiveConnectClient.h"
#import "CreateViewController.h"
#import "SelectionViewController.h"

@interface FirstViewController : UIViewController <LiveAuthDelegate, LiveOperationDelegate,LiveDownloadOperationDelegate, LiveUploadOperationDelegate, UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, CreateViewControllerDelegate, SelectionViewControllerDelegate>

@property (strong, nonatomic) LiveConnectClient *liveClient;
@property (strong, nonatomic) NSString *fileId;

@end
