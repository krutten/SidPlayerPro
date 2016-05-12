#!/usr/bin/env python2.5
# -*- coding: utf-8 -*-
# generate Retro Player database from HVSC, ASMA, or ModLand allsongs.txt
# (C) 2008-2010 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
# All Rights Reserved

__version__ = "1.6.4"

import sys, os, re, sqlite3, subprocess, urllib

#
# Index and Info Database
#
SQL_INIT = """PRAGMA encoding = "UTF-8";"""
SQL_SONG_CREATE_TABLE = "CREATE TABLE Songs (ID INTEGER PRIMARY KEY, fkAuthor INTEGER, Name TEXT COLLATE NOCASE, Type TEXT COLLATE NOCASE, URI TEXT, Cached BOOL, Duration INTEGER, PlayedCounter INTEGER, ProblemsFound BOOL, STIL TEXT);"
SQL_SONG_ADD = "INSERT INTO Songs (fkAuthor, Name, Type, URI, Cached, Duration, PlayedCounter, ProblemsFound, STIL) VALUES (?,?,?,?,'FALSE',?,0,'FALSE',?);"
SQL_SONG_CREATE_INDEX = "CREATE INDEX IdxAuthorName ON Songs (fkAuthor, Name);"

SQL_AUTHOR_CREATE_TABLE = "CREATE TABLE Authors (ID INTEGER PRIMARY KEY, Name TEXT COLLATE NOCASE, Cached BOOL, SongCount INTEGER NOT NULL DEFAULT '0');"
SQL_AUTHOR_ADD = "INSERT INTO Authors (Name, Cached) VALUES (?,'FALSE');"
SQL_AUTHOR_CREATE_INDEX = "CREATE INDEX IdxName ON Authors (Name);"
SQL_AUTHOR_SONG_COUNT = "UPDATE AUTHORS SET SongCount = (SELECT SUM(Rest+A+B+C+D+E+F+G+H+I+J+K+L+M+N+O+P+Q+R+S+T+U+V+W+X+Y+Z) FROM SongsCounted WHERE Authors.ID = SongsCounted.fkAuthor);"

SQL_AUTHORCOUNTER_CREATE_TABLE = "CREATE TABLE AuthorsCounted (Rest INTEGER, A INTEGER, B INTEGER, C INTEGER, D INTEGER, E INTEGER, F INTEGER, G INTEGER, H INTEGER, I INTEGER, J INTEGER, K INTEGER, L INTEGER, M INTEGER, N INTEGER, O INTEGER, P INTEGER, Q INTEGER, R INTEGER, S INTEGER, T INTEGER, U INTEGER, V INTEGER, W INTEGER, X INTEGER, Y INTEGER, Z INTEGER);"
SQL_AUTHORCOUNTER_ADD = "INSERT INTO AuthorsCounted (Rest, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);"
SQL_AUTHORCOUNTER_QUERY = "SELECT COUNT (ID) FROM Authors WHERE Name GLOB '%s';"

SQL_PLAYLISTS_POPULATE_TABLES = [
    "CREATE TABLE Playlists (Position NUMERIC, Type TEXT, ID INTEGER PRIMARY KEY, Name TEXT);",
    "INSERT INTO Playlists (Position, Type, ID, Name) VALUES (1,'fixed',1,'Top50');",
    "INSERT INTO Playlists (Position, Type, ID, Name) VALUES (1,'modifiable',2,'Favorites');",
    "INSERT INTO Playlists (Position, Type, ID, Name) VALUES (2,'fixed',3,'Random');",
    "INSERT INTO Playlists (Position, Type, ID, Name) VALUES (3,'fixed',4,'Top100');",
    "INSERT INTO Playlists (Position, Type, ID, Name) VALUES (4,'fixed',5,'Top64');",
    "CREATE TABLE SongsInPlaylists (Position NUMERIC, fkPlaylist INTEGER, fkSong INTEGER);"
]

SQL_SONGSPLAYED_CREATE_TABLE = "CREATE TABLE SongsPlayed (fkSong INTEGER PRIMARY KEY DEFAULT NULL, Counted INTEGER DEFAULT NULL);"

SQL_SONG_QUERY_ID = "SELECT ID FROM Songs WHERE URI = '%s';"
SQL_PLAYLIST_ADD_SONG = "INSERT INTO SongsInPLaylists (Position, fkPlaylist, fkSong) VALUES (%d,%d,%d);"

SQL_SONGCOUNTER_CREATE_TABLE = "CREATE TABLE SongsCounted (Rest INTEGER, A INTEGER, B INTEGER, C INTEGER, D INTEGER, E INTEGER, F INTEGER, G INTEGER, H INTEGER, I INTEGER, J INTEGER, K INTEGER, L INTEGER, M INTEGER, N INTEGER, O INTEGER, P INTEGER, Q INTEGER, R INTEGER, S INTEGER, T INTEGER, U INTEGER, V INTEGER, W INTEGER, X INTEGER, Y INTEGER, Z INTEGER, fkAuthor INTEGER PRIMARY KEY);"
SQL_SONGCOUNTER_ADD = "INSERT INTO SongsCounted (Rest, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z, fkAuthor) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);"
SQL_SONGCOUNTER_QUERY = "SELECT COUNT (ID) FROM Songs WHERE fkAuthor = '%s' AND Name GLOB '%s';"

#
# Song File Content Database
#
SQL_FILES_CREATE_TABLE = "CREATE TABLE Files (Data BLOB, ID INTEGER PRIMARY KEY);"
SQL_FILES_FILE_ADD = "INSERT INTO Files (Data) VALUES (?);"

