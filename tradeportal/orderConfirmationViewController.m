//
//  orderConfirmationViewController.m
//  tradeportal
//
//  Created by Nagarajan Sathish on 20/10/14.
//
//

#import "orderConfirmationViewController.h"
#import "orderEntryViewController.h"
#import "DataModel.h"
#import "OrderBookViewController.h"
#import "OrderEntryModel.h"

@interface orderConfirmationViewController ()

@property (strong, nonatomic) NSURLConnection *conn;
@property (strong, nonatomic) NSMutableData *buffer;
@property (strong, nonatomic) NSXMLParser *parser;
@property (strong, nonatomic) NSString *parseURL;
@property(strong,nonatomic)NSString *dataFound;
@property(nonatomic)CGFloat amt;
@end

@implementation orderConfirmationViewController

@synthesize conn,parser,buffer,parseURL,orderEntry,orderPrice,clientAccount,shortName,stockCode,qty,totalAmount,currency,type,routeDest,orderPriceValue,clientAccountValue,shortNameValue,stockCodeValue,qtyValue,totalAmountValue,currencyValue,typeValue,routeDestValue,side,exchange,orderType,exchangeRate,timeInForce,currencyCode,spinner,amt,cells;

DataModel *dm;
OrderEntryModel *em;
NSString *userID;

#pragma mark - View Delegates

- (void)viewDidLoad {
    [super viewDidLoad];
    userID = dm.userID;
    clientAccount.text = clientAccountValue;
    stockCode.text = stockCodeValue;
    shortName.text = shortNameValue;
    qty.text = qtyValue;
    orderPrice.text = orderPriceValue;
    currency.text = currencyValue;
    type.text = typeValue;
    routeDest.text = routeDestValue;
    orderType=@"2";
    timeInForce=@"0";
    currencyCode=@"SGD";
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldShouldReturn:) name:UIKeyboardWillHideNotification object:nil];
    amt = [orderPriceValue floatValue]*[[qtyValue stringByReplacingOccurrencesOfString:@"," withString:@""] integerValue];
    NSNumberFormatter *fmt = [[NSNumberFormatter alloc]init];
    [fmt setMaximumFractionDigits:2];
    [fmt setMinimumIntegerDigits:1];
    [fmt setMinimumFractionDigits:2];
    totalAmount.text = [fmt stringFromNumber:[NSNumber numberWithFloat:amt]];
    if ([typeValue isEqualToString:@"BUY"]) {
        type.textColor = iGREEN;
    }else if ([typeValue isEqualToString:@"SELL"]){
        type.textColor = iRED;
    }
    self.password.delegate = self;
}


- (void) viewWillAppear:(BOOL)animated{
    if (em.flag) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - TextField Delegates

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.35f];
    CGRect frame = self.view.frame;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        frame.origin.y = -100;
    }
    else{
        frame.origin.y = -250;
    }
    [self.view setFrame:frame];
    [UIView commitAnimations];
    return YES;
}


-(BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    [self hideKeyboard:textField];
    return YES;
}

-(IBAction)hideKeyboard:(id)sender{
    [ UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.35f];
    CGRect frame = self.view.frame;
    frame.origin.y = 0;
    [self.view setFrame:frame];
    [UIView commitAnimations];
    [self.view endEditing:YES];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self.view endEditing:YES];
    return YES;
}




#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 9;
}

#pragma mark - Invoke Confirm Order Service

