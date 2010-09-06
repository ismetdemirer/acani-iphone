//
//  Picture.h
//  Lovers
//
//  Created by Matt Di Pasquale on 9/6/10.
//  Copyright 2010 Diamond Dynasties, Inc. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "Photo.h"

@class Profile;

@interface Picture :  Photo  
{
}

@property (nonatomic, retain) NSManagedObject * thumb;
@property (nonatomic, retain) NSManagedObject * tiny;
@property (nonatomic, retain) Profile * profile;

@end