#
# Cached Tables
#
SQL_AUTHOR_CACHECOUNTER_CREATE_TABLE = "CREATE TABLE AuthorsCachedCounted (Rest INTEGER, A INTEGER, B INTEGER, C INTEGER, D INTEGER, E INTEGER, F INTEGER, G INTEGER, H INTEGER, I INTEGER, J INTEGER, K INTEGER, L INTEGER, M INTEGER, N INTEGER, O INTEGER, P INTEGER, Q INTEGER, R INTEGER, S INTEGER, T INTEGER, U INTEGER, V INTEGER, W INTEGER, X INTEGER, Y INTEGER, Z INTEGER);"
SQL_AUTHOR_CACHECOUNTER_ADD = "INSERT INTO AuthorsCachedCounted (Rest, A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z) VALUES (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);"
SQL_SONG_CACHECOUNTER_TABLE = "CREATE TABLE SongsCachedCounted (Rest INTEGER, A INTEGER, B INTEGER, C INTEGER, D INTEGER, E INTEGER, F INTEGER, G INTEGER, H INTEGER, I INTEGER, J INTEGER, K INTEGER, L INTEGER, M INTEGER, N INTEGER, O INTEGER, P INTEGER, Q INTEGER, R INTEGER, S INTEGER, T INTEGER, U INTEGER, V INTEGER, W INTEGER, X INTEGER, Y INTEGER, Z INTEGER, fkAuthor INTEGER PRIMARY KEY);"

#
# Misc constants
#
RE_FINDSTRING = re.compile( '''"[^"]*"''' )

ANSI_TABLE = u"""€ ‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—™š›œžŸ ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÒÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ         """

# set maximum files to include
#MAX_SONGS = 25
# set to "hvsc" or "file"
AUTHOR = "hvsc"
# set to "strict" or "fuzzy"
MATCHING = "strict"
# set something between 0.0 and 1.0
FUZZY_THRESHOLD = 0.73
# set to a number of seconds
DEFAULT_SONGLENGTH = 3 * 60

