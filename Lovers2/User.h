//
//  User.h
//  Lovers
//
//  Created by Matt Di Pasquale on 9/6/10.
//  Copyright 2010 Diamond Dynasties, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "Profile.h"


@interface User :  Profile  
{
}

@property (nonatomic, retain) NSNumber * weight;
@property (nonatomic, retain) NSString * sex;
@property (nonatomic, retain) NSDate * updated;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSString * fbLink;
@property (nonatomic, retain) NSString * onlineStatus;
@property (nonatomic, retain) NSString * head;
@property (nonatomic, retain) NSString * ethnic;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSNumber * age;
@property (nonatomic, retain) NSDate * lastOn;
@property (nonatomic, retain) NSNumber * fbid;
@property (nonatomic, retain) NSDate * created;
@property (nonatomic, retain) NSManagedObject * account;
@property (nonatomic, retain) NSManagedObject * location;
@property (nonatomic, retain) NSSet* groups;

@end


@interface User (CoreDataGeneratedAccessors)
- (void)addGroupsObject:(NSManagedObject *)value;
- (void)removeGroupsObject:(NSManagedObject *)value;
- (void)addGroups:(NSSet *)value;
- (void)removeGroups:(NSSet *)value;

@end

