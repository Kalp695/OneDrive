//
//  ViewController.m
//  OneDrive
//
//  Created by Dalibor Kozak on 29/05/15.
//  Copyright (c) 2015 Dalibor Kozak. All rights reserved.
//

#import "ViewController.h"

#import "AFNetworking/AFNetworking.h"

@interface ViewController ()

- (IBAction)signinBtn:(UIButton *)sender;

@property (strong, nonatomic) IBOutlet UITextField *username;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) IBOutlet UILabel *response;
@property (strong, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];

    [self sendLogin];
    
    
//    NSString* client_id = @"00000000481577FF";
//    self.liveClient = [[LiveConnectClient alloc] initWithClientId:client_id delegate:self userState:@"initialize"];
    
}

- (IBAction)signinBtn:(UIButton *)sender {
    [self sendLogin];
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
        self.response.text = responseString;
        
       
        [self.webView loadHTMLString:responseString baseURL:[NSURL URLWithString:redirectUrl]];

        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", [error localizedDescription]);
    }];
}


- (void)authCompleted:(LiveConnectSessionStatus) status
              session:(LiveConnectSession *) session
            userState:(id) userState
{
    if ([userState isEqual:@"initialize"])
    {
        [self.response setText:@"Initialized."];
        [self.liveClient login:self
                        scopes:[NSArray arrayWithObjects:@"wl.signin", nil]
                      delegate:self
                     userState:@"signin"];
    }
    if ([userState isEqual:@"signin"])
    {
        if (session != nil)
        {
            [self.response setText:@"Signed in."];
        }
    }
}

- (void)authFailed:(NSError *) error
         userState:(id)userState
{
    [self.response setText:[NSString stringWithFormat:@"Error: %@", [error localizedDescription]]];
}

- (void) displayScopes: (LiveConnectSession *) session
{
    self.response.text = [session.scopes componentsJoinedByString:@","];
}


- (IBAction)getMe:(id)sender
{
    [self.liveClient getWithPath:@"USER_ID"
                        delegate:self
                       userState:@"getUserID"];
}


@end
