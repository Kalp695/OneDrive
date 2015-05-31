//
//  ViewController.h
//  OneDrive
//
//  Created by Dalibor Kozak on 29/05/15.
//  Copyright (c) 2015 Dalibor Kozak. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LiveSDK/LiveConnectClient.h"

@interface ViewController : UIViewController <LiveAuthDelegate, LiveOperationDelegate,LiveDownloadOperationDelegate, LiveUploadOperationDelegate>

@property (strong, nonatomic) LiveConnectClient *liveClient;

@end