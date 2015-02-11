//
//  OrderBookViewController.m
//  tradeportal
//
//  Created by Nagarajan Sathish on 23/10/14.
//
//

#import "OrderBookViewController.h"
#import "OrderBookTableViewCell.h"
#import "OrderBookDetailsViewController.h"

@interface OrderBookViewController(){
    BOOL resultFound;
}

@property (strong, nonatomic) NSMutableData *buffer;
@property (strong, nonatomic) NSXMLParser *parser;
@property (strong, nonatomic) NSString *parseURL;
@property (strong, nonatomic) NSURLConnection *conn;
@property (strong, nonatomic) NSDictionary *statusDict;
@property (strong, nonatomic) NSString *sortedBy;
@property (assign, nonatomic) Boolean isAscending;

@end

@implementation OrderBookViewController


@synthesize orders = _orders,buffer,parseURL,parser,conn,orderList=_orderList,statusDict, searchBar,searchBtn,exeOrderList,sortedBy,isAscending;
OrderBookModel *obm;
DataModel *dm;
OrderBookTableViewCell *header;


#pragma mark - View Delegates

-(void)viewDidLoad{
    statusDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                  @"CXL",@"Cancelled",
                  @"CHG",@"Changed",
                  @"FILL",@"Filled",
                  @"PARK",@"Parked",
                  @"PART",@"Partially Filled",
                  @"PCHG",@"Pending Changed",
                  @"PCXL",@"Pending Cancel",
                  @"PQ",@"Pending Queue",
                  @"Q",@"Queue",
                  @"RJCT",@"Rejected",
                  @"CXL",@"Unsolicited Cancel",
                  @"CHG",@"Part Changed",
                  @"CXL",@"Part Cancelled",
                  nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldShouldReturn:) name:UIKeyboardWillHideNotification object:nil];
    orders = [[NSMutableArray alloc]init];
    orderList= [[NSMutableArray alloc]init];
    exeOrderList= [[NSMutableArray alloc]init];
    self.tableView.estimatedRowHeight = 40.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc]init];
    refreshControl.tintColor = iRELOAD;
    [refreshControl addTarget:self action:@selector(reloadTableData) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
    [self.refreshControl beginRefreshing];
    [self searchBar].hidden = TRUE;
    [self reloadTableData];
    [super viewDidLoad];
    header = [self.tableView dequeueReusableCellWithIdentifier:@"tableHeader"];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [self.navigationController.navigationBar endEditing:YES];
    [orders removeAllObjects];
    [orders addObjectsFromArray:orderList];
    [self.tableView reloadData];
    [[self segmentedControl]setSelectedSegmentIndex:0];
    [super viewWillAppear:animated];
    sortedBy = @"";
    isAscending = false;
    [self clearSortingFor:@""];
}

-(void) viewDidAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (([[[[[[self tabBarController]tabBar]items]objectAtIndex:1]badgeValue]intValue ]> 0 )) {
        [self reloadTableData];
        [[[[[self tabBarController]tabBar]items]objectAtIndex:1]setBadgeValue:NULL];
    }
    [super viewDidAppear:animated];
}

#pragma mark - Reload Order List

-(void)reloadTableData{
    //    [self.tableView setUserInteractionEnabled:NO];
    [self loadOrders];
}

- (IBAction)capitalize:(UITextField *)textField {
    textField.text = [textField.text uppercaseString];
}

#pragma mark - TextField Delegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self hideSearch:self];
    [[self searchBar]resignFirstResponder];
    return YES;
}

#pragma mark - Search

- (IBAction)stockSearch:(id)sender {
    [self searchBar].text = @"";
    [self.segmentedControl setSelectedSegmentIndex:0];
    [orders removeAllObjects];
    [orders addObjectsFromArray:orderList];
    [self.tableView reloadData];
    [self segmentedControl].hidden = TRUE;
    [self searchBtn].hidden = TRUE;
    [self searchBar].hidden = FALSE;
    [searchBar becomeFirstResponder];
}

- (IBAction)hideSearch:(id)sender {
    [self segmentedControl].hidden = FALSE;
    [self searchBtn].hidden = FALSE;
    [self searchBar].hidden = TRUE;
    if ([[self searchBar].text isEqualToString:@""]) {
        [[self segmentedControl]setSelectedSegmentIndex:0];
    } else {
        [[self segmentedControl]setSelectedSegmentIndex:UISegmentedControlNoSegment];
    }
}

