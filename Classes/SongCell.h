//
//  SongCell.h
//  ModPlayer
//
//  Created by Kai Teuber on 16.02.10.
//  Copyright 2010 Diplom-Informatiker. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SongCell : UITableViewCell {

	IBOutlet	UILabel*	name;
	IBOutlet	UILabel*	type;
	IBOutlet	UIImageView*	cached;
	
}

@property (nonatomic, retain) UILabel*	name;
@property (nonatomic, retain) UILabel*	type;
@property (nonatomic, retain) UIImageView*	cached;

@end
