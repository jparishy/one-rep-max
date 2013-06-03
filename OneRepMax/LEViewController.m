//
//  LEViewController.m
//  OneRepMax
//
//  Created by Julius Parishy on 6/1/13.
//  Copyright (c) 2013 Lonely Ether Software. All rights reserved.
//

#import "LEViewController.h"

#import <QuartzCore/QuartzCore.h>

#define LERepsString (@" reps")

typedef enum LEWeightUnit
{
    LEWeightUnitPounds,
    LEWeightUnitKilograms
} LEWeightUnit;

@interface LEViewController () <UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UILabel *subtitleLabel;

@property (nonatomic, strong) IBOutlet UILabel *repsLabel;
@property (nonatomic, strong) IBOutlet UILabel *unitLabel;

@property (nonatomic, strong) IBOutlet UITextField *repsTextField;
@property (nonatomic, strong) IBOutlet UITextField *weightTextField;

@property (nonatomic, strong) IBOutlet UIView *resultsContainerView;
@property (nonatomic, strong) IBOutlet UILabel *resultsLabel;

@property (nonatomic, strong) IBOutlet UILabel *instructionsLabel;

@property (nonatomic, assign) CGPoint onscreenResultsContainerPosition;
@property (nonatomic, assign) BOOL resultsContainerPresentlyOnscreen;

-(void)configureLabelFonts;
-(void)configureTextFieldFonts;

-(void)configureResultsViews;

-(NSInteger)calculateOneRepMaxWithRepititions:(NSInteger)repititions weight:(NSInteger)weight unit:(LEWeightUnit)unit;

-(void)updateResultsLabel;

-(void)subscribeToTextFieldEvents;
-(void)textFieldValueDidChange:(UITextField *)textField;

-(void)updateResultsContainerPosition:(BOOL)animated;

@end

@implementation LEViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self subscribeToTextFieldEvents];

    [self configureLabelFonts];
    [self configureTextFieldFonts];
    
    [self configureResultsViews];
    
    self.onscreenResultsContainerPosition = self.resultsContainerView.frame.origin;
    self.resultsContainerPresentlyOnscreen = YES;
    
    self.resultsContainerView.hidden = YES;
    [self updateResultsContainerPosition:NO];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.repsTextField becomeFirstResponder];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    __weak LEViewController *weakSelf = self;
    double delayInSeconds = 0.5f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        
        __strong LEViewController *self = weakSelf;
        self.resultsContainerView.hidden = NO;
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)subscribeToTextFieldEvents
{
    [self.repsTextField addTarget:self action:@selector(textFieldValueDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.weightTextField addTarget:self action:@selector(textFieldValueDidChange:) forControlEvents:UIControlEventEditingChanged];
}

-(void)textFieldValueDidChange:(UITextField *)textField
{
    [self updateResultsLabel];
    [self updateResultsContainerPosition:YES];
}

-(void)configureLabelFonts
{
    void(^adjustLabel)(UILabel *, NSString *) = ^(UILabel *label, NSString *fontName) {
    
        CGFloat fontSize = label.font.pointSize;
        UIFont *font = [UIFont fontWithName:fontName size:fontSize];
        label.font = font;
    };
    
    adjustLabel(self.titleLabel, LEStyleFontCondensed);
    adjustLabel(self.subtitleLabel, LEStyleFontRegular);
    
    adjustLabel(self.repsLabel, LEStyleFontCondensed);
    adjustLabel(self.unitLabel, LEStyleFontCondensed);
    
    adjustLabel(self.resultsLabel, LEStyleFontSemibold);
    
    adjustLabel(self.instructionsLabel, LEStyleFontCondensed);
}

-(void)configureTextFieldFonts
{
    void(^adjustTextField)(UITextField *, NSString *) = ^(UITextField *textField, NSString *fontName) {
    
        CGFloat fontSize = textField.font.pointSize;
        UIFont *font = [UIFont fontWithName:fontName size:fontSize];
        textField.font = font;
    };
    
    adjustTextField(self.repsTextField, LEStyleFontSemibold);
    adjustTextField(self.weightTextField, LEStyleFontSemibold);
}

-(void)configureResultsViews
{
    self.resultsContainerView.layer.cornerRadius = 3.0f;
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if(string.length == 0)
        return YES;
 
    for(NSInteger i = 0; i < string.length; ++i)
    {
        if(!isdigit([string characterAtIndex:i]))
        {
            return NO;
        }
    }
    
    return YES;
}

-(NSInteger)calculateOneRepMaxWithRepititions:(NSInteger)repititions weight:(NSInteger)weight unit:(LEWeightUnit)unit
{
    if(repititions == 0 || weight == 0)
        return 0;
    
    const NSInteger coefficientsCount = 12;
    CGFloat coefficients[coefficientsCount] = {
        1.0f,
        0.95f,
        0.90f,
        0.88f,
        0.86f,
        0.83f,
        0.80f,
        0.78f,
        0.76f,
        0.75f,
        0.72f,
        0.70f
    };
    
    NSInteger boundedRepitions = repititions;
    boundedRepitions = MAX(0, boundedRepitions);
    boundedRepitions = MIN(coefficientsCount, boundedRepitions);
    
    NSInteger index = boundedRepitions - 1;
    CGFloat coefficient = coefficients[index];
    
    NSInteger oneRepMax = (NSInteger)((CGFloat)weight * (1.0f / coefficient));
    return oneRepMax;
}

-(void)updateResultsLabel
{
    NSInteger repititions = self.repsTextField.text.integerValue;
    NSInteger weight      = self.weightTextField.text.integerValue;
    
    LEWeightUnit unit = LEWeightUnitPounds;
    NSInteger oneRepMax = [self calculateOneRepMaxWithRepititions:repititions weight:weight unit:unit];

    NSString *unitString = unit == LEWeightUnitPounds ? @"lbs" : @"kgs";
    NSString *text = [NSString stringWithFormat:@"%d%@", oneRepMax, unitString];
    
    self.resultsLabel.text = text;
}

-(void)updateResultsContainerPosition:(BOOL)animated
{
    BOOL onscreen = (self.repsTextField.text.length > 0) && (self.weightTextField.text.length > 0);
    if(onscreen == self.resultsContainerPresentlyOnscreen)
        return;
    
    CGPoint landingPosition = CGPointZero;
    CGFloat instructionsAlpha = 0.0f;
    
    if(onscreen)
    {
        landingPosition = self.onscreenResultsContainerPosition;
        instructionsAlpha = 0.0f;
    }
    else
    {
        CGPoint position = self.onscreenResultsContainerPosition;
        position.y += 100.0f;
        
        landingPosition = position;
        
        instructionsAlpha = 1.0f;
    }
    
    void(^changes)() = ^{
    
        CGRect frame = self.resultsContainerView.frame;
        frame.origin = landingPosition;
        self.resultsContainerView.frame = frame;
        
        self.instructionsLabel.alpha = instructionsAlpha;
    };
    
    if(animated)
    {
        [UIView animateWithDuration:0.25f animations:^{
    
            changes();
        }];
    }
    else
    {
        changes();
    }
    
    self.resultsContainerPresentlyOnscreen = onscreen;
}

@end
