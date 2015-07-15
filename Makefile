VALAC := valac
VAPIS = --vapidir=./vapis
VALAPKG = --pkg gtk+-3.0 --pkg webkitgtk-3.0
SRC = src/ontis.vala src/widgets.vala src/globals.vala
BIN = ontis

all:
	$(VALAC) $(VAPIS) $(VALAPKG) $(SRC) -o $(BIN)

clean:
	rm -f $(BIN)