- (IBAction)confirmPassword:(id)sender {
    [self.view endEditing:YES];
    NSString *password = self.password.text;
    if(password == nil){
        UIAlertView *toast = [[UIAlertView alloc]initWithTitle:nil message:@"Please enter user password!" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
        [toast show];
        int duration = 1.5;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [toast dismissWithClickedButtonIndex:0 animated:YES];
        });
        
    }
    else{
        NSString *soapRequest = [NSString stringWithFormat:
                                 @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
                                 "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"
                                 "<soap:Body>"
                                 "<CheckUserPwd xmlns=\"http://OMS/\">"
                                 "<strUserID>%@</strUserID>"
                                 "<strPwd>%@</strPwd>"
                                 "</CheckUserPwd>"
                                 "</soap:Body>"
                                 "</soap:Envelope>",userID,password];
        //        NSLog(@"SoapRequest is %@" , soapRequest);
        NSString *urls = [NSString stringWithFormat:@"%@%s",dm.serviceURL,"op=CheckUserPwd"];
        NSURL *url =[NSURL URLWithString:urls];
        
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
        [req addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
        [req addValue:@"http://OMS/CheckUserPwd" forHTTPHeaderField:@"SOAPAction"];
        NSString *msgLength = [NSString stringWithFormat:@"%lu", (unsigned long)[soapRequest length]];
        [req addValue:msgLength forHTTPHeaderField:@"Content-Length"];
        [req setHTTPMethod:@"POST"];
        [req setHTTPBody:[soapRequest dataUsingEncoding:NSUTF8StringEncoding]];
        
        
        conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
        spinner.hidesWhenStopped=YES;
        [spinner startAnimating];
        
        if (conn) {
            buffer = [NSMutableData data];
        }
    }
}

#pragma mark - Cancel Order

- (IBAction)cancelOrder:(id)sender {
    [orderEntry reloadData];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Connection Delegates

-(void) connection:(NSURLConnection *) connection didReceiveResponse:(NSURLResponse *) response {
    [buffer setLength:0];
}
-(void) connection:(NSURLConnection *) connection didReceiveData:(NSData *) data {
    [buffer appendData:data];
}
-(void) connection:(NSURLConnection *) connection didFailWithError:(NSError *) error {
    UIAlertView *toast = [[UIAlertView alloc]initWithTitle:nil message:@"Connection Error..." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
    [toast show];
    int duration = 1.5;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [toast dismissWithClickedButtonIndex:0 animated:YES];
    });
}

-(void) connectionDidFinishLoading:(NSURLConnection *) connection {
    NSMutableString *theXML =
    [[NSMutableString alloc] initWithBytes:[buffer mutableBytes]
                                    length:[buffer length]
                                  encoding:NSUTF8StringEncoding];
    [theXML replaceOccurrencesOfString:@"&lt;"
                            withString:@"<" options:0
                                 range:NSMakeRange(0, [theXML length])];
    [theXML replaceOccurrencesOfString:@"&gt;"
                            withString:@">" options:0
                                 range:NSMakeRange(0, [theXML length])];
//    NSLog(@"\n\nSoap Response is %@",theXML);
    [buffer setData:[theXML dataUsingEncoding:NSUTF8StringEncoding]];
    self.parser =[[NSXMLParser alloc]initWithData:buffer];
    [parser setDelegate:self];
    [parser parse];
    
}


#pragma mark - XML Parser

-(void) parser:(NSXMLParser *) parser didStartElement:(NSString *) elementName
  namespaceURI:(NSString *) namespaceURI qualifiedName:(NSString *) qName attributes:(NSDictionary *) attributeDict {
    
    if ([elementName isEqualToString:@"z:row"]) {
        NSInteger result = [[attributeDict objectForKey:@"RESULT"] integerValue];
        if (result == 1) {
            //success
            [self newOrder];
        }else if (result == -1){
            //Exception occurs while checking password
        }
        else if(result== 0){
            //Invalid password
        }
        else{
            //NSLog(@"default error msg");
        }
    }
    if ([elementName isEqualToString:@"CheckUserPwdResult"]) {
        _dataFound = @"checkUser";
    }
    if ([elementName isEqualToString:@"NewOrderFixIncomeResult"]) {
        _dataFound = @"newOrder";
    }
}

