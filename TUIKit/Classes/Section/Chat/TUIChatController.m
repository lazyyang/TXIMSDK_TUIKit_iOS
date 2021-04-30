//
//  TUIChatController.m
//  UIKit
//
//  Created by annidyfeng on 2019/5/21.
//

#import "TUIChatController.h"
#import "THeader.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import "ReactiveObjC/ReactiveObjC.h"
#import "MMLayout/UIView+MMLayout.h"
#import "TUIGroupPendencyViewModel.h"
#import "TUIMessageController.h"
#import "TUISelectMemberViewController.h"
#import "TUITextMessageCellData.h"
#import "TUIImageMessageCellData.h"
#import "TUIVideoMessageCellData.h"
#import "TUIFileMessageCellData.h"
#import "TUIGroupPendencyController.h"
#import "TUIFriendProfileControllerServiceProtocol.h"
#import "TUIUserProfileControllerServiceProtocol.h"
#import "TCServiceManager.h"
#import "Toast/Toast.h"
#import "THelper.h"
#import "UIColor+TUIDarkMode.h"
#import "TUICallManager.h"
#import "TUIKit.h"
#import "TUIGroupLiveMessageCell.h"
#import "NSBundle+TUIKIT.h"
#import <SDWebImage/SDWebImage.h>
#import "TTextEditController.h"
#import "ZYCustomOneCellData.h"
#import "ZYCustomOneTableViewCell.h"
#import "ZYCustomeTwoCellData.h"
#import "ZYCustomTwoTableViewCell.h"

@interface TUIChatController () <TMessageControllerDelegate, TInputControllerDelegate, UIImagePickerControllerDelegate, UIDocumentPickerDelegate, UINavigationControllerDelegate>
@property (nonatomic, strong) TUIConversationCellData *conversationData;
@property (nonatomic, strong) UIView *tipsView;
@property (nonatomic, strong) UILabel *pendencyLabel;
@property (nonatomic, strong) UIButton *pendencyBtn;
@property (nonatomic, strong) UIButton *atBtn;
@property (nonatomic, strong) TUIGroupPendencyViewModel *pendencyViewModel;
@property (nonatomic, strong) NSMutableArray<UserModel *> *atUserList;
@property (nonatomic, assign) BOOL responseKeyboard;
@end

@implementation TUIChatController

- (instancetype)initWithConversation:(TUIConversationCellData *)conversationData;
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _conversationData = conversationData;

        NSMutableArray *moreMenus = [NSMutableArray array];
        [moreMenus addObject:[TUIInputMoreCellData photoData]];
        [moreMenus addObject:[TUIInputMoreCellData pictureData]];
/*
        [moreMenus addObject:[TUIInputMoreCellData videoData]];
        [moreMenus addObject:[TUIInputMoreCellData fileData]];
        [moreMenus addObject:[TUIInputMoreCellData videoCallData]];
        [moreMenus addObject:[TUIInputMoreCellData audioCallData]];
        if ([TUIKit sharedInstance].config.enableGroupLiveEntry && conversationData.groupID.length > 0) {
            [moreMenus addObject:[TUIInputMoreCellData groupLivePalyData]];
        }
 */
        _moreMenus = moreMenus;

        if (self.conversationData.groupID.length > 0) {
            _pendencyViewModel = [TUIGroupPendencyViewModel new];
            _pendencyViewModel.groupId = _conversationData.groupID;
        }
        
        self.atUserList = [NSMutableArray array];
    }
    return self;
}

- (NSDictionary *)jsonData2Dictionary:(NSData *)jsonData
{
    if (jsonData == nil) {
        return nil;
    }
    NSError *err = nil;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if (err || ![dic isKindOfClass:[NSDictionary class]]) {
        NSLog(@"Json parse failed");
        return nil;
    }
    return dic;
}

