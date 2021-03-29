//
//  ZYCustomOneTableViewCell.h
//  TXIMSDK_TUIKit_iOS
//
//  Created by Lazy on 2021/3/28.
//

#import "TUIMessageCell.h"
#import "ZYCustomOneCellData.h"

NS_ASSUME_NONNULL_BEGIN

@interface ZYCustomOneTableViewCell : TUIMessageCell


@property UIImageView *coverImageView;

@property UIImageView *headImageView;

@property UILabel *nickLabel;

@property ZYCustomOneCellData *customData;

- (void)fillWithData:(ZYCustomOneCellData *)data;

@end

NS_ASSUME_NONNULL_END
