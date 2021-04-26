//
//  TContactsController.m
//  TUIKit
//
//  Created by annidyfeng on 2019/3/25.
//  Copyright © 2019年 Tencent. All rights reserved.
//

#import "TUIContactController.h"
#import "THeader.h"
#import "TUIKit.h"
#import "NSString+TUICommon.h"
#import "TUIFriendProfileControllerServiceProtocol.h"
#import "TCServiceManager.h"
#import "ReactiveObjC.h"
#import "MMLayout/UIView+MMLayout.h"
#import "TUIBlackListController.h"
#import "TUINewFriendViewController.h"
#import "TUIConversationListController.h"
#import "TUIChatController.h"
#import "TUIGroupConversationListController.h"
#import "TUIContactActionCell.h"
#import "UIColor+TUIDarkMode.h"
#import "NSBundle+TUIKIT.h"
@import SwiftUI;
@import ImSDK;

#define kContactCellReuseId @"ContactCellReuseId"
#define kContactActionCellReuseId @"ContactActionCellReuseId"

@interface TUIContactController () <UITableViewDelegate,UITableViewDataSource,TUIConversationListControllerDelegate,UISearchControllerDelegate,UISearchResultsUpdating>

@property (strong, nonatomic) UISearchController *mysearchController;

@property (strong, nonatomic) NSArray *searchArray;

@end

@implementation TUIContactController

#pragma mark - SearchTableView Helper Method
- (BOOL)enableForSearchTableView:(UITableView *)tableView {
    if (self.mysearchController.active) {
        return YES;
    }
    return NO;
}

-(void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    
    NSLog(@"updateSearchResultsForSearchController");
    NSString *searchText = [searchController.searchBar text];
    NSInteger count = self.viewModel.groupList.count;
    NSMutableArray *mulArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < count; i ++) {
        NSString *group = self.viewModel.groupList[i];
        NSArray *list = self.viewModel.dataDict[group];
        [mulArray addObjectsFromArray:list];
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title CONTAINS  %@", searchText];
    self.searchArray = [mulArray filteredArrayUsingPredicate:predicate];
    [self.tableView reloadData];
}

//根据颜色来绘制背景图片
- (UIImage *)imageWithColor:(UIColor *)color size:(CGSize)size
{
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    //[UIColor d_colorWithColorLight:TController_Background_Color dark:TController_Background_Color_Dark];
    _tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView setSectionIndexBackgroundColor:[UIColor clearColor]];
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, 8, 0);
    [_tableView setSectionIndexColor:[UIColor darkGrayColor]];
    [_tableView setBackgroundColor:self.view.backgroundColor];
    [self.view addSubview:_tableView];
    
    _mysearchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _mysearchController.automaticallyAdjustsScrollViewInsets = NO;
    self.searchDisplayController.searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _mysearchController.searchBar.returnKeyType = UIReturnKeyDone;
    _mysearchController.hidesNavigationBarDuringPresentation = NO;
    self.definesPresentationContext = YES;
    //设置代理
    _mysearchController.delegate = self;
    _mysearchController.searchResultsUpdater= self;
    _mysearchController.searchBar.placeholder = @"搜索用户";
    [_mysearchController.searchBar sizeToFit];
    _mysearchController.searchBar.backgroundImage = [self imageWithColor:[UIColor whiteColor] size:_mysearchController.searchBar.bounds.size];
    //搜索时，背景变暗色
    _mysearchController.dimsBackgroundDuringPresentation = NO;
    
    // 添加 searchbar 到 headerview
    self.tableView.tableHeaderView = _mysearchController.searchBar;
     
    //cell无数据时，不显示间隔线
    UIView *v = [[UIView alloc] initWithFrame:CGRectZero];
    [_tableView setTableFooterView:v];
    _tableView.separatorInset = UIEdgeInsetsMake(0, 58, 0, 0);
    [_tableView registerClass:[TCommonContactCell class] forCellReuseIdentifier:kContactCellReuseId];
    [_tableView registerClass:[TUIContactActionCell class] forCellReuseIdentifier:kContactActionCellReuseId];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFriendListChanged) name:TUIKitNotification_onFriendListAdded object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFriendListChanged) name:TUIKitNotification_onFriendListDeleted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFriendListChanged) name:TUIKitNotification_onFriendInfoUpdate object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFriendApplicationListChanged) name:TUIKitNotification_onFriendApplicationListAdded object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFriendApplicationListChanged) name:TUIKitNotification_onFriendApplicationListDeleted object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onFriendApplicationListChanged) name:TUIKitNotification_onFriendApplicationListRead object:nil];
    
    @weakify(self)
    [RACObserve(self.viewModel, isLoadFinished) subscribeNext:^(id finished) {
        @strongify(self)
        if ([(NSNumber *)finished boolValue]) {
            [self.tableView reloadData];
        }
    }];

    [_viewModel loadContacts];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationItem.title = @"新消息";
}

