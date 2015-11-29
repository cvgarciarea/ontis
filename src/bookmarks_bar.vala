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

    public class BookmarksBar: Gtk.Revealer {

        public Gtk.Toolbar toolbar;

        public BookmarksBar() {
            this.toolbar = new Gtk.Toolbar();
            this.add(this.toolbar);
        }

        public void a() {
            this.set_reveal_child(true);
        }

        public void b() {
            this.set_reveal_child(false);
        }

        public void update() {
        }
    }
}