-(IBAction)searchOrderList:(id)sender
{
    if ([searchBar.text isEqualToString:@""]) {
        [orders removeAllObjects];
        [orders addObjectsFromArray:orderList];
    } else {
        NSString *searchText = searchBar.text;
        [orders removeAllObjects];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(stockCode contains[cd] %@) or (desc contains[cd] %@) or (clientAccount contains[cd] %@)", searchText,searchText,searchText];
        [orders addObjectsFromArray:[orderList filteredArrayUsingPredicate:predicate]];
    }
    [self.tableView reloadData];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([orders count]==0) {
        return 4;
    }
    return [orders count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setGroupingSeparator:@","];
    [numberFormatter setGroupingSize:3];
    [numberFormatter setUsesGroupingSeparator:YES];
    
    NSNumberFormatter *priceFormatter = [[NSNumberFormatter alloc] init];
    [priceFormatter setDecimalSeparator:@"."];
    [priceFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    [priceFormatter setMaximumFractionDigits:3];
    [priceFormatter setMinimumFractionDigits:3];
    
    OrderBookTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"OrderBookTableViewCell"];
    if([orders count]>0){
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        NSMutableString *stock = [[[orders objectAtIndex:[indexPath row]]stockCode]mutableCopy];
        UIColor *textColor = [[UIColor alloc]init];
        //        [[cell stockCode] setText:[[orders objectAtIndex:[indexPath row]]stockCode]];
        if([[[orders objectAtIndex:[indexPath row]]side] isEqualToString:@"Buy"]){
            [stock appendString:@" (B)"];
            textColor = iGREEN;
        }
        if([[[orders objectAtIndex:[indexPath row]]side] isEqualToString:@"Sell"]){
            [stock appendString:@" (S)"];
            textColor = iRED;
        }
        NSMutableAttributedString * string = [[NSMutableAttributedString alloc]initWithString:stock];
        [string addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(stock.length-2, 1)];
        [string addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:14.0f] range:NSMakeRange(stock.length-2, 1)];
        
        [[cell account] setText:[[orders objectAtIndex:[indexPath row]]clientAccount]];
        [[cell stockCode] setAttributedText:string];
        [[cell price] setText:[priceFormatter stringFromNumber:[NSNumber numberWithDouble:[[[orders objectAtIndex:[indexPath row]]orderPrice] doubleValue]]]];
        [[cell quantity] setText:[numberFormatter stringFromNumber:[NSNumber numberWithInt:[[[orders objectAtIndex:[indexPath row]]orderQty] intValue]]]];
        [[cell qtyFilled] setText:[numberFormatter stringFromNumber:[NSNumber numberWithInt:[[[orders objectAtIndex:[indexPath row]]qtyFilled] intValue]]]];
        [[cell status] setText:[statusDict valueForKey:[[orders objectAtIndex:[indexPath row]]status]]];
        [[cell orderDate] setText:[NSDateFormatter localizedStringFromDate:[[orders objectAtIndex:[indexPath row]]orderDate] dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle]];
        [[cell refNo] setText:[[orders objectAtIndex:[indexPath row]]refNo]];
        cell.userInteractionEnabled=YES;
        if (indexPath.row==3) {
            cell.noResults.hidden=true;
        }
    }
    else
    {
        [[cell stockCode] setText:@" "];
        [[cell price] setText:@" "];
        [[cell quantity] setText:@" "];
        if (indexPath.row==3) {
            cell.noResults.hidden=false;
        }
        [[cell account] setText:@" "];
        [[cell qtyFilled] setText:@" "];
        [[cell status] setText:@" "];
        [[cell orderDate] setText:@" "];
        [[cell refNo] setText:@" "];
        cell.userInteractionEnabled=NO;
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    [cell setBackgroundColor:[UIColor clearColor]];
    return cell;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (!((exeOrderList.count == 0) || (orders.count == 0))) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"refNo contains[cd] %@", [[orders objectAtIndex:[indexPath row]]refNo]];
        NSArray *dummy =[exeOrderList filteredArrayUsingPredicate:predicate];
        if (dummy.count == 0) {
            [cell setBackgroundColor:iBackColorGreen];
        }
        else if (![[[dummy objectAtIndex:0]status] isEqualToString:[[orders objectAtIndex:[indexPath row]]status]]) {
            if (![[[orders objectAtIndex:[indexPath row]]status] rangeOfString:@"Cancel"].length == 0) {
                [cell setBackgroundColor:iBackColorRed];
            }
            else if (![[[orders objectAtIndex:[indexPath row]]status] rangeOfString:@"Reject"].length == 0) {
                [cell setBackgroundColor:iBackColorRed];
            }
            else{
                [cell setBackgroundColor:iBackColorGreen];
            }
        }
        else{
            [cell setBackgroundColor:[UIColor clearColor]];
        }
    }
    //    if([indexPath row] == ((NSIndexPath*)[[tableView indexPathsForVisibleRows] lastObject]).row){
    //        [exeOrderList removeAllObjects];
    //    }
}


