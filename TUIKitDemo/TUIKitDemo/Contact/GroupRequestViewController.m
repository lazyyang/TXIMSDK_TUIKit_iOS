//
//  GroupRequestViewController.m
//  TUIKitDemo
//
//  Created by annidyfeng on 2019/5/20.
//  Copyright © 2019年 Tencent. All rights reserved.
//
/** 腾讯云IM Demon群组加入页面，在用户想要加入群组时提供UI
 *
 * 本文件实现了加入群组时的视图，使得使用者能够对只能群组发送申请加入的请求
 *
 * 本类依赖于腾讯云 TUIKit和IMSDK 实现
 */
#import "GroupRequestViewController.h"
#import "TIMUserProfile+DataProvider.h"
#import "Toast/Toast.h"
#import <ReactiveObjC.h>
#import "MMLayout/UIView+MMLayout.h"
#import "TIMUserProfile+DataProvider.h"
#import "TUIProfileCardCell.h"
#import "THeader.h"
#import "UIImage+TUIKIT.h"
#import "TUIKit.h"
#import "THelper.h"
#import "TCUtil.h"
#import "TUIAvatarViewController.h"

@interface GroupRequestViewController ()<UITableViewDataSource, UITableViewDelegate>
@property UITableView *tableView;
@property UITextView  *addMsgTextView;
@property TUIProfileCardCellData *cardCellData;
@end

@implementation GroupRequestViewController

- (void)viewDidLoad {
    //初始化视图内容信息
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    [self.view addSubview:self.tableView];
    self.tableView.mm_fill();
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    self.addMsgTextView = [[UITextView alloc] initWithFrame:CGRectZero];
    self.addMsgTextView.font = [UIFont systemFontOfSize:14];
    NSString *loginUser = [[V2TIMManager sharedInstance] getLoginUser];
    [[V2TIMManager sharedInstance] getUsersInfo:@[loginUser] succ:^(NSArray<V2TIMUserFullInfo *> *infoList) {
        self.addMsgTextView.text = [NSString stringWithFormat:NSLocalizedString(@"GroupRequestJoinGroupFormat", nil), [[infoList firstObject] showName]]; // "%@ 申请加入群聊
    } fail:^(int code, NSString *msg) {
    }];
    TUIProfileCardCellData *data = [TUIProfileCardCellData new];
    data.name = self.groupInfo.groupName;
    data.identifier = self.groupInfo.groupID;
    data.avatarImage = DefaultGroupAvatarImage;
    data.avatarUrl = [NSURL URLWithString:self.groupInfo.faceURL];
    self.cardCellData = data;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Send", nil) style:UIBarButtonItemStylePlain target:self action:@selector(onSend)];
    self.title = NSLocalizedString(@"GroupJoin", nil);
}

/**
 *tableView委托函数
 */
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.section == 0) {
        return [self.cardCellData heightOfWidth:Screen_Width];
    }
    if (indexPath.section == 1) {
        return 120;
    }
    if (indexPath.section == 2) {
        return 44;
    }
    return 0.;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
    return 2;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 1)
        return NSLocalizedString(@"please_fill_in_verification_information", nil); // @"填写验证信息";
    return nil;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        TUIProfileCardCell *cell = [[TUIProfileCardCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"TPersonalCommonCell_ReuseId"];
        //设置 profileCard 的委托
        cell.delegate = self;
        [cell fillWithData:self.cardCellData];
        return cell;
    }
    if (indexPath.section == 1) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AddWord"];
        [cell.contentView addSubview:self.addMsgTextView];
        self.addMsgTextView.mm_width(Screen_Width).mm_height(120);
        return cell;
    }

    return nil;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

/**
 *点击 发送 按钮后执行的函数，包括信息收集和请求回调
 */
- (void)onSend
{
    // display toast with an activity spinner
    [self.view makeToastActivity:CSToastPositionCenter];
    [[V2TIMManager sharedInstance] joinGroup:self.groupInfo.groupID msg:self.addMsgTextView.text succ:^{
        [self.view hideToastActivity];
        [self.view makeToast:NSLocalizedString(@"send_success", nil)
                    duration:3.0
                    position:CSToastPositionBottom];
    } fail:^(int code, NSString *desc) {
        [self.view hideToastActivity];
        [THelper makeToastError:code msg:desc];
    }];
    [TCUtil report:Action_Addgroup actionSub:@"" code:@(0) msg:@"addgroup"];
}

/**
 *  点击头像查看大图的委托实现
 */
-(void)didTapOnAvatar:(TUIProfileCardCell *)cell{
    TUIAvatarViewController *image = [[TUIAvatarViewController alloc] init];
    image.avatarData = cell.cardData;
    [self.navigationController pushViewController:image animated:YES];
}

@end
