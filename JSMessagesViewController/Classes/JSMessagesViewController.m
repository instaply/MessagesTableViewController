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

#import "JSMessagesViewController.h"
#import "NSString+JSMessagesView.h"
#import "UIImage+JSMessagesView.h"
#import "DAProgressOverlayView.h"

@interface JSMessagesViewController () <JSDismissiveTextViewDelegate, JSMessageInputViewDelegate, UIGestureRecognizerDelegate>

@property(assign, nonatomic) CGFloat previousTextViewContentHeight;
@property(assign, nonatomic) BOOL isUserScrolling;

- (void)setup;

- (void)sendPressed:(UIButton *)sender;

- (void)handleTapGestureRecognizer:(UITapGestureRecognizer *)tap;

- (BOOL)shouldAllowScroll;

- (void)layoutAndAnimateMessageInputTextView:(UITextView *)textView;

- (void)setTableViewInsetsWithBottomValue:(CGFloat)bottom;

- (UIEdgeInsets)tableViewInsetsWithBottomValue:(CGFloat)bottom;

- (void)handleWillShowKeyboardNotification:(NSNotification *)notification;

- (void)handleWillHideKeyboardNotification:(NSNotification *)notification;

- (void)keyboardWillShowHide:(NSNotification *)notification;

- (UIViewAnimationOptions)animationOptionsForCurve:(UIViewAnimationCurve)curve;

- (void)updateSendButtonEnabled;

@end


@implementation JSMessagesViewController

#pragma mark - Initialization

- (void)setup {
    if ([self.view isKindOfClass:[UIScrollView class]]) {
        // FIXME: hack-ish fix for ipad modal form presentations
        ((UIScrollView *) self.view).scrollEnabled = NO;
    }

    _isUserScrolling = NO;

    JSMessageInputViewStyle inputViewStyle = [self.delegate inputViewStyle];
    CGFloat inputViewHeight = (inputViewStyle == JSMessageInputViewStyleFlat) ? 45.0f : 40.0f;
    if (self.recipient) {
        inputViewHeight += RECIPIENT_VIEW_HEIGHT;
    }

    JSMessageTableView *tableView = [[JSMessageTableView alloc] initWithFrame:self.view.frame style:UITableViewStylePlain];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.dataSource = self;
    tableView.delegate = self;
    [self.view addSubview:tableView];
    _tableView = tableView;

    [self setTableViewInsetsWithBottomValue:inputViewHeight];

    [self setBackgroundColor:[UIColor js_backgroundColorClassic]];

    CGRect inputFrame = CGRectMake(0.0f,
            self.view.frame.size.height - inputViewHeight,
            self.view.frame.size.width,
            inputViewHeight);

    BOOL allowsPan = YES;
    if ([self.delegate respondsToSelector:@selector(allowsPanToDismissKeyboard)]) {
        allowsPan = [self.delegate allowsPanToDismissKeyboard];
    }

    UIPanGestureRecognizer *pan = allowsPan ? _tableView.panGestureRecognizer : nil;

    JSMessageInputView *inputView = [[JSMessageInputView alloc] initWithFrame:inputFrame
                                                                        style:inputViewStyle
                                                                     delegate:self
                                                         panGestureRecognizer:pan];

    if (!allowsPan) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGestureRecognizer:)];
        tap.delegate = self;
        [_tableView addGestureRecognizer:tap];
    }

    if ([self.delegate respondsToSelector:@selector(sendButtonForInputView)]) {
        UIButton *sendButton = [self.delegate sendButtonForInputView];
        [inputView setSendButton:sendButton];
    }

    inputView.sendButton.enabled = NO;
    [inputView.sendButton addTarget:self
                             action:@selector(sendPressed:)
                   forControlEvents:UIControlEventTouchUpInside];

    [inputView.attachmentButton addTarget:self action:@selector(attachmentPressed:) forControlEvents:UIControlEventTouchUpInside];
    [inputView.removeAttachmentButton addTarget:self action:@selector(removeAttachmentPressed:) forControlEvents:UIControlEventTouchUpInside];
    [inputView.stopAttachmentUploadButton addTarget:self action:@selector(stopAttachmentUploadPressed:) forControlEvents:UIControlEventTouchUpInside];

    [self.view addSubview:inputView];
    inputView.delegate = self;
    _messageInputView = inputView;
}

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
    [[JSBubbleView appearance] setFont:[UIFont systemFontOfSize:16.0f]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillShowKeyboardNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleWillHideKeyboardNotification:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    [self.messageInputView.textView addObserver:self
                                     forKeyPath:@"contentSize"
                                        options:NSKeyValueObservingOptionNew
                                        context:nil];

    [self.tableView addObserver:self forKeyPath:@"tableFooterView" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.messageInputView resignFirstResponder];
    [self setEditing:NO animated:YES];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

    [self.messageInputView.textView removeObserver:self forKeyPath:@"contentSize"];
    [self.tableView removeObserver:self forKeyPath:@"tableFooterView"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"*** %@: didReceiveMemoryWarning ***", [self class]);
}

