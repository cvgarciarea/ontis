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

namespace Ontis {

    public class Toolbar: Gtk.Box {

        public signal void go_back(int step);
        public signal void go_forward(int step);

        public Gtk.Button button_back;
        public GLib.Menu back_menu;
        public Gtk.Popover back_popover;

        public Gtk.Button button_forward;
        public GLib.Menu forward_menu;
        public Gtk.Popover forward_popover;

        public Gtk.Button button_reload;
        public Gtk.Entry entry;
        public Gtk.Popover menu_popover;
        public Gtk.ToggleButton button_menu;

        public int state;

        public Toolbar() {
            this.set_orientation(Gtk.Orientation.HORIZONTAL);
            this.state = Utils.LoadState.LOADING;

            this.button_back = new Gtk.Button();
            this.button_back.set_sensitive(false);
            this.button_back.set_image(Utils.get_image_from_name("go-previous", 20));
            this.button_back.set_relief(Gtk.ReliefStyle.NONE);
            this.button_back.button_release_event.connect(this.button_back_released);
            this.pack_start(this.button_back, false, false, 0);

            this.back_menu = new GLib.Menu();
            this.back_popover = new Gtk.Popover.from_model(this.button_back, this.back_menu);

            this.button_forward = new Gtk.Button();
            this.button_forward.set_sensitive(false);
            this.button_forward.set_image(Utils.get_image_from_name("go-next", 20));
            this.button_forward.set_relief(Gtk.ReliefStyle.NONE);
            this.button_forward.button_release_event.connect(this.button_forward_released);
            this.pack_start(this.button_forward, false, false, 0);

            this.forward_menu = new GLib.Menu();
            this.forward_popover = new Gtk.Popover.from_model(this.button_forward, this.forward_menu);

            this.button_reload = new Gtk.Button();
            this.button_reload.set_image(Utils.get_image_from_name("view-refresh", 20));
            this.button_reload.set_relief(Gtk.ReliefStyle.NONE);
            this.pack_start(this.button_reload, false, false, 0);

            this.entry = new Gtk.Entry();
            this.override_font(Pango.FontDescription.from_string("10"));
            this.pack_start(this.entry, true, true, 0);

            this.button_menu = new Gtk.ToggleButton();
            this.button_menu.set_image(Utils.get_image_from_name("preferences-system", 20));
            this.button_menu.set_relief(Gtk.ReliefStyle.NONE);
            this.button_menu.toggled.connect(this.show_menu_popover);
            this.pack_start(this.button_menu, false, false, 0);

            GLib.Menu menu = new GLib.Menu();
            menu.append_item(get_item("New tab", "app.new-tab"));
            menu.append_item(get_item("New window", "app.new-window"));
            menu.append_item(get_item("New private window", "app.new-private-window"));
            // separator
            menu.append_item(get_item("History", "app.history"));
            menu.append_item(get_item("Downloads", "app.downloads"));
            menu.append_item(get_item("Recent tabs", "app.recent-tabs"));
            menu.append_item(get_item("Favorites", "app.favorites"));
            // separator
            menu.append_item(get_item("Search", "app.search"));
            menu.append_item(get_item("Print", "app.print"));
            menu.append_item(get_item("Save page as", "app.download-page"));
            menu.append_item(get_item("Settings", "app.settings"));
            menu.append_item(get_item("About Ontis", "app.about"));
            menu.append_item(get_item("Exit", "app.exit"));

            this.menu_popover = new Gtk.Popover.from_model(this.button_menu, menu);
            this.menu_popover.closed.connect(this.menu_popover_closed_cb);
        }

        public void set_load_state(int state) {
            this.state = state;
            if (this.state == Utils.LoadState.LOADING) {
                this.button_reload.set_image(Utils.get_image_from_name("view-refresh"));
            } else if (this.state == Utils.LoadState.FINISHED) {
                this.button_reload.set_image(Utils.get_image_from_name("window-close"));
            }
        }

        public void set_back_forward_list(WebKit.WebBackForwardList list, bool can_go_back, bool can_go_forward) {
            this.back_menu.remove_all();
            this.forward_menu.remove_all();

            int n = 1;
            foreach (WebKit.WebHistoryItem item in list.get_back_list_with_limit(10)) {
                this.back_menu.append_item(get_item(item.get_title(), "app.go-back-" + n.to_string()));
                n++;
            }

            n = 1;
            foreach (WebKit.WebHistoryItem item in list.get_forward_list_with_limit(10)) {
                this.forward_menu.append_item(get_item(item.get_title(), "app.go-forward-" + n.to_string()));
                n++;
            }

            this.button_back.set_sensitive(can_go_back);
            this.button_forward.set_sensitive(can_go_forward);
        }

        private GLib.MenuItem get_item(string name, string action) {
            GLib.MenuItem item = new GLib.MenuItem(name, action);
            return item;
        }

        private void show_menu_popover(Gtk.ToggleButton button) {
            if (this.button_menu.get_active()) {
                this.menu_popover.show_all();
            } else {
                this.menu_popover.hide();
            }
        }

        private void menu_popover_closed_cb(Gtk.Popover popover) {
            this.button_menu.set_active(false);
        }

        private bool button_back_released(Gtk.Widget widget, Gdk.EventButton event) {
            if (event.button == 1) {
                this.go_back(1);
            } else if (event.button == 3) {
                try {this.back_popover.show_all();} finally {};
            }

            return false;
        }

        private bool button_forward_released(Gtk.Widget widget, Gdk.EventButton event) {
            if (event.button == 1) {
                this.go_forward(1);
            } else if (event.button == 3) {
                try {this.forward_popover.show_all();} finally {};
            }

            return false;
        }
    }
}
