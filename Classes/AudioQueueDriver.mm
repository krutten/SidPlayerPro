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

#include "Player.h"
#include "AudioQueueDriver.h"

#import <CoreFoundation/CFRunLoop.h>
#import <AVFoundation/AVFoundation.h>

#import <pthread.h>

#import "AppDelegate.h"

//#define DEBUG
//#define PERFORMANCE_DEBUG

#define AUDIO_QUEUE_BUFFER_SIZE					(24*1024)
#define AUDIO_QUEUE_BUFFER_LENGTH				(AUDIO_QUEUE_BUFFER_SIZE / 2 / 44.1 / 1000)

#undef AUDIO_QUEUE_BUFFER_FRAGMENTS
#define AUDIO_QUEUE_SEPERATE_THREAD
//#undef AUDIO_QUEUE_SEPERATE_THREAD
#define THREAD_PRIORITY_MAX			99
#define THREAD_PRIORITY_HIGHER      70
#define THREAD_PRIORITY_REALTIME	47
#define THREAD_PRIORITY_HIGH		40
#define THREAD_PRIORITY_DEFAULT		31
#define THREAD_PRIORITY_MID			20
#define THREAD_PRIORITY_LOW			00
#define AUDIO_QUEUE_THREAD_SCHEDULING SCHED_RR
#define AUDIO_QUEUE_THREAD_PRIORITY THREAD_PRIORITY_HIGH

static const float  sBitScaleFactor = 1.0f / 32768.0f;
static int          sInstanceCount = 0;

#ifdef SIDPLAYER
 #define AUDIO_QUEUE_MONO
#else
 #undef AUDIO_QUEUE_MONO
#endif

// ----------------------------------------------------------------------------
AudioQueueDriver::AudioQueueDriver()
// ----------------------------------------------------------------------------
{
	mIsInitialized = false;
	mIsPlaying = false;
	mBufferUnderrunDetected = false;
    mBufferUnderrunCount = 0;

	mInstanceId = sInstanceCount;
	sInstanceCount++;
}

// ----------------------------------------------------------------------------
void AudioQueueDriver::releaseAudioQueue()
// ----------------------------------------------------------------------------
{
	OSStatus err = AudioQueueStop(mQueue, false); // false = stop async
	if (err) fprintf(stderr, "AudioQueueStop err %d\n", err);

	AudioQueueDispose(mQueue, true);
	delete[] mSampleBuffer;
}

// ----------------------------------------------------------------------------
AudioQueueDriver::~AudioQueueDriver()
// ----------------------------------------------------------------------------
{
	sInstanceCount--;
	// FIXME add check whether the last instance has quit

	stopPlayback();
	
	releaseAudioQueue();

	mIsInitialized = false;
}

// ----------------------------------------------------------------------------
void AudioQueueDriver::initialize(int sampleRate, int bitsPerSample)
// ----------------------------------------------------------------------------
{
	mStreamFormat.mBitsPerChannel = bitsPerSample;
	mStreamFormat.mSampleRate = sampleRate;

#ifdef AUDIO_QUEUE_SEPERATE_THREAD
	// launch posix thread
	int result = pthread_attr_init( &pthread_attr );
	if ( result )
	{
		fprintf( stderr, "pthread_attr_init failure.\n" );
		assert( false );
		return;
	}
	result = pthread_attr_setdetachstate( &pthread_attr, PTHREAD_CREATE_DETACHED );
	if ( result )
	{
		fprintf( stderr, "pthread_attr_setdetachstate failure.\n" );
		assert( false );
		return;
	}
	result = pthread_create( &pthread, &pthread_attr, (void*(*)(void*)) &initAudioServices, this );
	if ( result )
	{
		fprintf( stderr, "pthread_create failure.\n" );
		assert( false );
		return;
	}
	else
	{
		struct sched_param params;
		int scheduling;
		result = pthread_getschedparam( pthread, &scheduling, &params );
		if ( !result )
		{
			fprintf( stderr, "pthread_getshedparam reports scheduling type %d w/ priority %d\n", scheduling, params.sched_priority );
		}
		params.sched_priority = AUDIO_QUEUE_THREAD_PRIORITY;
		result = pthread_setschedparam( pthread, AUDIO_QUEUE_THREAD_SCHEDULING, &params );
		if ( result )
		{
			fprintf( stderr, "pthread_setshedparam failure: %d.\n", result );
			//assert( false );
			//return;
		}

		pthread_attr_destroy( &pthread_attr );
		fprintf( stderr, "audio thread started\n" );
	}
#else
	initAudioServices( this );
#endif
}

