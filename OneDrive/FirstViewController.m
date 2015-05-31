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

@interface FirstViewController ()

- (IBAction)editBtn:(UIBarButtonItem *)sender;
- (IBAction)moreBtn:(UIBarButtonItem *)sender;

@property (strong, nonatomic) IBOutlet UIBarButtonItem *more;
@property (strong, nonatomic) IBOutlet UIToolbar *toolbar;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) NSMutableArray *selectedItems;

@property (strong, nonatomic) NSArray *data;
@property (strong, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) UIRefreshControl *refreshControl;

@property (assign, nonatomic) BOOL isActionMove;
@property (assign, nonatomic) BOOL isActionCopy;

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
    self.liveClient = [[LiveConnectClient alloc] initWithClientId:@"00000000481577FF" delegate:self userState:@"initialize"];
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
    self.data = [self.appDelegate.data objectForKey:@"homeData"];
    [self.tableView reloadData];
}

#pragma mark - Login
- (void)authCompleted:(LiveConnectSessionStatus) status
              session:(LiveConnectSession *) session
            userState:(id) userState
{
    if ([userState isEqual:@"initialize"])
    {
        NSLog(@"Initialized");
        [self.liveClient login:self
                        scopes:@[@"wl.skydrive_update", @"wl.signin", @"wl.skydrive"]
                      delegate:self
                     userState:@"signin"];
    }
    if ([userState isEqual:@"signin"])
    {
        if (session != nil)
        {
            NSLog(@"signed in");
            [self.liveClient getWithPath:@"me/skydrive/files" delegate:self userState:@"getItems"];
        }
    }
}

- (void)authFailed:(NSError *) error userState:(id)userState {
    NSLog(@"Error: %@", [error localizedDescription]);
}

#pragma mark - Response to actions
- (void) liveOperationFailed:(NSError *)error operation:(LiveOperation *)operation {
    NSLog(@"req failed live: %@", [error localizedDescription]);
    NSLog(@"error message: %@", error);
}

- (void) liveOperationSucceeded:(LiveOperation *)operation {
    if ([operation.userState isEqualToString:@"delete"]) {
        NSLog(@"Item was deleted");
        [self reloadDataForCurrentItem];
        
    } else if ([operation.userState isEqualToString:@"getItems"]) {
        self.data = operation.result[@"data"];
        [self.appDelegate.data setObject:self.data forKey:@"homeData"];
        [self.tableView reloadData];
        
    } else if ([operation.userState isEqualToString:@"newFolder"]) {
        NSLog(@"Item was newFolder");
        [self reloadDataForCurrentItem];
    } else if ([operation.userState isEqualToString:@"moveFile"]) {
        NSLog(@"Item was moveFile");
        [self reloadDataForCurrentItem];
    } else if ([operation.userState isEqualToString:@"copyFile"]) {
        NSLog(@"Item was copyFile");
        [self reloadDataForCurrentItem];
    } else if ([operation.userState isEqualToString:@"download"]) {
        NSLog(@"Item was download");
        [self stopEditing];
    }
}

- (void)reloadDataForCurrentItem {
    [self stopEditing];
    [self.liveClient getWithPath:@"me/skydrive/files" delegate:self userState:@"getItems"];
    if(self.refreshControl != nil && self.refreshControl.isRefreshing == TRUE) {
        [self.refreshControl endRefreshing];
    }
}

#pragma mark - IBActions
- (IBAction)editBtn:(UIBarButtonItem *)sender {
    self.tableView.editing = !self.tableView.editing;
    self.toolbar.hidden = !self.tableView.editing;
}

- (IBAction)moreBtn:(UIBarButtonItem *)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles:@"Move", @"Copy", @"Create", @"Download", nil];
    [actionSheet showInView:self.view];
}

- (void)stopEditing {
    [self.tableView setEditing:NO animated:YES];
    self.toolbar.hidden = YES;
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
            [self createAction];
            break;
            
        case 4:
            [self downloadAction];
            break;
            
        default:
            break;
    }
}

- (void)deleteAction {
    for (NSString * itemId in self.selectedItems) {
        [self.liveClient deleteWithPath:itemId delegate:self userState:@"delete"];
    }
    [self stopEditing];
}

- (void)moveAction {
    self.isActionMove = YES;
    [self presentSelectionVC];
}

- (void)copyAction {
    self.isActionCopy = YES;
    [self presentSelectionVC];
}

- (void)createAction {
    CreateViewController *createVC = [self.storyboard instantiateViewControllerWithIdentifier:@"createVC"];
    createVC.delegate = self;
    [self presentViewController:createVC animated:YES completion:nil];
}

- (void)downloadAction {
    for (NSString *itemId in self.selectedItems) {
        NSString *path = [NSString stringWithFormat:@"%@/content", itemId];
        [self.liveClient downloadFromPath:path delegate:self userState:@"download"];
    }
}

- (void)presentSelectionVC {
    SelectionViewController *selectionVC = [self.storyboard instantiateViewControllerWithIdentifier:@"selectionVC"];
    selectionVC.fileId = @"me/skydrive";
    selectionVC.liveClient = self.liveClient;
    selectionVC.delegate = self;
    [self.navigationController pushViewController:selectionVC animated:YES];
}

#pragma mark - Create Action Delagate
- (void)addNewFolderWithName:(NSString *)name andDescription:(NSString *)description {
    NSDictionary * newFolder = @{@"name": name, @"description":description};
    [self.liveClient postWithPath:@"me/skydrive" dictBody:newFolder delegate:self userState:@"newFolder"];
}

#pragma mark - Move/Copy Acionn Delegate
- (void)didSelectFolder:(NSString *)folderId {
    if (self.isActionMove) {
        self.isActionMove = NO;
        for (NSString *itemId in self.selectedItems) {
            [self.liveClient moveFromPath:itemId toDestination:folderId delegate:self userState:@"moveFile"];
        }
    } else if (self.isActionCopy) {
        self.isActionCopy = NO;
        for (NSString *itemId in self.selectedItems) {
            [self.liveClient copyFromPath:itemId toDestination:folderId delegate:self userState:@"copyFile"];
        }
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
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dict = self.data[indexPath.item];
    NSString *fileId = dict[@"id"];
    [self.selectedItems removeObject:fileId];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

@end
