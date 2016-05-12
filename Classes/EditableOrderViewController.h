//
//  EditableOrderViewController.h
//  ModPlayer
//
//  Created by Kai Teuber on 11.02.10.
//  Copyright 2010 Diplom-Informatiker. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FixedOrderViewController.h"


@interface EditableOrderViewController : FixedOrderViewController {

@private
	BOOL	refresh;
	
}

@property (nonatomic)	BOOL refresh;

- (void) favoriteToggle: (BOOL) favorite;

@end