#
# Top 100 Hvsc
#
TOP100 = [ \
    "/MUSICIANS/D/Daglish_Ben/Last_Ninja%s",
    "/MUSICIANS/G/Galway_Martin/Wizball%s",
    "/MUSICIANS/H/Hubbard_Rob/Sanxion%s",
    "/MUSICIANS/H/Hubbard_Rob/International_Karate%s",
    "/MUSICIANS/H/Hubbard_Rob/Commando%s",
    "/MUSICIANS/T/Tel_Jeroen/Cybernoid_II%s",
    "/MUSICIANS/H/Hubbard_Rob/Delta%s",
    "/MUSICIANS/G/Galway_Martin/Rambo_First_Blood_Part_II%s",
    "/MUSICIANS/H/Hubbard_Rob/Monty_on_the_Run%s",
    "/MUSICIANS/G/Galway_Martin/Arkanoid%s",
    "/MUSICIANS/H/Hubbard_Rob/Crazy_Comets%s",
    "/MUSICIANS/T/Tel_Jeroen/Cybernoid%s",
    "/MUSICIANS/O/Ouwehand_Reyn/Last_Ninja_3%s",
    "/MUSICIANS/G/Gray_Matt/Last_Ninja_2%s",
    "/MUSICIANS/G/Gray_Fred/Mutants%s",
    "/MUSICIANS/H/Hubbard_Rob/Knucklebusters%s",
    "/MUSICIANS/H/Hubbard_Rob/Auf_Wiedersehen_Monty%s",
    "/MUSICIANS/C/Cooksey_Mark/Ghosts_n_Goblins%s",
    "/MUSICIANS/H/Hubbard_Rob/Nemesis_the_Warlock%s",
    "/MUSICIANS/G/Galway_Martin/Green_Beret%s",
    "/MUSICIANS/B/Brennan_Neil/Way_of_the_Exploding_Fist%s",
    "/MUSICIANS/D/Dunn_Jonathan/Platoon%s",
    "/MUSICIANS/H/Huelsbeck_Chris/R-Type%s",
    "/MUSICIANS/D/Daglish_Ben/Cobra%s",
    "/MUSICIANS/H/Huelsbeck_Chris/Great_Giana_Sisters%s",
    "/MUSICIANS/T/Tel_Jeroen/Myth%s",
    "/MUSICIANS/F/Follin_Tim/Ghouls_n_Ghosts%s",
    "/MUSICIANS/B/Bjerregaard_Johannes/Stormlord%s",
    "/MUSICIANS/G/Galway_Martin/Parallax%s",
    "/MUSICIANS/H/Hubbard_Rob/Lightforce%s",
    "/MUSICIANS/D/Deenen_Charles/Zamzara%s",
    "/MUSICIANS/G/Galway_Martin/Comic_Bakery%s",
    "/MUSICIANS/T/Tel_Jeroen/RoboCop_3%s",
    "/MUSICIANS/G/Galway_Martin/Yie_Ar_Kung_Fu%s",
    "/MUSICIANS/J/Joseph_Richard/Defender_of_the_Crown%s",
    "/MUSICIANS/T/Tel_Jeroen/Turbo_Outrun%s",
    "/MUSICIANS/H/Hubbard_Rob/Master_of_Magic%s",
    "/MUSICIANS/C/Clarke_Peter/Ocean_Loader_3%s",
    "/MUSICIANS/H/Hubbard_Rob/Spellbound%s",
    "/MUSICIANS/D/Daglish_Ben/Trap%s",
    "/MUSICIANS/B/Bjerregaard_Johannes/Sweet%s",
    "/MUSICIANS/H/Huelsbeck_Chris/Dulcedo_Cogitationis%s",
    "/MUSICIANS/H/Hubbard_Rob/IK_plus%s",
    "/MUSICIANS/D/Daglish_Ben/Thing_Bounces_Back%s",
    "/MUSICIANS/D/Dunn_Jonathan/RoboCop%s",
    "/MUSICIANS/F/Future_Freak/Cooperation_Demo%s",
    "/MUSICIANS/H/Hubbard_Rob/Zoids%s",
    "/MUSICIANS/T/Tel_Jeroen/Supremacy%s",
    "/MUSICIANS/G/Gray_Matt/Driller%s",
    "/MUSICIANS/H/Hubbard_Rob/One_Man_and_His_Droid%s",
    "/MUSICIANS/T/Tel_Jeroen/Savage%s",
    "/MUSICIANS/H/Hubbard_Rob/ACE_II%s",
    "/MUSICIANS/H/Hubbard_Rob/Thrust%s",
    "/MUSICIANS/G/Gray_Fred/Hysteria%s",
    "/MUSICIANS/H/Hubbard_Rob/BMX_Kidz%s",
    "/MUSICIANS/Y/Yip/Scroll_Machine%s",
    "/MUSICIANS/H/Huelsbeck_Chris/Baby_of_Can_Guru%s",
    "/MUSICIANS/H/Huelsbeck_Chris/To_Be_on_Top%s",
    "/GAMES/S-Z/Wizardry%s",
    "/MUSICIANS/W/Walker_Martin/Armalyte%s",
    "/MUSICIANS/F/Follin_Tim/Gauntlet_III%s",
    "/MUSICIANS/H/Hatlelid_Kris/Grand_Prix_Circuit%s",
    "/MUSICIANS/B/Bjerregaard_Johannes/Nightdawn%s",
    "/MUSICIANS/F/Follin_Tim/Scumball%s",
    "/MUSICIANS/B/Beben_Wally/R_I_S_K%s",
    "/MUSICIANS/F/Future_Freak/Rocky_Star%s",
    "/MUSICIANS/H/Hubbard_Rob/Mega_Apocalypse%s",
    "/MUSICIANS/H/Huelsbeck_Chris/Katakis%s",
    "/MUSICIANS/H/Hubbard_Rob/Gerry_the_Germ%s",
    "/MUSICIANS/A/ATOO/Compleeto%s",
    "/MUSICIANS/T/Tel_Jeroen/Eliminator%s",
    "/MUSICIANS/D/Daglish_Ben/Bulldog%s",
    "/MUSICIANS/C/Cooksey_Mark/Ramparts%s",
    "/MUSICIANS/D/Daglish_Ben/Ark_Pandora%s",
    "/MUSICIANS/H/Hubbard_Rob/Warhawk%s",
    "/MUSICIANS/D/Daglish_Ben/Vikings%s",
    "/MUSICIANS/F/FAME/FAME_1%s",
    "/MUSICIANS/G/Galway_Martin/Times_of_Lore%s",
    "/MUSICIANS/J/JCH/Batman_long%s",
    "/MUSICIANS/G/Galway_Martin/Mikie%s",
    "/MUSICIANS/C/Crowther_Antony/Zig_Zag%s",
    "/MUSICIANS/T/Tel_Jeroen/Battle_Valley%s",
    "/MUSICIANS/J/JCH/Chordian%s",
    "/MUSICIANS/T/Tel_Jeroen/Combat_Crazy%s",
    "/MUSICIANS/T/Tel_Jeroen/Hawkeye%s",
    "/MUSICIANS/G/Galway_Martin/Short_Circuit%s",
    "/MUSICIANS/L/Laxity/DNA_Warrior%s",
    "/MUSICIANS/W/Whittaker_David/Glider_Rider%s",
    "/MUSICIANS/T/Tel_Jeroen/Kinetix%s",
    "/MUSICIANS/T/Turner_Steve/Uridium%s",
    "/MUSICIANS/B/Bjerregaard_Johannes/Thunderforce%s",
    "/MUSICIANS/H/Hubbard_Rob/Kentilla%s",
    "/MUSICIANS/B/Bjerregaard_Johannes/Crazy_Comets_remix%s",
    "/MUSICIANS/C/Clarke_Peter/Mission_of_Mercy%s",
    "/MUSICIANS/T/Tel_Jeroen/Afterburner%s",
    "/MUSICIANS/B/Baldwin_Neil/Ala%s",
    "/MUSICIANS/G/Galway_Martin/Never_Ending_Story%s",
    "/MUSICIANS/G/Galway_Martin/Ocean_Loader_2%s",
    "/MUSICIANS/W/Walker_Martin/Snare%s",
    "/MUSICIANS/B/Brennan_Neil/Fist_II-Legend_Continues%s" ]

