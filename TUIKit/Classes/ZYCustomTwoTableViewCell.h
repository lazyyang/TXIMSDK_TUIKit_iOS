//
//  ZYCustomTwoTableViewCell.h
//  TXIMSDK_TUIKit_iOS
//
//  Created by Lazy on 2021/3/28.
//

#import "TUIMessageCell.h"
#import "ZYCustomeTwoCellData.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZYCustomTwoTableViewCell : TUIMessageCell

@property UIImageView *headImageView;

@property UILabel *nickLabel;

@property UILabel *descLabel;

@property ZYCustomeTwoCellData *customData;

- (void)fillWithData:(ZYCustomeTwoCellData *)data;

@end

NS_ASSUME_NONNULL_END
