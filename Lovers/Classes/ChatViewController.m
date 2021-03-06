#import "ChatViewController.h"
#import "LoversAppDelegate.h"
#import "Message.h"
#import "User.h"
#import "Constants.h"
#include <time.h>
#import <QuartzCore/QuartzCore.h>
#import "ZTWebSocket.h"
#import "SBJSON.h"

#define MAINLABEL	((UILabel *)self.navigationItem.titleView)

#define CHAT_BAR_HEIGHT_1	40.0f
#define CHAT_BAR_HEIGHT_4	94.0f
#define VIEW_WIDTH	self.view.frame.size.width
#define VIEW_HEIGHT	self.view.frame.size.height

#define RESET_CHAT_BAR_HEIGHT	SET_CHAT_BAR_HEIGHT(CHAT_BAR_HEIGHT_1)
#define EXPAND_CHAT_BAR_HEIGHT	SET_CHAT_BAR_HEIGHT(CHAT_BAR_HEIGHT_4)
#define	SET_CHAT_BAR_HEIGHT(HEIGHT) \
	CGRect chatContentFrame = chatContent.frame; \
	chatContentFrame.size.height = VIEW_HEIGHT - HEIGHT; \
	[UIView beginAnimations:nil context:NULL]; \
	[UIView setAnimationDuration:0.1f]; \
	chatContent.frame = chatContentFrame; \
	chatBar.frame = CGRectMake(chatBar.frame.origin.x, chatContentFrame.size.height, VIEW_WIDTH, HEIGHT); \
	[UIView commitAnimations]; \

#define ENABLE_SEND_BUTTON	SET_SEND_BUTTON(YES, 1.0f)
#define DISABLE_SEND_BUTTON	SET_SEND_BUTTON(NO, 0.5f)
#define SET_SEND_BUTTON(ENABLED, ALPHA) \
	sendButton.enabled = ENABLED; \
	sendButton.titleLabel.alpha = ALPHA

@implementation ChatViewController

@synthesize channel;
@synthesize messages;
@synthesize latestTimestamp;

@synthesize chatContent;

@synthesize chatBar;
@synthesize chatInput;
@synthesize lastContentHeight;
@synthesize chatInputHadText;
@synthesize sendButton;


#pragma mark -
#pragma mark Initialization

//- (id)initWithStyle:(UITableViewStyle)style {
//    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
//    if ((self = [super initWithStyle:style])) {
//    }
//    return self;
//}


- (void)done:(id)sender {
	[chatInput resignFirstResponder]; // temporary
	RESET_CHAT_BAR_HEIGHT;
	self.navigationItem.rightBarButtonItem = nil;
}

// Reveal a Done button when editing starts
- (void)textViewDidBeginEditing:(UITextView *)textView {
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
								   initWithTitle:@"Done" style:UIBarButtonItemStyleDone
								   target:self action:@selector(done:)];
	self.navigationItem.rightBarButtonItem = doneButton;
	[doneButton release];
}

- (void)textViewDidChange:(UITextView *)textView {
	CGFloat contentHeight = textView.contentSize.height - 12.0f;

	NSLog(@"contentOffset: (%f, %f)", textView.contentOffset.x, textView.contentOffset.y);
	NSLog(@"contentInset: %f, %f, %f, %f", textView.contentInset.top, textView.contentInset.right, textView.contentInset.bottom, textView.contentInset.left);
	NSLog(@"contentSize.height: %f", contentHeight);

	if ([textView hasText]) {
		if (!chatInputHadText) {
			ENABLE_SEND_BUTTON;
			chatInputHadText = YES;
		}

		if (textView.text.length > 1024) { // truncate text to 1024 chars
			textView.text = [textView.text substringToIndex:1024];
		}

		// Resize textView to contentHeight
		if (contentHeight != lastContentHeight) {
			if (contentHeight <= 76.0f) { // Limit chatInputHeight <= 4 lines
				CGFloat chatBarHeight = contentHeight + 18.0f;
				SET_CHAT_BAR_HEIGHT(chatBarHeight);
				if (lastContentHeight > 76.0f) {
					textView.scrollEnabled = NO;
				}
				textView.contentOffset = CGPointMake(0.0f, 6.0f); // fix quirk
			} else if (lastContentHeight <= 76.0f) { // grow
				textView.scrollEnabled = YES;
				textView.contentOffset = CGPointMake(0.0f, contentHeight-68.0f); // shift to bottom
				if (lastContentHeight < 76.0f) {
					EXPAND_CHAT_BAR_HEIGHT;
				}
			}
		}	
	} else { // textView is empty
		if (chatInputHadText) {
			DISABLE_SEND_BUTTON;
			chatInputHadText = NO;
		}
		if (lastContentHeight > 22.0f) {
			RESET_CHAT_BAR_HEIGHT;
			if (lastContentHeight > 76.0f) {
				textView.scrollEnabled = NO;
			}
		}		
		textView.contentOffset = CGPointMake(0.0f, 6.0f); // fix quirk			
	}
	lastContentHeight = contentHeight;
}