// ----------------------------------------------------------------------------
void* AudioQueueDriver::initAudioServices(AudioQueueDriver* self)
// ----------------------------------------------------------------------------
{
	if (self->mInstanceId != 0)
		return NULL;

    OSStatus err = AudioSessionInitialize(NULL, NULL, AudioSessionInterruptionCallback, self);
	if (err)
		NSLog(@"Error initializing audio session! %d", err);
	
	//[[AVAudioSession sharedInstance] setDelegate: self];
	NSError *setCategoryError = nil;
	[[AVAudioSession sharedInstance] setCategory: AVAudioSessionCategoryPlayback error: &setCategoryError];
	if (setCategoryError)
		NSLog(@"Error setting category! %d", setCategoryError);

	Float32 preferredBufferSize = 0.005; // I'd like a 5ms buffer duration
	err = AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize);
	if (err)
		fprintf(stderr, "WARNING: AudioSessionSetProperty (PreferredHardwareIOBufferDuration) err %d\n", err);
	
	//result = AudioSessionAddPropertyListener( kAudioSessionProperty_CurrentHardwareOutputVolume, AudioSessionPropertyChangeCallback, self );
	//if (err)
	//	fprintf(stderr, "WARNING: AudioSessionAddPropertyListener (CurrentHardwareOutputVolume) err %d\n", err);

	// register for audio route changes
	err = AudioSessionAddPropertyListener( kAudioSessionProperty_AudioRouteChange, AudioSessionPropertyChangeCallback, self );
	if (err)
		fprintf(stderr, "WARNING: AudioSessionAddPropertyListener (AudioRouteChange) err %d\n", err);	
	
	if (!self->mIsInitialized)
		self->initAudioQueue();
	
	self->mVolume = 1.0f;
	self->mIsInitialized = true;
	self->mPlayer = NULL;
	
#ifdef AUDIO_QUEUE_SEPERATE_THREAD
	CFRunLoopRun();
#endif

	return NULL;
}

// ----------------------------------------------------------------------------
void AudioQueueDriver::initAudioQueue()
// ----------------------------------------------------------------------------
{
	// FIXME can we compute the best buffer size for the given device?
	// The iPod has some more headroom, since it runs less processes
	mNumSamplesInBuffer = AUDIO_QUEUE_BUFFER_SIZE;
	
	// describe stream format
	//self->mStreamFormat.mSampleRate = sampleRate;
	//self->mStreamFormat.mBitsPerChannel = 16;
	mStreamFormat.mFormatID = kAudioFormatLinearPCM;
	mStreamFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
#ifdef AUDIO_QUEUE_MONO
	mStreamFormat.mBytesPerPacket = 2;
	mStreamFormat.mFramesPerPacket = 1;
	mStreamFormat.mBytesPerFrame = 2;
	mStreamFormat.mChannelsPerFrame = 1;
#else
	mStreamFormat.mBytesPerPacket = 4;
	mStreamFormat.mFramesPerPacket = 1;
	mStreamFormat.mBytesPerFrame = 4;
	mStreamFormat.mChannelsPerFrame = 2;
#endif
	OSStatus err = 0;

	fprintf( stderr, "AudioQueueDriver: initializing audio queue w/ sample rate of %d\n", mStreamFormat.mSampleRate );

	// create new audio queue
	err = AudioQueueNewOutput(&mStreamFormat,
							  AudioQueueOutputCallback,
							  this,
							  CFRunLoopGetCurrent(),
							  kCFRunLoopCommonModes,
							  0,
							  &mQueue);

	if (err) fprintf(stderr, "AudioQueueNewOutput err %d\n", err);
		
	// allocate lowlevel buffer
	mSampleBuffer = new short[mNumSamplesInBuffer];
	memset(mSampleBuffer, 0, sizeof(short) * mNumSamplesInBuffer);
		
	// allocate audio queue buffers
	int bufferByteSize = mNumSamplesInBuffer * mStreamFormat.mChannelsPerFrame * sizeof(short);
	fprintf(stderr, "audio queue buffer size = %d bytes\n", bufferByteSize);
		
	for (int i=0; i< kNumberBuffers; i++) {
		err = AudioQueueAllocateBuffer(mQueue, bufferByteSize, &mBuffers[i]);
		if (err) fprintf(stderr, "AudioQueueAllocateBuffer [%d] err %d\n",i, err);
		
		// fill buffer
		AudioQueueOutputCallback(this, mQueue, mBuffers[i]);
	}
	
	mScaleFactor = sBitScaleFactor;
	
	// global volume setup
	err = AudioQueueSetParameter(mQueue, kAudioQueueParam_Volume, 1.0);
	if (err) fprintf(stderr, "AudioQueueSetParameter err %d\n", err);

	// register property change callback
	err = AudioQueueAddPropertyListener(mQueue, kAudioQueueProperty_IsRunning, AudioQueuePropertyChangeCallback, this);
	if (err) fprintf(stderr, "AudioQueueAddPropertyListener err %d\n", err);
}

