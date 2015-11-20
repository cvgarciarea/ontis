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

    public class BaseView: Gtk.Box {

        public signal void update();

        public Gtk.SearchBar search_bar;
        public Gtk.SearchEntry search_entry;
        public Gtk.ScrolledWindow scroll;

        public BaseView() {
            this.set_orientation(Gtk.Orientation.VERTICAL);

            this.search_bar = new Gtk.SearchBar();
            this.pack_start(this.search_bar, false, false, 0);

            this.search_entry = new Gtk.SearchEntry();
            this.search_entry.set_size_request(300, -1);
            this.search_bar.add(this.search_entry);

            this.scroll = new Gtk.ScrolledWindow(null, null);
            this.pack_start(this.scroll, true, true, 0);
        }

        public void turn_show_search_bar() {
            this.search_bar.set_search_mode(!this.search_bar.get_search_mode());
        }
    }
}