// TChatController 回调函数
- (TUIMessageCellData *)chatController:(TUIChatController *)controller onNewMessage:(V2TIMMessage *)msg
{
  if (msg.elemType == V2TIM_ELEM_TYPE_CUSTOM) {
      NSDictionary *dic = [self jsonData2Dictionary:[msg customElem].data];
      if ([dic[@"type"] intValue] == 1) {//分享的作品
          ZYCustomOneCellData *cellData = [[ZYCustomOneCellData alloc] initWithDirection:msg.isSelf ? MsgDirectionOutgoing : MsgDirectionIncoming];
          cellData.cover = dic[@"cover"];
          cellData.head_url = dic[@"head_url"];
          cellData.nickName = dic[@"nickname"];
          cellData.bind_id = [NSString stringWithFormat:@"%@",dic[@"bind_id"]];
          cellData.avatarUrl = msg.faceURL;
          return cellData;
      } else if([dic[@"type"] intValue] == 2){//分享的名片
          ZYCustomeTwoCellData *cellData = [[ZYCustomeTwoCellData alloc] initWithDirection:msg.isSelf ? MsgDirectionOutgoing : MsgDirectionIncoming];
          cellData.avatarUrl = msg.faceURL;
          cellData.nickname = dic[@"nickname"];
          cellData.bind_id = dic[@"bind_id"];
          cellData.head_url = dic[@"head_url"];
          cellData.introduce = dic[@"introduce"];
          return cellData;
      }
  }
  return nil;
}
- (TUIMessageCell *)chatController:(TUIChatController *)controller onShowMessageData:(TUIMessageCellData *)data
{
  if ([data isKindOfClass:[ZYCustomOneCellData class]]) {
      ZYCustomOneTableViewCell *myCell = [[ZYCustomOneTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CustomOneCell"];
      [myCell fillWithData:(ZYCustomOneCellData *)data];
      return myCell;
  } else if ([data isKindOfClass:[ZYCustomeTwoCellData class]]){
      ZYCustomTwoTableViewCell *myCell = [[ZYCustomTwoTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CustomTwoCell"];
      [myCell fillWithData:(ZYCustomeTwoCellData *)data];
      return myCell;
  }
  return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupViews];
    @weakify(self)
    [[V2TIMManager sharedInstance] getFriendsInfo:@[_conversationData.userID] succ:^(NSArray<V2TIMFriendInfoResult *> *resultList) {
        V2TIMFriendInfoResult *result = resultList.firstObject;
        NSString *mute = [[NSString alloc] initWithData:result.friendInfo.friendCustomInfo[@"Mute"] encoding:NSUTF8StringEncoding];
        self.mute = mute;
        NSLog(@"mute = %@",mute);
    } fail:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.parentViewController.navigationItem.hidesBackButton = YES;
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightButton setImage:[UIImage imageNamed:TUIKitResource(@"right_item")] forState:UIControlStateNormal];
    [rightButton addTarget:self action:@selector(rightButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    self.parentViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    self.parentViewController.navigationItem.title = self.conversationData.title;
    
    
/*
    if(self.isFromUIKit == YES){
        self.navigationController.navigationItem.title = self.conversationData.title;
        UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [backButton setImage:[UIImage imageNamed:TUIKitResource(@"keyboard_arrow_left - material")] forState:UIControlStateNormal];
        [backButton setImage:[UIImage imageNamed:TUIKitResource(@"keyboard_arrow_left - material")] forState:UIControlStateHighlighted];
       [backButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
    } else{
        if (! @available(iOS 14.0, *)) {
            self.navigationItem.hidesBackButton = YES;
            UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [backButton setImage:[UIImage imageNamed:TUIKitResource(@"keyboard_arrow_left - material")] forState:UIControlStateNormal];
            [backButton setImage:[UIImage imageNamed:TUIKitResource(@"keyboard_arrow_left - material")] forState:UIControlStateHighlighted];
           [backButton addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
            self.navigationController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
        }
    }
 */
}

- (void)rightButtonClicked
{
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    
    UIAlertAction *editButton = [UIAlertAction actionWithTitle:@"修改备注名" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @weakify(self)
        self.selectedBlock(0,self.conversationData.userID);
    }];
    UIAlertAction *mainButton = [UIAlertAction actionWithTitle:@"主页" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @weakify(self)
        self.selectedBlock(1,self.conversationData.userID);
    }];
    UIAlertAction *muteButton;
    if ([self.mute isEqualToString:@"1"]) {//表示处于静音状态
        muteButton = [UIAlertAction actionWithTitle:@"取消静音" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @weakify(self)
            self.selectedBlock(7,self.conversationData.userID);
        }];
    } else{
        muteButton = [UIAlertAction actionWithTitle:@"静音" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @weakify(self)
            self.selectedBlock(2,self.conversationData.userID);
        }];
    }
    UIAlertAction *blackButton = [UIAlertAction actionWithTitle:@"黑名单" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"拉入黑名单同时会删除聊天记录" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @weakify(self)
            [[V2TIMManager sharedInstance] addToBlackList:@[self.conversationData.userID] succ:nil fail:nil];
            self.selectedBlock(3,self.conversationData.conversationID);
        }];
        [alertController addAction:okAction];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alertController addAction:cancelAction];
        [self presentViewController:alertController animated:YES completion:nil];
    }];
    UIAlertAction *reportButton = [UIAlertAction actionWithTitle:@"举报" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        @weakify(self)
        self.selectedBlock(4,self.conversationData.userID);
    }];
    UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

    }];
    [sheet addAction:editButton];
    [sheet addAction:mainButton];
    [sheet addAction:muteButton];
    [sheet addAction:blackButton];
    [sheet addAction:reportButton];
    [sheet addAction:cancelButton];
     
    [self presentViewController:sheet animated:YES completion:^{
         
    }];
}

