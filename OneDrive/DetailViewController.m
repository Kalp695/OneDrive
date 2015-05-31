//
//  DetailViewController.m
//  OneDrive
//
//  Created by Dalibor Kozak on 31/05/15.
//  Copyright (c) 2015 Dalibor Kozak. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()

- (IBAction)editBtnPressed:(UIBarButtonItem *)sender;

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editBtn;

@property (strong, nonatomic) NSArray *data;

@end

@implementation DetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.liveClient getWithPath:[NSString stringWithFormat:@"%@/files", self.fileId] delegate:self userState:@"getFiles"];
}

- (void) liveOperationFailed:(NSError *)error operation:(LiveOperation *)operation {
    NSLog(@"req failed live: %@", [error localizedDescription]);
}

- (void) liveOperationSucceeded:(LiveOperation *)operation {
    NSLog(@"req succ: %@, result: %@", operation.userState, operation.result);
    self.data = operation.result[@"data"];
    
    [self.tableView reloadData];
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
