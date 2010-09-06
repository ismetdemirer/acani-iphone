//
//  LauncherItem.h
//  Lovers
//
//  Created by Matt Di Pasquale on 9/6/10.
//  Copyright 2010 Diamond Dynasties, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Profile;

@interface LauncherItem :  NSManagedObject  
{
}

@property (nonatomic, retain) Profile * profile;

@end



