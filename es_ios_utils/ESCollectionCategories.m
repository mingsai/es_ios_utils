#import "ESCollectionCategories.h"
#import <objc/runtime.h>

@implementation ESCollectionCategories

@end


@implementation NSArray(ESUtils)

+(NSArray*)arrayByCoalescing:(id)first, ...
{
    NSMutableArray *a = [[[NSMutableArray alloc] init] autorelease];
    
    va_list args;
    va_start(args, first);
    for (id arg = first; arg != nil; arg = va_arg(args, id))
    {
        if([arg conformsToProtocol:@protocol(NSFastEnumeration)])
           for(id o in arg)
               [a addObject:o];//REFACTOR: pull up copying the whole of any fast enumerator to another
        else
            [a addObject:arg];
    }
    va_end(args);
    
    return [a.copy autorelease];
}

-(NSArray*)arrayByRemovingObject:(id)anObject
{
    NSMutableArray *a = [self.mutableCopy autorelease];
    [a removeObject:anObject];
    return a.copy;
}

-(NSArray*)arrayOfChildrenWithKeyPath:(NSString*)keyPath
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    for(NSObject *o in self)
    {
        id v = [o valueForKeyPath:keyPath];
        [result addObject:(v ? v : NSNull.null)];
    }
    return result;
}

-(NSArray*)arrayMappedWithFormat:(NSString*)format
{
    return [self arrayMappedWith:^id(id o) {
        return [NSString stringWithFormat:format, ((NSObject*)o).description];
    }];
}

-(NSArray*)arrayMappedWith:(id(^)(id))mapper
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
        
    for(NSObject *o in self)
    {
        id r = mapper(o);
        if(r)
            [result addObject:r];
        else
            NSLog(@"arrayMappedWith: returned nil for %@.", o);
    }
    
    return result;
}

-(NSArray*)filteredArrayWhereKeyPath:(NSString*)keyPath equals:(id)object;
{
    NSString *format = $format(@"%@ == %@", keyPath, @"%@");
    NSPredicate *pred = [NSPredicate predicateWithFormat:format, object];
    return [self filteredArrayUsingPredicate:pred];
}

-(NSArray*)reversed
{
    return self.reverseObjectEnumerator.allObjects;
}

-(id)firstObject
{
    if(self.count > 0)
        return [self objectAtIndex:0];
    return nil;
}

-(BOOL)isEmpty
{
    return self.count == 0;
}

-(BOOL)isNotEmpty
{
    return self.count > 0;
}

-(NSUInteger)lastIndex
{
    return self.count - 1;
}

-(NSArray*)filteredArrayUsingSet:(NSSet*)set
{
    NSMutableArray *a = [[[NSMutableArray alloc] initWithCapacity:set.count] autorelease];
    
    for(id o in self)
        if([set containsObject:o])
            [a addObject:o];
    
    return a.copy;
}

-(NSSet*)asSet
{
    return [NSSet setWithArray:self];
}

@end


@interface NSDictionary(ESUtilsPrivate)
    -(NSArray*)deepCopyArray:(NSArray*)a withKeyFilter:(NSString*(^)(NSString*))keyFilter;
    -(id)deepCopyObject:(id)o withKeyFilter:(NSString*(^)(NSString*))keyFilter;
@end

@implementation NSDictionary(ESUtilsPrivate)

-(NSArray*)deepCopyArray:(NSArray*)a withKeyFilter:(NSString*(^)(NSString*))keyFilter
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:a.count];
    for(id o in a)
        [result addObject:[self deepCopyObject:o withKeyFilter:keyFilter]];
    return result;
}

-(id)deepCopyObject:(id)o withKeyFilter:(NSString*(^)(NSString*))keyFilter
{
    if([o isKindOfClass:NSArray.class])
        return [self deepCopyArray:o withKeyFilter:keyFilter];
    else if([o isKindOfClass:NSDictionary.class])
        return [((NSDictionary*)o) asDeepCopyWithKeyFilter:keyFilter];
    else return o;
}

@end

@implementation NSDictionary(ESUtils)

-(NSDictionary*)asDeepCopy
{
    return [self asDeepCopyWithKeyFilter:nil];
}

-(NSDictionary*)asDeepCopyWithKeyFilter:(NSString*(^)(NSString*))keyFilter
{
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:self.count];
    [result addEntriesFromDictionary:self withKeyFilter:keyFilter];

    //copy subarrays and subdictionaries
    for(NSString *key in result.allKeys)
        [result setObject:[self deepCopyObject:[result objectForKey:key] withKeyFilter:keyFilter] forKey:key];
    
    return result;
}

-(BOOL)isEmpty
{
    return self.count == 0;
}

-(BOOL)isNotEmpty
{
    return self.count > 0;
}

-(BOOL)containsValueForKey:(NSString*)key
{
    id o = [self objectForKey:key];
    return true && o && ![o isKindOfClass:NSNull.class];
}

-(id)objectForKeyObject:(id)key;
{
    return [self objectForKey:[NSValue valueWithNonretainedObject:key]];
}

-(NSDictionary*)asCamelCaseKeysFromUnderscore
{
    return [self asDeepCopyWithKeyFilter:^NSString*(NSString *key){ return key.asCamelCaseFromUnderscore; }];
}

-(NSDictionary*)asUnderscoreKeysFromCamelCase
{
    return [self asDeepCopyWithKeyFilter:^NSString*(NSString *key){ return key.asUnderscoreFromCamelCase; }];
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


@implementation NSMutableDictionary(ESUtils)

-(void)setObject:(id)value forKeyObject:(id)key
{
    [self setObject:value forKey:[NSValue valueWithNonretainedObject:key]];
}

-(void)addEntriesFromDictionary:(NSDictionary*)d withKeyFilter:(NSString*(^)(NSString*))keyFilter
{
    if(!keyFilter)
        return [self addEntriesFromDictionary:d];
    
    for(NSString *key in d.allKeys)
        [self setObject:[d objectForKey:key] forKey:keyFilter(key)];
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

-(NSArray*)sortedArrayByKey:(NSString*)key ascending:(BOOL)ascending
{
    NSSortDescriptor *d = [[NSSortDescriptor alloc] initWithKey:key ascending:ascending];
    NSArray *result = [self sortedArrayUsingDescriptors:$array(d)];
    [d release];
    return result;
}

-(NSArray*)asArray
{
    return [NSArray arrayByCoalescing:self, nil];
}

@end