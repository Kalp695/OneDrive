//
//  CreateViewController.h
//  OneDrive
//
//  Created by Dalibor Kozak on 31/05/15.
//  Copyright (c) 2015 Dalibor Kozak. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CreateViewControllerDelegate <NSObject>

- (void)addNewFolderWithName:(NSString *)name andDescription:(NSString *)description;

@end

@interface CreateViewController : UIViewController

@property (weak, nonatomic) id <CreateViewControllerDelegate> delegate;
@end
