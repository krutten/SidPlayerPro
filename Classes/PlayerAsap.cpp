#import "PlayerAsap.h"
#import <assert.h>
#import <stdio.h>
#import <stdlib.h>

PlayerAsap::PlayerAsap()
           :Player()
{
	pthread_mutex_init( &mEngineMutex, NULL );
	
}


PlayerAsap::~PlayerAsap()
{
}


void PlayerAsap::setAudioDriver(AudioDriver* audioDriver)
{
	mAudioDriver = audioDriver;
}

bool PlayerAsap::loadFileIntoMemory(const char* filename)
{
	/* declare a file pointer */
	FILE    *infile;
	char    *buffer;
	long    numbytes;
	
	/* open an existing file for reading */
	infile = fopen( filename, "r");
	
	/* quit if the file does not exist */
	if(infile == NULL)
		return false;
	
	/* Get the number of bytes */
	fseek(infile, 0L, SEEK_END);
	numbytes = ftell(infile);
	
	/* reset the file position indicator to 
	 the beginning of the file */
	fseek(infile, 0L, SEEK_SET);	
	
	/* grab sufficient memory for the 
	 buffer to hold the text */
	buffer = (char*)calloc(numbytes, sizeof(char));	
	
	/* memory error */
	if(buffer == NULL)
		return 1;
	
	/* copy all the text into the buffer */
	fread(buffer, sizeof(char), numbytes, infile);
	fclose(infile);
	
	mSongData = buffer;
	mSongDataLength = numbytes;
	return true;
	
	/* free the memory we used for the buffer */
	//free(buffer);
}

bool PlayerAsap::playTuneByPath(const char *filename)
{
	printf("loading file: %s\n", filename);
	
	//mAudioDriver->stopPlayback();
	
	bool success = loadFileIntoMemory( filename );
	
	printf("load1 returned: %d\n", success);
	
	if (!success)
		return success;
	
	return playTuneFromBuffer( mSongData, mSongDataLength );
}

bool PlayerAsap::playTuneFromBuffer(void* buffer, long size)
{
	bool success = ASAP_Load(&mAsapState, "somefile.sap", (const byte*)buffer, size);
	if ( !success )
	{
		printf( "ASAP_Load failed\n" );
		return false;
	}
	else
	{
		printf( "ASAP_Load OK\n" );
	}
	ASAP_PlaySong(&mAsapState, mAsapState.module_info.default_song, -1);
	
	printf( "ASAP channels: %d | subsongs: %d | default: %d\n",
		   mAsapState.module_info.channels,
		   mAsapState.module_info.songs,
		   mAsapState.module_info.default_song);
	
	mCurrentSubtune = mAsapState.module_info.default_song;
	mPlaybackPosition = 0;
	mAudioDriver->startPlayback( this );
	
	return true;
}

void PlayerAsap::fillBuffer(void* buffer, unsigned int len)
{
	//printf("PlayerAsap::fillBuffer\n");
	
	if ( mAsapState.module_info.channels == 1 )
	{
		unsigned short* audiobuf = (unsigned short*)buffer;

		unsigned short* monobuf = (unsigned short*) malloc( len / 2 );
		unsigned short* buf = monobuf;

		// fill mono buffer
		ASAP_Generate(&mAsapState, monobuf, len/2, ASAP_FORMAT_S16_LE);

		// create stereo
		for( int i = 0; i < len/2; ++i )
		{
			audiobuf[i*2+0] = buf[i];
			audiobuf[i*2+1] = buf[i];
		}
		free( monobuf );
	}
	else // stereo
	{
		ASAP_Generate(&mAsapState, buffer, len, ASAP_FORMAT_S16_LE);
	}
	
	mPlaybackPosition += mAudioDriver->getBufferSizeMs();
}

const char* PlayerAsap::getCurrentTitle()
{
	return mAsapState.module_info.name;
}

const char* PlayerAsap::getAuthor()
{
	return mAsapState.module_info.author;
}

const char* PlayerAsap::getReleaseInfo()
{
	return mAsapState.module_info.date;
}

int PlayerAsap::getPlaybackLength()
{
	return mAsapState.module_info.durations[mAsapState.module_info.default_song] / 1000;
}

int PlayerAsap::getPlaybackSeconds()
{
	return mPlaybackPosition / 1000;
}

uint PlayerAsap::getNumberOfSamples()
{
	return 0; //return mModPlugFile ? ModPlug_NumSamples(mModPlugFile) : 0;
}

void PlayerAsap::startNextSubtune()
{
	if (mCurrentSubtune < mAsapState.module_info.songs-1)
	{
		ASAP_PlaySong(&mAsapState, ++mCurrentSubtune, -1);
	}
}

void PlayerAsap::startPrevSubtune()
{
	if (mCurrentSubtune > 0)
	{
		ASAP_PlaySong(&mAsapState, --mCurrentSubtune, -1);
	}
}


#pragma mark -
#pragma mark Sound Settings
#pragma mark -

