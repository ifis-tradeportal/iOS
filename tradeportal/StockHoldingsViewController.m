//
//  StockHoldingsViewController.m
//  tradeportal
//
//  Created by Nagarajan Sathish on 10/11/14.
//
//

#import "StockHoldingsViewController.h"
#import "StockHoldingsTableViewCell.h"
#import "ClientAccountViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "OrderEntryModel.h"

@interface StockHoldingsViewController (){
    BOOL resultFound;
}

@property (strong, nonatomic) NSMutableData *buffer;
@property (strong, nonatomic) NSXMLParser *parser;
@property (strong, nonatomic) NSString *parseURL;
@property (strong, nonatomic) NSURLConnection *conn;

@end

@implementation StockHoldingsViewController

@synthesize buffer,parseURL,parser,conn,clientAccount,stockCode,tableView,cAccount,spinner;
DataModel *dm;
OrderEntryModel *em;

#pragma mark - View Delegates

- (void)viewDidLoad {
    [super viewDidLoad];
    stockArray = [[NSMutableArray alloc]init];
    stockList = [[NSMutableArray alloc]init];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldShouldReturn:) name:UIKeyboardWillHideNotification object:nil];
}

-(void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
}

#pragma mark - View Delegates

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self.view endEditing:YES];
    return YES;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([stockList count]==0) {
        return 4;
    }
    return [stockList count];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    StockHoldingsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if(cell == nil){
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"Cell" owner:self options:nil];
        cell = [nib objectAtIndex:0];
    }
    if([stockList count]>0){
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setGroupingSeparator:@","];
        [numberFormatter setGroupingSize:3];
        [numberFormatter setUsesGroupingSeparator:YES];
        NSString *stkName = [[[stockList objectAtIndex:[indexPath row]]stockName]capitalizedString];
        [[cell stockName] setText:stkName];
        [[cell stockCode] setText:[[stockList objectAtIndex:[indexPath row]]stockCode]];
        [[cell location] setText:[[stockList objectAtIndex:[indexPath row]]stockLocation]];
        [[cell totalStock] setText:[numberFormatter stringFromNumber:[NSNumber numberWithInt:[[[stockList objectAtIndex:[indexPath row]]totalStock] intValue]]]];
        if (indexPath.row==3) {
            cell.noResults.hidden=true;
        }
        cell.userInteractionEnabled=YES;
    }
    else{
        [[cell stockCode] setText:@" "];
        [[cell stockName] setText:@" "];
        if (indexPath.row==3) {
            cell.noResults.hidden=false;
        }
        [[cell location] setText:@" "];
        [[cell totalStock] setText:@" "];
        cell.userInteractionEnabled=NO;
    }
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    em = [[OrderEntryModel alloc]init];
    em.searchStock = [[stockList objectAtIndex:[indexPath row]]stockCode];
    em.flag = true;
    em.accountNumber = clientAccount.titleLabel.text;
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setGroupingSeparator:@","];
    [numberFormatter setGroupingSize:3];
    [numberFormatter setUsesGroupingSeparator:YES];
    
    if ([[[stockList objectAtIndex:[indexPath row]]totalStock] intValue]<0) {
        em.action =@"BUY";
        em.quantity = [numberFormatter stringFromNumber:[NSNumber numberWithInt:abs([[[stockList objectAtIndex:[indexPath row]]totalStock]intValue])]];
    }
    else{
        em.action = @"SELL";
        em.quantity = [numberFormatter stringFromNumber:[NSNumber numberWithInt:[[[stockList objectAtIndex:[indexPath row]]totalStock]intValue]]];
    }
    NSLog(@"%@-%@-%@-%@",em.searchStock,em.action,em.accountNumber,em.quantity);
    [self.tabBarController setSelectedViewController:[[self.tabBarController viewControllers]objectAtIndex:0]];
    [self.tabBarController setSelectedIndex: 0];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

}


-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UITableViewCell *header = [tableView dequeueReusableCellWithIdentifier:@"tableHeader"];
    return header;
}
-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 38.0;
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
    [spinner stopAnimating];
}