// ----------------------------------------------------------------------------
void AudioQueueDriver::fillBuffer( short* buffer, unsigned int length )
// ----------------------------------------------------------------------------
{
	mLastAudioQueueBuffer = buffer;
	
	if (!mIsPlaying)
	{
		memset( buffer, 0, length );
		mBufferFillPerformance = 0.0f;
		return;
	}
	
/*	bool empty = true;
	for (i=0; i < length; ++i)
		if (buffer[i])
		{
			empty = false;
			break;
		}
*/

	if (!mPlayer)
	{
		fprintf(stderr, "no player available during fillBuffer!");
		return;
	}

#ifdef AUDIO_QUEUE_BUFFER_FRAGMENTS

	short* fragment = buffer;
	unsigned int fragmentSize = length / AUDIO_QUEUE_BUFFER_FRAGMENTS;
	for ( int i = 0; i < AUDIO_QUEUE_BUFFER_FRAGMENTS; ++i )
	{
		mPlayer->fillBuffer(fragment, fragmentSize);
		CFRunLoopRunInMode( kCFRunLoopDefaultMode, 0, false );
		fragment += fragmentSize / sizeof(short);
	}
#else
    mPlayer->fillBuffer( buffer, length );
#endif
}

// ----------------------------------------------------------------------------
void AudioQueueDriver::AudioQueueOutputCallback(void                 *inUserData,
									 AudioQueueRef        inAQ,
									 AudioQueueBufferRef  inBuffer)