- (void) parser:(NSXMLParser *) parser foundCharacters:(NSString *) string {
    NSString *msg=@"";
    if([_dataFound isEqualToString:@"newOrder"]){
        
        if ([string isEqualToString:@"S"]) {
            msg = @"Order Successfully Made!";
            [[self navigationController]popViewControllerAnimated:YES];
            [orderEntry reloadData];
            orderEntry.flag = true;
            
        }
        else{
            if([[string substringToIndex:1] isEqualToString:@"E"]){
                msg = @"User has logged on elsewhere!";
                [self dismissViewControllerAnimated:YES completion:nil];
                [[self navigationController]popToRootViewControllerAnimated:YES];
            }
            else{
                msg = string;
            }
        }
        _dataFound=@"";
    }
    if ([_dataFound isEqualToString:@"checkUser"]) {
        if ([[string substringToIndex:1] isEqualToString:@"R"]) {
            msg = @"Incorrect Password. \n Try again...";
        }
        else if ([[string substringToIndex:1] isEqualToString:@"E"]) {
            msg = @"Some Technical Error. \n Please Try again...";
        }
    }
    if (![msg isEqualToString:@""]) {
        [spinner stopAnimating];
        UIAlertView *toast = [[UIAlertView alloc]initWithTitle:nil message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
        [toast show];
        int duration = 1.5;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [toast dismissWithClickedButtonIndex:0 animated:YES];
        });
    }
}

#pragma mark - Invoke New Order Service

-(void)newOrder{
    qtyValue = [qtyValue stringByReplacingOccurrencesOfString:@"," withString:@""];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSString *currentdate = [dateFormatter stringFromDate:[NSDate date]];
    NSString *data = [NSString stringWithFormat:@"AlgoStartTime=~Exchange=%@~FI_PriceCode=7~ExchangeRate=1~AlPercent=~OrderSize=%@~VoiceLog=~UpdateBy=%@~SecCode=%@~ClientAccID=%@~SpecialInstruction=~FI_NumberAgent=5~ExtraCare=0~AlgoWouldQty=~FI_TaxPercent=2~BuySell=%@~Yield=0~ForceOrderStatus=%@~AlgoEndTime=~SecurityType=STOCK~OrderType=%@~FI_TaxType=CHAR~AltSymbol=~StockLocation=~TimeInForce=%@~NumberOfDaysAccuredInterest=1~OrderPrice=%@~SettCurr=%@~FI_TotalNetCashAmount=4~FI_TaxAmount=3~FI_TotalAccuredInterst=8~TradeCurrency=%@~tradeOfficer=%@~AlgoWouldPrice=~FI_PriceType=6~ExpireDate=%@~FI_TradeAmount=9~AlAuction=~AlgoStrategy=0~AlRelLimit=~AlBenchMark=~",exchange,qtyValue,userID,stockCodeValue,clientAccountValue,side,@"0",orderType,timeInForce,orderPriceValue,currencyCode,currencyCode,userID,currentdate];
    NSString *soapRequest = [NSString stringWithFormat:
                             @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
                             "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"
                             "<soap:Body>"
                             "<NewOrderFixIncome xmlns=\"http://OMS/\">"
                             "<UserSession>%@</UserSession>"
                             "<strData>%@</strData>"
                             "<nVersion>0</nVersion>"
                             "</NewOrderFixIncome>"
                             "</soap:Body>"
                             "</soap:Envelope>",dm.sessionID,data];
//    NSLog(@"SoapRequest is %@" , soapRequest);
    NSString *urls = [NSString stringWithFormat:@"%@%s",dm.serviceURL,"op=NewOrderFixIncome"];
    NSURL *url =[NSURL URLWithString:urls];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [req addValue:@"http://OMS/NewOrderFixIncome" forHTTPHeaderField:@"SOAPAction"];
    NSString *msgLength = [NSString stringWithFormat:@"%lu", (unsigned long)[soapRequest length]];
    [req addValue:msgLength forHTTPHeaderField:@"Content-Length"];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:[soapRequest dataUsingEncoding:NSUTF8StringEncoding]];
    conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    spinner.hidesWhenStopped=YES;
    [spinner startAnimating];
    if (conn) {
        buffer = [NSMutableData data];
    }
}

@end
