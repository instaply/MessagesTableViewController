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

#import "JSMessageInputView.h"

#import <QuartzCore/QuartzCore.h>
#import "JSBubbleView.h"
#import "NSString+JSMessagesView.h"
#import "UIColor+JSMessagesView.h"
#import "JSRecipientView.h"
#import "UIImage+JSMessagesView.h"
#import "DAProgressOverlayView.h"

#define kAttachmentButtonWidth 40.0f
#define kRemoveAttachmentButtonOffsetX 4.0f
#define kRemoveAttachmentButtonOffsetY 4.0f

@interface JSMessageInputView ()

- (void)setup;

- (void)configureAttachmentButton;

- (void)configureAttachmentUploadIndicator;

- (void)configureProgressOverlayView;

- (void)configureAttachmentThumbnail;

- (void)configureRemoveAttachmentButton;

- (void)configureStopAttachmentUploadButton;

- (void)configureRecipientBarWithStyle:(JSMessageInputViewStyle)style;

- (void)configureInputBarWithStyle:(JSMessageInputViewStyle)style;

- (void)configureSendButtonWithStyle:(JSMessageInputViewStyle)style;

@end


@implementation JSMessageInputView

#pragma mark - Initialization

- (void)setup {
    self.backgroundColor = [UIColor whiteColor];
    self.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin);
    self.opaque = YES;
    self.userInteractionEnabled = YES;
    self.recipient = nil;
}

- (void)configureRecipientBarWithStyle:(JSMessageInputViewStyle)style {
    CGFloat recipientViewHeight = RECIPIENT_VIEW_HEIGHT;
    CGRect recipientFrame = CGRectMake(0, 0, self.frame.size.width, recipientViewHeight);
    JSRecipientView *recipientView = [[JSRecipientView alloc] initWithFrame:recipientFrame];
    recipientView.delegate = self;
    _recipientView = recipientView;
}

- (void)configureInputBarWithStyle:(JSMessageInputViewStyle)style {
    CGFloat sendButtonWidth = (style == JSMessageInputViewStyleClassic) ? 78.0f : 64.0f;
    CGFloat attachmentButtonWidth = kAttachmentButtonWidth;

    CGFloat width = self.frame.size.width - sendButtonWidth - attachmentButtonWidth;
    CGFloat height = [JSMessageInputView textViewLineHeight];

    JSMessageTextView *textView = [[JSMessageTextView alloc] initWithFrame:CGRectZero];
    [self addSubview:textView];
    _textView = textView;

    if (style == JSMessageInputViewStyleClassic) {
        _textView.frame = CGRectMake(6.0f + attachmentButtonWidth, RECIPIENT_VIEW_HEIGHT + 3.0f, width, height);
        _textView.backgroundColor = [UIColor whiteColor];

        self.image = [[UIImage imageNamed:@"input-bar-background"] resizableImageWithCapInsets:UIEdgeInsetsMake(19.0f, 3.0f, 19.0f, 3.0f)
                                                                                  resizingMode:UIImageResizingModeStretch];

        UIImageView *inputFieldBack = [[UIImageView alloc] initWithFrame:CGRectMake(_textView.frame.origin.x - 1.0f,
                0.0f,
                _textView.frame.size.width + 2.0f,
                self.frame.size.height)];
        inputFieldBack.image = [[UIImage imageNamed:@"input-field-cover"] resizableImageWithCapInsets:UIEdgeInsetsMake(20.0f, 12.0f, 18.0f, 18.0f)];
        inputFieldBack.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
        inputFieldBack.backgroundColor = [UIColor clearColor];
        [self addSubview:inputFieldBack];
    }
    else {
        _textView.frame = CGRectMake(4.0f + attachmentButtonWidth, RECIPIENT_VIEW_HEIGHT + 4.5f, width, height);
        _textView.backgroundColor = [UIColor clearColor];
        _textView.layer.borderColor = [UIColor colorWithWhite:0.8f alpha:1.0f].CGColor;
        _textView.layer.borderWidth = 0.65f;
        _textView.layer.cornerRadius = 6.0f;

        self.image = [[UIImage imageNamed:@"input-bar-flat"] resizableImageWithCapInsets:UIEdgeInsetsMake(2.0f, 0.0f, 0.0f, 0.0f)
                                                                            resizingMode:UIImageResizingModeStretch];
    }
}

