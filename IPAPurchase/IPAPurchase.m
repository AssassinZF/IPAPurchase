//
//  IPAPurchase.m
//  iOS_Purchase
//
//  Created by zhanfeng on 2017/6/6.
//  Copyright © 2017年 zhanfeng. All rights reserved.
//

#import "IPAPurchase.h"
#import <StoreKit/StoreKit.h>
#import <StoreKit/SKPaymentTransaction.h>

@interface IPAPurchase()<SKPaymentTransactionObserver,SKProductsRequestDelegate>
{
    SKProductsRequest *request;

}
@end

@implementation IPAPurchase

+ (instancetype)manager
{
    static IPAPurchase *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!manager) {
            manager = [[IPAPurchase alloc] init];
        }
    });
    return manager;
}

-(void)buyProductWithProductID:(NSString *)productID payResult:(PayResult)payResult{
    self.payResultBlock = payResult;
    if (!productID.length) {
        NSLog(@"产品ID不能为空");
    }
    
    if ([SKPaymentQueue canMakePayments]) {
        
        [self requestProductInfo:productID];
        
    }else{
        NSLog(@"不支持购买");
    }
}

-(void)requestProductInfo:(NSString *)productID{
    
    NSSet *nsset = [NSSet setWithObject:productID];
    
    request=[[SKProductsRequest alloc] initWithProductIdentifiers:nsset];
    
    request.delegate=self;
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    
    [request start];
    
}

// 查询成功后的回调
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    NSLog(@"-----------收到产品反馈信息--------------");
    
    NSArray *myProduct = response.products;
    
    NSLog(@"无效产品Product ID:%@",response.invalidProductIdentifiers);
    
    // NSLog(@"产品付费数量: %lu", (unsigned long)[myProduct count]);
    if (myProduct.count==0) {
        NSLog(@"无法获取产品信息，购买失败");
        if (self.payResultBlock) {
            self.payResultBlock(NO, nil, @"无法获取产品信息，购买失败");
        }
        return;
    }
    for(SKProduct *product in myProduct){
        NSLog(@"SKProduct 描述信息%@", [product description]);
        NSLog(@"产品标题 %@" , product.localizedTitle);
        NSLog(@"产品描述信息: %@" , product.localizedDescription);
        NSLog(@"价格: %@" , product.price);
        NSLog(@"Product id: %@" , product.productIdentifier);
    }
    SKPayment *payment = nil;
    payment  = [SKPayment paymentWithProduct:myProduct.firstObject];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
    
}
//查询失败后的回调
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"请求苹果服务器失败%@",[error localizedDescription]);
    if (self.payResultBlock) {
        self.payResultBlock(NO, nil, [error localizedDescription]);
    }
    
}

//如果没有设置监听购买结果将直接跳至反馈结束；
-(void) requestDidFinish:(SKRequest *)request
{
    NSLog(@"您没有设置购买结果监听,结束了");
}

#pragma mark ------------------------- 监听结果

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    //当用户购买的操作有结果时，就会触发下面的回调函数，
    for (SKPaymentTransaction *transaction in transactions) {
        
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased://交易成功
            {
                [self completeTransaction:transaction];
                NSLog(@"结束订单了");
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                //验证成功与否,咱们都注销交易,否则会出现虚假凭证信息一直验证不通过..每次进程序都得输入苹果账号的情况
            }
                break;
                
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];//交易失败方法
                break;
                
            case SKPaymentTransactionStateRestored://已经购买过该商品
            {
                NSLog(@"已经购买过");
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            }
                break;
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"已经在商品列表中");
                break;
            case SKPaymentTransactionStateDeferred:
                NSLog(@"最终状态未确定 ");
                break;
            default:
                break;
        }
    }
}

//完成交易
- (void)completeTransaction:(SKPaymentTransaction *)transaction
{
    NSLog(@"购买成功验证订单");
    NSData *data = [NSData dataWithContentsOfFile:[[[NSBundle mainBundle] appStoreReceiptURL] path]];
    NSString *result = [data base64EncodedStringWithOptions:0];
    if (self.payResultBlock) {
        self.payResultBlock(YES, result, nil);
    }
    
}

//交易失败处理
- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    NSString *error = nil;
    if(transaction.error.code != SKErrorPaymentCancelled) {
        NSLog(@"购买失败");
        error = @"购买失败";
    } else {
        NSLog(@"用户取消交易");
        error = @"用户取消交易";
        
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    if (self.payResultBlock) {
        self.payResultBlock(NO, nil, error);
    }
}






@end
