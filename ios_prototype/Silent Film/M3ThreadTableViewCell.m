//
//  M3ThreadTableViewCell.m
//  Silent Film
//
//  Created by Max Meyers on 5/31/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import "M3ThreadTableViewCell.h"
#import <UIImageView+WebCache.h>
#import "PFUser+SilentFilm.h"
#import "M3Thread.h"
#import "M3Post.h"

@implementation M3ThreadTableViewCell

@synthesize thread = _thread;

- (M3Thread*)thread
{
    return _thread;
}

- (void)setThread:(M3Thread *)thread
{
    _thread = thread;
 
    [[NSNotificationCenter defaultCenter] addObserverForName:@"posts" object:thread queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        if (self.thread.freshPosts.count == 0) {
            self.subtitleLabel.text = @"Send a challenge!";
        } else {
            BOOL waitingForMe = NO;
            for (M3Post *post in self.thread.freshPosts) {
                if (![post.user isEqualToCurrentUser]) {
                    waitingForMe = YES;
                }
            }
            
            if (waitingForMe) {
                self.subtitleLabel.text = @"Waiting for you!";
            } else {
                self.subtitleLabel.text = @"Waiting for response...";
            }
        }
    }];
    
    [self.icon setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=normal", self.thread.otherUser.facebookId]] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
    }];
    

}

- (void)awakeFromNib
{
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
