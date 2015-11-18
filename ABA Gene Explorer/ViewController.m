//
//  ViewController.m
//  ABA Gene Explorer
//
//  Created by Joseph Salisbury on 11/17/15.
//

#import "ViewController.h"
#import "PickerViewHelper.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIPickerView *genePicker;
@property (weak, nonatomic) IBOutlet UIImageView *sectionViewer;
@property (weak, nonatomic) IBOutlet UILabel *geneLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sectionSegmentControl;
@property (weak, nonatomic) IBOutlet UIButton *loadImageSetButton;
@property (weak, nonatomic) IBOutlet UIStepper *sectionStepper;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activitySpinner;

@property (nonatomic) PickerViewHelper *genePickerHelper;

@property (nonatomic) NSMutableArray *genes;
@property (nonatomic) NSString *currentGene;
@property (nonatomic) NSMutableArray *coronalSections;
@property (nonatomic) NSMutableArray *sagittalSections;

- (void) showAlertMessage:(NSString *) myMessage;
- (void) loadGeneData;
- (void) loadExperimentsForGene;
- (void) loadImage;
- (void) loadFailed:(NSString*)msg;

- (void) panGestureDetected:(UIPanGestureRecognizer *)recognizer;
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Disable buttons until successful load
    [self.activitySpinner startAnimating];
    self.loadImageSetButton.enabled = NO;
    self.sectionStepper.enabled = NO;
    self.sectionSegmentControl.enabled = NO;
    
    // Sets up gene picker
    self.genePickerHelper = [[PickerViewHelper alloc] init];
    [self.genePicker setDelegate:self.genePickerHelper];
    [self.genePicker setDataSource:self.genePickerHelper];
    
    //Initialize gene list
    [self loadGeneData];
    
    //Create and configure the pan gesture
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureDetected:)];
    [panGestureRecognizer setDelegate:self];
    [self.sectionViewer addGestureRecognizer:panGestureRecognizer];
    
}

- (void) showAlertMessage:(NSString *) myMessage {
    if (self.isViewLoaded) {
        UIAlertController *alertController;
        alertController = [UIAlertController alertControllerWithTitle:nil message:myMessage preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleDefault handler: nil]];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)loadGeneData {
    
    // This query grabs just the first 50 genes for demo purposes
    NSString *urlStr = @"http://api.brain-map.org/api/v2/data/Gene/query.json?criteria=products%5Bid$eq1%5D&num_rows=50";
    NSURL *url = [NSURL URLWithString:urlStr];
    NSURLSession *session = [NSURLSession sharedSession];
    
    [[session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response,
                                                      NSError * _Nullable error) {
        
        // Check for network error
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Error: Couldn't finish request: %@", error];
            [self loadFailed:msg];
            return;
        }
        
        // Check for http error
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *) response;
        if (httpResp.statusCode < 200 || httpResp.statusCode >= 300) {
            NSString *msg = [NSString stringWithFormat:@"Error: Got status code %ld", (long)httpResp.statusCode];
            [self loadFailed:msg];
            return;
        }
        
        //Check for JSON parse error
        NSError *parseErr;
        id pkg = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseErr];
        if (!pkg) {
            NSString *msg = [NSString stringWithFormat:@"Error: Couldn't parse response: %@", parseErr];
            [self loadFailed:msg];
            return;
        }
        
        //If all is good, parse genes from JSON and sort
        NSInteger num_rows = [pkg[@"num_rows"] intValue];
        self.genes = [NSMutableArray arrayWithCapacity:num_rows];
        for (int i =0; i <num_rows; i++) {
            [self.genes addObject:pkg[@"msg"][i][@"acronym"]];
        }
        [self.genes sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        
        //Update genePicker UIPickerView
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.genePickerHelper setArray:self.genes];
            [self.genePicker reloadAllComponents];
            
            //Load first image
            [self loadExperimentsForGene];
            
        });
       
    }]resume];

}