// This fixes a scrolling quirk
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
	textView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 3.0f, 0.0f);
	return YES;
}

// Prepare to resize for keyboard
- (void)keyboardWillShow:(NSNotification *)notification {
//	NSDictionary *userInfo = [notification userInfo];
//	CGRect bounds;
//	[(NSValue *)[userInfo objectForKey:UIKeyboardBoundsUserInfoKey] getValue:&bounds];
	
//	// Resize text view
//	CGRect aFrame = chatInput.frame;
//	aFrame.size.height -= bounds.size.height;
//	chatInput.frame = aFrame;

	[self slideFrameUp];
	// These methods can do better.
	// They should check for version of iPhone OS.
	// And use appropriate methods to determine:
	//   animation movement, speed, duration, etc.
}

// Expand textview on keyboard dismissal
- (void)keyboardWillHide:(NSNotification *)notification {
//	NSDictionary *userInfo = [notification userInfo];
//	CGRect bounds;
//	[(NSValue *)[userInfo objectForKey:UIKeyboardBoundsUserInfoKey] getValue:&bounds];

	[self slideFrameDown];
}


#pragma mark -
#pragma mark View lifecycle

- (void)loadView {
	NSLog(@"channel: %@", channel);
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
	self.navigationController.navigationBar.translucent = NO;
	self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
	self.navigationController.navigationBar.tintColor = ACANI_RED;

	// Fetch messages.
	NSManagedObjectContext *managedObjectContext = [(LoversAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];

	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Message" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"channel == %@", channel];
	[request setPredicate:predicate];

	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	[sortDescriptors release];
	[sortDescriptor release];

	NSError *error;
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil) {
		// Handle the error.
	}
	
	[self setMessages:mutableFetchResults];
	[mutableFetchResults release];
	[request release];

	// Create contentView.
	CGRect navFrame = [[UIScreen mainScreen] applicationFrame];
	navFrame.size.height -= self.navigationController.navigationBar.frame.size.height;
	UIView *contentView = [[UIView alloc] initWithFrame:navFrame];
	contentView.backgroundColor = CHAT_BACKGROUND_COLOR; // shown during rotation

	// Create chatContent.
	UITableView *tempChatContent = [[UITableView alloc] initWithFrame:
					   CGRectMake(0.0f, 0.0f, contentView.frame.size.width,
								  contentView.frame.size.height - CHAT_BAR_HEIGHT_1)];
	self.chatContent = tempChatContent;
	[tempChatContent release];
	chatContent.clearsContextBeforeDrawing = NO;
	chatContent.delegate = self;
	chatContent.dataSource = self;
	chatContent.backgroundColor = CHAT_BACKGROUND_COLOR;
	chatContent.separatorStyle = UITableViewCellSeparatorStyleNone;
	chatContent.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[contentView addSubview:chatContent];

	// Create chatBar.
	UIImageView *tempChatBar = [[UIImageView alloc] initWithFrame:
				   CGRectMake(0.0f, contentView.frame.size.height - CHAT_BAR_HEIGHT_1,
							  contentView.frame.size.width, CHAT_BAR_HEIGHT_1)];
	self.chatBar = tempChatBar;
	[tempChatBar release];
	chatBar.clearsContextBeforeDrawing = NO;
	chatBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
	chatBar.image = [[UIImage imageNamed:@"ChatBar.png"] stretchableImageWithLeftCapWidth:18 topCapHeight:20];
	chatBar.userInteractionEnabled = YES;

	// Create chatInput.
	UITextView *tempChatInput = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 10.0f, 234.0f, 22.0f)];
	self.chatInput = tempChatInput;
	[tempChatInput release];
	chatInput.contentSize = CGSizeMake(234.0f, 22.0f);
	chatInput.delegate = self;
	chatInput.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	chatInput.scrollEnabled = NO; // not initially
	chatInput.scrollIndicatorInsets = UIEdgeInsetsMake(5.0f, 0.0f, 4.0f, -2.0f);
	chatInput.clearsContextBeforeDrawing = NO;
	chatInput.font = [UIFont systemFontOfSize:14.0];
	chatInput.dataDetectorTypes = UIDataDetectorTypeAll;
	chatInput.backgroundColor = [UIColor clearColor];
	lastContentHeight = chatInput.contentSize.height;
	chatInputHadText = NO;
	[chatBar addSubview:chatInput];

	// Create sendButton.
	self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
	sendButton.clearsContextBeforeDrawing = NO;
	sendButton.frame = CGRectMake(chatBar.frame.size.width - 70.0f, 8.0f, 64.0f, 26.0f);  // multi-line input & landscape (below)
	sendButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
	UIImage *sendButtonBackground = [UIImage imageNamed:@"SendButton.png"];
	[sendButton setBackgroundImage:sendButtonBackground forState:UIControlStateNormal];
	[sendButton setBackgroundImage:sendButtonBackground forState:UIControlStateDisabled];	
	sendButton.titleLabel.font = [UIFont boldSystemFontOfSize: 16];
	sendButton.backgroundColor = [UIColor clearColor];
	[sendButton setTitle:@"Send" forState:UIControlStateNormal];
	[sendButton addTarget:self action:@selector(sendMSG:) forControlEvents:UIControlEventTouchUpInside];
