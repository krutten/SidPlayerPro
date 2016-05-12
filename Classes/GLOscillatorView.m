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

#import "GLOscillatorView.h"

#import "AppDelegate.h"

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>

#define USE_DEPTH_BUFFER 0

short* lastBuffer;
short* runningBuffer;
short* buf1;
short* buf2;
short* buf3;

short* emptyBuf;

GLfloat linePointsL[1024];
GLfloat linePointsR[1024];

Sid_MachineAppDelegate* app;

// A class extension to declare private methods
@interface EAGLView ()

@property (nonatomic, retain) EAGLContext *context;
@property (nonatomic, assign) NSTimer *animationTimer;

- (BOOL) createFramebuffer;
- (void) destroyFramebuffer;

@end


@implementation EAGLView

@synthesize context;
@synthesize animationTimer;
@synthesize animationInterval;


// You must implement this method
+ (Class)layerClass {
    return [CAEAGLLayer class];
}


//The GL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder {
    
    if ((self = [super initWithCoder:coder])) {
        // Get the layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
        
        eaglLayer.opaque = NO;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
        
        if (!context || ![EAGLContext setCurrentContext:context]) {
            [self release];
            return nil;
        }       
        animationInterval = 1.0 / 30.0;
    }
	app = (Sid_MachineAppDelegate *) [[UIApplication sharedApplication]delegate];
	
	emptyBuf = malloc( 32768 );
	memset( emptyBuf, 0, 32768 );

    return self;
}

#define WIDTH 320

- (void)drawView
{
	if ( app.applicationRunningInBackground )
	{
		return;
	}
	short* sampleBuffer = [app getSampleBuffer];

	if ( sampleBuffer == NULL )
	{
		lastBuffer = emptyBuf;
		runningBuffer = emptyBuf;
		buf1 = emptyBuf;
		buf2 = emptyBuf;
		buf3 = emptyBuf;
	}
	else
	{
		if (sampleBuffer != lastBuffer)
		{
			lastBuffer = sampleBuffer;
			runningBuffer = buf1;
			buf1 = buf2;
			buf2 = buf3;
			buf3 = lastBuffer;
		}
	}
	
    [EAGLContext setCurrentContext:context];
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glViewport(0, 0, backingWidth, backingHeight);
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
	
    glOrthof(0.0f, 320.0f, -32768.0f, 32768.0f, -1.0f, 1.0f);
    glMatrixMode(GL_MODELVIEW);
       
	glClearColor(0.0f, 0.0f, 0.1f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
	
	CGFloat* pointsL = linePointsL;
	CGFloat* pointsR = linePointsR;
	
	if (runningBuffer != NULL)
	{
		for (int i = 0; i < WIDTH; i++)
		{
			(*pointsL++) = (float) i;
			(*pointsR++) = (float) i;
			(*pointsL++) = (float) *runningBuffer++;
			(*pointsR++) = (float) *runningBuffer++;
		}

		glLineWidth(2.3);
		glColor4f(1.0, 1.0, 0.4, 0.9);
		glEnableClientState(GL_VERTEX_ARRAY);

		glVertexPointer(2, GL_FLOAT, 0, linePointsL);
		glDrawArrays(GL_LINE_STRIP, 0, WIDTH);

		glColor4f(0.4, 1.0, 0.4, 0.9);
		glVertexPointer(2, GL_FLOAT, 0, linePointsR);
		glDrawArrays(GL_LINE_STRIP, 0, WIDTH);

		glDisableClientState(GL_VERTEX_ARRAY);
	}
	
	//NSLog( @"updating GL buffer" );
	
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
	
	//glEnable(GL_LINE_SMOOTH);
	//glEnable(GL_BLEND);
}


- (void)layoutSubviews {
    [EAGLContext setCurrentContext:context];
    [self destroyFramebuffer];
    [self createFramebuffer];
    [self drawView];
}


- (BOOL)createFramebuffer {
    
    glGenFramebuffersOES(1, &viewFramebuffer);
    glGenRenderbuffersOES(1, &viewRenderbuffer);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, viewFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, viewRenderbuffer);
    
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    
    if (USE_DEPTH_BUFFER) {
        glGenRenderbuffersOES(1, &depthRenderbuffer);
        glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
        glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
    }
    
    if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
        NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }
    
    return YES;
}


- (void)destroyFramebuffer {
    
    glDeleteFramebuffersOES(1, &viewFramebuffer);
    viewFramebuffer = 0;
    glDeleteRenderbuffersOES(1, &viewRenderbuffer);
    viewRenderbuffer = 0;
    
    if(depthRenderbuffer) {
        glDeleteRenderbuffersOES(1, &depthRenderbuffer);
        depthRenderbuffer = 0;
    }
}


- (void)startAnimation
{
	self.animationTimer = [NSTimer scheduledTimerWithTimeInterval:animationInterval target:self selector:@selector(drawView) userInfo:nil repeats:YES];
}


- (void)stopAnimation
{
    self.animationTimer = nil;
}


- (void)setAnimationTimer:(NSTimer *)newTimer {
    [animationTimer invalidate];
    animationTimer = newTimer;
}


- (void)setAnimationInterval:(NSTimeInterval)interval {
    
    animationInterval = interval;
    if (animationTimer) {
        [self stopAnimation];
        [self startAnimation];
    }
}


- (void)dealloc {
    
    [self stopAnimation];
    
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    [context release];  
    [super dealloc];
}

@end