- (void)loadExperimentsForGene {
    // Set current gene from genePicker and query ABA for available images
    self.currentGene = self.genes[[self.genePicker selectedRowInComponent:0]];
    
    NSString *geneURLStr = [@"http://api.brain-map.org/api/v2/data/SectionDataSet/query.json?criteria=products%5Bid$eq1%5D,genes%5Bacronym$eq%27" stringByAppendingString:[self.currentGene stringByAppendingString:@"%27%5D&include=genes,section_images"]];
    NSURL *geneURL = [NSURL URLWithString:geneURLStr];
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:geneURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response,
                                                           NSError * _Nullable error) {
        // Check for network error
        if (error) {
            NSString *msg = [NSString stringWithFormat:@"Error: Couldn't finish request: %@", error];
            [self loadFailed:msg];
            return;
        }
        
        // Check for http error
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *) response;
        if (httpResp.statusCode < 200 || httpResp.statusCode >= 300) {
            NSString *msg = [NSString stringWithFormat:@"Error: Got status code %ld", (long)httpResp.statusCode];
            [self loadFailed:msg];
            return;
        }
        
        //Check for JSON parse error
        NSError *parseErr;
        id pkg = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseErr];
        if (!pkg) {
            NSString *msg = [NSString stringWithFormat:@"Error: Couldn't parse response: %@", parseErr];
            [self loadFailed:msg];

            return;
        }
        
        //If all is good, parse sections from JSON and sort
        dispatch_async(dispatch_get_main_queue(), ^{
            self.coronalSections = [NSMutableArray array];
            self.sagittalSections = [NSMutableArray array];

            for (int i = 0; i<[pkg[@"msg"] count]; i++ ) {
                NSString *sectionTypeStr = pkg[@"msg"][i][@"plane_of_section_id"];
                NSInteger sectionType = [sectionTypeStr integerValue];
                for (int j = 0; j < [pkg[@"msg"][i][@"section_images"] count]; j++) {
                    NSString *experiment = pkg[@"msg"][i][@"section_images"][j][@"id"];
                    if (sectionType == 1) {
                        // "sectionType" 1 is coronal
                        [self.coronalSections addObject:experiment];
                    } else {
                        // "sectionType" 2 is sagittal
                        [self.sagittalSections addObject:experiment];
                    }
                }
            }

            //Disable segment controller options if there is no
            //sections for this gene
            
            if ([self.sagittalSections count]) {
                [self.sectionSegmentControl setEnabled:YES forSegmentAtIndex:0];
            } else {
                [self.sectionSegmentControl setEnabled:NO forSegmentAtIndex:0];
                [self.sectionSegmentControl setSelectedSegmentIndex:1];
            }
        
            if ([self.coronalSections count]) {
                [self.sectionSegmentControl setEnabled:YES forSegmentAtIndex:1];
            } else {
                [self.sectionSegmentControl setEnabled:NO forSegmentAtIndex:1];
                [self.sectionSegmentControl setSelectedSegmentIndex:0];

            }

            //Adjust stepper based on how many sections were found
            //then load image from there
            [self reloadSectionStepper];
            
        });
    }]resume];

}

- (void) reloadSectionStepper {
    
    dispatch_async(dispatch_get_main_queue(), ^{

        self.sectionStepper.value = 0;
    
        if (self.sectionSegmentControl.selectedSegmentIndex == 0) {
            self.sectionStepper.maximumValue = [self.sagittalSections count] -1;
        } else {
            self.sectionStepper.maximumValue = [self.coronalSections count] -1;
        }
    
        [self loadImage];
    });
}

- (void)loadImage {
    
     NSMutableString *sectionStr;
    
     if (self.sectionSegmentControl.selectedSegmentIndex == 1 && [self.coronalSections count]) {
         sectionStr = [NSMutableString stringWithFormat:@"%@", [self.coronalSections objectAtIndex:self.sectionStepper.value]];
     } else if ([self.sagittalSections count]) {
         sectionStr = [NSMutableString stringWithFormat:@"%@", [self.sagittalSections objectAtIndex:self.sectionStepper.value]];
     } else {
         [self loadFailed:@"No sections were found."];
     }
    
    
     NSString *imageURLStr = [@"http://api.brain-map.org/api/v2/section_image_download/" stringByAppendingString:[sectionStr stringByAppendingString:@"?downsample=4"]];

     NSURL *imageURL = [NSURL URLWithString:imageURLStr];
     NSURLSession *session = [NSURLSession sharedSession];
     [[session dataTaskWithURL:imageURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response,
     NSError * _Nullable error) {
     // Check for network error
     if (error) {
         NSString *msg = [NSString stringWithFormat:@"Error: Couldn't finish request: %@", error];
         [self loadFailed:msg];

         return;
     }
     
     // Check for http error
     NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *) response;
     if (httpResp.statusCode < 200 || httpResp.statusCode >= 300) {
         NSString *msg = [NSString stringWithFormat:@"Error: Got status code %ld", (long)httpResp.statusCode];
         [self loadFailed:msg];
         return;
     }
         
    
     dispatch_async(dispatch_get_main_queue(), ^{
         
         self.sectionViewer.image = [UIImage imageWithData:data];
         self.geneLabel.text = self.currentGene;
         self.loadImageSetButton.enabled = YES;
         self.sectionStepper.enabled = YES;
         self.sectionSegmentControl.enabled = YES;
         [self.activitySpinner stopAnimating];
         
     });
     }]resume];

}

- (void) loadFailed:(NSString*)msg {
    
    [self showAlertMessage:msg];
    self.loadImageSetButton.enabled = YES;
    [self.activitySpinner stopAnimating];
    
}

- (IBAction)loadImageSetPressed:(id)sender {
    
    self.loadImageSetButton.enabled = NO;
    self.sectionStepper.enabled = NO;
    self.sectionSegmentControl.enabled = NO;
    [self.activitySpinner startAnimating];
    
    [self loadExperimentsForGene];
    
}

- (IBAction)sectionTypeChanged:(id)sender {

    [self.activitySpinner startAnimating];
    [self reloadSectionStepper];

}

- (IBAction)sectionValueChanged:(id)sender {
    [self.activitySpinner startAnimating];
    [self loadImage];

}

- (void)panGestureDetected:(UIPanGestureRecognizer *)recognizer
{
    UIGestureRecognizerState state = [recognizer state];
    
    if (state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged)
    {
        CGPoint translation = [recognizer translationInView:recognizer.view];
        [recognizer.view setTransform:CGAffineTransformTranslate(recognizer.view.transform, translation.x, 0)];
        [recognizer setTranslation:CGPointZero inView:recognizer.view];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}



@end
