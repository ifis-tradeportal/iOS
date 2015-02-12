//
//  NotificationViewController.m
//  TradePortal
//
//  Created by Nagarajan Sathish on 22/1/15.
//
//

#import "NotificationViewController.h"
#import "DataModel.h"
#import "NotificationTableViewCell.h"

@interface NotificationViewController (){
    NSMutableArray *deviceList;
    NSMutableArray *deviceRegId;
    NSInteger i;
}

@end

@implementation NotificationViewController
DataModel *dm;

@synthesize refreshControl;

- (void)viewDidLoad {
    [super viewDidLoad];
    [refreshControl addTarget:self action:@selector(reloadTableData) forControlEvents:UIControlEventValueChanged];
    [refreshControl beginRefreshing];
    [self reloadTableData];
    
    
}

- (void)reloadTableData{
    [dm.currentInstallation fetchIfNeeded];
    PFQuery *query = [PFQuery queryWithClassName:@"DeviceList"];
    [query getObjectInBackgroundWithId:[dm.deviceDict objectForKey:dm.TR_Code] block:^(PFObject *userObject, NSError *error) {
        dm.parseDeviceList = userObject;
        deviceList = [[NSMutableArray alloc]initWithArray:dm.parseDeviceList[@"deviceList"]];
        deviceRegId = [[NSMutableArray alloc]initWithArray:dm.parseDeviceList[@"deviceRegId"]];
        [self.tableView reloadData];
    }];
}
- (void) viewWillAppear:(BOOL)animated{
    [[self tableView]reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    i=[deviceList count];
    return i;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[NotificationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    cell.deviceName.text = [deviceList objectAtIndex:indexPath.row];
    [cell.notifySwitch addTarget:self action:@selector(turnNotificationOnOrOff:) forControlEvents:UIControlEventValueChanged];
    [cell.notifySwitch setTag:indexPath.row];
    PFQuery *query1 = [PFQuery queryWithClassName:@"_Installation"];
    [query1 getObjectInBackgroundWithId:[deviceRegId objectAtIndex:indexPath.row] block:^(PFObject *userObject, NSError *error) {
        dm.Installation = (PFInstallation *)userObject;
        i--;
        if (dm.Installation.channels.count > 1) {
            
            if ([[dm.Installation.channels objectAtIndex:1] isEqualToString:dm.TR_Code]) {
                
                [cell.notifySwitch setOn:YES];
            }
            else
            {
                [cell.notifySwitch setOn:NO];
            }
        }
        
        
        else
        {
            [cell.notifySwitch setOn:NO];
        }
        if (i==0) {
        [refreshControl endRefreshing];
        }
    }];
    
    return cell;
}



- (IBAction)turnNotificationOnOrOff:(UISwitch*)sender {
    PFQuery *query = [PFQuery queryWithClassName:@"DeviceList"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (!error) {
//             NSLog(@"Successfully retrieved %lu.", (unsigned long)objects.count);
             for (PFObject *object in objects) {
                 if (![object.objectId isEqual:[dm.deviceDict objectForKey:dm.TR_Code]]) {
                     dm.parseDeviceList = object;
                     NSMutableArray *deviceList1 = [[NSMutableArray alloc]initWithArray:dm.parseDeviceList[@"deviceList"]];
                     NSMutableArray *deviceRegId1 = [[NSMutableArray alloc]initWithArray:dm.parseDeviceList[@"deviceRegId"]];
                     if ([deviceRegId1 containsObject:dm.currentInstallation.objectId]) {
                         [deviceList1 removeObject:[[UIDevice currentDevice]name]];
                         dm.parseDeviceList[@"deviceList"] = deviceList1;
                         [deviceRegId1 removeObject:dm.currentInstallation.objectId];
                         dm.parseDeviceList[@"deviceRegId"] = deviceRegId1;
                         [dm.parseDeviceList saveInBackground];
                     }
                 }
                 //                                 NSLog(@"%@", object);
             }
         } else {
             NSLog(@"Error: %@ %@", error, [error userInfo]);
         }
     }];
    
    PFQuery *query1 = [PFQuery queryWithClassName:@"_Installation"];
    [query1 getObjectInBackgroundWithId:[deviceRegId objectAtIndex:sender.tag] block:^(PFObject *userObject, NSError *error) {
        dm.Installation = (PFInstallation *)userObject;
        NSString *msg;
        if ([sender isOn]) {
            dm.Installation.channels = [NSArray arrayWithObjects:@"",dm.TR_Code,nil];
            msg = @"Notification turned on...";
        }
        else{
            dm.Installation.channels = [NSArray arrayWithObjects:@"",nil];
            msg = @"Notification turned off...";
        }
        [dm.Installation saveInBackground];
        UIAlertView *toast = [[UIAlertView alloc]initWithTitle:nil message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
        [toast show];
        int duration = 1.5;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [toast dismissWithClickedButtonIndex:0 animated:YES];
        });
    }];
    
}


@end