- (TContactViewModel *)viewModel
{
    if (_viewModel == nil) {
        _viewModel = [TContactViewModel new];
    }
    return _viewModel;
}


- (void)onFriendListChanged {
    [_viewModel loadContacts];
}

- (void)onFriendApplicationListChanged {
    [_viewModel loadFriendApplication];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;
{
    if ([self enableForSearchTableView:tableView]) {
        return 1;
    }
    return self.viewModel.groupList.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self enableForSearchTableView:tableView]) {
        return self.searchArray.count;
    }
    NSString *group = self.viewModel.groupList[section];
    NSArray *list = self.viewModel.dataDict[group];
    return list.count;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([self enableForSearchTableView:tableView]) {
        return  nil;
    } else{
        #define TEXT_TAG 1
        static NSString *headerViewId = @"ContactDrawerView";
        UITableViewHeaderFooterView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:headerViewId];
        if (!headerView)
        {
            headerView = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:headerViewId];
            headerView.backgroundColor = RGB(0xfa, 0xfa, 0xfa);
            UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            textLabel.tag = TEXT_TAG;
            textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
            textLabel.textColor = [UIColor blackColor];
            //RGB(0xe9, 0x48, 0x48);
            [headerView addSubview:textLabel];
            textLabel.mm_fill().mm_left(12);
            textLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        }
        UILabel *label = [headerView viewWithTag:TEXT_TAG];
        label.text = self.viewModel.groupList[section];
        return headerView;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 56;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([self enableForSearchTableView:tableView]) {
        return 0;
    }
    return 33;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    NSMutableArray *array = [NSMutableArray arrayWithObject:@""];
    [array addObjectsFromArray:self.viewModel.groupList];
    return array;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TCommonContactCell *cell = [tableView dequeueReusableCellWithIdentifier:kContactCellReuseId forIndexPath:indexPath];
    NSArray *list;
    if ([self enableForSearchTableView:tableView]) {
        TCommonContactCellData *data = self.searchArray[indexPath.row];
        data.cselector = @selector(onSelectFriend:);
        [cell fillWithData:data];
        return cell;
    } else{
        NSString *group = self.viewModel.groupList[indexPath.section];
        list = self.viewModel.dataDict[group];
        TCommonContactCellData *data = list[indexPath.row];
        data.cselector = @selector(onSelectFriend:);
        [cell fillWithData:data];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}

//封装原presentViewController:animated:completion:接口
- (void)presentViewController:(UIViewController *)viewControllerToPresent
                     animated:(BOOL)animated
                   completion:(void (^)(void))completion
                    pushStyle:(BOOL)isPushStyle {
    
    if (animated && isPushStyle) {
        viewControllerToPresent.transitioningDelegate = self;
        
        //添加自定义的返回手势
        UIScreenEdgePanGestureRecognizer *screenGesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self
                                                                                                            action:@selector(onPanGesture:)];
        screenGesture.delegate = self;
        screenGesture.edges = UIRectEdgeLeft;
        [viewControllerToPresent.view addGestureRecognizer:screenGesture];
        if ([viewControllerToPresent isKindOfClass:[UINavigationController class]]) {
            [screenGesture requireGestureRecognizerToFail:((UINavigationController*)viewControllerToPresent).interactivePopGestureRecognizer];
        }
    }
    
    [self presentViewController:viewControllerToPresent animated:animated completion:completion];
}


- (void)onSelectFriend:(TCommonContactCell *)cell
{
    TUIConversationCellData *data = [[TUIConversationCellData alloc] init];
    data.userID = cell.contactData.friendProfile.userID;
    self.selectedBlock(1, data,cell.contactData.friendProfile.userFullInfo.nickName);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.mysearchController.active = NO;
    });
/*
    TUIChatController *chat = [[TUIChatController alloc] initWithConversation:data];
    chat.title = cell.contactData.friendProfile.userFullInfo.nickName;
    chat.isFromUIKit = YES;
    [self.navigationController pushViewController:chat animated:YES];
 */
}

- (void)conversationListController:(TUIConversationListController *)conversationController didSelectConversation:(TUIConversationCell *)conversation;
{
/*
    TUIChatController *chat = [[TUIChatController alloc] initWithConversation:conversation.convData];
    chat.title = conversation.convData.title;
    [self.navigationController pushViewController:chat animated:YES];
 */
}


- (void)runSelector:(SEL)selector withObject:(id)object{
    if([self respondsToSelector:selector]){
        //因为 TCommonCell中写了 [vc performSelector:self.data.cselector withObject:self]，所以此处不管有无参数，和父类逻辑保持一致进行传参，防止意外情况
        IMP imp = [self methodForSelector:selector];
        void (*func)(id, SEL, id) = (void *)imp;
        func(self, selector, object);
    }

}

@end