-(UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIButton *refNo = [[UIButton alloc]init];
    refNo.tag = 1;
    refNo.hidden = NO;
    [refNo setBackgroundColor:[UIColor clearColor]];
    [refNo addTarget:self action:@selector(sort:) forControlEvents:UIControlEventTouchDown];
    [header addSubview:refNo];
    
    UIButton *stockCode = [[UIButton alloc]init];
    stockCode.tag = 2;
    stockCode.hidden = NO;
    [stockCode setBackgroundColor:[UIColor clearColor]];
    [stockCode addTarget:self action:@selector(sort:) forControlEvents:UIControlEventTouchDown];
    [header addSubview:stockCode];
    
    UIButton *account = [[UIButton alloc]init];
    account.tag = 3;
    account.hidden = NO;
    [account setBackgroundColor:[UIColor clearColor]];
    [account addTarget:self action:@selector(sort:) forControlEvents:UIControlEventTouchDown];
    [header addSubview:account];
    
    UIButton *orderDate = [[UIButton alloc]init];
    orderDate.tag = 4;
    orderDate.hidden = NO;
    [orderDate setBackgroundColor:[UIColor clearColor]];
    [orderDate addTarget:self action:@selector(sort:) forControlEvents:UIControlEventTouchDown];
    [header addSubview:orderDate];
    
    UIButton *price = [[UIButton alloc]init];
    price.tag = 5;
    price.hidden = NO;
    [price setBackgroundColor:[UIColor clearColor]];
    [price addTarget:self action:@selector(sort:) forControlEvents:UIControlEventTouchDown];
    [header addSubview:price];
    
    UIButton *quantity = [[UIButton alloc]init];
    quantity.tag = 6;
    quantity.hidden = NO;
    [quantity setBackgroundColor:[UIColor clearColor]];
    [quantity addTarget:self action:@selector(sort:) forControlEvents:UIControlEventTouchDown];
    [header addSubview:quantity];
    
    UIButton *qtyFilled = [[UIButton alloc]init];
    qtyFilled.tag = 7;
    qtyFilled.hidden = NO;
    [qtyFilled setBackgroundColor:[UIColor clearColor]];
    [qtyFilled addTarget:self action:@selector(sort:) forControlEvents:UIControlEventTouchDown];
    [header addSubview:qtyFilled];
    
    UIButton *status = [[UIButton alloc]init];
    status.tag = 8;
    status.hidden = NO;
    [status setBackgroundColor:[UIColor clearColor]];
    [status addTarget:self action:@selector(sort:) forControlEvents:UIControlEventTouchDown];
    [header addSubview:status];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [stockCode setFrame:header.stockCode.frame];
        [account setFrame:header.account.frame];
        [price setFrame:header.price.frame];
        [quantity setFrame:header.quantity.frame];
        [qtyFilled setFrame:header.qtyFilled.frame];
        [status setFrame:header.status.frame];
    }
    else {
        [stockCode setFrame:header.stockCode.frame];
        [account setFrame:header.account.frame];
        [price setFrame:header.price.frame];
        [quantity setFrame:header.quantity.frame];
        [qtyFilled setFrame:header.qtyFilled.frame];
        [status setFrame:header.status.frame];
        [refNo setFrame:header.refNo.frame];
        [orderDate setFrame:header.orderDate.frame];
        
    }
    return header;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 48.0;
}


#pragma mark - Invoke Order List Service