//	sendButton.layer.cornerRadius = 13; // not necessary now that we'are using background image
//	sendButton.clipsToBounds = YES; // not necessary now that we'are using background image
	DISABLE_SEND_BUTTON; // initially
	[chatBar addSubview:sendButton];

	[contentView addSubview:chatBar];
	[contentView sendSubviewToBack:chatBar];

	self.view = contentView;
	[contentView release];
}


- (void)viewDidLoad {
	[super viewDidLoad];
 
	// Listen for keyboard.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

 // Uncomment the following line to preserve selection between presentations.
 // self.clearsSelectionOnViewWillAppear = NO;
 
 // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
 // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


/*
 - (void)viewWillAppear:(BOOL)animated {
 [super viewWillAppear:animated];
 }
 */

//// This causes exception if there are no cells.
//// Also, I want it to work like iPhone Messages.
//- (void)viewDidAppear:(BOOL)animated {
//	[super viewDidAppear:animated];
//	[self scrollToBottomAnimated:YES]; 
//}


- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
	self.navigationController.navigationBar.tintColor = nil;
}

/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
//	return (interfaceOrientation == UIInterfaceOrientationPortrait);
	return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)sendMSG:(id)sender {
	ZTWebSocket *webSocket = [(LoversAppDelegate *)[[UIApplication sharedApplication] delegate] webSocket];
	if (![webSocket connected]) {
		NSLog(@"Cannot send message, not connected");
		return;
	} 

	// This is not really necessary since we disable the
	// "Send" button unless the chatInput has text.
	if (![chatInput hasText]) {
		NSLog(@"Cannot send message, no text");
		return;
	}
	
	NSManagedObjectContext *managedObjectContext = [(LoversAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
	Message *msg = (Message *)[NSEntityDescription insertNewObjectForEntityForName:@"Message" inManagedObjectContext:managedObjectContext];
	[msg setText:chatInput.text];
	[msg setSender:(Profile *)[[(LoversAppDelegate *)[[UIApplication sharedApplication] delegate] myAccount] user]];
	[msg setChannel:channel];
	time_t now; time(&now);
	latestTimestamp = now;
	[msg setTimestamp:[NSNumber numberWithLong:now]];

//	[activityIndicator startAnimating];
	
	NSString *escapedMsg = [[[[msg text] // escape chars: \ " \n
							  stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"]
							 stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""]
							stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
	NSLog(@"escapedMSG: %@", escapedMsg);
	
	NSString *msgJson = [NSString stringWithFormat:
						 @"{\"timestamp\":%@,\"channel\":\"%@\",\"sender\":\"%@\",\"text\":\"%@\",\"to_uid_public\":\"bob\"}",
						 [msg timestamp], [msg channel], [(User *)[msg sender] uid], escapedMsg];
	[webSocket send:msgJson];

	chatInput.text = @"";
	if (lastContentHeight > 22.0f) {
		RESET_CHAT_BAR_HEIGHT;
		chatInput.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 3.0f, 0.0f);
		chatInput.contentOffset = CGPointMake(0.0f, 6.0f); // fix quirk			
	}		

	NSError *error;
	if (![managedObjectContext save:&error]) {
		// Handle the error.
	}
	
	[messages addObject:msg];
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[messages count]-1 inSection:0];
	[chatContent insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
						  withRowAnimation:UITableViewRowAnimationNone];
	[self scrollToBottomAnimated:YES]; 
}

- (void)scrollToBottomAnimated:(BOOL)animated {
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[messages count]-1 inSection:0];
	[chatContent scrollToRowAtIndexPath:indexPath
					   atScrollPosition:UITableViewScrollPositionBottom animated:animated];
}

- (void)slideFrameUp {
	[self slideFrame:YES];
}

- (void)slideFrameDown {
	[self slideFrame:NO];
}

// Shorten height of UIView when keyboard pops up
// TODO: Test on different SDK versions; make more flexible if desired.
- (void)slideFrame:(BOOL)up {
	CGFloat movementDistance;

	UIInterfaceOrientation orientation =[[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationPortrait ||
        orientation == UIInterfaceOrientationPortraitUpsideDown) {
		movementDistance = 216.0f;
    } else {
		movementDistance = 162.0f;
    }
	CGFloat movement = (up ? -movementDistance : movementDistance);

	[UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.3];	
	CGRect viewFrame = self.view.frame;
	viewFrame.size.height += movement;
	self.view.frame = viewFrame;
	[UIView commitAnimations];
	
	if ([messages count] > 0) {
		NSUInteger index = [messages count] - 1;
		[chatContent scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
	}
	chatInput.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 3.0f, 0.0f);
	chatInput.contentOffset = CGPointMake(0.0f, 6.0f); // fix quirk
}


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return [messages count];
}


#define TIMESTAMP_TAG 1
#define TEXT_TAG 2
#define BACKGROUND_TAG 3

CGFloat msgTimestampHeight;

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	Message *msg = (Message *)[messages objectAtIndex:indexPath.row];

	UILabel *msgTimestamp;
	UIImageView *msgBackground;
	UILabel *msgText;

    static NSString *CellIdentifier = @"MessageCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		// Create message timestamp lable if appropriate
		msgTimestamp = [[[UILabel alloc] initWithFrame:
						 CGRectMake(0.0f, 0.0f, chatContent.frame.size.width, 12.0f)] autorelease];
		msgTimestamp.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		msgTimestamp.clearsContextBeforeDrawing = NO;
		msgTimestamp.tag = TIMESTAMP_TAG;
		msgTimestamp.font = [UIFont boldSystemFontOfSize:11.0f];
		msgTimestamp.lineBreakMode = UILineBreakModeTailTruncation;
		msgTimestamp.textAlignment = UITextAlignmentCenter;
		msgTimestamp.backgroundColor = CHAT_BACKGROUND_COLOR; // clearColor slows performance
		msgTimestamp.textColor = [UIColor darkGrayColor];			
		[cell.contentView addSubview:msgTimestamp];

		// Create message background image view
		msgBackground = [[[UIImageView alloc] init] autorelease];
		msgBackground.clearsContextBeforeDrawing = NO;
		msgBackground.tag = BACKGROUND_TAG;
		[cell.contentView addSubview:msgBackground];

		// Create message text label
		msgText = [[[UILabel alloc] init] autorelease];
		msgText.clearsContextBeforeDrawing = NO;
		msgText.tag = TEXT_TAG;
		msgText.backgroundColor = [UIColor clearColor];
		msgText.numberOfLines = 0;
		msgText.lineBreakMode = UILineBreakModeWordWrap;
		msgText.font = [UIFont systemFontOfSize:14.0];
		[cell.contentView addSubview:msgText];
	} else {
		msgTimestamp = (UILabel *)[cell.contentView viewWithTag:TIMESTAMP_TAG];
		msgBackground = (UIImageView *)[cell.contentView viewWithTag:BACKGROUND_TAG];
		msgText = (UILabel *)[cell.contentView viewWithTag:TEXT_TAG];
	}

