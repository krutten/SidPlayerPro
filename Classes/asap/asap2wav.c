/*
 * asap2wav.c - converter of ASAP-supported formats to WAV files
 *
 * Copyright (C) 2005-2009  Piotr Fusik
 *
 * This file is part of ASAP (Another Slight Atari Player),
 * see http://asap.sourceforge.net
 *
 * ASAP is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published
 * by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 *
 * ASAP is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty
 * of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with ASAP; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

#include "asap.h"

static const char *output_file = NULL;
static abool output_header = TRUE;
static int song = -1;
static abool use_16bit = TRUE;
static int duration = -1;
static int mute_mask = 0;

static void print_help(void)
{
	printf(
		"Usage: asap2wav [OPTIONS] INPUTFILE...\n"
		"Each INPUTFILE must be in a supported format:\n"
		"SAP, CMC, CMR, DMC, MPT, MPD, RMT, TMC, TM8 or TM2.\n"
		"Options:\n"
		"-o FILE     --output=FILE      Set output file name\n"
		"-o -        --output=-         Write to standard output\n"
		"-s SONG     --song=SONG        Select subsong number (zero-based)\n"
		"-t TIME     --time=TIME        Set output length (MM:SS format)\n"
		"-b          --byte-samples     Output 8-bit samples\n"
		"-w          --word-samples     Output 16-bit samples (default)\n"
		"            --raw              Output raw audio (no WAV header)\n"
		"-m CHANNELS --mute=CHANNELS    Mute POKEY channels (1-8)\n"
		"-h          --help             Display this information\n"
		"-v          --version          Display version information\n"
	);
}

static void fatal_error(const char *format, ...)
{
	va_list args;
	va_start(args, format);
	fprintf(stderr, "asap2wav: ");
	vfprintf(stderr, format, args);
	fputc('\n', stderr);
	va_end(args);
	exit(1);
}

static void set_song(const char *s)
{
	song = 0;
	do {
		if (*s < '0' || *s > '9')
			fatal_error("subsong number must be an integer");
		song = 10 * song + *s++ - '0';
		if (song > 31)
			fatal_error("maximum subsong number is 31");
	} while (*s != '\0');
}

static void set_time(const char *s)
{
	duration = ASAP_ParseDuration(s);
	if (duration <= 0)
		fatal_error("invalid time format");
}

static void set_mute_mask(const char *s)
{
	int mask = 0;
	while (*s != '\0') {
		if (*s >= '1' && *s <= '8')
			mask |= 1 << (*s - '1');
		s++;
	}
	mute_mask = mask;
}

/* write 16-bit word as little endian */
static void fput16(int x, FILE *fp)
{
	fputc(x & 0xff, fp);
	fputc((x >> 8) & 0xff, fp);
}

/* write 32-bit word as little endian */
static void fput32(int x, FILE *fp)
{
	fputc(x & 0xff, fp);
	fputc((x >> 8) & 0xff, fp);
	fputc((x >> 16) & 0xff, fp);
	fputc((x >> 24) & 0xff, fp);
}

