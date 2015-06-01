//
//  DetailViewController.m
//  OneDrive
//
//  Created by Dalibor Kozak on 31/05/15.
//  Copyright (c) 2015 Dalibor Kozak. All rights reserved.
//

#import "DetailViewController.h"
#import "AppDelegate.h"
#import <MBProgressHUD/MBProgressHUD.h>

@interface DetailViewController () <MBProgressHUDDelegate>

- (IBAction)editBtn:(UIBarButtonItem *)sender;
- (IBAction)moreBtn:(UIBarButtonItem *)sender;
- (IBAction)newFolderBtn:(UIBarButtonItem *)sender;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *edit;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *more;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) NSMutableArray *selectedItems;
@property (strong, nonatomic) NSArray *data;
@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) MBProgressHUD *hud;
@property (assign, nonatomic) BOOL isActionMove;

@end

@implementation DetailViewController

- (NSMutableArray *)selectedItems {
    if (!_selectedItems) {
        _selectedItems = [NSMutableArray new];
    }
    return _selectedItems;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self userNotification];
    self.appDelegate = [[UIApplication sharedApplication] delegate];
    [self tableViewSetup];
}

//  Adds waiting indicator
- (void)userNotification {
    self.hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:self.hud];
    self.hud.delegate = self;
    self.hud.color = [UIColor colorWithWhite:0.542 alpha:1.000];
}

//  Adds pull down refresh for table view
- (void)tableViewSetup {
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = [UIColor lightGrayColor];
    self.refreshControl.backgroundColor = [UIColor colorWithWhite:0.926 alpha:1.000];
    [self.refreshControl addTarget:self action:@selector(reloadDataForCurrentItem) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [self.tableView setEditing:NO];
}

//  Checks if we have chached items
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.data = [self.appDelegate.data objectForKey:self.fileId];
    if (!self.data.count) {
        [self.hud show:YES];
        [self.liveClient getWithPath:[NSString stringWithFormat:@"%@/files", self.fileId] delegate:self userState:@"getItems"];
    }
    [self.tableView reloadData];
}

#pragma mark - Response to actions
- (void)liveOperationFailed:(NSError *)error operation:(LiveOperation *)operation {
    NSLog(@"req failed live: %@", [error localizedDescription]);
}

//  Edit change was succesfull
- (void)liveOperationSucceeded:(LiveOperation *)operation {
    if ([operation.userState isEqualToString:@"getItems"]) {
        self.data = operation.result[@"data"];
        [self.appDelegate.data setObject:self.data forKey:self.fileId];
        [self.tableView reloadData];
        [self.hud hide:YES];
    } else {
        [self reloadDataForCurrentItem];
    }
}

// Reloading items in current list after change
- (void)reloadDataForCurrentItem {
    [self.hud hide:YES];
    [self stopEditing];
    [self.parentVC parentReload];
    
    [self.liveClient getWithPath:[NSString stringWithFormat:@"%@/files", self.fileId] delegate:self userState:@"getItems"];
    if(self.refreshControl != nil && self.refreshControl.isRefreshing == TRUE) {
        [self.refreshControl endRefreshing];
    }
}

#pragma mark - IBActions
- (IBAction)editBtn:(UIBarButtonItem *)sender {
    if (!self.tableView.editing) {
        [self.tableView setEditing:YES animated:YES];
        self.toolbar.hidden = NO;
        self.edit.title = @"Done";
    } else {
        [self.tableView setEditing:NO animated:YES];
        self.toolbar.hidden = YES;
        self.edit.title = @"Edit";
    }
}

//  Action sheet with editing options
- (IBAction)moreBtn:(UIBarButtonItem *)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Move", @"Copy", @"Download", nil];
    [actionSheet showInView:self.view];
}

//  Presents View controller for creating a new folder
- (IBAction)newFolderBtn:(UIBarButtonItem *)sender {
    CreateViewController *createVC = [self.storyboard instantiateViewControllerWithIdentifier:@"createVC"];
    createVC.delegate = self.parentVC;
    createVC.folderId = self.fileId;
    [self presentViewController:createVC animated:YES completion:nil];
}

- (void)stopEditing {
    self.edit.title = @"Edit";
    [self.tableView setEditing:NO animated:YES];
    self.toolbar.hidden = YES;
    [self.selectedItems removeAllObjects];
}

#pragma mark - ActionSheet
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self deleteAction];
            break;
        case 1:
            [self moveAction];
            break;
        case 2:
            [self copyAction];
            break;
        case 3:
            [self downloadAction];
            break;
        default:
            break;
    }
}

- (void)deleteAction {
    [self.hud show:YES];
    for (NSString * itemId in self.selectedItems) {
        [self.liveClient deleteWithPath:itemId delegate:self userState:@"delete"];
    }
}

- (void)moveAction {
    self.isActionMove = YES;
    [self presentSelectionVC];
    [self.appDelegate.data removeObjectForKey:self.fileId];
}

- (void)copyAction {
    self.isActionMove = NO;
    [self presentSelectionVC];
}

- (void)downloadAction {
    [self.hud show:YES];
    for (NSString *itemId in self.selectedItems) {
        NSString *path = [NSString stringWithFormat:@"%@/content", itemId];
        [self.liveClient downloadFromPath:path delegate:self userState:@"download"];
    }
}

//  Presents View controller for selecting folder into which to move or copy
- (void)presentSelectionVC {
    SelectionViewController *selectionVC = [self.storyboard instantiateViewControllerWithIdentifier:@"selectionVC"];
    selectionVC.fileId = @"me/skydrive";
    selectionVC.liveClient = self.liveClient;
    selectionVC.delegate = self.parentVC;
    selectionVC.btnTitle = self.isActionMove ? @"Move" : @"Copy";
    selectionVC.selectedItems = self.selectedItems;
    selectionVC.title = @"Home";
    
    [self.navigationController pushViewController:selectionVC animated:YES];
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
    cell.detailTextLabel.text = count ? [NSString stringWithFormat:@"Items: %@", count] : @"";
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dict = self.data[indexPath.item];
    NSString *name = dict[@"name"];
    NSString *fileId = dict[@"id"];
    NSString *type = dict[@"type"];
    
    if (!tableView.editing) {
        if ([type isEqual:@"folder"]) {
            DetailViewController * detailVC = [self.storyboard instantiateViewControllerWithIdentifier:@"detailVC"];
            detailVC.fileId = fileId;
            detailVC.liveClient = self.liveClient;
            detailVC.title = name;
            [self.navigationController pushViewController:detailVC animated:YES];
        }
    } else {
        if (! [self.selectedItems containsObject:fileId]) {
            [self.selectedItems addObject:fileId];
            self.more.enabled = self.selectedItems.count ? YES : NO;
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dict = self.data[indexPath.item];
    NSString *fileId = dict[@"id"];
    [self.selectedItems removeObject:fileId];
    self.more.enabled = self.selectedItems.count ? YES : NO;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

@end