// TODO: Only show timestamps every 15 mins
//	time_t now; time(&now);
//	if (now < latestTimestamp+780) // show timestamp every 15 mins
//		msg.timestamp = 0;
			
	if (true) { // latestTimestamp > ([[msg timestamp] longValue]+780)) {
		msgTimestampHeight = 20.0f;
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle]; // Jan 1, 2010
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];  // 1:43 PM
		
		NSDate *date = [NSDate dateWithTimeIntervalSince1970:[[msg timestamp] doubleValue]];
		
		NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]; // TODO: get locale from iPhone system prefs
		[dateFormatter setLocale:usLocale];
		[usLocale release];
		
		msgTimestamp.text = [dateFormatter stringFromDate:date];
		[dateFormatter release];
	} else {
		msgTimestampHeight = 0.0f;
		msgTimestamp.text = @"";
	}	

	// Layout message cell & its subviews.
	CGSize size = [[msg text] sizeWithFont:[UIFont systemFontOfSize:14.0]
						 constrainedToSize:CGSizeMake(240.0f, CGFLOAT_MAX)
							 lineBreakMode:UILineBreakModeWordWrap];
	UIImage *balloon;
	if ([[(User *)[msg sender] uid] isEqualToString:
		 [(User *)[[(LoversAppDelegate *)[[UIApplication sharedApplication] delegate] myAccount] user] uid]]) {
		msgBackground.frame = CGRectMake(chatContent.frame.size.width - (size.width + 35.0f), msgTimestampHeight, size.width + 35.0f, size.height + 13.0f);
		balloon = [[UIImage imageNamed:@"ChatBubbleGreen.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:13];
		msgText.frame = CGRectMake(chatContent.frame.size.width - 22.0f - size.width,
								   5.0f + msgTimestampHeight, size.width + 5.0f, size.height);
		msgBackground.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
		msgText.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
	} else {
		msgBackground.frame = CGRectMake(0.0f, msgTimestampHeight, size.width + 35.0f, size.height + 13.0f);
		balloon = [[UIImage imageNamed:@"ChatBubbleGray.png"] stretchableImageWithLeftCapWidth:23 topCapHeight:15];
		msgText.frame = CGRectMake(22.0f, 5.0f + msgTimestampHeight, size.width + 5.0f, size.height);
	}
	msgBackground.image = balloon;
	msgText.text = [msg text];

	// Mark message as read.
	// Let's instead do this (asynchronously) from loadView and iterate over all messages
	if ([msg unread]) { // then save as read
		[msg setUnread:[NSNumber numberWithBool:NO]];
		NSManagedObjectContext *managedObjectContext = [(LoversAppDelegate *)[[UIApplication sharedApplication] delegate] managedObjectContext];
		NSError *error = nil;
		if (![managedObjectContext save:&error]) {
			// Handle the error.
			NSLog(@"Error saving message as read! %@", error);
		}		
	}
	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath  {  
	Message *msg = (Message *)[messages objectAtIndex:indexPath.row];
	msgTimestampHeight = 20.0f; // [msg timestamp] ? 20.0f : 0.0f;
	CGSize size = [[msg text] sizeWithFont:[UIFont systemFontOfSize:14.0] constrainedToSize:CGSizeMake(240.0f, FLT_MAX) lineBreakMode:UILineBreakModeWordWrap];
	return size.height + 20.0f + msgTimestampHeight;
} 

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[super viewDidUnload];
	self.channel = nil;
	self.messages = nil;

	self.chatContent = nil;

	self.sendButton = nil;
	self.chatInput = nil;
	self.chatBar = nil;

	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)dealloc {
	[channel release];
	[messages release];

	[chatContent release];

	[sendButton release];
	[chatInput release];
	[chatBar release];

	[super dealloc];
}

@end
