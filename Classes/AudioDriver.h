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

#ifndef _AUDIODRIVER_H_
#define _AUDIODRIVER_H_

class Player;

class AudioDriver
{
public:
	virtual ~AudioDriver() { }

	virtual void initialize(int sampleRate = 44100, int bitsPerSample = 16) = 0;

	virtual bool startPlayback(Player* player) = 0;
	virtual void stopPlayback() = 0;

	virtual float getVolume() = 0;
	virtual void setVolume(float volume) = 0;

	virtual int getSampleRate() = 0;
	virtual long getBufferSizeMs() = 0;

	virtual bool getIsPlaying() = 0;

	float getPerformance() { return mBufferFillPerformance; };
	void resetPerformance() { mBufferFillPerformance = 0.0f; };
	
	virtual short* getSampleBuffer() = 0;

protected:
	float mBufferFillPerformance;
};


#endif // _AUDIODRIVER_H_