- (void)back:(UIButton *)button
{
    self.selectedBlock(8, @"");
/*
    if (self.isFromUIKit == YES) {
        [self.navigationController popViewControllerAnimated:YES];
    } else{
        self.selectedBlock(8, @"");
    }
 */
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.responseKeyboard = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.responseKeyboard = NO;
    self.navigationController.navigationItem.rightBarButtonItem = nil;
}

- (void)willMoveToParentViewController:(UIViewController *)parent
{
    if (parent == nil) {
        [self saveDraft];
    }
}

- (void)setupViews
{
    self.view.backgroundColor = [UIColor whiteColor];
    //[UIColor d_colorWithColorLight:TController_Background_Color dark:TController_Background_Color_Dark];

    @weakify(self)
    //message
    _messageController = [[TUIMessageController alloc] init];
    _messageController.delegate = self;
    [self addChildViewController:_messageController];
    [self.view addSubview:_messageController.view];
    [_messageController setConversation:self.conversationData];
    _messageController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - TTextView_Height - Bottom_SafeHeight);

    //input
    _inputController = [[TUIInputController alloc] init];
    _inputController.view.frame = CGRectMake(0, self.view.frame.size.height - TTextView_Height - Bottom_SafeHeight, self.view.frame.size.width, TTextView_Height + Bottom_SafeHeight);
    _inputController.view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    _inputController.delegate = self;
    [RACObserve(self, moreMenus) subscribeNext:^(NSArray *x) {
        @strongify(self)
        [self.inputController.moreView setData:x];
    }];
    [self addChildViewController:_inputController];
    [self.view addSubview:_inputController.view];
