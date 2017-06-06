//
//  IPAPurchase.h
//  iOS_Purchase
//
//  Created by zhanfeng on 2017/6/6.
//  Copyright © 2017年 zhanfeng. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 block

 @param isSuccess 是否支付成功
 @param certificate 支付成功得到的凭证（用于在自己服务器验证）
 @param errorMsg 错误信息
 */
typedef void(^PayResult)(BOOL isSuccess,NSString *certificate,NSString *errorMsg);

@interface IPAPurchase : NSObject
@property (nonatomic, copy)PayResult payResultBlock;

/**
 内购支付

 @param productID 内购商品ID
 @param payResult 结果
 */
-(void)buyProductWithProductID:(NSString *)productID payResult:(PayResult)payResult;

@end
