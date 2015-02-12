//
//  NotificationTableViewCell.h
//  TradePortal
//
//  Created by Nagarajan Sathish on 22/1/15.
//
//

#import <UIKit/UIKit.h>

@interface NotificationTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *deviceName;
@property (weak, nonatomic) IBOutlet UISwitch *notifySwitch;

@end
