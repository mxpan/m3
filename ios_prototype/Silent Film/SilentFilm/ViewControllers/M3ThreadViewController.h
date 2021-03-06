//
//  M3ThreadViewController.h
//  Silent Film
//
//  Created by Max Meyers on 4/29/14.
//  Copyright (c) 2014 M3. All rights reserved.
//

@class M3Thread, M3CreateCardViewController, AVCamViewController;

@interface M3ThreadViewController : UIViewController

@property M3Thread *thread;

- (id)initWithThread:(M3Thread*)thread;
- (void)recordedVideoWithFileAtURL:(NSURL *)url;
- (void)createCardViewControllerFinished:(M3CreateCardViewController*)createCardViewController;
- (void)dismissCardViewController:(M3CreateCardViewController*)createCardViewController;
- (void)dismissAvCam: (AVCamViewController*)avCamVc;
- (void)dismissEndingCardAndUpload: (M3CreateCardViewController *)createCardViewController;
- (void)skipEndingCard: (M3CreateCardViewController *)createCardViewController;

@property UIImage *titleCard;

@end
