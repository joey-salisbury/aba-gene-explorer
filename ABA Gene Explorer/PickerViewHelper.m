//
//  PickerViewHelper.m
//  ABA Gene Explorer
//
//  Created by Joseph Salisbury on 11/10/15.
//

#import "PickerViewHelper.h"

@interface PickerViewHelper ()
@property (nonatomic) NSMutableArray *pickerData;

@end

@implementation PickerViewHelper

- (id) init {
    if ([super init] == nil) {
        return nil;
    }
    self.pickerData = [NSMutableArray arrayWithArray:@[]];
    return self;
}

- (void)setArray:(NSArray *)incoming{
    self.pickerData = [NSMutableArray arrayWithArray:incoming];
}

- (NSObject *) getItemFromArray:(NSUInteger) index{
    return [self.pickerData objectAtIndex:index];
    
}

- (NSInteger) pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.pickerData count];
}

- (NSString *) pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [[self.pickerData objectAtIndex:row] description];
}

- (NSInteger) numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


@end
