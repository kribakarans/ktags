
# GNU Makefile

KTAG_EXE   = ktags
KTAG_SRC   = ktags.sh
CSCOPE_EXE = cs
CSCOPE_SRC = cscope.sh
BIN        = $(HOME)/bin

all: 
	bash -n $(KTAG_SRC)
	bash -n $(CSCOPE_SRC)

install:
	install -d $(BIN)
	install -D $(KTAG_SRC)   $(BIN)/$(KTAG_EXE)
	install -D $(CSCOPE_SRC) $(BIN)/$(CSCOPE_EXE)
	echo "set tags=.ktags/tags" >> $(HOME)/.vimrc

uninstall:
	rm -f $(BIN)/$(KTAG_EXE)
	rm -f $(BIN)/$(CSCOPE_EXE)

help:
	@echo "make [OPTIONS]"
	@echo "Options:"
	@echo "	 all       -- Validate scripts"
	@echo "	 install   -- install binaries"
	@echo "	 uninstall -- uninstall binaries"
	@echo "	 help      -- show this menu."

