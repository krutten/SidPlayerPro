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

#import "QuartzOscillatorView.h"
#import "AppDelegate.h"

@implementation QuartzOscillatorView

short* lastBuffer;
short* runningBuffer;
short* buf1;
short* buf2;
short* buf3;

CGPoint linePoints[1024];

Sid_MachineAppDelegate* app;

- (id)initWithFrame:(CGRect)frame {
    if ( (self = [super initWithFrame:frame]) ) {
        // Initialization code
    }
	
	app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];

    return self;
}

- (void)drawRect:(CGRect)rect {
	
	// don't draw if not visible
	if ([self superview].alpha == 0.0)
		return;
	
	CFAbsoluteTime time1 = CFAbsoluteTimeGetCurrent();
	
#if 0
	CGRect currentRect = CGRectMake(50,50,20,20);
    UIColor *currentColor = [UIColor redColor];
	
    CGContextRef context = UIGraphicsGetCurrentContext();
	
    CGContextSetLineWidth(context, 2.0);
    CGContextSetStrokeColorWithColor(context, currentColor.CGColor);
	
    CGContextSetFillColorWithColor(context, currentColor.CGColor);  
    CGContextAddEllipseInRect(context, currentRect);
    CGContextDrawPath(context, kCGPathFillStroke);
#endif

	CGRect contextRect;
	contextRect.origin.x = rect.origin.x;
	contextRect.origin.y = rect.origin.y;
	contextRect.size.width = rect.size.width;
	contextRect.size.height = rect.size.height;
	
    CGContextRef context = UIGraphicsGetCurrentContext();
	
	// fill region with "no color"
	CGContextSetRGBFillColor(context, 0.0f, 0.0f, 0.0f, 0.0f);
	CGContextFillRect(context, contextRect);

	short* sampleBuffer = [app getSampleBuffer];
	
	//NSLog( @"%0x %0x %0x [%0x]\n", buf1, buf2, buf3, runningBuffer );
	
	if (sampleBuffer != lastBuffer)
	{
		lastBuffer = sampleBuffer;
		runningBuffer = buf1;
		buf1 = buf2;
		buf2 = buf3;
		buf3 = lastBuffer;
	}

	float zeroLineHeight = contextRect.size.height * 0.5f + 0.5f;
	float width = contextRect.size.width;
	float height = contextRect.size.height;
	float hfactor = height / 65536.0f;
	
	//NSLog(@"drawing %0.2f * %0.2f with bytes at %p", width, height, runningBuffer);
	
	CGContextSetRGBStrokeColor(context, 1.0f, 1.0f, 0.4f, 1.0f);
	
	CGContextBeginPath(context);
	CGContextSetLineWidth(context, 2.0f);

	if (runningBuffer != NULL)
	{
		
		for (int i = 0; i < width; i++)
		{
			linePoints[i].x = i + 0.5f;
			linePoints[i].y = zeroLineHeight + (*runningBuffer++ * hfactor);
#ifndef SIDPLAYER
			runningBuffer++; // skip 2nd sample (stereo)
#endif
		}
		CGContextAddLines(context, linePoints, width);
		CGContextDrawPath(context, kCGPathEOFillStroke);
		
	}
	else
	{
		static CGPoint linePoints[2];
		linePoints[0].x = contextRect.origin.x;
		linePoints[0].y = zeroLineHeight;
		linePoints[1].x = width;
		linePoints[1].y = zeroLineHeight;
		
		CGContextAddLines(context, linePoints, 2);
		CGContextDrawPath(context, kCGPathFillStroke);
	}
	
	CFAbsoluteTime time2 = CFAbsoluteTimeGetCurrent();
	
	fprintf(stderr, "OscillatorV: draw rect performance = %.2f\n", time2-time1);
}


- (void)dealloc {
    [super dealloc];
}


@end