//    _inputController.view.backgroundColor = [UIColor greenColor];
    _inputController.inputBar.inputTextView.text = self.conversationData.draftText;
    NSString *loginUser = [[V2TIMManager sharedInstance] getLoginUser];
    [[V2TIMManager sharedInstance] getUsersInfo:@[loginUser] succ:^(NSArray<V2TIMUserFullInfo *> *infoList) {
        V2TIMUserFullInfo *profile = infoList.firstObject;
        [self.inputController.inputBar.headImageView sd_setImageWithURL:[NSURL URLWithString:profile.faceURL] placeholderImage:[UIImage imageNamed:TUIKitResource(@"default_c2c_head")]];
    } fail:nil];
    self.tipsView = [[UIView alloc] initWithFrame:CGRectZero];
    self.tipsView.backgroundColor = RGB(246, 234, 190);
    [self.view addSubview:self.tipsView];
    self.tipsView.mm_height(24).mm_width(self.view.mm_w);

    self.pendencyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.tipsView addSubview:self.pendencyLabel];
    self.pendencyLabel.font = [UIFont systemFontOfSize:12];


    self.pendencyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.tipsView addSubview:self.pendencyBtn];
    [self.pendencyBtn setTitle:TUILocalizableString(TUIKitChatPendencyTitle) forState:UIControlStateNormal];
    [self.pendencyBtn.titleLabel setFont:[UIFont systemFontOfSize:12]];
    [self.pendencyBtn addTarget:self action:@selector(openPendency:) forControlEvents:UIControlEventTouchUpInside];
    [self.pendencyBtn sizeToFit];
    self.tipsView.hidden = YES;


    [RACObserve(self.pendencyViewModel, unReadCnt) subscribeNext:^(NSNumber *unReadCnt) {
        @strongify(self)
        if ([unReadCnt intValue]) {
            self.pendencyLabel.text = [NSString stringWithFormat:TUILocalizableString(TUIKitChatPendencyRequestToJoinGroupFormat), unReadCnt]; ; // @"%@条入群请求"
            [self.pendencyLabel sizeToFit];
            CGFloat gap = (self.tipsView.mm_w - self.pendencyLabel.mm_w - self.pendencyBtn.mm_w-8)/2;
            self.pendencyLabel.mm_left(gap).mm__centerY(self.tipsView.mm_h/2);
            self.pendencyBtn.mm_hstack(8);

            [UIView animateWithDuration:1.f animations:^{
                self.tipsView.hidden = NO;
                self.tipsView.mm_top(self.navigationController.navigationBar.mm_maxY);
            }];
        } else {
            self.tipsView.hidden = YES;
        }
    }];
    [self getPendencyList];
    
    //监听入群请求通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getPendencyList) name:TUIKitNotification_onReceiveJoinApplication object:nil];
    
    //群 @ ,UI 细节比较多，放在二期实现
//    if (self.conversationData.groupID.length > 0 && self.conversationData.atMsgSeqList.count > 0) {
//        self.atBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.mm_w - 100, 100, 100, 40)];
//        [self.atBtn setTitle:@"有人@我" forState:UIControlStateNormal];
//        [self.atBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
//        [self.atBtn setBackgroundColor:[UIColor whiteColor]];
//        [self.atBtn addTarget:self action:@selector(loadMessageToAT) forControlEvents:UIControlEventTouchUpInside];
//        [self.view addSubview:_atBtn];
//    }
}

- (void)getPendencyList
{
    if (self.conversationData.groupID.length > 0)
        [self.pendencyViewModel loadData];
}

- (void)openPendency:(id)sender
{
    TUIGroupPendencyController *vc = [[TUIGroupPendencyController alloc] init];
    vc.viewModel = self.pendencyViewModel;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)inputController:(TUIInputController *)inputController didChangeHeight:(CGFloat)height
{
    if (!self.responseKeyboard) {
        return;
    }
    __weak typeof(self) ws = self;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGRect msgFrame = ws.messageController.view.frame;
        msgFrame.size.height = ws.view.frame.size.height - height;
        ws.messageController.view.frame = msgFrame;

        CGRect inputFrame = ws.inputController.view.frame;
        inputFrame.origin.y = msgFrame.origin.y + msgFrame.size.height;
        inputFrame.size.height = height;
        ws.inputController.view.frame = inputFrame;
        [ws.messageController scrollToBottom:NO];
    } completion:nil];
}

- (void)inputController:(TUIInputController *)inputController didSendMessage:(TUIMessageCellData *)msg
{
    if ([msg isKindOfClass:[TUITextMessageCellData class]]) {
        NSMutableArray *userIDList = [NSMutableArray array];
        for (UserModel *model in self.atUserList) {
            [userIDList addObject:model.userId];
        }
        if (userIDList.count > 0) {
            [msg setAtUserList:userIDList];
        }
        //消息发送完后 atUserList 要重置
        [self.atUserList removeAllObjects];
    }
    [_messageController sendMessage:msg];
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatController:didSendMessage:)]) {
        [self.delegate chatController:self didSendMessage:msg];
    }
}