#
# Skytopia 64
#
TOP64 = [ \
    "/MUSICIANS/H/Hubbard_Rob/Monty_on_the_Run%s",
    "/MUSICIANS/H/Huelsbeck_Chris/R-Type%s",
    "/MUSICIANS/H/Hubbard_Rob/One_Man_and_His_Droid%s",
    "/MUSICIANS/H/Hubbard_Rob/Spellbound%s",
    "/MUSICIANS/C/Clarke_Peter/Ocean_Loader_3%s",
    "/MUSICIANS/D/Deenen_Charles/After_the_War%s",
    "/MUSICIANS/F/Follin_Tim/Ghouls_n_Ghosts%s",
    "/MUSICIANS/T/Tel_Jeroen/Kinetix%s",
    "/MUSICIANS/H/Hubbard_Rob/Auf_Wiedersehen_Monty%s",
    "/MUSICIANS/F/Follin_Tim/Bionic_Commando%s",
    "/MUSICIANS/T/Tel_Jeroen/Turbo_Outrun%s",
    "/MUSICIANS/G/Gray_Fred/Batman_The_Caped_Crusader%s",
    "/MUSICIANS/D/Deenen_Charles/Zamzara%s",
    "/MUSICIANS/C/Cooksey_Mark/Battle_Ships%s",
    "/MUSICIANS/W/Whittaker_David/Loopz%s",
    "/MUSICIANS/D/Dunn_Jonathan/Ocean_Loader_4%s",
    "/MUSICIANS/L/Laxity/DNA_Warrior%s",
    "/MUSICIANS/T/Tel_Jeroen/Rubicon%s",
    "/MUSICIANS/H/Hubbard_Rob/Last_V8%s",
    "/MUSICIANS/T/Tel_Jeroen/Alloyrun%s",
    "/MUSICIANS/T/Tel_Jeroen/Hawkeye%s",
    "/MUSICIANS/T/Tel_Jeroen/Hotrod%s",
    "/MUSICIANS/B/Barrett_Steve/Super_Hang-On%s",
    "/MUSICIANS/C/Cooksey_Mark/Cataball%s",
    "/MUSICIANS/C/Cooksey_Mark/Ghosts_n_Goblins%s",
    "/MUSICIANS/F/Follin_Tim/Black_Lamp%s",
    "/MUSICIANS/H/Hubbard_Rob/Delta%s",
    "/MUSICIANS/T/Tel_Jeroen/Supremacy%s",
    "/MUSICIANS/V/Vaca_Ramiro/Turrican%s",
    "/MUSICIANS/F/Follin_Tim/Gauntlet_III%s",
    "/MUSICIANS/V/Vaca_Ramiro/Startrash%s",
    "/MUSICIANS/O/Ouwehand_Reyn/Flimbos_Quest%s",
    "/MUSICIANS/T/Tel_Jeroen/Cybernoid%s",
    "/MUSICIANS/M/Mad_Donne_Marcel/Scorpion%s",
    "/MUSICIANS/D/Daglish_Ben/Last_Ninja%s",
    "/MUSICIANS/M/Moppe/Blood_Money%s",
    "/MUSICIANS/F/Follin_Tim/L_E_D_Storm%s",
    "/MUSICIANS/H/Hubbard_Rob/Thing_on_a_Spring%s",
    "/MUSICIANS/B/Bjerregaard_Johannes/Fruitbank%s",
    "/MUSICIANS/T/Tel_Jeroen/Trivia_Ultimate_Challenge%s",
    "/MUSICIANS/H/Hubbard_Rob/Commando%s",
    "/MUSICIANS/H/Hubbard_Rob/Hollywood_or_Bust%s",
    "/MUSICIANS/W/Whittaker_David/Speedball%s",
    "/MUSICIANS/F/Follin_Tim/Peter_Pack_Rat%s",
    "/MUSICIANS/H/Hubbard_Rob/International_Karate%s",
    "/MUSICIANS/O/Ouwehand_Reyn/Last_Ninja_3%s",
    "/MUSICIANS/H/Hubbard_Rob/Gerry_the_Germ%s",
    "/MUSICIANS/H/Hubbard_Rob/Battle_of_Britain%s",
    "/MUSICIANS/F/Follin_Tim/Agent_X_II_The_Mad_Profs%s",
    "/MUSICIANS/J/Joseph_Richard/Barbarian%s",
    "/MUSICIANS/D/Dunn_Jonathan/Revenge_of_Doh%s",
    "/MUSICIANS/B/Bjerregaard_Johannes/Stormlord%s",
    "/MUSICIANS/B/Barrett_Steve/Tilt%s",
    "/MUSICIANS/T/Tel_Jeroen/Savage%s",
    "/MUSICIANS/T/Tel_Jeroen/Eliminator%s",
    "/MUSICIANS/F/Follin_Tim/Scumball%s",
    "/MUSICIANS/G/Gray_Fred/ShadowFire%s",
    "/MUSICIANS/T/Tel_Jeroen/Cybernoid_II%s",
    "/MUSICIANS/C/Cooksey_Mark/Paperboy%s",
    "/GAMES/S-Z/Task_III%s",
    "/MUSICIANS/D/Deenen_Charles/Mr_Heli%s",
    "/MUSICIANS/G/Galway_Martin/Yie_Ar_Kung_Fu%s",
    "/MUSICIANS/B/Brennan_Neil/Way_of_the_Exploding_Fist%s",
    "/MUSICIANS/H/Hubbard_Rob/Crazy_Comets%s" ]

#=======================================================================#
def LOG( args ):
    if __debug__:
        print args

#=======================================================================#
class Database( object ):
#=======================================================================#
    def __init__( self, name, initstatement = None ):
        if os.path.exists( name ):
            os.remove( name )
        self.db = sqlite3.connect( name )
        self.cursor = self.db.cursor()
        if initstatement is not None:
            self.execute( initstatement )

    def execute( self, *args, **kwargs ):
        self.cursor.execute( *args, **kwargs )

    def finalize( self ):
        self.db.commit()
        self.cursor.close()

    def fetchall( self ):
        return self.cursor.fetchall()

