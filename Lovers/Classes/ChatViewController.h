@interface ChatViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate> {
	NSString *channel;
	NSMutableArray *messages;
		time_t	latestTimestamp;

	UITableView *chatContent;

	UIImageView *chatBar;
		UITextView *chatInput;
			CGFloat lastContentHeight;
			Boolean chatInputHadText;
		UIButton *sendButton;
}

@property (nonatomic, retain) NSString *channel;
@property (nonatomic, retain) NSMutableArray *messages;
@property (nonatomic, assign) time_t latestTimestamp;

@property (nonatomic, retain) UITableView *chatContent;

@property (nonatomic, retain) UIImageView *chatBar;
@property (nonatomic, retain) UITextView *chatInput;
@property (nonatomic, assign) CGFloat lastContentHeight;
@property (nonatomic, assign) Boolean chatInputHadText;
@property (nonatomic, retain) UIButton *sendButton;

- (void)scrollToBottomAnimated:(BOOL)animated;
- (void)slideFrame:(BOOL)up;
- (void)slideFrameUp;
- (void)slideFrameDown;

@end
