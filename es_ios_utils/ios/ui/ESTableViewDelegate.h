#import <Foundation/Foundation.h>

@protocol ESTableViewDelegate<NSObject>
  #pragma mark - Data
    @required
      -(id)objectFor:(NSIndexPath*)ip;
      -(NSInteger)numberOfRowsInSection:(NSInteger)s;
    @optional
      // Either sectionTitles or numberOfSections and titleForSection must be implemented
      -(NSArray*)sectionTitles;
      -(int)numberOfSections;
      -(NSString*)titleForSection:(NSInteger)s;

  #pragma mark - View
    @required
      -(UITableViewCell*)createCell;
      -(void)updateCell:(UITableViewCell*)c for:(id)o;
    @optional
      -(float)heightForSelectedState;

  #pragma mark - Events
    @optional
      -(void)didSelectRowAt:(NSIndexPath*)ip;
      -(void)didSelectRowAt:(NSIndexPath*)ip for:(id)o;
      -(void)didDeselectRowAt:(NSIndexPath*)indexPath;
@end
