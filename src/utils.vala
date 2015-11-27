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

namespace Utils {

    public const string URL_NEWTAB = "ontis://newtab";
    public const string URL_HISTORY = "ontis://history";
    public const string URL_DOWNLOADS = "ontis://downloads";
    public const string URL_CONFIG = "ontis://settings";
    public const string[] SPECIAL_URLS = { URL_NEWTAB, URL_HISTORY, URL_DOWNLOADS, URL_CONFIG };

    public enum LoadState {
        LOADING,
        FINISHED,
    }

    public enum ViewMode {
        WEB,
        NEWTAB,
        HISTORY,
        DOWNLOADS,
        CONFIG,
    }

    public string get_download_dir() {
        return GLib.Environment.get_user_special_dir(GLib.UserDirectory.DOWNLOAD);
    }

    public string get_work_dir() {
        return GLib.Path.build_filename(GLib.Environment.get_user_config_dir(), "ontis");
    }

    public string get_cache_dir() {
        return GLib.Path.build_filename(GLib.Environment.get_user_cache_dir(), "ontis");
    }

    public string get_favicons_path() {
        return GLib.Path.build_filename(get_cache_dir(), "favicons");
    }

    public string get_history_path() {
        return GLib.Path.build_filename(get_work_dir(), "history.json");
    }

    public Gdk.Pixbuf get_newtab_pixbuf() {
        return get_image_from_name("go-home-symbolic", 16).get_pixbuf();
    }

    public Gdk.Pixbuf get_history_pixbuf() {
        return get_image_from_name("document-open-recent-symbolic", 16).get_pixbuf();
    }

    public Gdk.Pixbuf get_downloads_pixbuf() {
        return get_image_from_name("document-save-symbolic", 16).get_pixbuf();
    }

    public Gdk.Pixbuf get_config_pixbuf() {
        return get_image_from_name("emblem-system-symbolic", 16).get_pixbuf();
    }

    public void check_paths() {
        GLib.File work_dir = GLib.File.new_for_path(get_work_dir());
        GLib.File history_path = GLib.File.new_for_path(get_history_path());

        if (!work_dir.query_exists()) {
            try {
                work_dir.make_directory_with_parents(null);
            } catch(GLib.Error e) {}
        }

        if (!history_path.query_exists()) {
            try {
                history_path.create_readwrite(GLib.FileCreateFlags.NONE, null);
            } catch(GLib.Error e) {}
        }
    }

    public string search_in_google(string search) {
        string text = search.replace(" ", "+");
        return "https://www.google.com.uy/?#q=%s".printf(text);
    }

    public string parse_uri(string uri) {
        string[] search_chars = { " " };
        string[] url_chars = { "." };
        string[] hosts = { "http://", "https://", "ftp://", "file://" };

        foreach (string _char in search_chars) {
            if (_char in uri) {
                return search_in_google(uri);
            }
        }

        foreach (string _char in url_chars) {
            if (!(_char in uri)) {
                return search_in_google(uri);
            }
        }

        foreach (string host in hosts) {
            if (uri.has_prefix(host)) {
                return uri;
            }
        }

        print(uri);
        return "http://" + uri;
    }

    public Gtk.Image get_image_from_name(string icon, int size=24) {
        try {
            var screen = Gdk.Screen.get_default();
            var theme = Gtk.IconTheme.get_for_screen(screen);
            var pixbuf = theme.load_icon(icon, size, Gtk.IconLookupFlags.FORCE_SYMBOLIC);

            if (pixbuf.get_width() != size || pixbuf.get_height() != size) {
                pixbuf = pixbuf.scale_simple(size, size, Gdk.InterpType.BILINEAR);
            }

            return new Gtk.Image.from_pixbuf(pixbuf);
        }
        catch (GLib.Error e) {
            return new Gtk.Image();
        }
    }

    public void save_to_history(string uri, string n) {
        string name;
        if (" " in n) {
            name = n.replace(" ", "###space###");
        } else {
            name = n;
        }

        var now = new DateTime.now_local();
        Json.Array history = get_history();
        string data = now.format("%x %X") + " %s %s".printf(name, uri);
        history.add_string_element(data);

        var root_node = new Json.Node(Json.NodeType.ARRAY);
        root_node.set_array(history);

        var generator = new Json.Generator(){pretty=true, root=root_node};

        try {
            generator.to_file(get_history_path());
        } catch(GLib.Error e) {}
    }

    public Json.Array get_history() {
        check_paths();
        string dir = get_history_path();
        Json.Parser parser = new Json.Parser();
        try {
        	parser.load_from_file(dir);
	        return parser.get_root().get_array();
        } catch {
            return new Json.Array();
        }
    }

    public Gdk.Pixbuf get_pixbuf_from_path(string path, int size = 48) {
        Gtk.IconTheme icon_theme = Gtk.IconTheme.get_default();
        GLib.File file = GLib.File.new_for_path(path);
        Gdk.Pixbuf null_pixbuf = get_image_from_name("text-x-generic-symbolic", 24).get_pixbuf();
        GLib.FileInfo info;

        try {
    		info = file.query_info("standard::icon", 0);
    	} catch (GLib.Error e) {
    	    return null_pixbuf.copy();
    	}

		GLib.Icon icon = info.get_icon();

        string[] icon_names = icon.to_string().split(" ");
        Gtk.IconInfo icon_info = icon_theme.choose_icon(icon_names, size, Gtk.IconLookupFlags.GENERIC_FALLBACK);

        try {
            return icon_info.load_icon();
        } catch (GLib.Error e) {
            return null_pixbuf.copy();
        }
    }

    public void convert_size(double bytes, out double size, out string unity) {
        size = 0;
        unity = "B";

        string[] unities = { "KB", "MB", "GB", "TB" };
        foreach (string u in unities) {
            if (bytes >= 1024) {
                bytes /= 1024;
                unity = u;
            } else {
                break;
            }
        }
        size = bytes;
    }
}
