//
//  ZYCustomTwoTableViewCell.m
//  TXIMSDK_TUIKit_iOS
//
//  Created by Lazy on 2021/3/28.
//

#import "ZYCustomTwoTableViewCell.h"
#import "ReactiveObjC/ReactiveObjC.h"
#import "MMLayout/UIView+MMLayout.h"
#import "UIColor+TUIDarkMode.h"
#import "THeader.h"
#import <SDWebImage/SDWebImage.h>

@implementation ZYCustomTwoTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
      _headImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, 50, 50)];
      _headImageView.layer.cornerRadius = 25.0f;
      _headImageView.clipsToBounds = YES;
      [self.container addSubview:_headImageView];
      
      _nickLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, 15, 540.0f/2-80,20 )];
      _nickLabel.text = @"爱因斯坦（个人昵称）";
      _nickLabel.font = [UIFont boldSystemFontOfSize:16.0f];
      _nickLabel.textColor = [UIColor blackColor];
      [self.container addSubview:_nickLabel];
      
      _descLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, 40, 540.0f/2-80, 20)];
      _descLabel.text = @"这里是一段个人简介哦";
      _descLabel.font = [UIFont systemFontOfSize:14.0f];
      _descLabel.textColor = [UIColor blackColor];
      [self.container addSubview:_descLabel];
      
      
      UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 70, 540.0f/2, 0.5)];
      [self.container addSubview:lineView];
      lineView.backgroundColor = RGB(0xd6, 0xd7, 0xdc);
      
      UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 70, 540.0f/2, 36)];
      titleLabel.text = @"个人名片";
      titleLabel.font = [UIFont systemFontOfSize:14.0f];
      titleLabel.textColor = [UIColor blackColor];
      [self.container addSubview:titleLabel];
      
      self.container.backgroundColor = [UIColor whiteColor];
      [self.container.layer setMasksToBounds:YES];
      [self.container.layer setBorderColor:[UIColor lightGrayColor].CGColor];
      [self.container.layer setBorderWidth:0.5];
      [self.container.layer setCornerRadius:15];
  }
  return self;
}
- (void)fillWithData:(ZYCustomeTwoCellData *)data;
{
  [super fillWithData:data];
  self.customData = data;
 [self.headImageView sd_setImageWithURL:nil placeholderImage:[UIImage imageNamed:TUIKitResource(@"default_c2c_head")] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
              
 }];
}
- (void)layoutSubviews
{
  [super layoutSubviews];
//  self.coverImageView.mm_top(0).mm_left(0).mm_flexToRight(0).mm_flexToBottom(70);
//  self.headImageView.mm_left(10).mm_bottom(10).mm_width(50).mm_height(50);
}

@end
