
#---------------------------
# GNU Makefile for Ktags
#---------------------------

TARGET   :=  ktags
SRCDIR   :=  src
DISTDIR  :=  dist
BUILDDIR :=  build
KTAGDIR  :=  __ktags
PREFIX   ?=  /usr/local
BINDIR   :=  $(PREFIX)/bin
PKGBUILDDIR := $(BUILDDIR)/$(TARGET)-build

SRCS := $(SRCDIR)/ktags.sh

all: sanity

sanity:
	bash -n $(SRCS) && \
	install -D $(SRCS) ./$(TARGET).out

install:
	install -D $(SRCS) $(DESTDIR)$(BINDIR)/$(TARGET)

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/$(TARGET)

dist:
	@kdebuild --dpkg

build:
	@eval build/scripts/buildenv.sh

clean:
	rm -rf $(TARGET).out $(KTAGDIR)

cfgclean distclean: clean
	rm -rf $(PKGBUILDDIR) $(DISTDIR)/* $(KTAGDIR)

.PHONY: all sanity build clean dist install uninstall

