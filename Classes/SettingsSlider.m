
/*
 * Sid Player -- Bringing the C64 Classics to the iPhone
 * (C) 2008-2009 Lauer, Teuber GbR <sidplayer@vanille.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

#import "SettingsSlider.h"


@implementation SettingsSlider

@synthesize currentValue;
@synthesize textLabel;
@synthesize valueLabel;

- (void)dealloc {
    [super dealloc];
	[currentValue release];
	[textLabel release];
	[textLabel release];
}

- (id)initWithFrame:(CGRect)aRect
{
	[super initWithFrame:aRect];
	[self setFrame:CGRectMake(20.0f, 54.0f, 280.0f, 27.0f)];
	return self;
}

// set value 4 view
-(void)setViewValue:(NSNumber*)value
{
	[self setCurrentValue: value];

	if (!valueLabel)
	{
		// subview mit dem ganzen Zeugs anfügen!
		valueLabel =[[UILabel alloc] initWithFrame:CGRectMake(250.0f, -44.0f, 30.0f, 27.0f)];
		[valueLabel setTextAlignment:UITextAlignmentRight];
		[valueLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
		[self addSubview:valueLabel];
	}

	int intValue = [value intValue];
	[valueLabel setText:[NSString stringWithFormat:@"%i",intValue]];
}

// set label for view
-(void)setLabel:(NSString*)string
{
	if (!textLabel)
	{
		textLabel =[[UILabel alloc] initWithFrame:CGRectMake(0.0f, -44.0f, 250.0f, 27.0f)];
		[textLabel setTextAlignment:UITextAlignmentLeft];
		[textLabel setFont:[UIFont boldSystemFontOfSize:17.0f]];
        [textLabel setBackgroundColor:[UIColor clearColor]];
		[self addSubview:textLabel];
	}
	
	[textLabel setText:string];
}

@end
