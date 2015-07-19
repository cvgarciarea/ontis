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

public class Ontis: Gtk.Application {

    public Ontis() {
        Object(application_id: "com.browser.Ontis", flags: GLib.ApplicationFlags.FLAGS_NONE);
    }

	protected override void activate() {
	    this.register_session = true;
	    this.add_actions();
        this.new_window();
    }

    public void add_actions() {
        GLib.SimpleAction action = new GLib.SimpleAction("new-tab", null);
		action.activate.connect(this.new_tab);
		this.add_action(action);

        action = new GLib.SimpleAction("new-window", null);
		action.activate.connect(this.new_window);
		this.add_action(action);

        action = new GLib.SimpleAction("history", null);
		action.activate.connect(this.show_history);
		this.add_action(action);

        action = new GLib.SimpleAction("downloads", null);
		action.activate.connect(this.show_downloads);
		this.add_action(action);

        action = new GLib.SimpleAction("exit", null);
		action.activate.connect(this.close_all);
		this.add_action(action);

        this.add_accelerator(Gtk.accelerator_name(Gdk.Key.t, Gdk.ModifierType.CONTROL_MASK), "app.new-tab", null);
        this.add_accelerator(Gtk.accelerator_name(Gdk.Key.n, Gdk.ModifierType.CONTROL_MASK), "app.new-window", null);
        this.add_accelerator(Gtk.accelerator_name(Gdk.Key.h, Gdk.ModifierType.CONTROL_MASK), "app.history", null);
        this.add_accelerator(Gtk.accelerator_name(Gdk.Key.d, Gdk.ModifierType.CONTROL_MASK), "app.downloads", null);
    }

    public OntisWindow get_actual_window() {
        Gtk.Window win = this.get_active_window();
        return (OntisWindow)win;
    }

    public void new_tab(GLib.Variant? variant=null) {
        this.get_actual_window().notebook.new_page();
    }

    public void new_window(GLib.Variant? variant=null) {
        OntisWindow win = new OntisWindow();
        this.add_window(win);
    }

    public void show_history(GLib.Variant? variant=null) {
        this.get_actual_window().notebook.new_page("ontis://history");
    }

    public void show_downloads(GLib.Variant? variant=null) {
        this.get_actual_window().notebook.new_page("ontis://downloads");
    }

    public void close_all(GLib.Variant? variant=null) {
        foreach (Gtk.Window window in this.get_windows()) {
            OntisWindow owindow = (OntisWindow)window;

            if (owindow != this.get_actual_window()) {
                owindow.destroy();
            }
        }

        this.get_actual_window().destroy();
    }
}

public class OntisWindow: Gtk.ApplicationWindow {

    //public WebKit.Settings settings;
    public Canvas canvas;
    public DownloadManager download_manager;
    public Notebook notebook;

    public bool full_screen;

    public OntisWindow() {
        this.set_default_size(400, 280);
        //this.set_decorated(false);

        this.canvas = new Canvas();
        this.add(this.canvas);

        this.download_manager = new DownloadManager();

        this.notebook = new Notebook(this.download_manager);
        this.notebook.full_screen.connect(this.full_screen_mode);
        this.notebook.close.connect(this.close_now);
        this.canvas.pack_start(this.notebook, true, true, 0);

        this.key_release_event.connect(this.key_release_event_cb);
        this.motion_notify_event.connect(this.motion_event_cb);
        this.destroy.connect(destroy_cb);
        this.notebook.new_page();
        this.show_all();
    }

    public bool key_release_event_cb(Gtk.Widget self, Gdk.EventKey event) {
        switch(event.keyval) {
            case 65480:  // F11
                this.change_full_screen();
                break;

            case 65307:  // Scape
                if (this.full_screen) {
                    this.change_full_screen();
                }
                break;
        }

        return false;
    }

    public void destroy_cb(Gtk.Widget self) {
        // check if exists any download...
        //Gtk.main_quit();
    }

    public void full_screen_mode(Notebook notebook) {
        this.change_full_screen();
    }

    public void change_full_screen() {
        this.full_screen = !this.full_screen;
        this.notebook.set_topbar_visible(!this.full_screen);

        if (this.full_screen) {
            this.fullscreen();
        } else {
            this.unfullscreen();
        }
    }

    public bool motion_event_cb(Gtk.Widget self, Gdk.EventMotion event) {
        Gtk.Allocation a1;
        Gtk.Allocation a2;
        int? max_height = null;

        foreach (Gtk.Widget widget in this.notebook.get_children()) {
            if (max_height != null) {
                break;
            }

            View view = (View)widget;

            widget = this.notebook.get_tab_label(view);
            NotebookTab tab = (NotebookTab)widget;

            view.toolbar.get_allocation(out a1);
            tab.get_allocation(out a2);

            max_height = a1.height + a2.height + 10;
        }

        if (this.full_screen && event.y == 0) {
            this.notebook.set_topbar_visible(true);
        } else if (this.full_screen && event.y > max_height && this.notebook.get_show_tabs()) {
            this.notebook.set_topbar_visible(false);
        }

        return false;
    }

    public void close_now() {
        this.destroy();
    }
}

int main(string[] args) {
    Ontis ontis = new Ontis();
    return ontis.run(args);
}
