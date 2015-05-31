//
//  DetailViewController.h
//  OneDrive
//
//  Created by Dalibor Kozak on 31/05/15.
//  Copyright (c) 2015 Dalibor Kozak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LiveSDK/LiveConnectClient.h"

@interface DetailViewController : UIViewController <LiveOperationDelegate,LiveDownloadOperationDelegate, LiveUploadOperationDelegate,UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSString *fileId;
@property (strong, nonatomic) LiveConnectClient *liveClient;

@end
