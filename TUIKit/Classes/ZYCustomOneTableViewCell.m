//
//  ZYCustomOneTableViewCell.m
//  TXIMSDK_TUIKit_iOS
//
//  Created by Lazy on 2021/3/28.
//

#import "ZYCustomOneTableViewCell.h"
#import "ReactiveObjC/ReactiveObjC.h"
#import "MMLayout/UIView+MMLayout.h"
#import "UIColor+TUIDarkMode.h"
#import "THeader.h"
#import <SDWebImage/SDWebImage.h>

@implementation ZYCustomOneTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self) {
//      _myTextLabel = [[UILabel alloc] init];
//      _myTextLabel.numberOfLines = 0;
//      _myTextLabel.font = [UIFont systemFontOfSize:15];
//      [self.container addSubview:_myTextLabel];
//
//      _myLinkLabel = [[UILabel alloc] initWithFrame:CGRectZero];
//      _myLinkLabel.text = @"查看详情>>";
//      _myLinkLabel.font = [UIFont systemFontOfSize:15];
//      _myLinkLabel.textColor = [UIColor blueColor];
//      [self.container addSubview:_myLinkLabel];
      
      _coverImageView = [[UIImageView alloc] init];
      _coverImageView.backgroundColor = [UIColor clearColor];
      _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
      _coverImageView.clipsToBounds = YES;
      [self.container addSubview:_coverImageView];
//      [_coverImageView sd_setImageWithURL:[NSURL URLWithString:@"https://file.gy1826.com/file/1"]];
      
      _headImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 680.0f/2-70 + 10, 50, 50)];
//      _headImageView.backgroundColor = [UIColor redColor];
      _headImageView.layer.cornerRadius = 25.0f;
      _headImageView.clipsToBounds = YES;
      [self.container addSubview:_headImageView];
      
      _nickLabel = [[UILabel alloc] initWithFrame:CGRectMake(70, 680.0f/2-60, 540.0f/2-80,50 )];
//      _nickLabel.text = @"爱因斯坦（个人昵称）";
      _nickLabel.font = [UIFont boldSystemFontOfSize:16.0f];
      _nickLabel.textColor = [UIColor blackColor];
//      _nickLabel.backgroundColor = [UIColor greenColor];
      [self.container addSubview:_nickLabel];
      
      
      self.container.backgroundColor = [UIColor whiteColor];
      [self.container.layer setMasksToBounds:YES];
      [self.container.layer setBorderColor:[UIColor lightGrayColor].CGColor];
      [self.container.layer setBorderWidth:0.5];
      [self.container.layer setCornerRadius:15];
  }
  return self;
}
- (void)fillWithData:(ZYCustomOneCellData *)data;
{
  [super fillWithData:data];
  self.customData = data;
  [self.coverImageView sd_setImageWithURL:[NSURL URLWithString:data.cover]];
  [self.headImageView sd_setImageWithURL:[NSURL URLWithString:data.head_url] placeholderImage:[UIImage imageNamed:TUIKitResource(@"default_c2c_head")] completed:^(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
            
  }];
  self.nickLabel.text = [NSString stringWithFormat:@"%@（个人昵称）",data.nickName];
}
- (void)layoutSubviews
{
  [super layoutSubviews];
  self.coverImageView.mm_top(0).mm_left(0).mm_flexToRight(0).mm_flexToBottom(70);
  self.headImageView.mm_left(10).mm_bottom(10).mm_width(50).mm_height(50);
}

@end