- (void)configureAttachmentButton {
    UIButton *attachmentButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *attachmentIcon = [UIImage imageNamed:@"icon-attachment.png"];
    [attachmentButton setImage:attachmentIcon forState:UIControlStateNormal];
    [attachmentButton setImage:[attachmentIcon js_imageMaskWithColor:[UIColor darkGrayColor]] forState:UIControlStateHighlighted];
    self.attachmentButton = attachmentButton;
}

- (void)configureAttachmentUploadIndicator {
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicatorView.hidesWhenStopped = YES;
    self.attachmentUploadIndicator = activityIndicatorView;
}

- (void)configureProgressOverlayView {
    DAProgressOverlayView *progressOverlayView = [[DAProgressOverlayView alloc] init];
    progressOverlayView.hidden = YES;
    progressOverlayView.triggersDownloadDidFinishAnimationAutomatically = NO;
    progressOverlayView.overlayColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.75];
    progressOverlayView.outerRadiusRatio = 0.8;
    progressOverlayView.innerRadiusRatio = 0.7;
    self.progressOverlayView = progressOverlayView;
}

- (void)configureAttachmentThumbnail {
    UIImageView *attachmentThumbnail = [[UIImageView alloc] init];
    attachmentThumbnail.contentMode = UIViewContentModeScaleAspectFill;
    attachmentThumbnail.clipsToBounds = YES;
    attachmentThumbnail.layer.masksToBounds = YES;
    attachmentThumbnail.layer.cornerRadius = 4.;
    attachmentThumbnail.userInteractionEnabled = YES;
    self.attachmentThumbnail = attachmentThumbnail;
}

- (void)configureRemoveAttachmentButton {
    UIButton *removeAttachmentButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [removeAttachmentButton setImage:[[UIImage imageNamed:@"button-remove-attachment.png"] js_imageAsCircle:YES withDiamter:16.0 borderColor:nil borderWidth:0.0 shadowOffSet:CGSizeZero] forState:UIControlStateNormal];
    [removeAttachmentButton setImage:[[UIImage imageNamed:@"button-remove-attachment-pressed.png"] js_imageAsCircle:YES withDiamter:16.0 borderColor:nil borderWidth:0.0 shadowOffSet:CGSizeZero] forState:UIControlStateHighlighted];
    removeAttachmentButton.hidden = YES;
    self.removeAttachmentButton = removeAttachmentButton;
}

- (void)configureStopAttachmentUploadButton {
    UIButton *stopAttachmentUploadButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [stopAttachmentUploadButton setImage:[UIImage imageNamed:@"473-stop2"] forState:UIControlStateNormal];
    stopAttachmentUploadButton.enabled = YES;
    self.stopAttachmentUploadButton = stopAttachmentUploadButton;
}

- (void)configureSendButtonWithStyle:(JSMessageInputViewStyle)style {
    UIButton *sendButton;

    if (style == JSMessageInputViewStyleClassic) {
        sendButton = [UIButton buttonWithType:UIButtonTypeCustom];

        UIEdgeInsets insets = UIEdgeInsetsMake(0.0f, 13.0f, 0.0f, 13.0f);
        UIImage *sendBack = [[UIImage imageNamed:@"send-button"] resizableImageWithCapInsets:insets];
        UIImage *sendBackHighLighted = [[UIImage imageNamed:@"send-button-pressed"] resizableImageWithCapInsets:insets];
        [sendButton setBackgroundImage:sendBack forState:UIControlStateNormal];
        [sendButton setBackgroundImage:sendBack forState:UIControlStateDisabled];
        [sendButton setBackgroundImage:sendBackHighLighted forState:UIControlStateHighlighted];

        UIColor *titleShadow = [UIColor colorWithRed:0.325f green:0.463f blue:0.675f alpha:1.0f];
        [sendButton setTitleShadowColor:titleShadow forState:UIControlStateNormal];
        [sendButton setTitleShadowColor:titleShadow forState:UIControlStateHighlighted];
        sendButton.titleLabel.shadowOffset = CGSizeMake(0.0f, -1.0f);

        [sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
        [sendButton setTitleColor:[UIColor colorWithWhite:1.0f alpha:0.5f] forState:UIControlStateDisabled];

        sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:16.0f];
    }
    else {
        sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
        sendButton.backgroundColor = [UIColor clearColor];

        [sendButton setTitleColor:[UIColor js_bubbleBlueColor] forState:UIControlStateNormal];
        [sendButton setTitleColor:[UIColor js_bubbleBlueColor] forState:UIControlStateHighlighted];
        [sendButton setTitleColor:[UIColor js_bubbleLightGrayColor] forState:UIControlStateDisabled];

        sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
    }

    NSString *title = NSLocalizedString(@"Send", nil);
    [sendButton setTitle:title forState:UIControlStateNormal];
    [sendButton setTitle:title forState:UIControlStateHighlighted];
    [sendButton setTitle:title forState:UIControlStateDisabled];

    sendButton.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin);

    [self setSendButton:sendButton];
}

