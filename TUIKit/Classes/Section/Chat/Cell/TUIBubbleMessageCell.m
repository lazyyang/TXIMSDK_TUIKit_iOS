//
//  TBubbleMessageCell.m
//  TXIMSDK_TUIKit_iOS
//
//  Created by annidyfeng on 2019/5/22.
//

#import "TUIBubbleMessageCell.h"
#import "TUIFaceView.h"
#import "TUIFaceCell.h"
#import "THeader.h"
#import "TUIKit.h"
#import "THelper.h"
#import "MMLayout/UIView+MMLayout.h"

@implementation TUIBubbleMessageCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _bubbleView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [self.container addSubview:_bubbleView];
        _bubbleView.mm_fill();
        _bubbleView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void)fillWithData:(TUIBubbleMessageCellData *)data
{
    [super fillWithData:data];
    self.bubbleData = data;
    if (data.direction == MsgDirectionOutgoing) {
        self.bubbleView.backgroundColor = [UIColor colorWithRed:77.0f/255.0f green:189.0f/255.0f blue:253.0f/255.0f alpha:1.0];
    } else{
        self.bubbleView.backgroundColor = [UIColor colorWithRed:241.0f/255.0f green:240.0f/255.0f blue:240.0f/255.0f alpha:1.0];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.bubbleView.mm_top(self.bubbleData.bubbleTop);
    self.retryView.mm__centerY(self.bubbleView.mm_centerY);
    if (self.bubbleData.mydirection == MsgDirectionOutgoing) {
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bubbleView.bounds      byRoundingCorners:UIRectCornerTopLeft | UIRectCornerBottomLeft  | UIRectCornerTopRight  cornerRadii:CGSizeMake(15, 15)];
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.path = maskPath.CGPath;
        self.bubbleView.layer.mask = maskLayer;
    } else{
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bubbleView.bounds      byRoundingCorners:UIRectCornerTopLeft | UIRectCornerBottomRight  | UIRectCornerTopRight  cornerRadii:CGSizeMake(15, 15)];
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.path = maskPath.CGPath;
        self.bubbleView.layer.mask = maskLayer;
    }
}
@end