#=======================================================================#
class Generator( object ):
#=======================================================================#
    def __init__( self, hvsc, metadb, datadb, selection ):
        self.hvsc = hvsc

        self.songs = Database( metadb, SQL_INIT )
        self.songs.execute( SQL_SONG_CREATE_TABLE )
        self.songs.execute( SQL_SONGSPLAYED_CREATE_TABLE )
        self.songs.execute( SQL_AUTHOR_CREATE_TABLE )

        for command in SQL_PLAYLISTS_POPULATE_TABLES:
            self.songs.execute( command )

        if datadb is not None:
            self.files = Database( datadb, SQL_INIT )
            self.files.execute( SQL_FILES_CREATE_TABLE )
        else:
            self.files = None

        self.authorid = 1
        self.authors = {}

        self.numSongs = 0
        self.maxName = 0
        self.maxUri = 0
        self.maxAuthor = 0

        self.unknownSongLength = 0
        self.selection = selection

        self.pk = 1
        self.top100pks = []

    def readSongLengths( self ):
        LOG( "reading HVSC songlength database(s)..." )
        self.length = {}
        self._readSongLengths( "%s/DOCUMENTS/Songlengths.txt" % self.hvsc )
#        self._readSongLengths( "%s/DOCUMENTS/Songlengths.psid" % self.hvsc )

    def _readSongLengths( self, filename ):
        lengths = open( filename, "r" )
        name = None
        for line in lengths:
            #LOG( "dealing with line '%s'" % line )
            if name is not None: # fix bogus lines in Songlengths.txt introduced in HVSC 52
                if not name.startswith( "/" ):
                    name = "/" + name;
                durations = line.strip().split('=')[1].replace( "(G)", "" ).split(' ')
                all = []
                for duration in durations:
                    try:
                        minutes, seconds = duration.split( ':', 1 )
                    except ValueError:
                        LOG( "syntax error in line '%s'" % line )
                        raise
                    seconds = seconds[:2]
                    all.append( int(minutes)*60+int(seconds) )
                self.length[name] = all
                #LOG( "songlengths for %s: %s" % ( name, self.length[name] ) )
                name = None
            elif line[1:].strip().endswith( ".sid" ):
                name = line[1:].strip()
        LOG( "finished. total number of songlenghts = %d" % len( self.length ) )

    def readStil( self ):
        LOG( "reading STIL text..." )
        stil = open( "%s/DOCUMENTS/STIL.txt" % self.hvsc, "r" )
        self.stil = {}
        for line in stil:
            sline = line.strip()
            if sline == "" or sline.startswith( "#" ):
                name = None
                continue
            #LOG( "dealing with line '%s'" % sline )
            if sline.startswith( "/" ):
                name = sline
                self.stil[name] = ""
                continue
            if name is not None:
                self.stil[name] += "%s\n" % sline
                continue
            name = None
        LOG( "finished. total number of stil entries = %d" % len( self.stil ) )

    def grabInfoFromFile( self, filename ):
        bytes = file( filename, "r" ).read()

        rawname = bytes[22:22+32]
        # ansify songname
        songname = u""
        for c in rawname.strip():
            if ord(c) > 128:
                songname += unicode( ANSI_TABLE[ord(c)-129] )
            else:
                songname += unicode(c)
        rawauthor = bytes[54:54+32]
        # ansify authorname
        authname = u""
        for c in rawauthor.strip():
            if ord(c) > 128:
                authname += unicode( ANSI_TABLE[ord(c)-129] )
            else:
                authname += unicode(c)
        defaultsubsong = ord(bytes[17])
        if not (0 < defaultsubsong < 99 ):
            LOG( "default subsong for %s is %d, this seems to be corrupt. Using 1 instead" % ( filename, defaultsubsong ) )

        sidtype = bytes[:4]
        return songname.replace( '\x00', '' ), authname.replace( '\x00', '' ), defaultsubsong, bytes, sidtype

    def ansi2unicode( self, ansi ):
        """ansify"""
        ustring = u""
        for c in ansi.strip():
            if ord(c) > 128:
                ustring += unicode( ANSI_TABLE[ord(c)-129] )
            else:
                ustring += unicode(c)
        return ustring

    def escapeName( self, name ):
        if "." in name:
            self.maxName = max( self.maxName, len( name ) )
            components = name.split( "." )
            nameName = ".".join( components[:-1] )
            nameExt = components[-1].upper()
            if type (nameName) == type (u""):
                return nameName, nameExt
            else:
                return unicode( nameName, encoding = "cp1252" ), unicode( nameExt, encoding = "cp1252" )
    	else:
            if type (name) == type (u""):
                return name, "unknown"
            else:
                return unicode( name, encoding = "cp1252" ), "unknown"

    def escapeUri( self, uri ):
        self.maxUri = max( self.maxUri, len( uri ) )
        #return unicode( urllib.quote( uri ) );
        return unicode( uri )

    def escapeAuthor( self, author ):
        self.maxAuthor = max( self.maxAuthor, len( author ) )
        return unicode( author, encoding = "cp1252" )

    def addSidToTable( self, name, uri ):
        # check name of song
        filename = name.replace( '_', ' ' )
        self.numSongs += 1
        song, author, defaultsubsong, bytes, sidtype = self.grabInfoFromFile( uri )

        binary = sqlite3.Binary( bytes )
        self.files.execute( SQL_FILES_FILE_ADD, ( binary, ) )

        if song == "" or song == "<?>":
            LOG( "invalid song name found, using file name" )
            song = filename.strip()
        # post process songname
        if song.endswith( ".sid" ):
            song = song.replace( ".sid", '' )
        uri = uri.replace( self.hvsc, '' )
        #LOG( "found song: '%s' (%s)" % ( song, uri ) )

        if AUTHOR == "file":
            # check author of song
            author = author.replace( "<?>", "" ) # remove bogus
            #author = re.sub( "\(.*\)", "", author ) # remove stuff in brackets
            author = author.strip()
            authorFromDirectory = os.path.basename( os.path.dirname( uri ) ).replace( '_', ' ' )

            if author == "" or author == "<?>":
                LOG( "invalid author name found, using directory name" )
                author = authorFromDirectory
        elif AUTHOR == "hvsc":
            # always use author from HVSC category
            if "MUSICIANS" in uri:
                author = os.path.basename( os.path.dirname( uri ) ).replace( '_', ' ' )
            elif "DEMOS" in uri:
                author = "Demos/%s" % os.path.basename( os.path.dirname( uri ) ).replace( '_', ' ' )
            elif "GAMES" in uri:
                author = "Games/%s" % os.path.basename( os.path.dirname( uri ) ).replace( '_', ' ' )
            else:
                assert False, "unknown category in HVSC, expected MUSICIANS, DEMOS, GAMES"
            # replace UNKNOWN string
            author = author.replace( "UNKNOWN", "Unknown" )
        else:
            assert False, "wrong setting for AUTHOR"

        if MATCHING == "fuzzy":
            fkAuthor = self.fuzzyAuthorMatching( author )
        elif MATCHING == "strict":
            fkAuthor = self.strictAuthorMatching( author )
        else:
            assert False, "wrong setting for MATCHING"
        if fkAuthor is None:
            LOG( "found new author: '%s'. Assigning foreign key %d" % ( author, self.authorid ) )
            self.authors[author] = fkAuthor = self.authorid
            self.authorid += 1

        lengthfilename = uri.replace( "/C64Music", "" )

        # get length entry
        try:
            duration = self.length[lengthfilename][defaultsubsong-1]
        except KeyError:
            LOG( "can't find songlength for %s -- setting to %d seconds" % ( name, DEFAULT_SONGLENGTH ) )
            self.unknownSongLength += 1
            duration = DEFAULT_SONGLENGTH
        except IndexError:
            duration = self.length[lengthfilename][0]

        # get STIL entry
        try:
            stil = self.stil[lengthfilename]
        except KeyError:
            stil = ""
        #escapeName, escapeType = self.escapeName( song )
        self.songs.execute( SQL_SONG_ADD, ( fkAuthor, song, sidtype, self.escapeUri( uri ), duration, self.ansi2unicode(stil), ) )

    def addModToTable( self, author, title, uri, filesize ):
        song = title
        #song = title.replace( ".mod", "" )
        song = " ".join( word.capitalize() for word in song.split() )

        if "nknown" in author:
            author = "Unknown Author"

        try:
            escapeName, escapeType = self.escapeName( song )
            escapeUri = self.escapeUri( uri )
            escapeAuthor = self.escapeAuthor( author )
        except UnicodeDecodeError:
            LOG( "^^^ skipping song %s %s %s because of unicode error" % (author, song, uri) )
            return

        if MATCHING == "fuzzy":
            fkAuthor = self.fuzzyAuthorMatching( escapeAuthor )
        elif MATCHING == "strict":
            fkAuthor = self.strictAuthorMatching( escapeAuthor )
        else:
            assert False, "wrong setting for MATCHING"
        if fkAuthor is None:
            #LOG( "found new author: '%s'. Assigning foreign key %d" % ( escapeAuthor, self.authorid ) )
            self.authors[author] = fkAuthor = self.authorid
            self.authorid += 1
        # since we can tell when a .mod has finished (other than with a .sid), we do not need the duration field
        # therefore we (ab)use it to tell the filesize of the .mod, which is handy for a progressbar on download
        duration = filesize
        self.songs.execute( SQL_SONG_ADD, ( fkAuthor, escapeName, escapeType, escapeUri, duration, "No Info Yet", ) )
        self.numSongs += 1

    def addSapToTable( self, uri, author, title, date, duration ):
        song = title.replace( ".sap", "" ).replace( ".SAP", "" )
        song = " ".join( word.capitalize() for word in song.split() )

        authorFromDirectory = os.path.basename( os.path.dirname( uri ) ).replace( '_', ' ' )
        if author == "" or author == "<?>":
            LOG( "invalid author name found, using directory name" )
            author = authorFromDirectory

        if "nknown" in author:
            author = "Unknown Author"

        try:
            escapeName, escapeType = self.escapeName( song )
            escapeUri = self.escapeUri( uri )
            escapeAuthor = self.escapeAuthor( author )
        except UnicodeDecodeError:
            LOG( "^^^ skipping song %s %s %s because of unicode error" % (author, song, uri) )
            return

        if MATCHING == "fuzzy":
            fkAuthor = self.fuzzyAuthorMatching( escapeAuthor )
        elif MATCHING == "strict":
            fkAuthor = self.strictAuthorMatching( escapeAuthor )
        else:
            assert False, "wrong setting for MATCHING"
        if fkAuthor is None:
            LOG( "found new author: '%s'. Assigning foreign key %d" % ( escapeAuthor, self.authorid ) )
            self.authors[author] = fkAuthor = self.authorid
            self.authorid += 1

        self.songs.execute( SQL_SONG_ADD, ( fkAuthor, self.escapeName( song ), self.escapeUri( uri ), duration, date ) )
        self.numSongs += 1

    def strictAuthorMatching( self, newAuthor ):
        return self.authors.get( newAuthor, None )

    def fuzzyAuthorMatching( self, newAuthor ):
        # exact matching
        try:
            return self.authors[newAuthor]
        except KeyError:
            import FuGrep
            # simple fuzzy matching
            for author in self.authors:
                if ( newAuthor.startswith( author ) ) or \
                   ( newAuthor.endswith( author ) ) or \
                   ( newAuthor in author ) or \
                   ( author.startswith( newAuthor ) ) or \
                   ( author.endswith( newAuthor ) ) or \
                   ( author in newAuthor ):
                    LOG( "got simple fuzzy matching: %s ~ %s" % ( newAuthor, author ) )
                    value = self.authors[author]
                    if len( newAuthor ) < len( author ):
                        self.authors[newAuthor] = self.authors[author]
                        del self.authors[author]
                    return value
            # complex fuzzy matching
            maxSimilarity = 0
            maxSimilarAuthor = None
            for author in self.authors:
                similarity = FuGrep.similarity( newAuthor, author )
                if similarity > maxSimilarity:
                    maxSimilarity = similarity
                    maxSimilarAuthor = author
                    value = self.authors[author]
            if maxSimilarity >= FUZZY_THRESHOLD:
                LOG( "complex fuzzy matching reports %s ~ %s by %0.2f" % ( newAuthor, maxSimilarAuthor, maxSimilarity ) )
                if len( newAuthor ) < len( author ):
                    self.authors[newAuthor] = self.authors[author]
                    del self.authors[author]
                return value

    def sortByValue(self, d):
        """ Returns the keys of dictionary d sorted by their values """
        items = d.items()
        backitems = [ [v[1],v[0]] for v in items ]
        backitems.sort()
        return [ backitems[i][1] for i in range( 0, len(backitems) ) ]

    def finalize( self ):
        # write author table
        for author in self.sortByValue( self.authors ):
            self.songs.execute( SQL_AUTHOR_ADD, ( self.escapeAuthor( author ), ) )

        # create indices
        self.songs.execute( SQL_SONG_CREATE_INDEX )
        self.songs.execute( SQL_AUTHOR_CREATE_INDEX )

        # count songs per author starting with certain letter
        self.songs.execute( SQL_SONGCOUNTER_CREATE_TABLE )
        for fkAuthor in self.authors.values():
            resultlist = []
            for character in "[^a-zA-Z]* [Aa]* [Bb]* [Cc]* [Dd]* [Ee]* [Ff]* [Gg]* [Hh]* [Ii]* [Jj]* [Kk]* [Ll]* [Mm]* [Nn]* [Oo]* [Pp]* [Qq]* [Rr]* [Ss]* [Tt]* [Uu]* [Vv]* [Ww]* [Xx]* [Yy]* [Zz]*".split():
                #print "executing: ", SQL_SONGCOUNTER_QUERY % ( fkAuthor, character )
                self.songs.execute( SQL_SONGCOUNTER_QUERY % ( fkAuthor, character ) )
                resultlist.append( self.songs.fetchall()[0][0] )
            resultlist.append( fkAuthor )
            self.songs.execute( SQL_SONGCOUNTER_ADD, tuple(resultlist) )

        # count authors starting with certain letter
        self.songs.execute( SQL_AUTHORCOUNTER_CREATE_TABLE )
        resultlist = []
        for character in "[^a-zA-Z]* [Aa]* [Bb]* [Cc]* [Dd]* [Ee]* [Ff]* [Gg]* [Hh]* [Ii]* [Jj]* [Kk]* [Ll]* [Mm]* [Nn]* [Oo]* [Pp]* [Qq]* [Rr]* [Ss]* [Tt]* [Uu]* [Vv]* [Ww]* [Xx]* [Yy]* [Zz]*".split():
            #print "executing: ", SQL_AUTHORCOUNTER_QUERY % ( character )
            LOG( character );
            self.songs.execute( SQL_AUTHORCOUNTER_QUERY % ( character ) )
            resultlist.append( self.songs.fetchall()[0][0] )
        self.songs.execute( SQL_AUTHORCOUNTER_ADD, tuple(resultlist) )

		# add author song count
        self.songs.execute( SQL_AUTHOR_SONG_COUNT )

        # create empty tables for caching
        self.songs.execute( SQL_SONG_CACHECOUNTER_TABLE );
        self.songs.execute( SQL_AUTHOR_CACHECOUNTER_CREATE_TABLE );
        self.songs.execute( SQL_AUTHOR_CACHECOUNTER_ADD );
		
        # finalize dbs
        self.songs.finalize()
        del self.songs
        if self.files is not None:
            self.files.finalize()
            del self.files
        print "========================================="
        print "added %s songs to table" % self.numSongs
        print "added %s authors to table" % self.authorid
        print "max(songname) = %d, max(uri) = %d, max(authorname) = %d" % ( self.maxName, self.maxUri, self.maxAuthor )
        print "could not find songlength for %d songs" % self.unknownSongLength

    def generateForFiles( self, root, files ):
        #LOG( "generateForFiles: root=%s, files=%s" % ( root, files ) )
        # first pass -- eliminate non-PSID files, if PSID existing
        newfiles = files[:]
        for f in files:
            if "_PSID" in f:
                nopsid = f.replace( "_PSID", "" )
                LOG( "PSID %s found, preferring this over the non-PSID version" % f )
                try:
                    newfiles.remove( nopsid )
                except ValueError:
                    LOG( "oops, couldn't remove PSID? dumping newfiles and files" )
                    #LOG( newfiles )
                    #LOG( "=========================================" )
                    #LOG( files )

        for f in newfiles:
            if f.endswith( ".sid" ):
                if "MUSICIANS" not in root \
                and "DEMOS" not in root \
                and "GAMES" not in root:
                    continue
                #if "PSID" in f:
                #    print "skipping PSID song", f
                else:
                    self.addSidToTable( f, "%s/%s" % ( root, f ) )

    def generateSid( self ):
        if self.selection is None:
            for root, dirs, files in os.walk( self.hvsc ):
                self.generateForFiles( root, files )
        else:
            files = open( self.selection, "r" ).read().split( '\n' )
            for f in files:
                root = "%s/C64Music%s" % ( self.hvsc, os.path.dirname( f ) )
                fls = [ os.path.basename( f ) ]
                self.generateForFiles( root, fls )

    def generateMod( self ):
        songcounter = 0
        try:
            maxsongs = MAX_SONGS
        except NameError:
            maxsongs = 999999

        # read through file; skip everything that does not end with one of our blessed extensions
        for line in open( self.hvsc ):
            line = line.strip()
            #LOG( "dealing with line '%s'" % line )

            filesize, filename = line.split( '\t' )

            extension = filename.split( "." )[-1]

            if not extension in "669 abc amf ams dbm dmf far it j2b mdl mid mod mt2 mtm okt psm s3m stm ult umx wav xm".split():
                continue

            #if not filename.startswith( "Protracker" ):
            #    continue

            filesize = int( filesize.strip() )
            values = filename.split( '\\' )
            author = values[1]
            title = values[-1]

            self.addModToTable( author, title, "%s" % ( '/'.join( values ) ), filesize )
            songcounter += 1
            if songcounter == maxsongs:
                return

    def getSongMetadataForSAP( self, filename ):
        assert( filename.endswith( ".sap" ) )
        sapfile = open( filename, "rb" ).read()
        filesize = len( sapfile )
        saplines = sapfile.split( "\r\n" )

        author = "Unknown"
        name = "Unknown"
        date = "Unknown"
        subsongs = 1
        duration = DEFAULT_SONGLENGTH

        for line in saplines:
            if line.startswith( "\0xff" ):
                return author, name, date, subsongs, duration # header ended
            if line.startswith( "AUTHOR" ):
                author = line[8:-1]
            elif line.startswith( "NAME" ):
                name = line[6:-1]
            elif line.startswith( "DATE" ):
                date = line[6:-1]
            elif line.startswith( "SONGS" ):
                subsongs = int( line[6:] )
        return author, name, date, subsongs, duration # header ended

    def generateXL( self ):
        songcounter = 0
        try:
            maxsongs = MAX_SONGS
        except NameError:
            maxsongs = 999999

        for root, dirs, files in os.walk( self.hvsc ):
            for f in files:
                if f.endswith( ".sap" ):
                    filename = "%s/%s" % ( root, f )
                    result = self.getSongMetadataForSAP( filename )
                    author, title, date, subsongs, duration = result
                    #if ( "<?>" in author ):
                    #    author = ( filename ).split( "/" )[-2]
                    author = ""
                    title = ( filename ).split( "/" )[-1].replace( "_", " " )
                    self.addSapToTable( filename.replace( self.hvsc, "" ), author, title, date, duration )

    def createTopList( self, playlist, liste ):
        index = 1
        for uri in liste:
            uri2 = uri % "_PSID.sid"
            result = self._getIndexForUri( uri2 )
            if result is not None:
                command = SQL_PLAYLIST_ADD_SONG % ( index, playlist, result )
                self.songs.execute( command )
                index += 1
                continue
            uri1 = uri % ".sid"
            result = self._getIndexForUri( uri1 )
            if result is not None:
                command = SQL_PLAYLIST_ADD_SONG % ( index, playlist, result )
                self.songs.execute( command )
                index += 1
                continue
            LOG( "ERROR: Could not find %s" % uri );

    def _getIndexForUri( self, uri ):
        command = SQL_SONG_QUERY_ID % uri
        self.songs.cursor.execute( command )
        result = self.songs.cursor.fetchone()
        return result[0] if result else None
        

