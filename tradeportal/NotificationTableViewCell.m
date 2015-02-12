//
//  NotificationTableViewCell.m
//  TradePortal
//
//  Created by Nagarajan Sathish on 22/1/15.
//
//

#import "NotificationTableViewCell.h"
#import "DataModel.h"

@implementation NotificationTableViewCell

@synthesize notifySwitch,deviceName;
DataModel *dm;

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


@end
