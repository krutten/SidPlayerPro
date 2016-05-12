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

#ifndef _AUDIOQUEUEDRIVER_H_
#define _AUDIOQUEUEDRIVER_H_

#include <AudioToolbox/AudioToolbox.h>
#include "AudioDriver.h"

class AudioQueueDriver;

class AudioQueueDriver : public AudioDriver
{
public:

	AudioQueueDriver();
	~AudioQueueDriver();

	void initialize(int sampleRate = 44100, int bitsPerSample = 16);

	bool startPlayback(Player* player);
	void stopPlayback();
	int getSampleRate();

	inline float getVolume()								{ return mVolume; }
	void setVolume(float volume);

	virtual short* getSampleBuffer()						{ return mLastAudioQueueBuffer; }
	inline int getNumSamplesInBuffer()						{ return mNumSamplesInBuffer; }
	inline bool getIsPlaying()								{ return mIsPlaying; }
	inline bool getIsInitialized()							{ return mIsInitialized; }

	long getBufferSizeMs();

private:
	static void* initAudioServices(AudioQueueDriver* self);
	
	bool                        mFastForward;
	float                       mVolume;
	float                       mAudioLevel;

	// called by the audio session when an audio interruption has occured
	static void AudioSessionInterruptionCallback(void* inClientData,
												 UInt32 inInterruptionState);

	// called by the audio session when a audio property has changed
	static void AudioSessionPropertyChangeCallback(void                      *inClientData,
												   AudioSessionPropertyID    inID,
												   UInt32                    inDataSize,
												   const void                *inData );

	// called by the audio queue when a property has changed
	static void AudioQueuePropertyChangeCallback(void     *inUserData,
									 AudioQueueRef         inAQ,
									 AudioQueuePropertyID  inID);

	// called by the audio queue when there are buffers to fill
	static void AudioQueueOutputCallback(void                 *inUserData,
									     AudioQueueRef        inAQ,
									     AudioQueueBufferRef  inBuffer);

	// called to fill a new playback buffer
	void fillBuffer( short* buffer, unsigned int length );
	// internal
	void initAudioQueue();
	void releaseAudioQueue();

	bool                        mIsInitialized;
	Player*						mPlayer;
	int							sampleRate;

	float                       mScaleFactor; // pre-output volume scaler

	static const int			kNumberBuffers = 3;
	AudioStreamBasicDescription mStreamFormat;
	AudioQueueRef				mQueue;
	AudioQueueBufferRef			mBuffers[kNumberBuffers];

	bool                        mIsPlaying;
	bool						mBufferUnderrunDetected;
    int                         mBufferUnderrunCount;
	int                         mInstanceId;

	// low level buffers filled by sid player engine
	int							mNumSamplesInBuffer;
	short*                      mSampleBuffer;
	short*						mLastAudioQueueBuffer;

	// only used if the audio queue runs in a seperate thread
	pthread_attr_t				pthread_attr;
	pthread_t					pthread;

};


#endif // _AUDIOCOREDRIVER_H_