- (void)inputControllerDidInputAt:(TUIInputController *)inputController
{
    // 检测到 @ 字符的输入
    if (_conversationData.groupID.length > 0) {
        TUISelectMemberViewController *vc = [[TUISelectMemberViewController alloc] init];
        vc.groupId = _conversationData.groupID;
        vc.name = TUILocalizableString(TUIKitAtSelectMemberTitle); // @"选择群成员";
        vc.optionalStyle = TUISelectMemberOptionalStyleAtAll;
        vc.selectedFinished = ^(NSMutableArray<UserModel *> * _Nonnull modelList) {
            NSMutableString *atText = [[NSMutableString alloc] init];
            for (int i = 0; i < modelList.count; i++) {
                UserModel *model = modelList[i];
                [self.atUserList addObject:model];
                if (i == 0) {
                    [atText appendString:[NSString stringWithFormat:@"%@ ",model.name]];
                } else {
                    [atText appendString:[NSString stringWithFormat:@"@%@ ",model.name]];
                }
            }
            NSString *inputText = self.inputController.inputBar.inputTextView.text;
            self.inputController.inputBar.inputTextView.text = [NSString stringWithFormat:@"%@%@ ",inputText,atText];
            [self.inputController.inputBar updateTextViewFrame];
        };
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)inputController:(TUIInputController *)inputController didDeleteAt:(NSString *)atText
{
    // 删除了 @ 信息，atText 格式为：@xxx空格
    for (UserModel *user in self.atUserList) {
        if ([atText rangeOfString:user.name].location != NSNotFound) {
            [self.atUserList removeObject:user];
            break;
        }
    }
}

- (void)sendMessage:(TUIMessageCellData *)message
{
    [_messageController sendMessage:message];
}

- (void)sendMessageDict:(NSDictionary *)msgDict {
    NSString *className = msgDict[@"className"];
    Class cellDataClass = NSClassFromString(className);
    SEL selector = @selector(initWithDict:);
    if (cellDataClass && [cellDataClass instancesRespondToSelector:selector]) {
        TUIMessageCellData *msgData = [[cellDataClass alloc] initWithDict:msgDict];
        msgData.direction = MsgDirectionOutgoing;
        [self sendMessage:msgData];
    }
}

- (void)saveDraft
{
    NSString *draft = self.inputController.inputBar.inputTextView.text;
    draft = [draft stringByTrimmingCharactersInSet: NSCharacterSet.whitespaceAndNewlineCharacterSet];
    [[V2TIMManager sharedInstance] setConversationDraft:self.conversationData.conversationID draftText:draft succ:nil fail:nil];
}

- (void)inputController:(TUIInputController *)inputController didSelectMoreCell:(TUIInputMoreCell *)cell
{
    cell.disableDefaultSelectAction = NO;
    if(_delegate && [_delegate respondsToSelector:@selector(chatController:onSelectMoreCell:)]){
        [_delegate chatController:self onSelectMoreCell:cell];
    }
    if (cell.disableDefaultSelectAction) {
        return;
    }
    if (cell.data == [TUIInputMoreCellData photoData]) {
        [self selectPhotoForSend];
    }
    if (cell.data == [TUIInputMoreCellData videoData]) {
        [self takeVideoForSend];
    }
    if (cell.data == [TUIInputMoreCellData fileData]) {
        [self selectFileForSend];
    }
    if (cell.data == [TUIInputMoreCellData pictureData]) {
        [self takePictureForSend];
    }
    if (cell.data == [TUIInputMoreCellData videoCallData]) {
        [self videoCall];
    }
    if (cell.data == [TUIInputMoreCellData audioCallData]) {
        [self audioCall];
    }
    if (cell.data == [TUIInputMoreCellData groupLivePalyData]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kTUINotifyGroupLiveOnSelectMoreCell" object:nil userInfo:@{
            @"groupID":_conversationData.groupID?:@"",
            @"msgSender": self,
        }];
    }
}

- (void)didTapInMessageController:(TUIMessageController *)controller
{
    [_inputController reset];
}

