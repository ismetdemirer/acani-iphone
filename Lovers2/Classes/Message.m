#import "Message.h"
#import "SBJSON.h"

@implementation Message

@synthesize channel;
@synthesize timestamp;
@synthesize text;

- (void)dealloc {
    [channel release];
    [text release];
	// how do we dealloc timestamp (time_t)?
	[super dealloc];
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    if (self = [super init]) {
		self.channel   = [dictionary valueForKey:@"channel"];
		self.timestamp = (time_t)[dictionary valueForKey:@"timestamp"];
		self.text      = [dictionary valueForKey:@"content"];
    }
    return self;
}

@end
