//
//  DetailViewController.h
//  OneDrive
//
//  Created by Dalibor Kozak on 31/05/15.
//  Copyright (c) 2015 Dalibor Kozak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CreateViewController.h"
#import "SelectionViewController.h"
#import "LiveSDK/LiveConnectClient.h"
#import "FirstViewController.h"

@interface DetailViewController : UIViewController <LiveOperationDelegate,LiveDownloadOperationDelegate,UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>

@property (strong, nonatomic) NSString *fileId;
@property (strong, nonatomic) LiveConnectClient *liveClient;
@property (weak, nonatomic) FirstViewController *parentVC;

@end
