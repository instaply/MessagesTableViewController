//
// Created by Sebastien Arbogast on 26/03/14.
// Copyright (c) 2014 Hexed Bits. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JSRecipientView;

@protocol JSRecipientViewDelegate <NSObject>
-(void)recipientViewDidTapRecipientName:(JSRecipientView *)recipientView;
-(void)recipientViewDidTapRemoveRecipient:(JSRecipientView *)recipientView;
@end

@interface JSRecipientView : UIView
@property (weak, nonatomic) id<JSRecipientViewDelegate> delegate;
@property (strong, nonatomic) NSString *recipient;
@end