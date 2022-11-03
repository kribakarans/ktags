
#---------------------------
# GNU Makefile for Ktags
#---------------------------

TARGET   :=  ktags
SRCDIR   :=  src
DISTDIR  :=  dist
BUILDDIR :=  build
KTAGDIR  :=  __ktags
INSTALL  ?=  install
PREFIX   ?=  /usr/local
BINDIR   :=  $(PREFIX)/bin
PKGBUILDDIR := $(BUILDDIR)/$(TARGET)-build

SRCS := $(SRCDIR)/ktags.sh

all: sanity

sanity:
	bash -n $(SRCS) && \
	$(INSTALL) -D $(SRCS) ./$(TARGET).out

install:
	$(INSTALL) -D $(SRCS) $(DESTDIR)$(BINDIR)/$(TARGET)

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/$(TARGET)

dist:
	@kdebuild --dpkg

build:
	@eval build/scripts/buildenv.sh

clean:
	rm -rf $(TARGET).out $(KTAGDIR)

cfgclean distclean:
	rm -rf $(PKGBUILDDIR) $(DISTDIR)/* $(KTAGDIR)

.PHONY: all sanity build clean dist install uninstall