- (instancetype)initWithFrame:(CGRect)frame
                        style:(JSMessageInputViewStyle)style
                     delegate:(id <UITextViewDelegate, JSDismissiveTextViewDelegate>)delegate
         panGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer {
    self = [super initWithFrame:frame];
    if (self) {
        _style = style;
        [self setup];
        [self configureRecipientBarWithStyle:style];
        [self configureInputBarWithStyle:style];
        [self configureSendButtonWithStyle:style];
        [self configureAttachmentUploadIndicator];
        [self configureAttachmentThumbnail];
        [self configureAttachmentButton];
        [self configureRemoveAttachmentButton];
        [self configureProgressOverlayView];
        [self configureStopAttachmentUploadButton];

        _textView.delegate = delegate;
        _textView.keyboardDelegate = delegate;
        _textView.dismissivePanGestureRecognizer = panGestureRecognizer;
    }
    return self;
}

- (void)dealloc {
    _textView = nil;
    _sendButton = nil;
}

#pragma mark - UIView

- (BOOL)resignFirstResponder {
    [self.textView resignFirstResponder];
    return [super resignFirstResponder];
}

#pragma mark - Setters

- (void)setSendButton:(UIButton *)btn {
    if (_sendButton)
        [_sendButton removeFromSuperview];

    if (self.style == JSMessageInputViewStyleClassic) {
        btn.frame = CGRectMake(self.frame.size.width - 65.0f, 8.0f, 59.0f, 26.0f + RECIPIENT_VIEW_HEIGHT);
    }
    else {
        CGFloat padding = 8.0f;
        btn.frame = CGRectMake(self.textView.frame.origin.x + self.textView.frame.size.width,
                padding + RECIPIENT_VIEW_HEIGHT,
                60.0f,
                self.textView.frame.size.height - padding);
    }

    [self addSubview:btn];
    _sendButton = btn;
}

- (void)setAttachmentButton:(UIButton *)btn {
    if (_attachmentButton) {
        [_attachmentButton removeFromSuperview];
    }

    if (self.style == JSMessageInputViewStyleClassic) {
        btn.frame = CGRectMake(6.0f, 8.0f, kAttachmentButtonWidth, 26.0f + RECIPIENT_VIEW_HEIGHT);
    }
    else {
        CGFloat padding = 8.0f;
        btn.frame = CGRectMake(4.0f,
                padding + RECIPIENT_VIEW_HEIGHT,
                kAttachmentButtonWidth,
                self.textView.frame.size.height - padding);
    }

    [self addSubview:btn];
    _attachmentButton = btn;
}

- (void)setAttachmentUploadIndicator:(UIActivityIndicatorView *)attachmentUploadIndicator {
    if (_attachmentUploadIndicator) {
        [_attachmentUploadIndicator removeFromSuperview];
    }

    if (self.style == JSMessageInputViewStyleClassic) {
        attachmentUploadIndicator.frame = CGRectMake(6.0f, 8.0f, kAttachmentButtonWidth, 26.0f + RECIPIENT_VIEW_HEIGHT);
    }
    else {
        CGFloat padding = 8.0f;
        attachmentUploadIndicator.frame = CGRectMake(4.0f,
                padding + RECIPIENT_VIEW_HEIGHT,
                kAttachmentButtonWidth,
                self.textView.frame.size.height - padding);
    }

    [self addSubview:attachmentUploadIndicator];
    _attachmentUploadIndicator = attachmentUploadIndicator;
}

