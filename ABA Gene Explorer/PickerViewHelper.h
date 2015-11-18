//
//  PickerViewHelper.h
//  ABA Gene Explorer
//
//  Created by Joseph Salisbury on 11/10/15.
//

#import <UIKit/UIKit.h>

@interface PickerViewHelper : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

- (void)setArray:(NSArray *)incoming;

- (NSObject *) getItemFromArray:(NSUInteger)index;
    
@end
