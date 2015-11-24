/*
Copyright (C) 2015, Cristian García <cristian99garcia@gmail.com>

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

public class App: Gtk.Application {

    public App() {
        Object(application_id: "com.browser.Ontis", flags: GLib.ApplicationFlags.FLAGS_NONE);
    }

	protected override void activate() {
	    this.register_session = true;
	    this.window_removed.connect(this.window_removed_cb);
	    this.add_actions();
        this.new_window();
    }

    private void window_removed_cb(Gtk.Application self, Gtk.Window window) {
        int length = 0;
        foreach (Gtk.Window win in this.get_windows()) {
            length ++;
            if (length > 1) {
                break;
            }
        }

        if (length == 0) {
            this.quit();
        }
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

        action = new GLib.SimpleAction("search", null);
		action.activate.connect(this.turn_search_bar);
		this.add_action(action);

        action = new GLib.SimpleAction("settings", null);
		action.activate.connect(this.show_settings);
		this.add_action(action);

        action = new GLib.SimpleAction("exit", null);
		action.activate.connect(this.close_all);
		this.add_action(action);

        for (int i=1; i<=10; i++) {
            action = new GLib.SimpleAction("go-back-" + i.to_string(), null);
            action.activate.connect(this.go_back);
            this.add_action(action);
        }

        for (int i=1; i<=10; i++) {
            action = new GLib.SimpleAction("go-forward-" + i.to_string(), null);
            action.activate.connect(this.go_forward);
            this.add_action(action);
        }

        this.add_accelerator(Gtk.accelerator_name(Gdk.Key.t, Gdk.ModifierType.CONTROL_MASK), "app.new-tab", null);
        this.add_accelerator(Gtk.accelerator_name(Gdk.Key.n, Gdk.ModifierType.CONTROL_MASK), "app.new-window", null);
        this.add_accelerator(Gtk.accelerator_name(Gdk.Key.h, Gdk.ModifierType.CONTROL_MASK), "app.history", null);
        this.add_accelerator(Gtk.accelerator_name(Gdk.Key.d, Gdk.ModifierType.CONTROL_MASK), "app.downloads", null);
        this.add_accelerator(Gtk.accelerator_name(Gdk.Key.f, Gdk.ModifierType.CONTROL_MASK), "app.search", null);
    }

    public Ontis.Window get_current_window() {
        Gtk.Window win = this.get_active_window();
        return (win as Ontis.Window);
    }

    public void new_tab(GLib.Variant? variant=null) {
        this.get_current_window().new_page();
    }

    public void new_window(GLib.Variant? variant=null) {
        Ontis.Window win = new Ontis.Window();
        this.add_window(win);
    }

    public void show_history(GLib.Variant? variant=null) {
        this.get_current_window().show_history();
    }

    public void show_downloads(GLib.Variant? variant=null) {
        this.get_current_window().show_downloads();
    }

    public void turn_search_bar(GLib.Variant? variant=null) {
        Ontis.BaseView view;
        Ontis.Window window = this.get_current_window();
        Ontis.View current_view = window.get_current_view();

        switch (current_view.mode) {
            case Utils.ViewMode.WEB:
                view = current_view.web_view;
                break;

            case Utils.ViewMode.HISTORY:
                view = current_view.history_view;
                break;

            case Utils.ViewMode.DOWNLOADS:
                view = current_view.downloads_view;
                break;

            case Utils.ViewMode.CONFIG:
                view = current_view.config_view;
                break;

            default:  // Never happen
                view = current_view.history_view;
                break;
        }

        view.turn_show_search_bar();
    }

    public void show_settings(GLib.Variant? variant=null) {
        this.get_current_window().show_settings();
    }

    public void close_all(GLib.Variant? variant=null) {
        foreach (Gtk.Window window in this.get_windows()) {
            Ontis.Window owindow = (Ontis.Window)window;

            if (owindow != this.get_current_window()) {
                owindow.destroy();
            }
        }

        this.get_current_window().destroy();
    }

    public void go_back(GLib.SimpleAction action, GLib.Variant? variant) {
        int step = (int)(action.get_name().split("-")[-1]);
        this.get_current_window().get_current_view().web_view.view.go_back_or_forward(step * -1);
    }

    public void go_forward(GLib.SimpleAction action, GLib.Variant? variant) {
        int step = (int)(action.get_name().split("-")[-1]);
        this.get_current_window().get_current_view().web_view.view.go_back_or_forward(step);
    }
}

int main(string[] args) {
    App ontis = new App();
    return ontis.run(args);
}