- (void)setRemoveAttachmentButton:(UIButton *)btn {
    if (_removeAttachmentButton) {
        [_removeAttachmentButton removeFromSuperview];
    }

    btn.frame = CGRectMake(self.attachmentThumbnail.frame.origin.x - kRemoveAttachmentButtonOffsetX, self.attachmentThumbnail.frame.origin.y - kRemoveAttachmentButtonOffsetY, 16, 16);

    [self addSubview:btn];
    _removeAttachmentButton = btn;
}

- (void)setStopAttachmentUploadButton:(UIButton *)btn {
    if (_stopAttachmentUploadButton) {
        [_stopAttachmentUploadButton removeFromSuperview];
    }

    btn.frame = CGRectMake(0,0,self.attachmentThumbnail.frame.size.width, self.attachmentThumbnail.frame.size.height);

    [self.progressOverlayView addSubview:btn];
    _stopAttachmentUploadButton = btn;
}

- (void)setAttachmentThumbnail:(UIImageView *)attachmentThumbnail {
    if (_attachmentThumbnail) {
        [_attachmentThumbnail removeFromSuperview];
    }

    if (self.style == JSMessageInputViewStyleClassic) {
        attachmentThumbnail.frame = CGRectMake(6.0f, 8.0f, kAttachmentButtonWidth, 26.0f + RECIPIENT_VIEW_HEIGHT);
    }
    else {
        CGFloat padding = 8.0f;
        attachmentThumbnail.frame = CGRectMake(4.0f,
                padding + RECIPIENT_VIEW_HEIGHT,
                kAttachmentButtonWidth,
                self.textView.frame.size.height - padding);
    }

    [self addSubview:attachmentThumbnail];
    _attachmentThumbnail = attachmentThumbnail;
}

- (void)setProgressOverlayView:(DAProgressOverlayView *)progressOverlayView {
    if(_progressOverlayView) {
        [_progressOverlayView removeFromSuperview];
    }
    progressOverlayView.frame = CGRectMake(0, 0, self.attachmentThumbnail.frame.size.width, self.attachmentThumbnail.frame.size.height);
    [self.attachmentThumbnail addSubview:progressOverlayView];
    _progressOverlayView = progressOverlayView;
}

- (void)setRecipient:(NSString *)recipient {
    if (recipient != nil && _recipient == nil) {
        [self addSubview:_recipientView];
    } else if (recipient == nil && _recipient != nil) {
        [_recipientView removeFromSuperview];
    }
    _recipient = recipient;
    _recipientView.recipient = recipient;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat sendButtonWidth = (self.style == JSMessageInputViewStyleClassic) ? 78.0f : 64.0f;
    CGFloat attachmentButtonWidth = kAttachmentButtonWidth;

    CGFloat width = self.frame.size.width - sendButtonWidth - attachmentButtonWidth;
    CGFloat height = _textView.frame.size.height;
    if (self.recipient) {
        _recipientView.frame = CGRectMake(0, 0, self.frame.size.width, RECIPIENT_VIEW_HEIGHT);
        if (self.style == JSMessageInputViewStyleClassic) {
            _textView.frame = CGRectMake(6.0f + attachmentButtonWidth, RECIPIENT_VIEW_HEIGHT + 3.0f, width, height);
            _sendButton.frame = CGRectMake(self.frame.size.width - 65.0f, 8.0f, 59.0f, 26.0f + RECIPIENT_VIEW_HEIGHT);
            _attachmentButton.frame = CGRectMake(6.0f, RECIPIENT_VIEW_HEIGHT + 3.0f, kAttachmentButtonWidth, height);
        } else {
            _textView.frame = CGRectMake(4.0f + attachmentButtonWidth, RECIPIENT_VIEW_HEIGHT + 4.5f, width, height);
            CGFloat padding = 8.0f;
            _sendButton.frame = CGRectMake(self.textView.frame.origin.x + self.textView.frame.size.width,
                    padding + RECIPIENT_VIEW_HEIGHT,
                    60.0f,
                    self.textView.frame.size.height - padding);
            _attachmentButton.frame = CGRectMake(4.0f, RECIPIENT_VIEW_HEIGHT + 4.5f, kAttachmentButtonWidth, height);
        }

    } else {
        _recipientView.frame = CGRectZero;
        if (self.style == JSMessageInputViewStyleClassic) {
            _textView.frame = CGRectMake(6.0f + attachmentButtonWidth, 3.0f, width, height);
            _sendButton.frame = CGRectMake(self.frame.size.width - 65.0f, 8.0f, 59.0f, 26.0f);
            _attachmentButton.frame = CGRectMake(6.0f, 3.0f, kAttachmentButtonWidth, height);
        } else {
            _textView.frame = CGRectMake(4.0f + attachmentButtonWidth, 4.5f, width, height);
            CGFloat padding = 8.0f;
            _sendButton.frame = CGRectMake(self.textView.frame.origin.x + self.textView.frame.size.width,
                    padding,
                    60.0f,
                    self.textView.frame.size.height - padding);
            _attachmentButton.frame = CGRectMake(4.0f, 4.5f, kAttachmentButtonWidth, height);
        }
    }
    _attachmentUploadIndicator.frame = _attachmentButton.frame;
    _attachmentThumbnail.frame = CGRectMake(
            _attachmentButton.frame.origin.x + 2,
            _attachmentButton.frame.origin.y - ((kAttachmentButtonWidth - _attachmentButton.frame.size.height) / 2) + 2,
            _attachmentButton.frame.size.width - 4,
            kAttachmentButtonWidth - 4
    );
    _progressOverlayView.frame = CGRectMake(0, 0, self.attachmentThumbnail.frame.size.width, self.attachmentThumbnail.frame.size.height);
    _stopAttachmentUploadButton.frame = CGRectMake(0, 0, self.attachmentThumbnail.frame.size.width, self.attachmentThumbnail.frame.size.height);
    _removeAttachmentButton.frame = CGRectMake(self.attachmentThumbnail.frame.origin.x - kRemoveAttachmentButtonOffsetX, self.attachmentThumbnail.frame.origin.y - kRemoveAttachmentButtonOffsetY, 16, 16);
}