- (BOOL)messageController:(TUIMessageController *)controller willShowMenuInCell:(TUIMessageCell *)cell
{
    if([_inputController.inputBar.inputTextView isFirstResponder]){
        _inputController.inputBar.inputTextView.overrideNextResponder = cell;
        return YES;
    }
    return NO;
}

- (TUIMessageCellData *)messageController:(TUIMessageController *)controller onNewMessage:(V2TIMMessage *)data
{
//    if ([self.delegate respondsToSelector:@selector(chatController:onNewMessage:)]) {
        return [self chatController:self onNewMessage:data];
//    }
//    return nil;
}

- (TUIMessageCell *)messageController:(TUIMessageController *)controller onShowMessageData:(TUIMessageCellData *)data
{
//    if ([self.delegate respondsToSelector:@selector(chatController:onShowMessageData:)]) {
        return [self chatController:self onShowMessageData:data];
//    }
//    return nil;
}

- (void)messageController:(TUIMessageController *)controller onSelectMessageAvatar:(TUIMessageCell *)cell
{
    if (cell.messageData.identifier == nil)
        return;

    if ([self.delegate respondsToSelector:@selector(chatController:onSelectMessageAvatar:)]) {
        [self.delegate chatController:self onSelectMessageAvatar:cell];
        return;
    }

    @weakify(self)
    [[V2TIMManager sharedInstance] getFriendsInfo:@[cell.messageData.identifier] succ:^(NSArray<V2TIMFriendInfoResult *> *resultList) {
        V2TIMFriendInfoResult *result = resultList.firstObject;
        if (result.relation == V2TIM_FRIEND_RELATION_TYPE_IN_MY_FRIEND_LIST || result.relation == V2TIM_FRIEND_RELATION_TYPE_BOTH_WAY) {
            @strongify(self)
            id<TUIFriendProfileControllerServiceProtocol> vc = [[TCServiceManager shareInstance] createService:@protocol(TUIFriendProfileControllerServiceProtocol)];
            if ([vc isKindOfClass:[UIViewController class]]) {
                vc.friendProfile = result.friendInfo;
                [self.navigationController pushViewController:(UIViewController *)vc animated:YES];
            }
        } else {
            [[V2TIMManager sharedInstance] getUsersInfo:@[cell.messageData.identifier] succ:^(NSArray<V2TIMUserFullInfo *> *infoList) {
                @strongify(self)
                id<TUIUserProfileControllerServiceProtocol> vc = [[TCServiceManager shareInstance] createService:@protocol(TUIUserProfileControllerServiceProtocol)];
                if ([vc isKindOfClass:[UIViewController class]]) {
                    vc.userFullInfo = infoList.firstObject;
                    if ([vc.userFullInfo.userID isEqualToString:[[V2TIMManager sharedInstance] getLoginUser]]) {
                        vc.actionType = PCA_NONE;
                    } else {
                        vc.actionType = PCA_ADD_FRIEND;
                    }
                    [self.navigationController pushViewController:(UIViewController *)vc animated:YES];
                }
            } fail:^(int code, NSString *msg) {
                [THelper makeToastError:code msg:msg];
            }];
        }
    } fail:^(int code, NSString *msg) {
        [THelper makeToastError:code msg:msg];
    }];
}

- (void)messageController:(TUIMessageController *)controller onSelectMessageContent:(TUIMessageCell *)cell
{
    cell.disableDefaultSelectAction = NO;
    if ([self.delegate respondsToSelector:@selector(chatController:onSelectMessageContent:)]) {
        [self.delegate chatController:self onSelectMessageContent:cell];
    }
    if (cell.disableDefaultSelectAction) {
        return;
    }
    if ([cell isKindOfClass:[TUIGroupLiveMessageCell class]]) {
        TUIGroupLiveMessageCellData *celldata = [(TUIGroupLiveMessageCell *)cell customData];
        NSDictionary *roomInfo = celldata.roomInfo;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kTUINotifyGroupLiveOnSelectMessage" object:nil userInfo:@{
            @"roomInfo": roomInfo,
            @"groupID": _conversationData.groupID?:@"",
            @"msgSender": self,
        }];
    } else if ([cell isKindOfClass:[ZYCustomOneTableViewCell class]]){ //作品
        ZYCustomOneCellData *data = [(TUIGroupLiveMessageCell *)cell customData];
        
        self.selectedBlock(5, data.bind_id);
    } else if ([cell isKindOfClass:[ZYCustomTwoTableViewCell class]]){ //名片
        self.selectedBlock(6, nil);
    }
}