- (void)messageInputViewDidTapRecipientName:(JSMessageInputView *)messageInputView {
    if ([self.delegate respondsToSelector:@selector(didTapRecipient)]) {
        [self.delegate didTapRecipient];
    }
}

- (void)messageInputViewDidTapRecipientRemove:(JSMessageInputView *)messageInputView {
    if ([self.delegate respondsToSelector:@selector(didAskToRemoveRecipient)]) {
        [self.delegate didAskToRemoveRecipient];
    }
}

- (void)dealloc {
    _delegate = nil;
    _dataSource = nil;
    _tableView = nil;
    _messageInputView = nil;
}

#pragma mark - View rotation

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.tableView reloadData];
    [self.tableView setNeedsLayout];
}

#pragma mark - Actions

- (void)sendPressed:(UIButton *)sender {
    [self.delegate didSendText:[self.messageInputView.textView.text js_stringByTrimingWhitespace]
                    fromSender:self.sender
                        onDate:[NSDate date]];
}

- (void)attachmentPressed:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(didAskToAddAttachment)]) {
        self.messageInputView.attachmentButton.hidden = YES;
        [self.messageInputView.attachmentUploadIndicator startAnimating];
        self.messageInputView.sendButton.enabled = NO;
        _isUploadingAttachment = YES;
        [self.delegate didAskToAddAttachment];
    }
}

- (void)removeAttachmentPressed:(UIButton *)sender {
    [self removeAttachment];
    [self.delegate didRemoveAttachment];
    _isUploadingAttachment = NO;
    [self updateSendButtonEnabled];
}

- (void)stopAttachmentUploadPressed:(id)sender {
    if([self.delegate respondsToSelector:@selector(didAskToCancelAttachmentUpload)]){
        [self.delegate didAskToCancelAttachmentUpload];
    }
}

- (void)stopAttachmentUpload {
    [self removeAttachment];
    [self.delegate didCancelAttachmentUpload];
    _isUploadingAttachment = NO;
    [self updateSendButtonEnabled];
}

- (void)removeAttachment {
    [self.messageInputView.attachmentUploadIndicator stopAnimating];
    self.messageInputView.attachmentThumbnail.image = nil;
    self.messageInputView.removeAttachmentButton.hidden = YES;
    self.messageInputView.progressOverlayView.hidden = YES;
    self.messageInputView.progressOverlayView.progress = 0.f;
    self.messageInputView.attachmentButton.hidden = NO;
    _isUploadingAttachment = NO;
    [self updateSendButtonEnabled];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    // We prevent the gesture recognizer to begin if the
    // keyboard is hidden in the message screen, so that
    // underlying elements can receive touch events normally
    // (The gesture recognizer here is the TapGestureRecognizer used
    // to dismiss the keyboad when tapping outside of it)
    return [self.messageInputView.textView isFirstResponder];
}

