//
//  FirstViewController.m
//  OneDrive
//
//  Created by Dalibor Kozak on 31/05/15.
//  Copyright (c) 2015 Dalibor Kozak. All rights reserved.
//

#import "FirstViewController.h"
#import "DetailViewController.h"
#import "AppDelegate.h"
#import <MBProgressHUD/MBProgressHUD.h>

#define kURL_Home @"me/skydrive"
#define kURL_Home_Files @"me/skydrive/files"

@interface FirstViewController () <MBProgressHUDDelegate>

- (IBAction)editBtn:(UIBarButtonItem *)sender;
- (IBAction)moreBtn:(UIBarButtonItem *)sender;
- (IBAction)logoutBtn:(UIBarButtonItem *)sender;
- (IBAction)newFolderBtn:(UIBarButtonItem *)sender;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *edit;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *more;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *selectedItems;

@property (strong, nonatomic) NSArray *data;
@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) MBProgressHUD *hud;
@property (assign, nonatomic) BOOL isActionMove;

@end

@implementation FirstViewController

- (NSMutableArray *)selectedItems {
    if (!_selectedItems) {
        _selectedItems = [NSMutableArray new];
    }
    return _selectedItems;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self login];
    self.appDelegate = [[UIApplication sharedApplication] delegate];
    [self tableViewSetup];
    [self userNotification];
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
    self.data = [self.appDelegate.data objectForKey:@"homeData"];
    [self.tableView reloadData];
}

#pragma mark - Login
- (void)login {
    self.liveClient = [[LiveConnectClient alloc] initWithClientId:@"00000000481577FF" delegate:self userState:@"initialize"];
}

// Auth completed, loading list of items in home folder
- (void)authCompleted:(LiveConnectSessionStatus) status
              session:(LiveConnectSession *) session
            userState:(id) userState
{
    if ([userState isEqual:@"initialize"])
    {
        [self.liveClient login:self
                        scopes:@[@"wl.skydrive_update", @"wl.signin", @"wl.skydrive"]
                      delegate:self
                     userState:@"signin"];
    }
    if ([userState isEqual:@"signin"])
    {
        if (session != nil)
        {
            [self.hud show:YES];
            [self.liveClient getWithPath:kURL_Home_Files delegate:self userState:@"getItems"];
        }
    }
}

- (void)authFailed:(NSError *) error userState:(id)userState {
    NSLog(@"Error: %@", [error localizedDescription]);
}

#pragma mark - Response to actions
- (void) liveOperationFailed:(NSError *)error operation:(LiveOperation *)operation {
    NSLog(@"error message: %@", error);
}

//  Edit change was succesfull
- (void) liveOperationSucceeded:(LiveOperation *)operation {
    if ([operation.userState isEqualToString:@"getItems"]) {
        self.data = operation.result[@"data"];
        [self.appDelegate.data setObject:self.data forKey:@"homeData"];
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
    [self.liveClient getWithPath:kURL_Home_Files delegate:self userState:@"getItems"];
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

- (IBAction)logoutBtn:(UIBarButtonItem *)sender {
    [self.liveClient logout];
    [self login];
    [self.appDelegate.data removeAllObjects];
}

//  Presents View controller for creating a new folder
- (IBAction)newFolderBtn:(UIBarButtonItem *)sender {
    CreateViewController *createVC = [self.storyboard instantiateViewControllerWithIdentifier:@"createVC"];
    createVC.delegate = self;
    createVC.folderId = kURL_Home;
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
    selectionVC.fileId = kURL_Home;
    selectionVC.liveClient = self.liveClient;
    selectionVC.delegate = self;
    selectionVC.btnTitle = self.isActionMove ? @"Move" : @"Copy";
    selectionVC.selectedItems = self.selectedItems;
    selectionVC.title = @"Home";
    [self.navigationController pushViewController:selectionVC animated:YES];
}

#pragma mark - Create New Folder Action Delagate
- (void)addNewFolderWithName:(NSString *)name andDescription:(NSString *)description inFolder:(NSString *)folder {
    [self.hud show:YES];
    NSDictionary * newFolder = @{@"name": name, @"description":description};
    [self.liveClient postWithPath:folder dictBody:newFolder delegate:self userState:@"newFolder"];
}

#pragma mark - Move/Copy Acionn Delegate
- (void)didSelectFolder:(NSString *)folderId forAction:(NSString *)action withItems:(NSArray *)items {
    if ([action isEqualToString:@"Move"]) {
        [self.hud show:YES];
        for (NSString *itemId in items) {
            [self.liveClient moveFromPath:itemId toDestination:folderId delegate:self userState:@"moveFile"];
        }
    } else  {
        [self.hud show:YES];
        for (NSString *itemId in items) {
            [self.liveClient copyFromPath:itemId toDestination:folderId delegate:self userState:@"copyFile"];
        }
    }
    [self.appDelegate.data removeObjectForKey:folderId];
}

//  reloading data after they have been changed in DetailVC
- (void)parentReload {
    [self reloadDataForCurrentItem];
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
            detailVC.parentVC = self;
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