-(void) connectionDidFinishLoading:(NSURLConnection *) connection {
    
    //NSLog(@"\n\nDone with bytes %lu", (unsigned long)[buffer length]);
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

#pragma mark -XML Parser

-(void) parser:(NSXMLParser *) parser didStartElement:(NSString *) elementName
  namespaceURI:(NSString *) namespaceURI qualifiedName:(NSString *) qName attributes:(NSDictionary *) attributeDict {
    //parse the data
    if ([parseURL isEqualToString:@"loadStocks"]) {
        if([elementName isEqualToString:@"GetCustodyStockLocationDetailsResult"]){
            ////NSLog(@"%@",[attributeDict description]);
            resultFound=NO;
        }
        if ([elementName isEqualToString:@"z:row"]) {
            
            StockHoldingsDataModel *stock = [[StockHoldingsDataModel alloc]init];
            stock.stockCode = [attributeDict objectForKey:@"RICCODE"];
            stock.stockLocation = [attributeDict objectForKey:@"STOCK_LOCATION"];
            stock.stockName = [attributeDict objectForKey:@"STOCK_NAME"];
            stock.totalStock = [attributeDict objectForKey:@"TOTAL"];
            
            [stockList addObject:stock];
            [stockArray addObject:stock];
        }
        [tableView reloadData];
    }
}

- (void) parser:(NSXMLParser *) parser foundCharacters:(NSString *) string {
    NSString *msg;
    BOOL flag=FALSE;
    if(!resultFound){
        if([[string substringToIndex:1] isEqualToString:@"R"]){
            msg = @"Some Technical Error...\nPlease Try again...";
            flag=TRUE;
        }
        else if([[string substringToIndex:1] isEqualToString:@"E"]){
            //NSLog(@"E error");
            msg = @"User has logged on elsewhere!";
            [self dismissViewControllerAnimated:YES completion:nil];
            [[self navigationController]popToRootViewControllerAnimated:YES];
            flag=TRUE;
        }
        if (flag) {
            
            UIAlertView *toast = [[UIAlertView alloc]initWithTitle:nil message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
            [toast show];
            int duration = 1.5;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [toast dismissWithClickedButtonIndex:0 animated:YES];
            });
            
        }
        resultFound=YES;
    }
    [spinner stopAnimating];
}

#pragma mark - Load Stocks

- (void)LoadStocksForAccount:(NSString *)account {
    self.parseURL = @"loadStocks";
    stockCode.text =@"";
    NSString *soapRequest = [NSString stringWithFormat:
                             @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
                             "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"
                             "<soap:Body>"
                             "<GetCustodyStockLocationDetails xmlns=\"http://OMS/\">"
                             "<PUserSession>%@</PUserSession>"
                             "<PClientAccount>%@</PClientAccount>"
                             "<PRicCode></PRicCode>"
                             "</GetCustodyStockLocationDetails>"
                             "</soap:Body>"
                             "</soap:Envelope>", dm.sessionID,account];
    //    NSLog(@"SoapRequest is %@" , soapRequest);
    NSString *urls = [NSString stringWithFormat:@"%@%s",dm.serviceURL,"op=GetCustodyStockLocationDetails"];
    NSURL *url =[NSURL URLWithString:urls];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [req addValue:@"http://OMS/GetCustodyStockLocationDetails" forHTTPHeaderField:@"SOAPAction"];
    NSString *msgLength = [NSString stringWithFormat:@"%lu", (unsigned long)[soapRequest length]];
    [req addValue:msgLength forHTTPHeaderField:@"Content-Length"];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:[soapRequest dataUsingEncoding:NSUTF8StringEncoding]];
    [stockList removeAllObjects];
    [stockArray removeAllObjects];
    conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (conn) {
        buffer = [NSMutableData data];
    }
    [spinner startAnimating];
}

#pragma mark -Search Stocks

- (IBAction)SearchStocks:(id)sender {
    [stockList removeAllObjects];
    NSString *searchText = stockCode.text;
    if([searchText isEqualToString:@""]){
        [stockList addObjectsFromArray:stockArray];
    }
    else
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(SELF.stockCode contains[c] %@) or (SELF.stockName contains[c] %@)", searchText, searchText];
        [stockList addObjectsFromArray:[stockArray filteredArrayUsingPredicate:predicate]];
    }
    [tableView reloadData];
}


-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    if (stockArray.count > 0) {
        return YES;
    }
    return NO;
}




#pragma mark -Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"clientAccount"]) {
        
        ClientAccountViewController *vc = (ClientAccountViewController *)segue.destinationViewController;
        vc.clientAccountStock = self;
    }
}

@end
