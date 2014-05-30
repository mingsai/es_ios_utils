#if IS_IOS

#import "ESBlockActionSheet.h"

@interface ESBlockActionSheet()
  @property(nonatomic, strong) NSMutableArray* buttonTitles;
  @property(nonatomic, strong) NSMutableArray* doOnPresses;
@end

@implementation ESBlockActionSheet

+(ESBlockActionSheet*)blockActionSheetWithTitle:(NSString*)title
{
    ESBlockActionSheet* sheet = [[ESBlockActionSheet alloc] init];
    sheet.title = title;
    
    return sheet;
}

+(ESBlockActionSheet*)blockActionSheetWithTitle:(NSString*)title
                                   cancelTitle:(NSString*)cancelTitle
                                    doOnCancel:(void (^)(void))doOnCancel
{
    ESBlockActionSheet* sheet = [self blockActionSheetWithTitle:title];
    sheet.cancelTitle = cancelTitle;
    sheet.doOnCancel = doOnCancel;
    
    return sheet;
}

+(ESBlockActionSheet*)blockActionSheetWithTitle:(NSString*)title
                                    cancelTitle:(NSString*)cancelTitle
                                     doOnCancel:(void(^)(void))doOnCancel
                                   destroyTitle:(NSString*)destroyTitle
                                    doOnDestroy:(void(^)(void))doOnDestroy
{
    ESBlockActionSheet* sheet = [self blockActionSheetWithTitle:title cancelTitle:cancelTitle doOnCancel:doOnCancel];
    sheet.destroyTitle = destroyTitle;
    sheet.doOnDestroy = doOnDestroy;
    
    return sheet;
}

+(ESBlockActionSheet*)blockActionSheetWithTitle:(NSString*)title
                                   destroyTitle:(NSString*)destroyTitle
                                    doOnDestroy:(void(^)(void))doOnDestroy
{
    return [self blockActionSheetWithTitle:title cancelTitle:nil doOnCancel:nil destroyTitle:destroyTitle doOnDestroy:doOnDestroy];
}

- (id)init
{
    self.doOnPresses  = [NSMutableArray arrayWithCapacity:10];
    self.buttonTitles = [NSMutableArray arrayWithCapacity:10];
    
    return self;
}

#pragma mark Properties
@synthesize sheet, title, cancelTitle, destroyTitle, doOnCancel, doOnClose, doOnDestroy, buttonTitles, doOnPresses;

-(void)addButtonWithTitle:(NSString*)buttonTitle doOnPress:(void(^)(void))doOnPress
{
    if(self.sheet)
        return;
    [self.buttonTitles addObject:buttonTitle];
    [self.doOnPresses addObject:doOnPress?(id)[doOnPress copy]:NSNull.null];
}

#pragma mark Control

//Once this is called, the action sheet becomes static.
-(IBAction)buildSheet
{
    if(!self.sheet)
    {
        self.sheet = [[UIActionSheet alloc] init];
        self.sheet.title = title;
        self.sheet.delegate = self;
        
        if(self.destroyTitle)
        {
            [self.sheet addButtonWithTitle:destroyTitle];
            self.sheet.destructiveButtonIndex = sheet.numberOfButtons-1;
            [self.doOnPresses insertObject:self.doOnDestroy?(id)self.doOnDestroy:NSNull.null atIndex:0];
        }
        
        if(self.buttonTitles)
            for(NSString *buttonTitle in self.buttonTitles)
                [self.sheet addButtonWithTitle:buttonTitle];
        
        if(self.cancelTitle)
        {
            [self.sheet addButtonWithTitle:self.cancelTitle];
            self.sheet.cancelButtonIndex = sheet.numberOfButtons-1;
            [self.doOnPresses addObject:self.doOnCancel?(id)self.doOnCancel:NSNull.null];
        }
    }
}

-(IBAction)presentIn:(UIViewController*)controller
{
    [self buildSheet];
    [self.sheet showInView:controller.view];
}

-(IBAction)presentIn:(UIView*)view fromRect:(CGRect)from
{
    [self buildSheet];
    [self.sheet showFromRect:from inView:view animated:YES];
}

-(IBAction)presentFromBarButtonItem:(UIBarButtonItem*)item
{
    [self buildSheet];
    [self.sheet showFromBarButtonItem:item animated:YES];
}

-(IBAction)dismissWithAnimation:(BOOL)animate
{
    [self.sheet dismissWithClickedButtonIndex:-1 animated:animate];
}

-(IBAction)dismiss
{
    [self dismissWithAnimation:YES];
}

#pragma mark Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if([self.doOnPresses isIndexInRange:buttonIndex])//filter out cancel
    {
        __block ESBlockActionSheet *bself = self;
        void(^actionBlock)(void) = (bself.doOnPresses)[buttonIndex];
        if(actionBlock && (id)actionBlock != NSNull.null)
            actionBlock();
    }
    if(self.doOnClose)
        self.doOnClose();
}

@end

#endif /*IS_IOS*/