/*
 *
 * Copyright (c) 2005, Andreas Varga <sid@galway.c64.org>
 * All rights reserved.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */


#ifndef _PlayerLibSidplay_H
#define _PlayerLibSidplay_H

#import "Player.h"
#import "AudioDriver.h"

#include <sidplay2.h>
#include <resid.h>
#include <resid-emu.h>

#import <pthread.h>

enum SPFilterType
{
	SID_FILTER_6581_Resid = 0,
	SID_FILTER_6581R3,
	SID_FILTER_6581_Galway,
	SID_FILTER_6581R4,
	SID_FILTER_8580,
	SID_FILTER_CUSTOM
};


struct PlaybackSettings
{
	int mFrequency;
	int mBits;
	int mStereo;

	int mOversampling;
	int mSidModel;
	bool mForceSidModel;
	int mClockSpeed;
	int mOptimization;

	float mFilterKinkiness;
	float mFilterBaseLevel;
	float mFilterOffset;
	float mFilterSteepness;
	float mFilterRolloff;
	SPFilterType mFilterType;

	int mEnableFilterDistortion;
	int	mDistortionRate;
	int	mDistortionHeadroom;

};

const int TUNE_BUFFER_SIZE = 65536 + 2 + 0x7c;
extern unsigned char sid_registers[0x19];

class PlayerLibSidplay : public Player
{
public:
	PlayerLibSidplay();
	virtual ~PlayerLibSidplay();

	void setAudioDriver(AudioDriver* audioDriver);

	void initEmuEngine(PlaybackSettings *settings);
	void updateSampleRate(int newSampleRate);

	bool playTuneByPath(const char *filename, int subtune, PlaybackSettings *settings );
	bool playTuneFromBuffer( char *buffer, int length, int subtune, PlaybackSettings *settings );

	bool loadTuneByPath(const char *filename, int subtune, PlaybackSettings *settings );
	bool loadTuneFromBuffer( char *buffer, int length, int subtune, PlaybackSettings *settings );

	void startPrevSubtune();
	void startNextSubtune();
	bool startSubtune(int which);
	bool initCurrentSubtune();

	inline int getTempo()									{ return mCurrentTempo; }
	void setTempo(int tempo);

	void setVoiceVolume(int voice, float volume);

	sid_filter_t* getFilterSettings()						{ return &mFilterSettings; }
	void setFilterSettings(sid_filter_t* filterSettings);

	inline bool isTuneLoaded()								{ return mSidTune != NULL; }

	int getPlaybackSeconds();
	inline int getCurrentSubtune()							{ return mCurrentSubtune; }
	inline int getSubtuneCount()							{ return mSubtuneCount; }
	inline int getDefaultSubtune()							{ return mDefaultSubtune; }
	inline const char* getCurrentTitle()					{ return mTuneInfo.infoString[0]; }
	const char* getAuthor();
	const char* getReleaseInfo();
	inline unsigned short getCurrentInitAddress()			{ return mTuneInfo.initAddr; }
	inline unsigned short getCurrentPlayAddress()			{ return mTuneInfo.playAddr; }
	inline const char* getCurrentFormat()					{ return mTuneInfo.formatString; }
	inline int getCurrentFileSize()							{ return mTuneInfo.dataFileLen; }
	inline char* getTuneBuffer(int& outTuneLength)			{ outTuneLength = mTuneLength; return mTuneBuffer; }

	inline const char* getCurrentChipModel()
	{
		if (mTuneInfo.sidModel == SIDTUNE_SIDMODEL_6581) return sChipModel6581;
		if (mTuneInfo.sidModel == SIDTUNE_SIDMODEL_8580) return sChipModel8580;
		return sChipModelUnspecified;
	}

	inline unsigned char* getCurrentSidRegisters()			{ return sid_registers; }

	virtual void fillBuffer(void* buffer, unsigned int nSamples); // from Player

	static void	setFilterSettingsFromPlaybackSettings(sid_filter_t& filterSettings, PlaybackSettings* settings);

	static const char*	sChipModel6581;
	static const char*	sChipModel8580;
	static const char*	sChipModelUnknown;
	static const char*	sChipModelUnspecified;

private:

	bool initSIDTune(PlaybackSettings *settings);
	void setupSIDInfo();

	sidplay2*			mSidEmuEngine;
	SidTune*			mSidTune;
	ReSIDBuilder*		mBuilder;
	SidTuneInfo			mTuneInfo;
	PlaybackSettings	mPlaybackSettings;

	AudioDriver*		mAudioDriver;

	char				mTuneBuffer[TUNE_BUFFER_SIZE];
	int					mTuneLength;

	int					mCurrentSubtune;
	int					mSubtuneCount;
	int					mDefaultSubtune;
	int					mCurrentTempo;

	int					mPreviousOversamplingFactor;
	char*				mOversamplingBuffer;

	sid_filter_t		mFilterSettings;

	pthread_mutex_t		mEngineMutex;
};

#endif
