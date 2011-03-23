//
//  NSCategories.m
//  es_ios_utils
//
//  Created by Peter DeWeese on 3/16/11.
//  Copyright 2011 Eye Street Research, LLC. All rights reserved.
//

#import "ESNSCategories.h"


@implementation ESNSCategories

@end


@implementation NSArray(ESUtils)

-(id)firstObject
{
    return [self objectAtIndex:0];
}

-(BOOL)isEmpty
{
    return self.count == 0;
}

-(BOOL)isNotEmpty
{
    return self.count > 0;
}

@end


@implementation NSDictionary(ESUtils)

-(BOOL)isEmpty
{
    return self.count == 0;
}

-(BOOL)isNotEmpty
{
    return self.count > 0;
}

@end


@implementation NSError(ESUtils)

-(void)log
{
    NSLog(@"%@, %@", self, self.userInfo);
}

-(void)logWithMessage:(NSString*)message
{
    NSLog(@"%@ %@, %@", message, self, self.userInfo);
}

@end


@implementation NSFetchedResultsController(ESUtils)

-(NSManagedObject*)createManagedObject
{
    return (NSManagedObject*)[self.managedObjectContext createManagedObjectNamed:self.fetchRequest.entity.name];
}

@end


@implementation NSManagedObject(ESUtils)

//  Created by Scott Means on 1/5/11.
//  http://smeans.com/2011/01/07/exporting-from-core-data-on-ios/
//  Released into the public domain without warranty.
//  TODO: a libxml or nsxml implementation may be more appropriate.
//  Modified to include one-to-one relationships and to prevent inverses causing circular references.
- (NSString *)xmlString:(NSMutableSet*)referenced
{
    if([referenced containsObject:self])
        return [NSString string];
    else
        [referenced addObject:self];
    
    NSEntityDescription *ed = self.entity;
    NSURL *uri = self.objectID.URIRepresentation;
    NSMutableString *x = [NSMutableString stringWithFormat:@"<%@ id=\"/%@%@\"",
                          ed.name.lowercaseString, uri.host, uri.path];
    
    for (NSString *a in ed.attributesByName.allKeys)
    {
        id value = [self valueForKey:a];
        
        if (value)
        {
            if ([value isKindOfClass:NSString.class])
                [x appendFormat:@" %@=\"%@\"", a, value];
            else
            {
                if (![value respondsToSelector:@selector(stringValue)])
                    NSLog(@"no stringValue");

                [x appendFormat:@" %@=\"%@\"", a, [value stringValue]];
            }
        }
    }
    
    bool hasChildren = ed.relationshipsByName.isNotEmpty;

    [x appendString:hasChildren ? @">" : @"/>"];
    
    for (NSString *r in ed.relationshipsByName)
    {
        NSRelationshipDescription *rd = [ed.relationshipsByName objectForKey:r];

        if(rd.isToMany)
        {
            hasChildren = YES;
            [x appendFormat:@"<%@>", r];
            
            for (NSManagedObject *c in [self valueForKey:r])
                [x appendString:[c xmlString:referenced]];
            
            [x appendFormat:@"", r];
        }
        else
        {
            hasChildren = YES;
            NSManagedObject *c = [self valueForKey:r];
            [x appendString:[c xmlString:referenced]];
        }
    }
    
    if (hasChildren)
        [x appendFormat:@"</%@>", ed.name.lowercaseString];
    
    return x;
}

//Prevents circular dependencies.
- (NSString*)xmlString
{
    return [self xmlString:[[[NSMutableSet alloc] init] autorelease]];
}

@end


@implementation NSManagedObjectContext(ESUtils)

-(NSManagedObject*)createManagedObjectNamed:(NSString*)name
{
    // Create a new instance of the entity managed by the fetched results controller.
    return [NSEntityDescription insertNewObjectForEntityForName:name inManagedObjectContext:self];
}

-(BOOL)saveAndDoOnError:(ErrorBlock)doOnError
{
    NSError *error;
    BOOL result = [self save:&error];
    
    if (!result)
        doOnError(error);

    return result;
}

@end


@implementation NSMutableArray(ESUtils)

- (id)dequeue
{
    if(self.count == 0)
        return nil;
    
    id object = [self objectAtIndex:0];
    [self removeObjectAtIndex:0];
    return object;
}

- (id)pop
{
    if(self.count == 0)
        return nil;
    
    id object = [self lastObject];
    [self removeLastObject];
    return object;
}

@end


@implementation NSNull(ESUtils)

-(BOOL)isEmpty
{
    return YES;
}

-(BOOL)isNotEmpty
{
    return NO;
}

@end


@implementation NSSet(ESUtils)

-(BOOL)isEmpty
{
    return self.count == 0;
}

-(BOOL)isNotEmpty
{
    return self.count > 0;
}

@end


@implementation NSString(ESUtils)

-(NSData*)dataWithUTF8
{
    return [self dataUsingEncoding:NSUTF8StringEncoding];
}

-(NSString*)strip
{
    return [self stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
}

-(BOOL)isEmpty
{
    return self.length == 0;
}

-(BOOL)isNotEmpty
{
    return self.length > 0;
}

-(BOOL)isBlank
{
    return self.isEmpty || self.strip.isEmpty;
}

@end