-(void)loadOrders{
    self.parseURL = @"getOrders";
    NSString *soapRequest = [NSString stringWithFormat:
                             @"<?xml version=\"1.0\" encoding=\"utf-8\"?>"
                             "<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">"
                             "<soap:Body>"
                             "<GetOrderByUserID xmlns=\"http://OMS/\">"
                             "<UserSession>%@</UserSession>"
                             "<UserID>%@</UserID>"
                             "</GetOrderByUserID>"
                             "</soap:Body>"
                             "</soap:Envelope>", dm.sessionID,dm.userID];
    //    NSLog(@"SoapRequest is %@" , soapRequest);
    NSString *urls = [NSString stringWithFormat:@"%@%s",dm.serviceURL,"op=GetOrderByUserID"];
    NSURL *url =[NSURL URLWithString:urls];
    //    NSLog(@"%@",url);
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req addValue:@"text/xml; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [req addValue:@"http://OMS/GetOrderByUserID" forHTTPHeaderField:@"SOAPAction"];
    NSString *msgLength = [NSString stringWithFormat:@"%lu", (unsigned long)[soapRequest length]];
    [req addValue:msgLength forHTTPHeaderField:@"Content-Length"];
    [req setHTTPMethod:@"POST"];
    [req setHTTPBody:[soapRequest dataUsingEncoding:NSUTF8StringEncoding]];
    [exeOrderList removeAllObjects];
    [exeOrderList addObjectsFromArray:orderList];
    
    
    conn = [[NSURLConnection alloc] initWithRequest:req delegate:self];
    if (conn) {
        buffer = [NSMutableData data];
    }
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
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
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
    [orderList removeAllObjects];
    [orders removeAllObjects];
    [buffer setData:[theXML dataUsingEncoding:NSUTF8StringEncoding]];
    parser =[[NSXMLParser alloc]initWithData:buffer];
    [parser setDelegate:self];
    [parser parse];
}


#pragma mark - XML Parser

-(void) parser:(NSXMLParser *) parser didStartElement:(NSString *) elementName
  namespaceURI:(NSString *) namespaceURI qualifiedName:(NSString *) qName attributes:(NSDictionary *) attributeDict {
    
    //parse the data
    if ([parseURL isEqualToString:@"getOrders"]) {
        if ([elementName isEqualToString:@"z:row"]) {
            resultFound=YES;
            OrderBookModel *order = [[OrderBookModel alloc]init];
            order.refNo = [attributeDict objectForKey:@"c8"];
            order.clientAccount = [attributeDict objectForKey:@"c9"];
            order.stockCode = [attributeDict objectForKey:@"Stock"];
            order.desc = [attributeDict objectForKey:@"c43"];
            order.exchange = [attributeDict objectForKey:@"Exchange"];
            order.side = [attributeDict objectForKey:@"c4"];
            order.orderType = [attributeDict objectForKey:@"c24"];
            order.status = [attributeDict objectForKey:@"c7"];
            order.orderQty = [attributeDict objectForKey:@"OrderQty"];
            order.qtyFilled = [attributeDict objectForKey:@"FilledQty"];
            order.orderPrice = [attributeDict objectForKey:@"OrderPrice"];
            order.avgPrice = [attributeDict objectForKey:@"AvePrice"];
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
            order.orderDate = [dateFormatter dateFromString:[attributeDict objectForKey:@"c11"]];
            order.currency = [attributeDict objectForKey:@"c22"];
            //Add arrribute value to array
            [orderList addObject:order];
            [orders addObject:order];
            
        }
        [self.refreshControl endRefreshing];
        [self clearSortingFor:@""];
        [self.segmentedControl setSelectedSegmentIndex:0];
        
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
    if ([elementName isEqualToString:@"GetOrderByUserIDResult"]) {
        [self.tableView reloadData];
    }
    //        [self.tableView setUserInteractionEnabled:YES];
}

- (void) parser:(NSXMLParser *) parser foundCharacters:(NSString *) string {
    NSString *msg;
    BOOL flag=FALSE;
    if([[string substringToIndex:1] isEqualToString:@"R"]){
        msg = @"Some Technical Error...\nPlease Try again...";
        flag=TRUE;
    }
    else if([string length]>1){
        if([string isEqualToString:@"E  No permission to access "]){
            msg = @"User has logged on elsewhere!";
            [self dismissViewControllerAnimated:YES completion:nil];
            [[self navigationController]popToRootViewControllerAnimated:YES];
            flag=TRUE;
        }
    }
    if (flag) {
        UIAlertView *toast = [[UIAlertView alloc]initWithTitle:nil message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
        [toast show];
        int duration = 1.5;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [toast dismissWithClickedButtonIndex:0 animated:YES];
        });
    }
}


