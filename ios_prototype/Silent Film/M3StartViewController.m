//
//  M3StartViewController.m
//  Silent Film
//
//  Created by Max Meyers on 5/27/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import "M3StartViewController.h"
#import <BlocksKit.h>

@interface M3StartViewController ()

@property NSTimer *countdownTimer;
@property CGFloat countdown;
@property (weak, nonatomic) IBOutlet UILabel *countdownLabel;

@end

@implementation M3StartViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.countdown = 3.5;
    }
    return self;
}

- (void)start
{
    self.countdownTimer = [NSTimer bk_scheduledTimerWithTimeInterval:1.0 block:^(NSTimer *timer) {
        self.countdown -= 1.0;
        NSInteger integer = floorf(self.countdown);
        self.countdownLabel.text = [NSString stringWithFormat:@"%d", integer];
        if (self.countdown < 0) {
            if (self.callback) {
                self.callback();
            }
            [timer invalidate];
        }
    } repeats:YES];
}

@end