static void process_file(const char *input_file)
{
	FILE *fp;
	static byte module[ASAP_MODULE_MAX];
	int module_len;
	static ASAP_State asap;
	int n_bytes;
	static byte buffer[8192];
	if (strlen(input_file) >= FILENAME_MAX)
		fatal_error("filename too long");
	fp = fopen(input_file, "rb");
	if (fp == NULL)
		fatal_error("cannot open %s", input_file);
	module_len = fread(module, 1, sizeof(module), fp);
	fclose(fp);
	if (!ASAP_Load(&asap, input_file, module, module_len))
		fatal_error("%s: format not supported", input_file);
	if (song < 0)
		song = asap.module_info.default_song;
	if (song >= asap.module_info.songs) {
		fatal_error("you have requested subsong %d ...\n"
			"... but %s contains only %d subsongs",
			song, input_file, asap.module_info.songs);
	}
	if (duration < 0) {
		duration = asap.module_info.durations[song];
		if (duration < 0)
			duration = 180 * 1000;
	}
	ASAP_PlaySong(&asap, song, duration);
	ASAP_MutePokeyChannels(&asap, mute_mask);
	if (output_file == NULL) {
		static char output_default[FILENAME_MAX];
		strcpy(output_default, input_file);
		ASAP_ChangeExt(output_default, output_header ? "wav" : "raw");
		output_file = output_default;
	}
	if (output_file[0] == '-' && output_file[1] == '\0')
		fp = stdout;
	else {
		fp = fopen(output_file, "wb");
		if (fp == NULL)
			fatal_error("cannot write %s", output_file);
	}
	if (output_header) {
		int block_size = asap.module_info.channels << use_16bit;
		int bytes_per_second = ASAP_SAMPLE_RATE * block_size;
		n_bytes = duration * (ASAP_SAMPLE_RATE / 100) / 10 * block_size;
		fwrite("RIFF", 1, 4, fp);
		fput32(n_bytes + 36, fp);
		fwrite("WAVEfmt \x10\0\0\0\1\0", 1, 14, fp);
		fput16(asap.module_info.channels, fp);
		fput32(ASAP_SAMPLE_RATE, fp);
		fput32(bytes_per_second, fp);
		fput16(block_size, fp);
		fput16(8 << use_16bit, fp);
		fwrite("data", 1, 4, fp);
		fput32(n_bytes, fp);
	}
	do {
		n_bytes = ASAP_Generate(&asap, buffer, sizeof(buffer),
			use_16bit ? ASAP_FORMAT_S16_LE : ASAP_FORMAT_U8);
		if (fwrite(buffer, 1, n_bytes, fp) != n_bytes) {
			fclose(fp);
			fatal_error("error writing to %s", output_file);
		}
	} while (n_bytes == sizeof(buffer));
	if (!(output_file[0] == '-' && output_file[1] == '\0'))
		fclose(fp);
	output_file = NULL;
	song = -1;
	duration = -1;
}

int main(int argc, char *argv[])
{
	abool no_input_files = TRUE;
	int i;
	for (i = 1; i < argc; i++) {
		const char *arg = argv[i];
		if (arg[0] != '-') {
			process_file(arg);
			no_input_files = FALSE;
		}
		else if (arg[1] == 'o' && arg[2] == '\0')
			output_file = argv[++i];
		else if (strncmp(arg, "--output=", 9) == 0)
			output_file = arg + 9;
		else if (arg[1] == 's' && arg[2] == '\0')
			set_song(argv[++i]);
		else if (strncmp(arg, "--song=", 7) == 0)
			set_song(arg + 7);
		else if (arg[1] == 't' && arg[2] == '\0')
			set_time(argv[++i]);
		else if (strncmp(arg, "--time=", 7) == 0)
			set_time(arg + 7);
		else if ((arg[1] == 'b' && arg[2] == '\0')
			|| strcmp(arg, "--byte-samples") == 0)
			use_16bit = FALSE;
		else if ((arg[1] == 'w' && arg[2] == '\0')
			|| strcmp(arg, "--word-samples") == 0)
			use_16bit = TRUE;
		else if (strcmp(arg, "--raw") == 0)
			output_header = FALSE;
		else if (arg[1] == 'm' && arg[2] == '\0')
			set_mute_mask(argv[++i]);
		else if (strncmp(arg, "--mute=", 7) == 0)
			set_mute_mask(arg + 7);
		else if ((arg[1] == 'h' && arg[2] == '\0')
			|| strcmp(arg, "--help") == 0) {
			print_help();
			no_input_files = FALSE;
		}
		else if ((arg[1] == 'v' && arg[2] == '\0')
			|| strcmp(arg, "--version") == 0) {
			printf("ASAP2WAV " ASAP_VERSION "\n");
			no_input_files = FALSE;
		}
		else
			fatal_error("unknown option: %s", arg);
	}
	if (no_input_files) {
		print_help();
		return 1;
	}
	return 0;
}
