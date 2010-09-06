//
//  Profile.h
//  Lovers
//
//  Created by Matt Di Pasquale on 9/6/10.
//  Copyright 2010 Diamond Dynasties, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface Profile :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * about;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet* photos;
@property (nonatomic, retain) NSSet* sentMessages;
@property (nonatomic, retain) NSSet* channels;
@property (nonatomic, retain) NSSet* receivedMessages;
@property (nonatomic, retain) NSManagedObject * picture;
@property (nonatomic, retain) NSManagedObject * launcherItem;

@end


@interface Profile (CoreDataGeneratedAccessors)
- (void)addPhotosObject:(NSManagedObject *)value;
- (void)removePhotosObject:(NSManagedObject *)value;
- (void)addPhotos:(NSSet *)value;
- (void)removePhotos:(NSSet *)value;

- (void)addSentMessagesObject:(NSManagedObject *)value;
- (void)removeSentMessagesObject:(NSManagedObject *)value;
- (void)addSentMessages:(NSSet *)value;
- (void)removeSentMessages:(NSSet *)value;

- (void)addChannelsObject:(NSManagedObject *)value;
- (void)removeChannelsObject:(NSManagedObject *)value;
- (void)addChannels:(NSSet *)value;
- (void)removeChannels:(NSSet *)value;

- (void)addReceivedMessagesObject:(NSManagedObject *)value;
- (void)removeReceivedMessagesObject:(NSManagedObject *)value;
- (void)addReceivedMessages:(NSSet *)value;
- (void)removeReceivedMessages:(NSSet *)value;

@end

