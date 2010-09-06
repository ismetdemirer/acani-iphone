//
//  Photo.h
//  Lovers
//
//  Created by Matt Di Pasquale on 9/6/10.
//  Copyright 2010 Diamond Dynasties, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Profile;

@interface Photo :  NSManagedObject  
{
}

@property (nonatomic, retain) NSData * data;
@property (nonatomic, retain) NSString * md5;
@property (nonatomic, retain) NSSet* messages;
@property (nonatomic, retain) Profile * owner;

@end


@interface Photo (CoreDataGeneratedAccessors)
- (void)addMessagesObject:(NSManagedObject *)value;
- (void)removeMessagesObject:(NSManagedObject *)value;
- (void)addMessages:(NSSet *)value;
- (void)removeMessages:(NSSet *)value;

@end

