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

    public class Cache: Object {

        public string BASE_DIRECTORY;
        public string FAVICONS;
        public string DATABASES;
        public string COOKIES;
        public string DOWNLOADS;

        public Cache () {
            BASE_DIRECTORY = Ontis.get_cache_dir();
            FAVICONS = Ontis.get_favicons_path();
            DATABASES = GLib.Path.build_filename(BASE_DIRECTORY, "databases");
            COOKIES = GLib.Path.build_filename(BASE_DIRECTORY, "cookies.txt");
            DOWNLOADS = Ontis.get_download_dir();
            GLib.File favicons = GLib.File.new_for_path(FAVICONS);

            if (!favicons.query_exists()) {
                try {
                    favicons.make_directory_with_parents(null);
                } catch(GLib.Error e) {}
            }
        }
    }
}
