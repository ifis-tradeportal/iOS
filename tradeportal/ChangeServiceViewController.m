//
//  ChangeServiceViewController.m
//  tradeportal
//
//  Created by Nagarajan Sathish on 8/12/14.
//
//

#import "ChangeServiceViewController.h"
#import "DataModel.h"
@interface ChangeServiceViewController ()

@end

@implementation ChangeServiceViewController


@synthesize url,protocol,ip,domain,path,settings,service,spinner;
DataModel *dm;

#pragma mark - View Delegates
Boolean flag;
- (void)viewDidLoad {
    [super viewDidLoad];
    flag =false;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        self.view.backgroundColor=[UIColor clearColor];
        settings.view.alpha=0.5f;
    }
    [self loadData];
}
-(void)loadData{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); //1
    NSString *documentsDirectory = [paths objectAtIndex:0]; //2
    path = [documentsDirectory stringByAppendingPathComponent:@"TradePortal.plist"];
    url = [[NSMutableDictionary alloc] initWithContentsOfFile: path];
    BOOL oldIP= [url objectForKey:@"ip"]!=nil;
    if (!oldIP) {
        [dm resetService];
        url = [[NSMutableDictionary alloc] initWithContentsOfFile: path];
    }
    else{
        protocol.placeholder = [url objectForKey:@"protocol"];
        ip.placeholder = [url objectForKey:@"ip"];
        domain.placeholder = [url objectForKey:@"domain"];
        service.placeholder = [url objectForKey:@"service"];
        protocol.text = @"";
        ip.text = @"";
        domain.text = @"";
        service.text = @"";
    }
}

-(IBAction)hideKeyboard:(id)sender{
    [self.view endEditing:YES];
}

#pragma mark - TextField Delegates

-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    [self.view endEditing:YES];
    return YES;
}

#pragma mark - Reset Data

- (IBAction)setDefault:(id)sender {
    [spinner startAnimating];
    [dm resetService ];
    [self loadData];
    dm.serviceURL = [NSString stringWithFormat:@"%@://%@%@/%@",[url objectForKey:@"protocol"],[url objectForKey:@"ip"],[url objectForKey:@"domain"],[url objectForKey:@"service"]];
    //    NSLog(@"%@",dm.serviceURL);
    flag=true;
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(dismissView:)
                                   userInfo:nil
                                    repeats:NO];
}


#pragma mark - Save Data

- (IBAction)saveChanges:(id)sender {
    [spinner startAnimating];
    if (![ip.text isEqualToString:@""]) {
        if ([ip.text isEqualToString:@"-"]) {
            [url setObject:@"" forKey:@"ip"];
        }
        else{
            [url setObject:[NSString stringWithString:ip.text] forKey:@"ip"];
        }
    }
    if (![domain.text isEqualToString:@""]) {
        if ([domain.text isEqualToString:@"-"]) {
            [url setObject:@"" forKey:@"domain"];
        }
        else{
            [url setObject:[NSString stringWithString:domain.text] forKey:@"domain"];
        }
    }
    if (![protocol.text isEqualToString:@""]) {
        if ([protocol.text isEqualToString:@"-"]) {
            [url setObject:@"" forKey:@"protocol"];
        }
        else{
            [url setObject:[NSString stringWithString:protocol.text] forKey:@"protocol"];
        }
    }
    if (![service.text isEqualToString:@""]) {
        if ([service.text isEqualToString:@"-"]) {
            [url setObject:@"" forKey:@"service"];
        }
        else{
            [url setObject:[NSString stringWithString:service.text] forKey:@"service"];
        }
    }
    [url writeToFile: path atomically:YES];
    dm.serviceURL = [NSString stringWithFormat:@"%@://%@%@/%@",[url objectForKey:@"protocol"],[url objectForKey:@"ip"],[url objectForKey:@"domain"],[url objectForKey:@"service"]];
    //    NSLog(@"%@",dm.serviceURL);
    [self loadData];
    flag = true;
    [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(dismissView:)
                                   userInfo:nil
                                    repeats:NO];
}

#pragma mark - Dismiss View

- (IBAction)dismissView:(id)sender {
    [spinner stopAnimating];
    [self dismissViewControllerAnimated:YES completion:nil];
    settings.view.alpha = 1.0f;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && flag)
    {
        SettingsViewController *s = (SettingsViewController*)settings;
        [s dismissView];
        
    }
    
}
@end
