//
//  SecondViewController.m
//  OneDrive
//
//  Created by Dalibor Kozak on 31/05/15.
//  Copyright (c) 2015 Dalibor Kozak. All rights reserved.
//

#import "SecondViewController.h"
#import "AFNetworking/AFNetworking.h"

@interface SecondViewController ()

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)sendLogin {
    NSString* client_id = @"00000000481577FF";
    NSString *redirectUrl = @"https://login.live.com/oauth20_desktop.srf";
    NSString *scope = @"wl.signin onedrive.readwrite";
    NSString *url = @"https://login.live.com/oauth20_authorize.srf";
    
    
    NSDictionary *params = @{@"client_id":client_id, @"scope" : scope, @"response_type":@"token", @"redirect_url":redirectUrl};
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    [manager GET:url parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"responseObject: %@", responseObject);
        NSLog(@"operation: %@", operation);
        
        NSString* responseString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
