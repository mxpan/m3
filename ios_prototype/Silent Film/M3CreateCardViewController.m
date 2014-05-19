//
//  M3CreateCardViewController.m
//  Silent Film
//
//  Created by Matthew Pick on 5/4/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

#import "M3CreateCardViewController.h"
#import "AVCamViewController.h"

@interface M3CreateCardViewController ()
@property (weak, nonatomic) IBOutlet UILabel *screenTitle;

@property (weak, nonatomic) IBOutlet UILabel *cardLabel;
@property (weak, nonatomic) IBOutlet UITextField *inputTextField;

@property (weak, nonatomic) IBOutlet UIButton *dontCreateCardButton;
@property (weak, nonatomic) IBOutlet UIButton *createCardButton;

@end

@implementation M3CreateCardViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    if (!self.isTitleCard) [self.screenTitle setText:@"Create Ending Card"];
}

- (IBAction)userDoneEnteringText:(UITextField *)sender {
    [sender resignFirstResponder];
}

- (IBAction)createCard:(UIButton *)sender {
    [self hideExtraText];
    [self setCardLabelText: [self.inputTextField text]];
    
    [self.threadViewController createCardViewControllerFinished:self];
}

- (void) setCardLabelText: (NSString *)text {
    [self.cardLabel setText:text];
}

- (void) hideExtraText {
    self.screenTitle.hidden =  true;
    self.dontCreateCardButton.hidden = true;
    self.createCardButton.hidden = true;
    self.inputTextField.hidden = true;
}

- (UIImage *) image
{
    UIGraphicsBeginImageContext(self.view.bounds.size);
    
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return viewImage;
}

- (void) saveImage:(UIImage *)image {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Image.png"];
    
    // Save image.
    [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];
}

- (IBAction)dontCreateCardPressed:(UIButton *)sender {
    [self.threadViewController dismissCardViewController:self];
}

- (IBAction)cancelVideo:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