- (void)didHideMenuInMessageController:(TUIMessageController *)controller
{
    _inputController.inputBar.inputTextView.overrideNextResponder = nil;
}

// ----------------------------------
- (void)selectPhotoForSend
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)takePictureForSend
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)takeVideoForSend
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
        picker.cameraCaptureMode =UIImagePickerControllerCameraCaptureModeVideo;
        picker.videoQuality = UIImagePickerControllerQualityTypeMedium;
        [picker setVideoMaximumDuration:15];
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)selectFileForSend
{
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[(NSString *)kUTTypeData] inMode:UIDocumentPickerModeOpen];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];

}

- (void)videoCall
{
    if (![[TUICallManager shareInstance] checkAudioAuthorization] || ![[TUICallManager shareInstance] checkVideoAuthorization]) {
        [THelper makeToast:TUILocalizableString(TUIKitMicCamerAuthTips)];
        return;
    }
    
    [[TUICallManager shareInstance] call:self.conversationData.groupID userID:self.conversationData.userID callType:CallType_Video];
}

- (void)audioCall
{
    if (![[TUICallManager shareInstance] checkAudioAuthorization]) {
        [THelper makeToast:TUILocalizableString(TUIKitMicAuth)];
        return;
    }
    [[TUICallManager shareInstance] call:self.conversationData.groupID userID:self.conversationData.userID callType:CallType_Audio];
}

#pragma mark -
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    // 快速点的时候会回调多次
    @weakify(self)
    picker.delegate = nil;
    [picker dismissViewControllerAnimated:YES completion:^{
        @strongify(self)
        NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
        if([mediaType isEqualToString:(NSString *)kUTTypeImage]){
            UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
            UIImageOrientation imageOrientation = image.imageOrientation;
            if(imageOrientation != UIImageOrientationUp)
            {
                CGFloat aspectRatio = MIN ( 1920 / image.size.width, 1920 / image.size.height );
                CGFloat aspectWidth = image.size.width * aspectRatio;
                CGFloat aspectHeight = image.size.height * aspectRatio;

                UIGraphicsBeginImageContext(CGSizeMake(aspectWidth, aspectHeight));
                [image drawInRect:CGRectMake(0, 0, aspectWidth, aspectHeight)];
                image = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }

            NSData *data = UIImageJPEGRepresentation(image, 0.75);
            NSString *path = [TUIKit_Image_Path stringByAppendingString:[THelper genImageName:nil]];
            [[NSFileManager defaultManager] createFileAtPath:path contents:data attributes:nil];
            
            TUIImageMessageCellData *uiImage = [[TUIImageMessageCellData alloc] initWithDirection:MsgDirectionOutgoing];
            uiImage.path = path;
            uiImage.length = data.length;
            [self sendMessage:uiImage];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(chatController:didSendMessage:)]) {
                [self.delegate chatController:self didSendMessage:uiImage];
            }
        }
        else if([mediaType isEqualToString:(NSString *)kUTTypeMovie]){
            NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
            
            if(![url.pathExtension  isEqual: @"mp4"]) {
                NSString* tempPath = NSTemporaryDirectory();
                NSURL *urlName = [url URLByDeletingPathExtension];
                NSURL *newUrl = [NSURL URLWithString:[NSString stringWithFormat:@"file://%@%@.mp4", tempPath,[urlName.lastPathComponent stringByRemovingPercentEncoding]]];
                // mov to mp4
                AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:url options:nil];
                AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]initWithAsset:avAsset presetName:AVAssetExportPresetHighestQuality];
                 exportSession.outputURL = newUrl;
                 exportSession.outputFileType = AVFileTypeMPEG4;
                 exportSession.shouldOptimizeForNetworkUse = YES;

                 [exportSession exportAsynchronouslyWithCompletionHandler:^{
                 switch ([exportSession status])
                 {
                      case AVAssetExportSessionStatusFailed:
                           NSLog(@"Export session failed");
                           break;
                      case AVAssetExportSessionStatusCancelled:
                           NSLog(@"Export canceled");
                           break;
                      case AVAssetExportSessionStatusCompleted:
                      {
                           //Video conversion finished
                           NSLog(@"Successful!");
                          dispatch_async(dispatch_get_main_queue(), ^{
                              [self sendVideoWithUrl:newUrl];
                          });
                      }
                           break;
                      default:
                           break;
                  }
                 }];
            } else {
                [self sendVideoWithUrl:url];
            }
        }
    }];
}