- (void)handleTapGestureRecognizer:(UITapGestureRecognizer *)tap {
    [self.messageInputView.textView resignFirstResponder];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    JSBubbleMessageType type = [self.delegate messageTypeForRowAtIndexPath:indexPath];

    UIImageView *bubbleImageView = [self.delegate bubbleImageViewWithType:type
                                                        forRowAtIndexPath:indexPath];

    id <JSMessageData> message = [self.dataSource messageForRowAtIndexPath:indexPath];

    UIImageView *avatar = [self.dataSource avatarImageViewForRowAtIndexPath:indexPath sender:[message sender]];

    BOOL displayTimestamp = YES;
    if ([self.delegate respondsToSelector:@selector(shouldDisplayTimestampForRowAtIndexPath:)]) {
        displayTimestamp = [self.delegate shouldDisplayTimestampForRowAtIndexPath:indexPath];
    }

    NSString *CellIdentifier = nil;
    if ([self.delegate respondsToSelector:@selector(customCellIdentifierForRowAtIndexPath:)]) {
        CellIdentifier = [self.delegate customCellIdentifierForRowAtIndexPath:indexPath];
    }

    if (!CellIdentifier) {
        CellIdentifier = [NSString stringWithFormat:@"JSMessageCell_%d_%d_%d_%d", (int) type, displayTimestamp, avatar != nil, [message sender] != nil];
    }

    JSBubbleMessageCell *cell = (JSBubbleMessageCell *) [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (!cell) {
        cell = [[JSBubbleMessageCell alloc] initWithBubbleType:type
                                               bubbleImageView:bubbleImageView
                                                       message:message
                                             displaysTimestamp:displayTimestamp
                                                     hasAvatar:avatar != nil
                                               reuseIdentifier:CellIdentifier];
    }

    [cell setMessage:message];
    [cell setAvatarImageView:avatar];
    [cell setBackgroundColor:tableView.backgroundColor];

    if ([self.delegate respondsToSelector:@selector(configureCell:atIndexPath:)]) {
        [self.delegate configureCell:cell atIndexPath:indexPath];
    }

    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    id <JSMessageData> message = [self.dataSource messageForRowAtIndexPath:indexPath];
    UIImageView *avatar = [self.dataSource avatarImageViewForRowAtIndexPath:indexPath sender:[message sender]];

    BOOL displayTimestamp = YES;
    if ([self.delegate respondsToSelector:@selector(shouldDisplayTimestampForRowAtIndexPath:)]) {
        displayTimestamp = [self.delegate shouldDisplayTimestampForRowAtIndexPath:indexPath];
    }

    return [JSBubbleMessageCell neededHeightForBubbleMessageCellWithMessage:message
                                                             displaysAvatar:avatar != nil
                                                          displaysTimestamp:displayTimestamp];
}

#pragma mark - Messages view controller

- (void)finishSend {
    [self.messageInputView.textView setText:nil];
    [self textViewDidChange:self.messageInputView.textView];
    [self.tableView reloadData];
    [self removeAttachment];
    [self updateSendButtonEnabled];
}

- (void)startUploadingAttachment:(UIImage *)attachmentThumbnail {
    self.messageInputView.attachmentButton.hidden = YES;
    self.messageInputView.attachmentThumbnail.image = [attachmentThumbnail js_imageAsRoundedSquare:YES withSideLength:self.messageInputView.textView.frame.size.height borderColor:[UIColor whiteColor] borderWidth:2 shadowOffSet:CGSizeZero];
    [self.messageInputView.attachmentUploadIndicator stopAnimating];
    self.messageInputView.progressOverlayView.hidden = NO;
    [self.messageInputView.progressOverlayView displayOperationWillTriggerAnimation];
}

- (void)setAttachment:(UIImage *)attachmentThumbnail {
    self.messageInputView.attachmentButton.hidden = YES;
    self.messageInputView.attachmentThumbnail.image = [attachmentThumbnail js_imageAsRoundedSquare:YES withSideLength:self.messageInputView.textView.frame.size.height borderColor:[UIColor whiteColor] borderWidth:2 shadowOffSet:CGSizeZero];
    [self.messageInputView.attachmentUploadIndicator stopAnimating];
    self.messageInputView.progressOverlayView.hidden = YES;
    self.messageInputView.progressOverlayView.progress = 0.f;
    self.messageInputView.removeAttachmentButton.hidden = NO;
    _isUploadingAttachment = NO;
    [self updateSendButtonEnabled];
}

- (void)setAttachmentUploadProgress:(CGFloat)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.messageInputView.progressOverlayView setProgress:progress];
    });
}

- (void)finishUploadingAttachment {
    [self.messageInputView.progressOverlayView displayOperationDidFinishAnimation];
    double delayInSeconds = self.messageInputView.progressOverlayView.stateChangeAnimationDuration;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t) (delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
        self.messageInputView.progressOverlayView.progress = 0.f;
        self.messageInputView.progressOverlayView.hidden = YES;
        self.messageInputView.removeAttachmentButton.hidden = NO;
        _isUploadingAttachment = NO;
        [self updateSendButtonEnabled];
    });
}

- (void)setBackgroundColor:(UIColor *)color {
    self.view.backgroundColor = color;
    _tableView.backgroundColor = color;
    _tableView.separatorColor = color;
}

