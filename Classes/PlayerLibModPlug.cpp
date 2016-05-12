#import "PlayerLibModPlug.h"

#import <stdio.h>
#import <stdlib.h>

PlayerLibModPlug::PlayerLibModPlug()
                 :Player()
{
	pthread_mutex_init( &mEngineMutex, NULL );
	
	ModPlug_GetSettings( &mSettings );

	// DO NOT MODIFY
	mSettings.mResamplingMode = MODPLUG_RESAMPLE_FIR; /* HIGH QUALITY */
    mSettings.mChannels = 2;
    mSettings.mBits = 16;
    mSettings.mFrequency = 44100;

	// default sound settings	
	mSettings.mFlags = MODPLUG_ENABLE_OVERSAMPLING | MODPLUG_ENABLE_NOISE_REDUCTION | MODPLUG_ENABLE_SURROUND;
	
	mSettings.mReverbDepth = 60;    /* Reverb level 0(quiet)-100(loud)      */
	mSettings.mReverbDelay = 100;    /* Reverb delay in ms, usually 40-200ms */
	mSettings.mBassAmount  = 30;     /* XBass level 0(quiet)-100(loud)       */
	mSettings.mBassRange   = 70;      /* XBass cutoff in Hz 10-100            */
	mSettings.mSurroundDepth = 100;  /* Surround level 0(quiet)-100(heavy)   */
	mSettings.mSurroundDelay = 40;  /* Surround delay in ms, usually 5-40ms */
	mSettings.mLoopCount = 0;      /* Number of times to loop.  Zero prevents looping. -1 loops forever. */
	
	ModPlug_SetSettings( &mSettings );
}


PlayerLibModPlug::~PlayerLibModPlug()
{
}


void PlayerLibModPlug::setAudioDriver(AudioDriver* audioDriver)
{
	mAudioDriver = audioDriver;
}

bool PlayerLibModPlug::loadFileIntoMemory(const char* filename)
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

bool PlayerLibModPlug::playTuneByPath(const char *filename)
{
	printf("loading file: %s\n", filename);
	
	//mAudioDriver->stopPlayback();
	
	bool success = loadFileIntoMemory( filename );
	
	printf("load1 returned: %d\n", success);
	
	if (!success)
		return success;
	
	return playTuneFromBuffer( mSongData, mSongDataLength );
}

bool PlayerLibModPlug::playTuneFromBuffer(void* buffer, long size)
{
	mModPlugFile = ModPlug_Load(buffer, size);
	
	printf("modplugfile = %p\n", mModPlugFile);
	
	if (!mModPlugFile)
		return false;
	
	printf( "module name = %s ('%s')\n", ModPlug_GetName(mModPlugFile), ModPlug_GetMessage(mModPlugFile) );
	
	printf( "number of samples = %d\n", ModPlug_NumSamples(mModPlugFile) );
	for( int i = 1; i <= ModPlug_NumSamples(mModPlugFile); ++i )
	{
		char name[512];
		ModPlug_SampleName(mModPlugFile, i, name);
		printf( "sample %02d= '%s'\n", i, name );
	}
	
	
	ModPlug_SetMasterVolume(mModPlugFile, 400 );
	
	mPlaybackPosition = 0;
	mAudioDriver->startPlayback( this );
	
	return true;
}


void PlayerLibModPlug::fillBuffer(void* buffer, unsigned int len)
{
	//printf("PlayerLibModPlug::fillBuffer\n");
	
	int mlen = ModPlug_Read( mModPlugFile, buffer, len );
	mlen;
	mPlaybackPosition += mAudioDriver->getBufferSizeMs();
	
	//printf( "filled %d bytes\n", mlen );
	
}

void PlayerLibModPlug::seek( double t )
{
	int mpos = (double)ModPlug_GetLength(mModPlugFile) * t;
	ModPlug_Seek(mModPlugFile, mpos);
	mPlaybackPosition = mpos;
}

