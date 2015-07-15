/*
Copyright (C) 2015, Cristian García <cristian99garcia@gmail.com>

Compile with:
    valac --vapidir=./vapis --pkg gtk+-3.0 --pkg webkitgtk-3.0 --thread ontis.vala widgets.vala globals.vala

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

public class Ontis: Gtk.Window {

    //public WebKit.Settings settings;
    public Canvas canvas;
    public DownloadManager download_manager;
    public Notebook notebook;
    public DownloadsViewer downloads_viewer;

    public Ontis() {
        this.set_default_size(400, 280);
        //this.set_decorated(false);

        //this.settings = new WebKit.Settings();
        //this.settings.set_auto_load_images(true);

        this.canvas = new Canvas();
        this.add(this.canvas);

        this.download_manager = new DownloadManager();

        this.notebook = new Notebook(this.download_manager);
        this.notebook.close.connect(this.close_now);
        this.notebook.move_to.connect(this.move_to);
        this.notebook.minimize.connect(this.minimize_now);
        this.notebook.maximize.connect(this.maximize_now);
        this.notebook.show_download_manager.connect(this.show_download_manager_cb);
        this.canvas.pack_start(this.notebook, true, true, 0);

        this.downloads_viewer = new DownloadsViewer(this.download_manager);
        this.hide();

        this.destroy.connect(destroy_cb);
        //self.connect('window-state-event', self.__window_state_event_cb)

        this.notebook.new_page();
        this.show_all();
    }

    public void destroy_cb(Gtk.Widget self) {
        // check if exists any download...
        Gtk.main_quit();
    }

    public void close_now() {
        this.destroy();
    }

    public void move_to(int x, int y) {
        this.move(x, y);
    }

    public void minimize_now() {
        this.iconify();
    }

    public void maximize_now() {
        if (this.is_maximized) {
            this.unmaximize();
        } else {
            this.maximize();
        }
    }

    public void show_download_manager_cb() {
        this.downloads_viewer.show_all();
    }
}

void main(string[] args) {
    Gtk.init(ref args);

    new Ontis();
    Gtk.main();
}
