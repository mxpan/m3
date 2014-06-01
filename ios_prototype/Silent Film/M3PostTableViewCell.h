//
//  M3PostTableViewCell.h
//  Silent Film
//
//  Created by Max Meyers on 5/31/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface M3PostTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *icon;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIView *unreadIcon;

@end
