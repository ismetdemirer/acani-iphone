//
//  Message.h
//  Lovers
//
//  Created by Matt Di Pasquale on 9/6/10.
//  Copyright 2010 Diamond Dynasties, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Channel;
@class Photo;
@class Profile;

@interface Message :  NSManagedObject  
{
}

@property (nonatomic, retain) NSDate * dateSent;
@property (nonatomic, retain) NSNumber * unread;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) Profile * source;
@property (nonatomic, retain) Channel * channel;
@property (nonatomic, retain) NSSet* targets;
@property (nonatomic, retain) Photo * photo;

@end


@interface Message (CoreDataGeneratedAccessors)
- (void)addTargetsObject:(Profile *)value;
- (void)removeTargetsObject:(Profile *)value;
- (void)addTargets:(NSSet *)value;
- (void)removeTargets:(NSSet *)value;

@end