// ----------------------------------------------------------------------------
{
	CFAbsoluteTime time1 = CFAbsoluteTimeGetCurrent();
	
//	fprintf(stderr, "AudioQueueOutputCallback called from CFRunLoop %d\n", CFRunLoopGetCurrent());

	AudioQueueDriver* driverInstance = reinterpret_cast<AudioQueueDriver*>(inUserData);

	register short* aqBuffer	= (short*) inBuffer->mAudioData;
	//register short* audioBuffer = (short*) driverInstance->getSampleBuffer();
	//register short* bufferEnd	= audioBuffer + driverInstance->getNumSamplesInBuffer();

	//fprintf(stderr, "outBuffer=%p, audioBuffer=%p, bufferEnd=%p\n", outBuffer, audioBuffer, bufferEnd);

#ifdef DEBUG
	// generate sine wave @ 440Hz
	int frameCount = driverInstance->getNumSamplesInBuffer();
	int sampleNr = 0;
	for(int i=0; i < frameCount*2; i=i+2) {
		float floatVal = sin(((float)sampleNr * 2.0 * M_PI * 440.0) / 44100.0); // A
		int sampleValue = (int)(floatVal * 32767.0);
		aqBuffer[i] = sampleValue; // left
		aqBuffer[i+1] = sampleValue; // right
		sampleNr++;
	}
#else

    driverInstance->fillBuffer( aqBuffer, driverInstance->getNumSamplesInBuffer() );

#endif // DEBUG

	// tell core audio how many bytes we have just filled
	inBuffer->mAudioDataByteSize = driverInstance->getNumSamplesInBuffer();
	//* driverInstance->mStreamFormat.mChannelsPerFrame;

	//fprintf(stderr, "enqueuing new audio block w/ %d bytes\n", inBuffer->mAudioDataByteSize);

	// enqueue the new buffer
	OSStatus err = AudioQueueEnqueueBuffer( inAQ, inBuffer, 0, 0 ); // CBR has no packet descriptions
	if (err) fprintf(stderr, "AudioQueueEnqueueBuffer err %d\n", err);
	
	CFAbsoluteTime time2 = CFAbsoluteTimeGetCurrent();

	if ( driverInstance->mIsPlaying )
	{
		driverInstance->mBufferFillPerformance += ( time2-time1-AUDIO_QUEUE_BUFFER_LENGTH );
#ifdef PERFORMANCE_DEBUG
		fprintf(stderr, "buffer fill performance = %.2f\n(last offset: %.2f / %.2f)\n", driverInstance->mBufferFillPerformance, time2-time1, AUDIO_QUEUE_BUFFER_LENGTH);
#endif
	}
	else
		driverInstance->mBufferFillPerformance = 0.0f;
}

void AudioQueueDriver::AudioSessionInterruptionCallback(void* inClientData,
									 UInt32 inInterruptionState)
{
	AudioQueueDriver* self = (AudioQueueDriver*)inClientData;
	OSStatus err;
	
	if ( inInterruptionState == kAudioSessionBeginInterruption )
	{
		fprintf(stderr, "AudioQueueDriver: audio session interruption. Stopping playback.\n");
		self->stopPlayback();
		err = AudioSessionSetActive(false);
		if (err)
			fprintf(stderr, "AudioQueueDriver: AudioSessionSetActive(false) returned error %d\n", err);
	}
	else if ( inInterruptionState == kAudioSessionEndInterruption )
	{
		fprintf(stderr, "AudioQueueDriver: audio session resumed. Restarting playback.\n" );
		// restart audio queue
		err = AudioSessionSetActive(true);
		if (err)
			fprintf(stderr, "AudioQueueDriver: AudioSessionSetActive(true) returned error %d\n", err);
		err = AudioQueueStart(self->mQueue, NULL);
		if (err) fprintf(stderr, "AudioQueueStart err %d\n", err);
		
		self->startPlayback(self->mPlayer);
	}
	else
		fprintf(stderr, "AudioQueueDriver: unhandled audio session interruption state %d", inInterruptionState);
}

void AudioQueueDriver::AudioSessionPropertyChangeCallback(void  *inClientData,
									   AudioSessionPropertyID    inID,
									   UInt32                    inDataSize,
									   const void                *inUserData )
{
	AudioQueueDriver* driverInstance = (AudioQueueDriver*) inUserData;

	fprintf(stderr, "NOTE: Audio Session property change for ID %c%c%c%c\n",
			(inID >> 24) & 0xff,
			(inID >> 16) & 0xff,
			(inID >> 8) & 0xff,
			inID & 0xff);

	UInt32 routeSize = sizeof (CFStringRef);
	CFStringRef route;

	switch ( inID )
	{
		case kAudioSessionProperty_AudioRouteChange:			
			AudioSessionGetProperty( kAudioSessionProperty_AudioRoute, &routeSize, &route );
			NSLog( @"New Audio Route = %@", route );
			if ( [route isEqualToString:@"Speaker"] )
			{
				Sid_MachineAppDelegate* app = (Sid_MachineAppDelegate*) [[UIApplication sharedApplication] delegate];
				[app performSelectorOnMainThread:@selector(doPlayerAction:) withObject:@"pause" waitUntilDone:NO];
			}
			break;
		default:
			fprintf( stderr, "FIXME: Handle session property change for this value\n" );
			break;
	}
}

