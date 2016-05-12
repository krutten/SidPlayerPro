#ifndef _PlayerAsap_H
#define _PlayerAsap_H

#import "Player.h"
#import "AudioDriver.h"

#import <pthread.h>

#import "asap/asap.h"

#define uint unsigned int

class PlayerAsap : public Player
{
public:
	PlayerAsap();
	virtual ~PlayerAsap();

	// play
	virtual void setAudioDriver( AudioDriver* audioDriver );
	virtual bool playTuneByPath( const char* filename );
	virtual bool playTuneFromBuffer( void* buffer, long size );
	virtual void fillBuffer( void* buffer, unsigned int nSamples );
	
	// info
	virtual const char* getCurrentTitle();
	virtual const char* getAuthor();
	virtual int getPlaybackLength();
	virtual int getPlaybackSeconds();
	virtual const char* getReleaseInfo();
	
	// subtunes
	virtual bool haveSubtunes() { return true; };
	virtual int getSubtuneCount() { return mAsapState.module_info.songs; };
	virtual int getDefaultSubtune() { return mAsapState.module_info.default_song + 1; };
	virtual int getCurrentSubtune() { return mCurrentSubtune + 1; };
	virtual void startNextSubtune();
	virtual void startPrevSubtune();
	
	// mod-specific info
	uint getNumberOfSamples();
	const char* getSampleName( uint i );
	uint getNumberOfChannels();
	uint getNumberOfPatterns();
	
protected:
	bool loadFileIntoMemory(const char* filename);

private:
	AudioDriver*		mAudioDriver;
	pthread_mutex_t		mEngineMutex;
	
	ASAP_State			mAsapState;
	int					mCurrentSubtune;
	
	void*				mSongData;
	long				mSongDataLength;
	
	int					mPlaybackPosition;
};

#endif