#pragma mark - Segmented Control

-(IBAction)indexChanged:(UISegmentedControl *)sender
{
    switch (self.segmentedControl.selectedSegmentIndex)
    {
        case 0:
            [orders removeAllObjects];
            [orders addObjectsFromArray:orderList];
            [self.tableView reloadData];
            break;
        case 1:
            [orders removeAllObjects];
            for(OrderBookModel *ob in orderList){
                if([ob.status isEqualToString:@"Filled"]){
                    [orders addObject:ob];
                }
            }
            [self.tableView reloadData];
            break;
        case 2:
            [orders removeAllObjects];
            for(OrderBookModel *ob in orderList){
                if([ob.status isEqualToString:@"Queue"]){
                    [orders addObject:ob];
                }
            }
            [self.tableView reloadData];
            break;
        default:
            break;
    }
}



#pragma mark - Sort

- (IBAction)sort:(UIButton *)sender{
        NSLog(@"%ld",(long)sender.tag);
    NSSortDescriptor *sortDescriptor;
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    NSAttributedString *attachmentString;
    NSMutableAttributedString *myString;
    NSArray *tempArray = [[NSArray alloc]initWithArray:orders];
    [orders removeAllObjects];
    switch (sender.tag) {
        case 1:
            [self clearSortingFor:@"refNo"];
            myString= [[NSMutableAttributedString alloc] initWithString:header.refNo.text];
            if (!isAscending) {
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"refNo" ascending:YES];
                attachment.image = [UIImage imageNamed:@"icon_up_sort_arrow.png"];
                isAscending = true;
            }
            else{
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"refNo" ascending:NO];
                attachment.image = [UIImage imageNamed:@"icon_down_sort_arrow.png"];
                isAscending = false;
            }
            attachmentString= [NSAttributedString attributedStringWithAttachment:attachment];
            [myString appendAttributedString:attachmentString];
            header.refNo.attributedText = myString;
            sortedBy = @"refNo";
            break;
        case 2:
            [self clearSortingFor:@"stockCode"];
            myString= [[NSMutableAttributedString alloc] initWithString:header.stockCode.text];
            if (!isAscending) {
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"stockCode" ascending:YES];
                attachment.image = [UIImage imageNamed:@"icon_up_sort_arrow.png"];
                isAscending = true;
            }
            else{
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"stockCode" ascending:NO];
                attachment.image = [UIImage imageNamed:@"icon_down_sort_arrow.png"];
                isAscending = false;
            }
            attachmentString= [NSAttributedString attributedStringWithAttachment:attachment];
            [myString appendAttributedString:attachmentString];
            header.stockCode.attributedText = myString;
            sortedBy = @"stockCode";
            break;
        case 3:
            [self clearSortingFor:@"account"];
            myString= [[NSMutableAttributedString alloc] initWithString:header.account.text];
            if (!isAscending) {
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"clientAccount" ascending:YES];
                attachment.image = [UIImage imageNamed:@"icon_up_sort_arrow.png"];
                isAscending = true;
            }
            else{
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"clientAccount" ascending:NO];
                attachment.image = [UIImage imageNamed:@"icon_down_sort_arrow.png"];
                isAscending = false;
            }
            attachmentString= [NSAttributedString attributedStringWithAttachment:attachment];
            [myString appendAttributedString:attachmentString];
            header.account.attributedText = myString;
            sortedBy = @"account";
            break;
        case 4:
            [self clearSortingFor:@"orderDate"];
            myString= [[NSMutableAttributedString alloc] initWithString:header.orderDate.text];
            if (!isAscending) {
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"orderDate" ascending:YES];
                attachment.image = [UIImage imageNamed:@"icon_up_sort_arrow.png"];
                isAscending = true;
            }
            else{
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"orderDate" ascending:NO];
                attachment.image = [UIImage imageNamed:@"icon_down_sort_arrow.png"];
                isAscending = false;
            }
            attachmentString= [NSAttributedString attributedStringWithAttachment:attachment];
            [myString appendAttributedString:attachmentString];
            header.orderDate.attributedText = myString;
            sortedBy = @"orderDate";
            break;
        case 5:
            [self clearSortingFor:@"price"];
            myString= [[NSMutableAttributedString alloc] initWithString:header.price.text];
            if (!isAscending) {
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"orderPrice" ascending:YES];
                attachment.image = [UIImage imageNamed:@"icon_up_sort_arrow.png"];
                isAscending = true;
            }
            else{
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"orderPrice" ascending:NO];
                attachment.image = [UIImage imageNamed:@"icon_down_sort_arrow.png"];
                isAscending = false;
            }
            attachmentString= [NSAttributedString attributedStringWithAttachment:attachment];
            [myString appendAttributedString:attachmentString];
            header.price.attributedText = myString;
            sortedBy = @"price";
            break;
        case 6:
            [self clearSortingFor:@"quantity"];
            myString= [[NSMutableAttributedString alloc] initWithString:header.quantity.text];
            if (!isAscending) {
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"orderQty" ascending:YES selector:@selector(localizedStandardCompare:)];
                attachment.image = [UIImage imageNamed:@"icon_up_sort_arrow.png"];
                isAscending = true;
            }
            else{
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"orderQty" ascending:NO selector:@selector(localizedStandardCompare:)];
                attachment.image = [UIImage imageNamed:@"icon_down_sort_arrow.png"];
                isAscending = false;
            }
            attachmentString= [NSAttributedString attributedStringWithAttachment:attachment];
            [myString appendAttributedString:attachmentString];
            header.quantity.attributedText = myString;
            sortedBy = @"quantity";
            break;
        case 7:
            [self clearSortingFor:@"qtyFilled"];
            myString= [[NSMutableAttributedString alloc] initWithString:header.qtyFilled.text];
            if (!isAscending) {
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"qtyFilled" ascending:YES selector:@selector(localizedStandardCompare:)];
                attachment.image = [UIImage imageNamed:@"icon_up_sort_arrow.png"];
                isAscending = true;
            }
            else{
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"qtyFilled" ascending:NO selector:@selector(localizedStandardCompare:)];
                attachment.image = [UIImage imageNamed:@"icon_down_sort_arrow.png"];
                isAscending = false;
            }
            attachmentString= [NSAttributedString attributedStringWithAttachment:attachment];
            [myString appendAttributedString:attachmentString];
            header.qtyFilled.attributedText = myString;
            sortedBy = @"qtyFilled";
            break;
        case 8:
            [self clearSortingFor:@"status"];
            myString= [[NSMutableAttributedString alloc] initWithString:header.status.text];
            if (!isAscending) {
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"status" ascending:YES];
                attachment.image = [UIImage imageNamed:@"icon_up_sort_arrow.png"];
                isAscending = true;
            }
            else{
                sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"status" ascending:NO];
                attachment.image = [UIImage imageNamed:@"icon_down_sort_arrow.png"];
                isAscending = false;
            }
            attachmentString= [NSAttributedString attributedStringWithAttachment:attachment];
            [myString appendAttributedString:attachmentString];
            header.status.attributedText = myString;
            sortedBy = @"status";
            break;
            
        default:
            break;
    }
    NSMutableArray *sortDescriptors = [NSMutableArray arrayWithObject:sortDescriptor];
    [orders addObjectsFromArray:[tempArray sortedArrayUsingDescriptors:sortDescriptors]];
    
    [header setNeedsDisplay];
    [self.tableView reloadData];
    
}


- (void) clearSortingFor:(NSString*)column{
    if (![column isEqualToString:sortedBy]) {
        isAscending = false;
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        header.quantity.text = @"Qty.";
        header.qtyFilled.text = @"Qty. Filled";
    }
    else {
        header.quantity.text = @"Quantity";
        header.qtyFilled.text = @"Quantity Filled";
    }
    header.refNo.text = @"# Order ref.";
    header.stockCode.text = @"Stock (Action)";
    header.account.text = @"Account No.";
    header.orderDate.text = @"Order Date";
    header.price.text = @"Price";
    header.status.text = @"Status";
}


#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    [self.navigationController.navigationBar endEditing:YES];
    if ([[segue identifier] isEqualToString:@"orderDetail"]) {
        
        OrderBookDetailsViewController *vc = (OrderBookDetailsViewController *)segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        //        NSLog(@"%@",indexPath);
        OrderBookModel *obm = [orders objectAtIndex:indexPath.row];
        vc.order = obm;
        vc.orderBook = self;
    }
    
}


@end