- (void)scrollToBottomAnimated:(BOOL)animated {
    if (![self shouldAllowScroll])
        return;

    NSInteger rows = [self.tableView numberOfRowsInSection:0];

    if (rows > 0) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows - 1 inSection:0]
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:animated];
    }
}

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath
              atScrollPosition:(UITableViewScrollPosition)position
                      animated:(BOOL)animated {
    if (![self shouldAllowScroll])
        return;

    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:position
                                  animated:animated];
}

- (BOOL)shouldAllowScroll {
    if (self.isUserScrolling) {
        if ([self.delegate respondsToSelector:@selector(shouldPreventScrollToBottomWhileUserScrolling)]
                && [self.delegate shouldPreventScrollToBottomWhileUserScrolling]) {
            return NO;
        }
    }

    return YES;
}

#pragma mark - Scroll view delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.isUserScrolling = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.isUserScrolling = NO;
}

#pragma mark - Text view delegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [textView becomeFirstResponder];

    if (!self.previousTextViewContentHeight)
        self.previousTextViewContentHeight = textView.contentSize.height;

    [self scrollToBottomAnimated:YES];
}

- (void)textViewDidChange:(UITextView *)textView {
    [self updateSendButtonEnabled];
}

- (void)updateSendButtonEnabled {
    self.messageInputView.sendButton.enabled = !self.isUploadingAttachment && (([[self.messageInputView.textView.text js_stringByTrimingWhitespace] length] > 0) || (self.messageInputView.attachmentThumbnail.image != nil));
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    [textView resignFirstResponder];
}

#pragma mark - Layout message input view

- (void)layoutAndAnimateMessageInputTextView:(UITextView *)textView {
    CGFloat maxHeight = [JSMessageInputView maxHeight];

    BOOL isShrinking = textView.contentSize.height < self.previousTextViewContentHeight;
    CGFloat changeInHeight = textView.contentSize.height - self.previousTextViewContentHeight;

    if (!isShrinking && (self.previousTextViewContentHeight == maxHeight || textView.text.length == 0)) {
        changeInHeight = 0;
    }
    else {
        changeInHeight = MIN(changeInHeight, maxHeight - self.previousTextViewContentHeight);
    }

    if (changeInHeight != 0.0f) {
        [UIView animateWithDuration:0.25f
                         animations:^{
            [self setTableViewInsetsWithBottomValue:self.tableView.contentInset.bottom + changeInHeight];

            [self scrollToBottomAnimated:NO];

            if (isShrinking) {
                // if shrinking the view, animate text view frame BEFORE input view frame
                [self.messageInputView adjustTextViewHeightBy:changeInHeight];
            }

            CGRect inputViewFrame = self.messageInputView.frame;
            self.messageInputView.frame = CGRectMake(0.0f,
                    inputViewFrame.origin.y - changeInHeight,
                    inputViewFrame.size.width,
                    inputViewFrame.size.height + changeInHeight);

            if (!isShrinking) {
                // growing the view, animate the text view frame AFTER input view frame
                [self.messageInputView adjustTextViewHeightBy:changeInHeight];
            }
        }
                         completion:^(BOOL finished) {

        }];

        self.previousTextViewContentHeight = MIN(textView.contentSize.height, maxHeight);
    }

    // Once we reached the max height, we have to consider the bottom offset for the text view.
    // To make visible the last line, again we have to set the content offset.
    if (self.previousTextViewContentHeight == maxHeight) {
        double delayInSeconds = 0.01;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t) (delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime,
                dispatch_get_main_queue(),
                ^(void) {
                    CGPoint bottomOffset = CGPointMake(0.0f, textView.contentSize.height - textView.bounds.size.height);
                    [textView setContentOffset:bottomOffset animated:YES];
                });
    }
}

- (void)setTableViewInsetsWithBottomValue:(CGFloat)bottom {
    UIEdgeInsets insets = [self tableViewInsetsWithBottomValue:bottom];
    self.tableView.contentInset = insets;
    self.tableView.scrollIndicatorInsets = insets;
}

- (UIEdgeInsets)tableViewInsetsWithBottomValue:(CGFloat)bottom {
    UIEdgeInsets insets = UIEdgeInsetsZero;

    if ([self respondsToSelector:@selector(topLayoutGuide)]) {
        insets.top = self.topLayoutGuide.length;
    }

    insets.bottom = bottom;

    return insets;
}