def showUsage( prgname ):
    print "Usage: %s <path to C64Music directory (root of HVSC)> <metadata.sql> <data.sql> [selection]" % prgname
    print "Usage: %s <path to ASMA directory (root of ASMA)> <metadata.sql>" % prgname
    print "Usage: %s <path to modland allsongs text file> <metadata.sql>" % prgname
    sys.exit( -1 )

#=======================================================================#
if __name__ == "__main__":
#=======================================================================#
    if len( sys.argv ) < 3:
        showUsage( sys.argv[0] )

    if sys.argv[1] == "test":
        g = Generator( "." )
        g.test()
        g.finalize()

    else:
        path = sys.argv[1]
        dbfile1 = sys.argv[2]

        if ( path.endswith( ".txt" ) ):
            print "Generating db for the modland ftp server..."
            assert os.path.isfile( path ), "%s no directory" % path
            g = Generator( path, dbfile1, None, None )
            g.generateMod()
            g.finalize()
        elif ( path.endswith( "C64Music" ) ):
            print "Generating db for the HVSC..."
            dbfile2 = sys.argv[3]
            selection = None
            assert os.path.isdir( path ), "%s no directory" % path
            assert os.path.exists( path ), "%s not existing" % path
            if len( sys.argv ) == 5:
                selection = sys.argv[4]
            g = Generator( path, dbfile1, dbfile2, selection )
            g.readSongLengths()
            g.readStil()
            g.generateSid()
            g.createTopList( 4, TOP100 )
            g.createTopList( 5, TOP64 )
            g.finalize()
        elif ( path.endswith( "ASMA" ) ):
            print "Generating db for the ASMA"
            assert os.path.isdir( path ), "%s no directory" % path
            assert os.path.exists( path ), "%s not existing" % path
            dbfile2 = sys.argv[3]
            g = Generator( path, dbfile1, None, None )
            g.generateXL()
            g.finalize()
        else:
            showUsage( sys.argv[0] )
