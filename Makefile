VERSION = 2.1.49
DESTDIR = /tmp/sidplayer-$(VERSION)
DESTFILE = /tmp/sidplayer-$(VERSION).tar.bz2

all: dist

dist:
	@rm -rf $(DESTDIR)/
	@mkdir -p $(DESTDIR)/
	@echo copying resources...
	@cp *.png $(DESTDIR)/
	@cp *.xib $(DESTDIR)/
	#@cp -fR *.lproj $(DESTDIR)/
	@cp *.plist *.html $(DESTDIR)/
	@cp COPYING NEWS AUTHORS INSTALL $(DESTDIR)/
	@cp files.sql $(DESTDIR)/
	@cp -fR sidplayer $(DESTDIR)/
	@rm -f $(DESTDIR)/sidplayer/*.sql
	@cp sidplayer/hvsc49index_gpl.sql $(DESTDIR)/sidplayer/hvsc49index.sql
	@echo copying xcode projects...
	@mkdir -p $(DESTDIR)/SidPlayer.xcodeproj
	@mkdir -p $(DESTDIR)/SidPlayerPro.xcodeproj
	@cp SidPlayer.xcodeproj/project.pbxproj $(DESTDIR)/SidPlayer.xcodeproj
	@cp SidPlayerPro.xcodeproj/project.pbxproj $(DESTDIR)/SidPlayerPro.xcodeproj
	@echo copying sources...
	@cp -R main.m SidPlayer_Prefix.pch Classes $(DESTDIR)/
	@echo removing svn leftovers...
	@find $(DESTDIR) -name ".svn" | xargs rm -rf || true
	@find $(DESTDIR) -name ".git" | xargs rm -rf || true
	@echo creating tarball...
	@tar cjf $(DESTFILE) -C /tmp sidplayer-$(VERSION)
	@echo available as $(DESTFILE)