#pragma mark - Key-value observing

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (object == self.messageInputView.textView && [keyPath isEqualToString:@"contentSize"]) {
        [self layoutAndAnimateMessageInputTextView:object];
    } else if (object == self.tableView && [keyPath isEqualToString:@"tableFooterView"]) {
        [self setTableViewInsetsWithBottomValue:self.tableView.contentInset.bottom];
    }
}

#pragma mark - Keyboard notifications

- (void)handleWillShowKeyboardNotification:(NSNotification *)notification {
    [self keyboardWillShowHide:notification];
}

- (void)handleWillHideKeyboardNotification:(NSNotification *)notification {
    [self keyboardWillShowHide:notification];
}

- (void)keyboardWillShowHide:(NSNotification *)notification {
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIViewAnimationCurve curve = (UIViewAnimationCurve) [notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    double duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];

    [UIView animateWithDuration:duration
                          delay:0.0
                        options:[self animationOptionsForCurve:curve]
                     animations:^{
        CGFloat keyboardY = [self.view convertRect:keyboardRect fromView:nil].origin.y;

        CGRect inputViewFrame = self.messageInputView.frame;
        CGFloat inputViewFrameY = keyboardY - inputViewFrame.size.height;

        // for ipad modal form presentations
        CGFloat messageViewFrameBottom = self.view.frame.size.height - inputViewFrame.size.height;
        if (inputViewFrameY > messageViewFrameBottom)
            inputViewFrameY = messageViewFrameBottom;

        self.messageInputView.frame = CGRectMake(inputViewFrame.origin.x,
                inputViewFrameY,
                inputViewFrame.size.width,
                inputViewFrame.size.height);

        [self setTableViewInsetsWithBottomValue:self.view.frame.size.height
                - self.messageInputView.frame.origin.y];
    }
                     completion:nil];
}

#pragma mark - Dismissive text view delegate

- (void)keyboardDidScrollToPoint:(CGPoint)point {
    CGRect inputViewFrame = self.messageInputView.frame;
    CGPoint keyboardOrigin = [self.view convertPoint:point fromView:nil];
    inputViewFrame.origin.y = keyboardOrigin.y - inputViewFrame.size.height;
    self.messageInputView.frame = inputViewFrame;
}

- (void)keyboardWillBeDismissed {
    CGRect inputViewFrame = self.messageInputView.frame;
    inputViewFrame.origin.y = self.view.bounds.size.height - inputViewFrame.size.height;
    self.messageInputView.frame = inputViewFrame;
}

#pragma mark - Utilities

- (UIViewAnimationOptions)animationOptionsForCurve:(UIViewAnimationCurve)curve {
    switch (curve) {
        case UIViewAnimationCurveEaseInOut:
            return UIViewAnimationOptionCurveEaseInOut;

        case UIViewAnimationCurveEaseIn:
            return UIViewAnimationOptionCurveEaseIn;

        case UIViewAnimationCurveEaseOut:
            return UIViewAnimationOptionCurveEaseOut;

        case UIViewAnimationCurveLinear:
            return UIViewAnimationOptionCurveLinear;

        default:
            return (UIViewAnimationOptions) kNilOptions;
    }
}

- (void)setRecipient:(NSString *)recipient {
    CGFloat inputViewHeight = self.messageInputView.frame.size.height;
    CGFloat inputViewY = self.messageInputView.frame.origin.y;
    CGFloat bottomInset = _tableView.contentInset.bottom;
    if (recipient != nil && _recipient == nil) {
        inputViewHeight += RECIPIENT_VIEW_HEIGHT;
        inputViewY -= RECIPIENT_VIEW_HEIGHT;
        bottomInset += RECIPIENT_VIEW_HEIGHT;
    } else if (recipient == nil && _recipient != nil) {
        inputViewHeight -= RECIPIENT_VIEW_HEIGHT;
        inputViewY += RECIPIENT_VIEW_HEIGHT;
        bottomInset -= RECIPIENT_VIEW_HEIGHT;
    }
    [self setTableViewInsetsWithBottomValue:bottomInset];
    [UIView animateWithDuration:0.25f animations:^{
        self.messageInputView.frame = CGRectMake(self.messageInputView.frame.origin.x, inputViewY, self.messageInputView.frame.size.width, inputViewHeight);
        self.messageInputView.recipient = recipient;
    }                completion:^(BOOL finished) {
        _recipient = [recipient mutableCopy];

        [self.messageInputView setNeedsLayout];
        [self scrollToBottomAnimated:YES];
    }];
}


@end
