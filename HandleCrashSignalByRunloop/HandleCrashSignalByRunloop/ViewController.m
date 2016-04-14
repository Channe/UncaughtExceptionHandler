//
//  ViewController.m
//  HandleCrashSignalByRunloop
//
//  Created by QianLei on 16/4/13.
//  Copyright © 2016年 ichanne. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
- (IBAction)buttonPressed:(UIButton *)sender;
- (IBAction)button2Pressed:(UIButton *)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)buttonPressed:(UIButton *)sender {
    
//    [self performSelector:@selector(unExistMethod)];
    
    NSArray *arr = @[];
    NSLog(@"%@",arr[1]);
}

- (IBAction)button2Pressed:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"正常的按钮" message:@"一切正常了" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"继续" style:UIAlertActionStyleDefault
                                                     handler:^(UIAlertAction * action) {
                                                         //do something
                                                     }];
    [alert addAction:okAction];
    
    [self presentViewController:alert animated:YES completion:nil];
    
}
@end
