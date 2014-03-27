//
// Created by Sebastien Arbogast on 26/03/14.
// Copyright (c) 2014 Hexed Bits. All rights reserved.
//

#import "JSRecipientView.h"
#import "UIColor+JSMessagesView.h"

#define PADDING 5
#define SYSTEM_VERSION_EQUAL_OR_GREATER_THAN(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface JSRecipientView ()
@property (strong, nonatomic) UILabel *toLabel;
@property (strong, nonatomic) UIButton *nameButton;
@property (strong, nonatomic) UIButton *removeButton;
@end

@implementation JSRecipientView {

}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        NSString *to = NSLocalizedString(@"To: ", @"");
        UIFont *toFont = [UIFont systemFontOfSize:17.0f];
        CGFloat toWidth = [to sizeWithFont:toFont].width;
        CGRect toFrame = CGRectMake(PADDING, 0, toWidth, frame.size.height);
        CGRect nameFrame = CGRectMake(toWidth + PADDING, 0, frame.size.width - toWidth - frame.size.height - PADDING, frame.size.height);
        CGRect removeFrame = CGRectMake(toWidth + nameFrame.size.width + PADDING, 0, frame.size.height, frame.size.height);

        _toLabel = [[UILabel alloc] initWithFrame:toFrame];
        _toLabel.text = to;
        _toLabel.backgroundColor = [UIColor clearColor];

        _nameButton = [[UIButton alloc] initWithFrame:nameFrame];
        [_nameButton setTitle:@"" forState:UIControlStateNormal];
        if([self respondsToSelector:@selector(tintColor)]){
            [_nameButton setTitleColor:self.tintColor forState:UIControlStateNormal];
            [_nameButton setTitleColor:[self.tintColor js_darkenColorWithValue:0.5] forState:UIControlStateHighlighted];
        } else {
            [_nameButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        }

        [_nameButton addTarget:self action:@selector(nameButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        _nameButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;

        _removeButton = [[UIButton alloc] initWithFrame:removeFrame];

        UIImage *removeIcon;
        if(SYSTEM_VERSION_EQUAL_OR_GREATER_THAN(@"7.0")){
            removeIcon = [[UIImage imageNamed:@"button-remove-recipient"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [_removeButton setTintColor:self.tintColor];
        } else {
            removeIcon = [UIImage imageNamed:@"button-remove-recipient"];
        }
        [_removeButton setImage:removeIcon forState:UIControlStateNormal];
        [_removeButton addTarget:self action:@selector(removeButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

        [self addSubview:_toLabel];
        [self addSubview:_nameButton];
        [self addSubview:_removeButton];
    }

    return self;
}

- (void)nameButtonTapped:(id)sender {
    [self.delegate recipientViewDidTapRecipientName:self];
}

- (void)removeButtonTapped:(id)sender {
    [self.delegate recipientViewDidTapRemoveRecipient:self];
}

- (void)setRecipient:(NSString *)recipient {
    _recipient = recipient;
    [_nameButton setTitle:recipient forState:UIControlStateNormal];
}


@end