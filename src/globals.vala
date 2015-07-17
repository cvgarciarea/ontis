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

enum LoadState {
    LOADING,
    FINISHED,
}

enum ViewMode {
    WEB,
    HISTORY,
    DOWNLOADS,
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
    return "https://www.google.com.uy/?gws_rd=cr&ei=vRJEVaPsNImlgwSh44DYBA#q=%s".printf(text);
}

public string parse_uri(string uri) {
    string url;

    if (" " in uri || !("." in uri) && !("/" in uri)) {
        url = search_in_google(uri);
    } else {
        if (!("http://" in uri) && !("https://" in uri) && !("ftp://" in uri) && !("file:///" in uri)) {
            url = "https://" + uri;
        } else {
            url = uri;
        }
    }

    return url;
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

public void save_to_history(string uri, string name) {
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

public class Download: GLib.Object {

    public signal void start();
    public signal void progress_changed(int size);
    public signal void finish();

    public int current_size;
    public int total_size;

    public string uri;
    public string path;

    public WebKit.Download download;

    public Download(WebKit.Download download) {
        this.download = download;
        this.path = GLib.Path.build_filename(get_download_dir(), this.get_filename());

        this.uri = this.download.get_uri();
        this.download.set_destination_uri("file://" + this.path);
        this.download.notify["status"].connect(this.status_changed_cb);
        this.download.notify["current-size"].connect(this.current_size_changed_cb);
    }

    public void start_now() {
        //this.download.start();
    }

    public string get_filename() {
        return this.download.get_suggested_filename();
    }

    public int get_total_size() {
        return this.total_size;
    }

    private void status_changed_cb(GLib.ParamSpec paramspec) {
        var status = this.download.get_status();
        this.total_size = (int)this.download.get_total_size();

        switch(status) {
            case WebKit.DownloadStatus.ERROR:
                break;

            case WebKit.DownloadStatus.CREATED:
                stdout.printf("download created\n");
                break;

            case WebKit.DownloadStatus.STARTED:
                break;

            case WebKit.DownloadStatus.CANCELLED:
                stdout.printf("download cacelled\n");
                break;

            case WebKit.DownloadStatus.FINISHED:
                this.finish();
                break;
        }
    }

    private void current_size_changed_cb(GLib.ParamSpec paramspec) {
        this.current_size = (int)this.download.get_current_size();
        if (this.current_size != this.total_size) {
            this.progress_changed(this.current_size);
        }
    }
}

public class DownloadManager: GLib.Object {

    public signal void new_download(Download download);

    GLib.List<Download> downloads;

    public DownloadManager() {
        this.downloads = new GLib.List<Download>();
    }

    public void add_download(WebKit.Download d) {
        Download download = new Download(d);
        downloads.append(download);
        //connect signals;
        this.new_download(download);
    }
}

public class Cache : Object {
    public string BASE_DIRECTORY;
    public string FAVICONS;
    public string DATABASES;
    public string COOKIES;
	public string DOWNLOADS;

    public Cache () {
        BASE_DIRECTORY = get_cache_dir();
        FAVICONS = get_favicons_path();
        DATABASES = GLib.Path.build_filename(BASE_DIRECTORY, "databases");
        COOKIES = GLib.Path.build_filename(BASE_DIRECTORY, "cookies.txt");
        DOWNLOADS = get_download_dir();
        GLib.File favicons = GLib.File.new_for_path(FAVICONS);

        if (!favicons.query_exists()) {
            try {
                favicons.make_directory_with_parents(null);
            } catch(GLib.Error e) {}
        }
    }
}