void AudioQueueDriver::AudioQueuePropertyChangeCallback(void                  *inUserData,
									   AudioQueueRef         inAQ,
									   AudioQueuePropertyID  inID)
{
	AudioQueueDriver* driverInstance = reinterpret_cast<AudioQueueDriver*>(inUserData);

	UInt32 value;
	UInt32 size = sizeof(value);
	OSStatus err = AudioQueueGetProperty(inAQ, inID, &value, &size);
	if ( !err )
	{
		fprintf(stderr, "NOTE: Audio queue property change for ID %c%c%c%c - new value = %0x\n",
			(inID >> 24) & 0xff,
			(inID >> 16) & 0xff,
			(inID >> 8) & 0xff,
			inID & 0xff,
			value);
	}

	switch ( inID )
	{
		case kAudioQueueProperty_IsRunning:
			AudioSessionSetActive( value );
			break;
		default:
			fprintf( stderr, "FIXME: Handle audio property change for this value\n" );
			break;
	}

	/*
	// nothing is playing right from the start
	err = AudioSessionSetActive( false );
	if (err)
		fprintf(stderr, "WARNING: AudioSessionSetActive err %d\n", err);
	*/
}

// ----------------------------------------------------------------------------
bool AudioQueueDriver::startPlayback(Player* player)
// ----------------------------------------------------------------------------
{
	fprintf(stderr, "AudioQueueDriver::startPlayback()\n");
	resetPerformance();

	// launch audio queue
	OSStatus err = AudioQueueStart(mQueue, NULL);
	if (err) fprintf(stderr, "AudioQueueStart err %d\n", err);

	/*
	err = AudioSessionSetActive( true );
	if (err)
		fprintf(stderr, "WARNING: AudioSessionSetActive err %d\n", err);
	*/

	if (mInstanceId != 0)
		return false;

	if (!mIsInitialized)
		return false;

	mPlayer = player;
	mIsPlaying = true;

	return true;
}

// ----------------------------------------------------------------------------
void AudioQueueDriver::stopPlayback()
// ----------------------------------------------------------------------------
{
	fprintf(stderr, "AudioQueueDriver::stopPlayback()\n");
	
	if (!mIsInitialized)
	{
		return;
	}

	if (!mIsPlaying)
	{
		return;
	}

	mIsPlaying = false;

	/*
	// shutdown audio queue
	OSStatus err = AudioQueueStop(mQueue, YES);
	if (err) fprintf(stderr, "AudioQueueStop err %ld\n", err);
	*/

	// shutdown audio queue
	OSStatus err = AudioQueuePause(mQueue);
	if (err) fprintf(stderr, "AudioQueuePause err %ld\n", err);
	err = AudioQueueStop(mQueue, NO);
	if (err) fprintf(stderr, "AudioQueueStop err %ld\n", err);
	
	/*
	OSStatus err = AudioSessionSetActive( false );
	if (err)
		fprintf(stderr, "WARNING: AudioSessionSetActive err %d\n", err);
	*/
}

// ----------------------------------------------------------------------------
int AudioQueueDriver::getSampleRate()
// ----------------------------------------------------------------------------
{
	return mStreamFormat.mSampleRate;
}

// ----------------------------------------------------------------------------
long AudioQueueDriver::getBufferSizeMs()
// ----------------------------------------------------------------------------
{
	assert( mIsInitialized );
	
	//NOTE: getNumSamplesInBuffer is broken currently. It's numBytesInBuffer,
	// to get the actual result, you need to divide by the amount of channels and the amount of bytes/sample.
	
	long ms = 250 * getNumSamplesInBuffer() / getSampleRate();
	
	return ms;
}

// ----------------------------------------------------------------------------
void AudioQueueDriver::setVolume(float volume)
// ----------------------------------------------------------------------------
{
	fprintf(stderr, "AudioQueueDriver::setVolume()\n");
	mVolume = volume;
	mScaleFactor = sBitScaleFactor * volume;
}

