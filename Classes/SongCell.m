//
//  SongCell.m
//  ModPlayer
//
//  Created by Kai Teuber on 16.02.10.
//  Copyright 2010 Diplom-Informatiker. All rights reserved.
//

#import "SongCell.h"


@implementation SongCell

@synthesize name, type, cached;

- (void)dealloc
{
	[name release];
	[type release];
	[cached release];
    [super dealloc];
}


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        // Initialization code
    }
    return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)didTransitionToState:(UITableViewCellStateMask)state
{
	[super didTransitionToState:state];

	if ( state == UITableViewCellStateDefaultMask)
	{
		self.type.hidden = NO;
	}
	
}

- (void)willTransitionToState:(UITableViewCellStateMask)state
{
	[super willTransitionToState:state];
	if ( state == UITableViewCellStateEditingMask)
	{
		self.type.hidden = YES;
	}
}

@end
