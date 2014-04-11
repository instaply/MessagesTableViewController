//
//  Created by Jesse Squires
//  http://www.hexedbits.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSMessagesViewController
//
//
//  The MIT License
//  Copyright (c) 2013 Jesse Squires
//  http://opensource.org/licenses/MIT
//

#import "JSDemoViewController.h"
#import "JSMessage.h"
#import "DAProgressOverlayView.h"

#define kSubtitleJobs @"Jobs"
#define kSubtitleWoz @"Steve Wozniak"
#define kSubtitleCook @"Mr. Cook"

@interface JSDemoViewController ()
@property (strong, nonatomic) JSAttachment *currentAttachment;
@property (strong, nonatomic) NSTimer *timer;
@end

@implementation JSDemoViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    self.delegate = self;
    self.dataSource = self;
    [super viewDidLoad];

    [[JSBubbleView appearance] setFont:[UIFont systemFontOfSize:16.0f]];

    self.title = @"Messages";
    self.messageInputView.textView.placeHolder = @"New Message";
    self.sender = @"Jobs";

    [self setBackgroundColor:[UIColor whiteColor]];

    self.messages = [[NSMutableArray alloc] initWithObjects:
            [[JSMessage alloc] initWithText:@"JSMessagesViewController is simple and easy to use." sender:kSubtitleJobs date:[NSDate distantPast]],
            [[JSMessage alloc] initWithText:@"It's highly customizable." sender:kSubtitleWoz date:[NSDate distantPast]],
            [[JSMessage alloc] initWithText:@"It even has data detectors. You can call me tonight. My cell number is 452-123-4567. \nMy website is www.hexedbits.com." sender:kSubtitleJobs date:[NSDate distantPast]],
            [[JSMessage alloc] initWithText:@"Group chat. Sound effects and images included. Animations are smooth. Messages can be of arbitrary size!" sender:kSubtitleCook date:[NSDate distantPast]],
            [[JSMessage alloc] initWithText:@"Group chat. Sound effects and images included. Animations are smooth. Messages can be of arbitrary size!" sender:kSubtitleJobs date:[NSDate date]],
            [[JSMessage alloc] initWithText:@"Group chat. Sound effects and images included. Animations are smooth. Messages can be of arbitrary size!" sender:kSubtitleWoz date:[NSDate date]],
            [[JSMessage alloc] initWithText:@"Attachment test from Jobs." sender:kSubtitleJobs date:[NSDate date] attachment:[[JSAttachment alloc] initWithName:@"test1.pdf" contentType:@"application/pdf" contentLength:100000000 url:@"file.pdf"]],
            [[JSMessage alloc] initWithText:@"Attachment test from Woz." sender:kSubtitleWoz date:[NSDate date] attachment:[[JSAttachment alloc] initWithName:@"test2.pdf" contentType:@"application/pdf" contentLength:100000000 url:@"file.pdf"]],
            nil];


    for (NSUInteger i = 0; i < 3; i++) {
        [self.messages addObjectsFromArray:self.messages];
    }

    self.avatars = [[NSDictionary alloc] initWithObjectsAndKeys:
            [JSAvatarImageFactory avatarImageNamed:@"demo-avatar-jobs" croppedToCircle:YES], kSubtitleJobs,
            [JSAvatarImageFactory avatarImageNamed:@"demo-avatar-woz" croppedToCircle:YES], kSubtitleWoz,
            [JSAvatarImageFactory avatarImageNamed:@"demo-avatar-cook" croppedToCircle:YES], kSubtitleCook,
            nil];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward
                                                                                           target:self
                                                                                           action:@selector(buttonPressed:)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self scrollToBottomAnimated:NO];
}

#pragma mark - Actions