#pragma mark - JSRecipientViewDelegate implementation

- (void)recipientViewDidTapRecipientName:(JSRecipientView *)recipientView {
    [self.delegate messageInputViewDidTapRecipientName:self];
}

- (void)recipientViewDidTapRemoveRecipient:(JSRecipientView *)recipientView {
    [self.delegate messageInputViewDidTapRecipientRemove:self];
}


#pragma mark - Message input view

- (void)adjustTextViewHeightBy:(CGFloat)changeInHeight {
    CGRect prevFrame = self.textView.frame;

    NSUInteger numLines = MAX([self.textView numberOfLinesOfText],
    [self.textView.text js_numberOfLines]);

    //  below iOS 7, if you set the text view frame programmatically, the KVO will continue notifying
    //  to avoid that, we are removing the observer before setting the frame and add the observer after setting frame here.
    [self.textView removeObserver:_textView.keyboardDelegate
                       forKeyPath:@"contentSize"];

    self.textView.frame = CGRectMake(prevFrame.origin.x,
            prevFrame.origin.y,
            prevFrame.size.width,
            prevFrame.size.height + changeInHeight);

    [self.textView addObserver:_textView.keyboardDelegate
                    forKeyPath:@"contentSize"
                       options:NSKeyValueObservingOptionNew
                       context:nil];

    self.textView.contentInset = UIEdgeInsetsMake((numLines >= 6 ? 4.0f : 0.0f),
            0.0f,
            (numLines >= 6 ? 4.0f : 0.0f),
            0.0f);

    // from iOS 7, the content size will be accurate only if the scrolling is enabled.
    self.textView.scrollEnabled = YES;

    if (numLines >= 6) {
        CGPoint bottomOffset = CGPointMake(0.0f, self.textView.contentSize.height - self.textView.bounds.size.height);
        [self.textView setContentOffset:bottomOffset animated:YES];
        [self.textView scrollRangeToVisible:NSMakeRange(self.textView.text.length - 2, 1)];
    }
}

+ (CGFloat)textViewLineHeight {
    return 36.0f; // for fontSize 16.0f
}

+ (CGFloat)maxLines {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) ? 4.0f : 8.0f;
}

+ (CGFloat)maxHeight {
    return ([JSMessageInputView maxLines] + 1.0f) * [JSMessageInputView textViewLineHeight];
}

@end
