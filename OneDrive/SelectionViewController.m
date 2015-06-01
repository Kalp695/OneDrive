//
//  SelectionViewController.m
//  OneDrive
//
//  Created by Dalibor Kozak on 31/05/15.
//  Copyright (c) 2015 Dalibor Kozak. All rights reserved.
//

#import "SelectionViewController.h"

#define kURL_Home @"me/skydrive"
#define kURL_Home_Files @"me/skydrive/files"

@interface SelectionViewController ()

- (IBAction)moveBtnPressed:(UIBarButtonItem *)sender;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *moveBtn;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSString *selectedItemId;

@property (strong, nonatomic) NSMutableArray *data;

@end

@implementation SelectionViewController

- (NSMutableArray *)data {
    if (!_data) {
        _data = [NSMutableArray array];
    }
    return _data;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.liveClient getWithPath:[NSString stringWithFormat:@"%@/files", self.fileId] delegate:self userState:@"getFiles"];
    self.selectedItemId = self.fileId;
    [self.navigationItem.rightBarButtonItem setTitle:self.btnTitle];
    self.moveBtn.enabled = [self.fileId isEqualToString:kURL_Home] ? NO : YES;
}

- (void) liveOperationSucceeded:(LiveOperation *)operation {
    NSArray *result = operation.result[@"data"];
    for (NSDictionary *dict in result) {
        if ([dict[@"type"] isEqualToString:@"folder"]) {
            [self.data addObject:dict];
        }
    }
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
    NSString *fileId = dict[@"id"];
    NSString *name = dict[@"name"];
    SelectionViewController *selectionVC = [self.storyboard instantiateViewControllerWithIdentifier:@"selectionVC"];
    selectionVC.fileId = fileId;
    selectionVC.liveClient = self.liveClient;
    selectionVC.delegate = self.delegate;
    selectionVC.btnTitle = self.btnTitle;
    selectionVC.selectedItems = self.selectedItems;
    selectionVC.title = name;
    [self.navigationController pushViewController:selectionVC animated:YES];
}

- (IBAction)moveBtnPressed:(UIBarButtonItem *)sender {
    [self.delegate didSelectFolder:self.selectedItemId forAction:self.btnTitle withItems:self.selectedItems];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
