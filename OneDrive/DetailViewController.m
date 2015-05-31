//
//  DetailViewController.m
//  OneDrive
//
//  Created by Dalibor Kozak on 31/05/15.
//  Copyright (c) 2015 Dalibor Kozak. All rights reserved.
//

#import "DetailViewController.h"
#import "AppDelegate.h"

@interface DetailViewController ()

- (IBAction)editBtnPressed:(UIBarButtonItem *)sender;

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editBtn;
@property (strong, nonatomic) UIRefreshControl *refreshControl;

@property (strong, nonatomic) NSArray *data;
@property (strong, nonatomic) AppDelegate *appDelegate;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.liveClient getWithPath:[NSString stringWithFormat:@"%@/files", self.fileId] delegate:self userState:@"getFiles"];
    self.appDelegate = [[UIApplication sharedApplication] delegate];
    [self tableViewSetup];
}

- (void)tableViewSetup {
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = [UIColor lightGrayColor];
    self.refreshControl.backgroundColor = [UIColor colorWithWhite:0.926 alpha:1.000];
    [self.refreshControl addTarget:self action:@selector(reloadDataForCurrentItem) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [self.tableView setEditing:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.data = [self.appDelegate.data objectForKey:self.fileId];
    [self.tableView reloadData];
}

- (void) liveOperationFailed:(NSError *)error operation:(LiveOperation *)operation {
    NSLog(@"req failed live: %@", [error localizedDescription]);
}

- (void) liveOperationSucceeded:(LiveOperation *)operation {
    self.data = operation.result[@"data"];
    
    AppDelegate *delegate = [[UIApplication sharedApplication] delegate];
    [delegate.data setObject:self.data forKey:self.fileId];
    
    [self.tableView reloadData];
}

- (void)reloadDataForCurrentItem {
    [self.liveClient getWithPath:[NSString stringWithFormat:@"%@/files", self.fileId] delegate:self userState:@"getItems"];
    if(self.refreshControl != nil && self.refreshControl.isRefreshing == TRUE) {
        [self.refreshControl endRefreshing];
    }
}

#pragma mark - TableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    NSDictionary *dict = self.data[indexPath.item];
    NSString *name = dict[@"name"];
    NSString *count = dict[@"count"];
    
    cell.textLabel.text = name;
    cell.detailTextLabel.text = count ? [NSString stringWithFormat:@"%@", count] : @"";
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dict = self.data[indexPath.item];
    NSString *name = dict[@"name"];
    NSString *fileId = dict[@"id"];
    NSString *type = dict[@"type"];
    
    if (!tableView.editing) {
        if ([type isEqualToString:@"folder"]) {
            DetailViewController * detailVC = [self.storyboard instantiateViewControllerWithIdentifier:@"detailVC"];
            detailVC.fileId = fileId;
            detailVC.liveClient = self.liveClient;
            detailVC.title = name;
            [self.navigationController pushViewController:detailVC animated:YES];
        }
    }
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}


- (IBAction)editBtnPressed:(UIBarButtonItem *)sender {
}
@end
