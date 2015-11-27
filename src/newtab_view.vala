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

    public class SearchBox: Gtk.Box {

        public signal void search(string text);

        public Gtk.SearchEntry entry;
        public Gtk.Button button_go;

        public SearchBox() {
            this.set_orientation(Gtk.Orientation.HORIZONTAL);
            this.set_border_width(50);

            this.entry = new Gtk.SearchEntry();
            this.entry.set_size_request(400, 1);
            this.entry.set_placeholder_text("Search or enter web adress");
            this.pack_start(this.entry, false, false, 0);

            this.entry.activate.connect(() => {
                if (this.entry.get_text() != "") {
                    this.search(this.entry.get_text());
                }
            });

            this.button_go = new Gtk.Button();
            this.button_go.clicked.connect(() => { this.entry.activate(); });
            this.pack_start(this.button_go, false, false, 0);

            Gtk.Image icon = Utils.get_image_from_name("go-next-symbolic");
            this.button_go.add(icon);
            icon.show();

            this.show_all();
        }
    }

    public class NewTabView: Ontis.BaseView {

        public signal void search(string text);

        public Ontis.SearchBox box;

        public NewTabView() {
            this.remove(this.search_bar);

            Gtk.Box prebox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            this.pack_start(prebox, false, false, 0);
            this.reorder_child(prebox, 0);

            this.box = new Ontis.SearchBox();
            this.box.search.connect((text) => { this.search(text); });
            prebox.set_center_widget(this.box);

            this.update.connect(this.update_cb);

            this.show_all();
        }

        private void update_cb(Ontis.BaseView view) {
            this.box.entry.set_text("");
            this.box.entry.grab_focus();
        }
    }
}
