#ifndef _PlayerLibModPlug_H
#define _PlayerLibModPlug_H

#import "Player.h"
#import "AudioDriver.h"

#import <pthread.h>

#import "libmodplug-0.8.4/src/modplug.h"

#define uint unsigned int

class PlayerLibModPlug : public Player
{
public:
	PlayerLibModPlug();
	virtual ~PlayerLibModPlug();

	// play
	virtual void setAudioDriver( AudioDriver* audioDriver );
	virtual bool playTuneByPath( const char* filename );
	virtual bool playTuneFromBuffer( void* buffer, long size );
	virtual void fillBuffer( void* buffer, unsigned int nSamples );
	virtual void seek( double t );

	// info
	virtual const char* getCurrentTitle();
	virtual int getPlaybackLength();
	virtual int getPlaybackSeconds();
	virtual void getPlaybackPosition( int* pattern, int* row );
	virtual const char* getReleaseInfo();
	
	// mod-specific info
	uint getNumberOfSamples();
	const char* getSampleName( uint i );
	uint getNumberOfChannels();
	uint getNumberOfPatterns();
	
	// sound settings
	void setNoiseReduction( bool on );
	void setOversampling( bool on );
	void setReverb( bool on, uint delay, uint depth );
	void setBass( bool on, uint depth, uint freq );
	void setSurround( bool on, uint delay, uint depth );
	void syncSettings();

protected:
	bool loadFileIntoMemory(const char* filename);

private:
	AudioDriver*		mAudioDriver;
	pthread_mutex_t		mEngineMutex;
	
	void*				mSongData;
	long				mSongDataLength;
	
	ModPlugFile*		mModPlugFile;
	ModPlug_Settings	mSettings;
	
	int					mPlaybackPosition;
};

#endif
