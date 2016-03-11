//
//  ViewController.m
//  ApplyPayTxet
//
//  Created by 李阳 on 16/3/9.
//  Copyright © 2016年 liyang. All rights reserved.
//

#import "ViewController.h"
#import "UPAPayPlugin.h"
#import <PassKit/PassKit.h>
//#import "AFNetworking.h"
#import "UPPaymentControl.h"

@interface ViewController ()
{
    NSMutableData *UPPresponseData;
    int whichBtn;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    PKPaymentButton *payBtn = [PKPaymentButton buttonWithType:PKPaymentButtonTypePlain style:PKPaymentButtonStyleBlack];
    payBtn.frame = CGRectMake((self.view.frame.size.width - 80) / 2, 120, 80, 40);
    [payBtn addTarget:self action:@selector(payBtnPress:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:payBtn];
    
    
    UIButton *UppayBtn = [[UIButton alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 80) / 2, 180, 80, 40)];
    [UppayBtn setTitle:@"银联支付" forState:UIControlStateNormal];
    UppayBtn.backgroundColor = [UIColor blackColor];
    [UppayBtn addTarget:self action:@selector(UppayBtnPress:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:UppayBtn];
    
}

- (void)payBtnPress:(id)sender{
    whichBtn = 0;
    [self urlConnStart];
}

- (void)UppayBtnPress:(UIButton *)sender{
    whichBtn = 1;
    [self urlConnStart];
}

- (void)urlConnStart{
    NSURL* url;
    switch (whichBtn) {
        case 0:
            url = [NSURL URLWithString:@"http://101.231.114.216:1725/sim/getacptn"];
            break;
        case 1:
            url = [NSURL URLWithString:@"http://101.231.204.84:8091/sim/getacptn"];
            break;
            
        default:
            break;
    }
    
    
    NSURLRequest * urlRequest = [NSURLRequest requestWithURL:url];
    NSURLConnection* urlConn = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self];
    [urlConn start];
}

#pragma mark - connection

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse*)response
{
    NSHTTPURLResponse* rsp = (NSHTTPURLResponse*)response;
    NSInteger code = [rsp statusCode];
    if (code != 200)
    {
        NSLog(@"网络错误!!!");
        [connection cancel];
    }
    else
    {
        
        UPPresponseData = [[NSMutableData alloc] init];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [UPPresponseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    
    NSString* tn = [[NSMutableString alloc] initWithData:UPPresponseData encoding:NSUTF8StringEncoding];
    if (tn != nil && tn.length > 0)
    {
        if (whichBtn == 0) {
            [UPAPayPlugin startPay:tn mode:@"00" viewController:self delegate:self andAPMechantID:@"merchant.com.example.aptext"];
        }else if(whichBtn == 1){
            [[UPPaymentControl defaultControl] startPay:tn fromScheme:@"ApplyPyTxet" mode:@"01" viewController:self];
        }
        
    }
    
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"网络错误");
}

#pragma mark -
#pragma mark 响应控件返回的支付结果
#pragma mark -
- (void)UPAPayPluginResult:(UPPayResult *)result
{
    if(result.paymentResultStatus == UPPaymentResultStatusSuccess) {
        NSString *otherInfo = result.otherInfo?result.otherInfo:@"";
        NSString *successInfo = [NSString stringWithFormat:@"支付成功\n%@",otherInfo];
        NSLog(@"%@",successInfo);
    }
    else if(result.paymentResultStatus == UPPaymentResultStatusCancel){
        
        NSLog(@"支付取消");
    }
    else if (result.paymentResultStatus == UPPaymentResultStatusFailure) {
        
        NSString *errorInfo = [NSString stringWithFormat:@"%@",result.errorDescription];
        NSLog(@"%@",errorInfo);
    }
    else if (result.paymentResultStatus == UPPaymentResultStatusUnknownCancel)  {
        
        //TODO UPPAymentResultStatusUnknowCancel表示发起支付以后用户取消，导致支付状态不确认，需要查询商户后台确认真实的支付结果
        NSString *errorInfo = [NSString stringWithFormat:@"支付过程中用户取消了，请查询后台确认订单"];
        NSLog(@"%@",errorInfo);
        
    }
}

@end
