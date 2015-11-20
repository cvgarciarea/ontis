VALAC = valac
VAPIS = --vapidir=./vapis

VALAPKG = --pkg gtk+-3.0 \
          --pkg webkitgtk-3.0 \
          --pkg libsoup-2.4 \
          --pkg json-glib-1.0

SRC = src/cache.vala \
      src/downloads_manager.vala \
      src/down_panel.vala \
      src/history_view.vala \
      src/ontis.vala \
      src/view.vala \
      src/canvas.vala \
      src/downloads_view.vala \
      src/web_view.vala \
      src/utils.vala \
      src/notebook.vala \
      src/toolbar.vala \
      src/config_view.vala \
      src/base_view.vala \
      src/window.vala

BIN = ontis

all:
	$(VALAC) $(VAPIS) $(VALAPKG) $(SRC) -o $(BIN)

clean:
	rm -f $(BIN)
