//
//  CreateViewController.m
//  OneDrive
//
//  Created by Dalibor Kozak on 31/05/15.
//  Copyright (c) 2015 Dalibor Kozak. All rights reserved.
//

#import "CreateViewController.h"

@interface CreateViewController ()

- (IBAction)createFolderBtn:(UIButton *)sender;
- (IBAction)cancelBtn:(UIButton *)sender;

@property (strong, nonatomic) IBOutlet UITextField *folderNameTextField;
@property (strong, nonatomic) IBOutlet UITextField *folderDescrTextField;

@end

@implementation CreateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)createFolderBtn:(UIButton *)sender {
    [self.delegate addNewFolderWithName:self.folderNameTextField.text andDescription:self.folderDescrTextField.text];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelBtn:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