const char* PlayerLibModPlug::getCurrentTitle()
{
	return ModPlug_GetName(mModPlugFile);
}

int PlayerLibModPlug::getPlaybackLength()
{
	return ModPlug_GetLength(mModPlugFile) / 1000;
}

int PlayerLibModPlug::getPlaybackSeconds()
{

	return mPlaybackPosition / 1000;
}

void PlayerLibModPlug::getPlaybackPosition( int* pattern, int* row )
{
	*pattern = ModPlug_GetCurrentPattern(mModPlugFile);
	*row = ModPlug_GetCurrentRow(mModPlugFile);
}

const char* PlayerLibModPlug::getReleaseInfo()
{
	if (!mModPlugFile)
		return "unknown";
	
	const char* info = ModPlug_GetMessage(mModPlugFile);
	
	return info ? info : "(no release info)";
}

uint PlayerLibModPlug::getNumberOfSamples()
{
	return mModPlugFile ? ModPlug_NumSamples(mModPlugFile) : 0;
}

const char* PlayerLibModPlug::getSampleName( uint i )
{
	static char name[1024];
	if (mModPlugFile)
	{
		ModPlug_SampleName(mModPlugFile, i+1, name);
		printf("%s\n",name);
		return name;
	}
	else
		return "";
}

uint PlayerLibModPlug::getNumberOfChannels()
{
	return mModPlugFile ? ModPlug_NumChannels(mModPlugFile) : 0;
}

uint PlayerLibModPlug::getNumberOfPatterns()
{
	return mModPlugFile ? ModPlug_NumPatterns(mModPlugFile) : 0;
}


#pragma mark -
#pragma mark Sound Settings
#pragma mark -

void PlayerLibModPlug::setNoiseReduction( bool on )
{
	if (on)
		mSettings.mFlags |= MODPLUG_ENABLE_NOISE_REDUCTION;
	else
		mSettings.mFlags &= ~MODPLUG_ENABLE_NOISE_REDUCTION;
}

void PlayerLibModPlug::setOversampling( bool on )
{
	if (on)
		mSettings.mFlags |= MODPLUG_ENABLE_OVERSAMPLING;
	else
		mSettings.mFlags &= ~MODPLUG_ENABLE_OVERSAMPLING;
}

void PlayerLibModPlug::setReverb( bool on, uint delay, uint depth )
{
	if (on)
	{
		mSettings.mFlags |= MODPLUG_ENABLE_REVERB;
		mSettings.mReverbDelay = delay;
		mSettings.mReverbDepth = depth;
	}
	else
	{
		mSettings.mFlags &= ~MODPLUG_ENABLE_REVERB;
		mSettings.mReverbDelay = 0;
		mSettings.mReverbDepth = 0;
	}
}

void PlayerLibModPlug::setBass( bool on, uint depth, uint freq )
{
	if (on)
	{
		mSettings.mFlags |= MODPLUG_ENABLE_MEGABASS;
		mSettings.mBassAmount = depth;
		mSettings.mBassRange = freq;
	}
	else
	{
		mSettings.mFlags &= ~MODPLUG_ENABLE_MEGABASS;
		mSettings.mBassAmount = 0;
		mSettings.mBassRange = 0;
	}
}

void PlayerLibModPlug::setSurround( bool on, uint delay, uint depth )
{
	if (on)
	{
		mSettings.mFlags |= MODPLUG_ENABLE_SURROUND;
		mSettings.mSurroundDelay = delay;
		mSettings.mSurroundDepth = depth;
	}
	else
	{
		mSettings.mFlags &= ~MODPLUG_ENABLE_SURROUND;
		mSettings.mSurroundDelay = 0;
		mSettings.mSurroundDepth = 0;
	}
}

void PlayerLibModPlug::syncSettings()
{
	ModPlug_SetSettings( &mSettings );
}
