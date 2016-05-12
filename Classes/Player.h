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

#ifndef _PLAYER_H_
#define _PLAYER_H_

class AudioDriver;

class Player
{
public:
	Player() {};
	virtual ~Player() {};

	// play
	virtual void setAudioDriver(AudioDriver* audioDriver) = 0;
#ifndef SIDPLAYER
	virtual bool playTuneByPath(const char *filename) = 0;
	virtual bool playTuneFromBuffer(void* buffer, long size) = 0;
#endif
	virtual void fillBuffer(void* buffer, unsigned int nSamples) = 0;

	// informational
	virtual const char* getCurrentTitle()
	{
		return "unknown title";
	};
	virtual int getPlaybackSeconds()
	{
		return 0;
	};
	virtual int getPlaybackLength()
	{
		return 180;
	};
	virtual void getPlaybackPosition( int* pattern, int* row )
	{
	}
	// subtunes
	virtual bool haveSubTunes()
	{
		return false;
	};
	virtual void startNextSubtune()
	{
	};
	virtual void startPrevSubtune()
	{
	};
	virtual int getSubtuneCount()
	{
		return 0;
	};
	virtual int getDefaultSubtune()
	{
		return 0;
	};
	virtual int getCurrentSubtune()
	{
		return 0;
	};
	virtual void seek(double t)
	{
	};
	virtual const char* getAuthor()
	{
		return "";
	};
	virtual const char* getReleaseInfo()
	{
		return "";
	};
	virtual const char* getTuneInfo()
	{
		return "";
	};
	
};

#endif // _PLAYER_H_