- (void)buttonPressed:(UIBarButtonItem *)sender {
    // Testing pushing/popping messages view
    /*JSDemoViewController *vc = [[JSDemoViewController alloc] initWithNibName:nil bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];*/
    if (self.recipient) {
        self.recipient = nil;
    } else {
        self.recipient = @"John Doe";
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.messages.count;
}

#pragma mark - Messages view delegate: REQUIRED

- (void)didSendText:(NSString *)text fromSender:(NSString *)sender onDate:(NSDate *)date {
    if ((self.messages.count - 1) % 2) {
        [JSMessageSoundEffect playMessageSentSound];
    }
    else {
        // for demo purposes only, mimicing received messages
        [JSMessageSoundEffect playMessageReceivedSound];
        sender = arc4random_uniform(10) % 2 ? kSubtitleCook : kSubtitleWoz;
    }

    [self.messages addObject:[[JSMessage alloc] initWithText:text sender:sender date:date attachment:self.currentAttachment]];

    [self finishSend];

    UILabel *footer = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
    footer.text = @"message sent";
    self.tableView.tableFooterView = footer;

    [self scrollToBottomAnimated:YES];
}

- (JSBubbleMessageType)messageTypeForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (indexPath.row % 2) ? JSBubbleMessageTypeIncoming : JSBubbleMessageTypeOutgoing;
}

- (UIImageView *)bubbleImageViewWithType:(JSBubbleMessageType)type
                       forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row % 2) {
        return [JSBubbleImageViewFactory bubbleImageViewForType:type
                                                          color:[UIColor js_bubbleLightGrayColor]];
    }

    return [JSBubbleImageViewFactory bubbleImageViewForType:type
                                                      color:[UIColor js_bubbleBlueColor]];
}

- (JSMessageInputViewStyle)inputViewStyle {
    return JSMessageInputViewStyleFlat;
}

#pragma mark - Messages view delegate: OPTIONAL

- (BOOL)shouldDisplayTimestampForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row % 3 == 0) {
        return YES;
    }
    return NO;
}

//
//  *** Implement to customize cell further
//
- (void)configureCell:(JSBubbleMessageCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    if ([cell messageType] == JSBubbleMessageTypeOutgoing) {
        cell.bubbleView.textView.textColor = [UIColor whiteColor];

        if ([cell.bubbleView.textView respondsToSelector:@selector(linkTextAttributes)]) {
            NSMutableDictionary *attrs = [cell.bubbleView.textView.linkTextAttributes mutableCopy];
            [attrs setValue:[UIColor blueColor] forKey:UITextAttributeTextColor];

            cell.bubbleView.textView.linkTextAttributes = attrs;
        }
    }

    if (cell.timestampLabel) {
        cell.timestampLabel.textColor = [UIColor lightGrayColor];
        cell.timestampLabel.shadowOffset = CGSizeZero;
    }

    if (cell.subtitleLabel) {
        cell.subtitleLabel.textColor = [UIColor lightGrayColor];
    }

#if TARGET_IPHONE_SIMULATOR
        cell.bubbleView.textView.dataDetectorTypes = UIDataDetectorTypeNone;
    #else
    cell.bubbleView.textView.dataDetectorTypes = UIDataDetectorTypeAll;
#endif
}

//  *** Implement to use a custom send button
//
//  The button's frame is set automatically for you
//
//  - (UIButton *)sendButtonForInputView
//

//  *** Implement to prevent auto-scrolling when message is added
//
- (BOOL)shouldPreventScrollToBottomWhileUserScrolling {
    return YES;
}

// *** Implemnt to enable/disable pan/tap todismiss keyboard
//
- (BOOL)allowsPanToDismissKeyboard {
    return YES;
}

#pragma mark - Messages view data source: REQUIRED

- (JSMessage *)messageForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.messages objectAtIndex:indexPath.row];
}

- (UIImageView *)avatarImageViewForRowAtIndexPath:(NSIndexPath *)indexPath sender:(NSString *)sender {
    UIImage *image = [self.avatars objectForKey:sender];
    return [[UIImageView alloc] initWithImage:image];
}

- (void)didTapRecipient {
    NSLog(@"Recipient should change!");
}

- (void)didAskToRemoveRecipient {
    self.recipient = nil;
}

- (void)didAskToAddAttachment {
    UIImage *attachment = [UIImage imageNamed:@"3387753757_f5ab39dcc5_b.jpg"];
    [self startUploadingAttachment:attachment];

    double delayInSeconds = self.messageInputView.progressOverlayView.stateChangeAnimationDuration;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
    });
}

- (void)updateProgress {
    CGFloat progress = self.messageInputView.progressOverlayView.progress + 0.01;
    if (progress >= 1) {
        [self.timer invalidate];
        [self finishUploadingAttachment];
    } else {
        [self setAttachmentUploadProgress:progress];
    }
}

- (void)didRemoveAttachment {
    NSLog(@"Attachment removed");
}


#pragma mark - View rotation

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.messageInputView setNeedsLayout];
}


@end