- (void)sendVideoWithUrl:(NSURL*)url {
    NSData *videoData = [NSData dataWithContentsOfURL:url];
    NSString *videoPath = [NSString stringWithFormat:@"%@%@.mp4", TUIKit_Video_Path, [THelper genVideoName:nil]];
    [[NSFileManager defaultManager] createFileAtPath:videoPath contents:videoData attributes:nil];
    
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset =  [AVURLAsset URLAssetWithURL:url options:opts];
    NSInteger duration = (NSInteger)urlAsset.duration.value / urlAsset.duration.timescale;
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:urlAsset];
    gen.appliesPreferredTrackTransform = YES;
    gen.maximumSize = CGSizeMake(192, 192);
    NSError *error = nil;
    CMTime actualTime;
    CMTime time = CMTimeMakeWithSeconds(0.0, 10);
    CGImageRef imageRef = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *image = [[UIImage alloc] initWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    NSData *imageData = UIImagePNGRepresentation(image);
    NSString *imagePath = [TUIKit_Video_Path stringByAppendingString:[THelper genSnapshotName:nil]];
    [[NSFileManager defaultManager] createFileAtPath:imagePath contents:imageData attributes:nil];
    
    TUIVideoMessageCellData *uiVideo = [[TUIVideoMessageCellData alloc] initWithDirection:MsgDirectionOutgoing];
    uiVideo.snapshotPath = imagePath;
    uiVideo.snapshotItem = [[TUISnapshotItem alloc] init];
    UIImage *snapshot = [UIImage imageWithContentsOfFile:imagePath];
    uiVideo.snapshotItem.size = snapshot.size;
    uiVideo.snapshotItem.length = imageData.length;
    uiVideo.videoPath = videoPath;
    uiVideo.videoItem = [[TUIVideoItem alloc] init];
    uiVideo.videoItem.duration = duration;
    uiVideo.videoItem.length = videoData.length;
    uiVideo.videoItem.type = url.pathExtension;
    uiVideo.uploadProgress = 0;
    [self sendMessage:uiVideo];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(chatController:didSendMessage:)]) {
        [self.delegate chatController:self didSendMessage:uiVideo];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url
{
    [url startAccessingSecurityScopedResource];
    NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] init];
    NSError *error;
    @weakify(self)
    [coordinator coordinateReadingItemAtURL:url options:0 error:&error byAccessor:^(NSURL *newURL) {
        @strongify(self)
        NSData *fileData = [NSData dataWithContentsOfURL:url];
        NSString *fileName = [url lastPathComponent];
        NSString *filePath = [TUIKit_File_Path stringByAppendingString:fileName];
        [[NSFileManager defaultManager] createFileAtPath:filePath contents:fileData attributes:nil];
        if([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
            long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
            TUIFileMessageCellData *uiFile = [[TUIFileMessageCellData alloc] initWithDirection:MsgDirectionOutgoing];
            uiFile.path = filePath;
            uiFile.fileName = fileName;
            uiFile.length = (int)fileSize;
            uiFile.uploadProgress = 0;
            [self sendMessage:uiFile];
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(chatController:didSendMessage:)]) {
                [self.delegate chatController:self didSendMessage:uiFile];
            }
        }
    }];
    [url stopAccessingSecurityScopedResource];
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}
@end
