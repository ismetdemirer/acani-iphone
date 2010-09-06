//
//  Group.h
//  Lovers
//
//  Created by Matt Di Pasquale on 9/6/10.
//  Copyright 2010 Diamond Dynasties, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "Profile.h"

@class User;

@interface Group :  Profile  
{
}

@property (nonatomic, retain) NSManagedObject * superGroup;
@property (nonatomic, retain) NSSet* members;
@property (nonatomic, retain) NSSet* subGroups;

@end


@interface Group (CoreDataGeneratedAccessors)
- (void)addMembersObject:(User *)value;
- (void)removeMembersObject:(User *)value;
- (void)addMembers:(NSSet *)value;
- (void)removeMembers:(NSSet *)value;

- (void)addSubGroupsObject:(NSManagedObject *)value;
- (void)removeSubGroupsObject:(NSManagedObject *)value;
- (void)addSubGroups:(NSSet *)value;
- (void)removeSubGroups:(NSSet *)value;

@end

