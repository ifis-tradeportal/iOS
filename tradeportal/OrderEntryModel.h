//
//  OrderEntryModel.h
//  TradePortal
//
//  Created by Nagarajan Sathish on 29/1/15.
//
//

#import <Foundation/Foundation.h>

@interface OrderEntryModel : NSObject{
    NSString *searchStock;
    NSString *accountNumber;
    NSString *action;
    NSString *quantity;
    BOOL flag;
}


@property(strong,nonatomic)NSString *searchStock;
@property(strong,nonatomic)NSString *accountNumber;
@property(strong,nonatomic)NSString *action;
@property(strong,nonatomic)NSString *quantity;
@property(assign,nonatomic)BOOL flag;


@end
