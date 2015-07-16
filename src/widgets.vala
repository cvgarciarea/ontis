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

public class Canvas: Gtk.Box {

    public Canvas() {
        this.set_orientation(Gtk.Orientation.VERTICAL);
    }
}

public class NotebookTab: Gtk.Box {

    public signal void close_now(Gtk.Box vbox);

    public int? state = null;

    public Gtk.Box vbox;
    public Gtk.Image icon;
    public Gtk.Spinner spinner;
    public Gtk.Button button;
    public Gtk.Label label;

    public NotebookTab(string name, Gtk.Box vbox) {
        this.set_orientation(Gtk.Orientation.HORIZONTAL);

        this.vbox = vbox;

        this.icon = new Gtk.Image.from_stock(Gtk.Stock.FILE, Gtk.IconSize.MENU);
        this.pack_start(this.icon, false, false, 0);

        this.spinner = new Gtk.Spinner();

        this.button = new Gtk.Button();
        this.button.set_image(get_image_from_name("window-close", 16));
        this.button.clicked.connect(this.close);
        this.pack_end(this.button, false, false, 0);

        this.label = new Gtk.Label(name);
        this.label.set_max_width_chars(20);
        //this.label.set_ellipsize(Pango.EllipsizeMode.END);
        this.pack_end(this.label, false, false, 5);

        this.show_all();
    }

    private void close(Gtk.Button button) {
        this.close_now(this.vbox);
    }

    public void set_title(string title) {
        if (title.length <= 20) {
            this.label.set_label(title);
        } else {
            string str = "";
            for (int i=0; i <= 17; i++) {
                str += title.get_char(title.index_of_nth_char(i)).to_string();
            }

            this.label.set_label(str + "...");
        }

        this.set_tooltip_text(title);
    }

    public string get_title() {
        return this.label.get_label();
    }

    public void set_icon(int state) {
        if (state == this.state) {
            return;
        }

        this.state = state;

        switch(state) {
            case LoadState.LOADING:
                this.remove(this.icon);
                this.pack_start(this.spinner, false, false, 0);
                this.spinner.start();
                break;

            case LoadState.FINISHED:
                this.spinner.stop();
                this.remove(this.spinner);
                this.pack_start(this.icon, false, false, 0);
                break;
        }

        this.show_all();
    }

    public void set_pixbuf(Gdk.Pixbuf? pixbuf) {
        if (this.state == LoadState.FINISHED) {
            this.remove(this.icon);
        }

        if (pixbuf != null) {
            this.icon = new Gtk.Image.from_pixbuf(pixbuf);
        } else {
            this.icon = new Gtk.Image.from_stock(Gtk.Stock.FILE, Gtk.IconSize.MENU);
        }

        if (this.state == LoadState.FINISHED) {
            this.pack_start(this.icon, false, false, 0);
            this.show_all();
        }
    }
}

public class Notebook: Gtk.Notebook {

    public signal void close();
    public signal void show_download_manager();

    public bool dragging;
    public int dragging_x;
    public int dragging_y;

    public DownloadManager download_manager;

    public Notebook(DownloadManager download_manager) {
        this.download_manager = download_manager;

        Gtk.Button button = new Gtk.Button();
        button.set_relief(Gtk.ReliefStyle.NONE);
        button.set_image(get_image_from_name("tab-new-symbolic", 16));
        button.clicked.connect(this.new_page);
        this.set_action_widget(button, Gtk.PackType.END);
        button.show_all();

        this.set_scrollable(true);
        this.add_events(Gdk.EventMask.SCROLL_MASK);
        this.scroll_event.connect(scroll_event_cb);
    }

    private bool scroll_event_cb(Gtk.Widget self, Gdk.EventScroll event) {
        switch (event.direction) {
            case Gdk.ScrollDirection.UP:
                this.prev_page();
                break;

            case Gdk.ScrollDirection.DOWN:
                this.next_page();
                break;
        }

        return false;
    }

    public void new_page() {
        View view = new View();
        view.set_vexpand(true);
        view.icon_loaded.connect(this.icon_loaded_cb);
        view.new_download.connect(this.new_download_cb);

        NotebookTab tab = new NotebookTab("New page", view);
        tab.close_now.connect(this.close_tab);
        view.set_tab(tab);

        this.insert_page(view, tab, -1);
        this.show_all();
        this.set_current_page(-1);

        this.set_tab_reorderable(view, true);
        view.open("google.com");
    }

    public void close_tab(Gtk.Box vbox) {
        this.remove_page(this.get_children().index(vbox));

        if (this.get_children().length() == 0) {
            this.close();
        }
    }

    private void icon_loaded_cb(View view, Gdk.Pixbuf? pixbuf) {
        view.tab.set_pixbuf(pixbuf);
    }

    private void new_download_cb(WebKit.Download download) {
        this.download_manager.add_download(download);
    }
}

public class Toolbar: Gtk.Box {

    public Gtk.Button button_back;
    public Gtk.Button button_forward;
    public Gtk.Button button_reload;
    public Gtk.Entry entry;
    public Gtk.Button button_preferences;

    public int state;

    public Toolbar() {
        this.set_orientation(Gtk.Orientation.HORIZONTAL);
        this.state = LoadState.LOADING;

        this.button_back = new Gtk.Button();
        this.button_back.set_image(get_image_from_name("go-previous", 20));
        this.button_back.set_relief(Gtk.ReliefStyle.NONE);
        this.pack_start(this.button_back, false, false, 0);

        this.button_forward = new Gtk.Button();
        this.button_forward.set_image(get_image_from_name("go-next", 20));
        this.button_forward.set_relief(Gtk.ReliefStyle.NONE);
        this.pack_start(this.button_forward, false, false, 0);

        this.button_reload = new Gtk.Button();
        this.button_reload.set_image(get_image_from_name("view-refresh", 20));
        this.button_reload.set_relief(Gtk.ReliefStyle.NONE);
        this.pack_start(this.button_reload, false, false, 0);

        this.entry = new Gtk.Entry();
        this.modify_font(Pango.FontDescription.from_string("10"));
        this.pack_start(this.entry, true, true, 0);

        this.button_preferences = new Gtk.Button();
        this.button_preferences.set_image(get_image_from_name("preferences-system", 20));
        this.button_preferences.set_relief(Gtk.ReliefStyle.NONE);
        this.pack_start(this.button_preferences, false, false, 0);
    }

    public void set_load_state(int state) {
        this.state = state;
        if (this.state == LoadState.LOADING) {
            this.button_reload.set_image(get_image_from_name("view-refresh"));
        } else if (this.state == LoadState.FINISHED) {
            this.button_reload.set_image(get_image_from_name("window-close"));
        }
    }
}

public class View: Gtk.Box {

    public signal void icon_loaded(Gdk.Pixbuf? pixbuf);
    public signal void new_download(WebKit.Download download); // pixbuf;

    public Toolbar toolbar;
    public Gtk.Button button_back;
    public Gtk.Button button_forward;
    public Gtk.Button button_reload;
    public Gtk.Entry entry;
    public NotebookTab tab;
    public WebKit.WebView view;

    public Cache cache;

    public View() {
        this.set_orientation(Gtk.Orientation.VERTICAL);

        this.toolbar = new Toolbar();
        this.pack_start(this.toolbar, false, false, 0);

        this.button_back = this.toolbar.button_back;
        this.button_back.clicked.connect(this.back);

        this.button_forward = this.toolbar.button_forward;
        this.button_forward.clicked.connect(this.forward);

        this.button_reload = this.toolbar.button_reload;
        this.button_reload.clicked.connect(this.reload_stop);

        this.entry = this.toolbar.entry;
        this.entry.activate.connect(() => {
            this.open(this.entry.get_text());
        });

        Gtk.Box hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        this.pack_start(hbox, true, true, 0);

        Gtk.ScrolledWindow scroll = new Gtk.ScrolledWindow(null, null);
        hbox.pack_start(scroll, true, true, 0);

        this.view = new WebKit.WebView();
        this.view.title_changed.connect(this.title_changed_cb);
        this.view.download_requested.connect(this.download_requested_cb);
        this.view.icon_loaded.connect(this.icon_loaded_cb);
        //this.view.load_error.connect(this.load_error_cb);
        this.view.load_started.connect(this.load_started_cb);
        this.view.load_progress_changed.connect(this.load_progress_changed_cb);
        this.view.load_finished.connect(this.load_finishied_cb);
        this.view.load_committed.connect(this.load_committed_cb);
        this.view.mime_type_policy_decision_requested.connect(this.mime_type_policy_decision_requested_cb);
        //this.view.connect('hovering-over-link', self.__hovering_over_link_cb)
        //this.view.connect('status-bar-text-changed', self.__status_bar_text_changed_cb)
        //this.view.connect('geolocation-policy-decision-requested', self.__gelocation_requested_cb)
        scroll.add(this.view);

        this.cache = new Cache();
    }

    private void title_changed_cb(WebKit.WebView view, WebKit.WebFrame frame, string title) {
        this.tab.set_title(title);
        save_to_history(this.view.get_uri(), title);
    }

    private bool download_requested_cb(WebKit.WebView view, WebKit.Download download) {
        this.new_download(download);
        return true;
    }

    private void icon_loaded_cb(WebKit.WebView view, string icon_uri) {
		Soup.URI uri = new Soup.URI(icon_uri);
		string filename = @"$(this.cache.FAVICONS)/$(uri.host)_$(uri.port).ico";
		GLib.File file = GLib.File.new_for_path(filename);
		if (file.query_exists()) {
			try {
				Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_file_at_scale(filename, 16, 16, true);
				this.icon_loaded(pixbuf);
			} catch (GLib.Error e) {
				try {
					file.delete(null);
				} catch (GLib.Error e) {
				}
			}
		} else {
			this.icon_loaded(null);
			Soup.Session session = WebKit.get_default_session();
			Soup.Message message = new Soup.Message.from_uri("GET", uri);
			session.queue_message(message, this.icon_downloaded_cb);
		}
	}

    private void icon_downloaded_cb(Soup.Session session, Soup.Message message) {
		unowned Soup.MessageBody body = message.response_body;
		GLib.MemoryInputStream stream = new GLib.MemoryInputStream.from_data(body.data, null);
		try {
			Gdk.Pixbuf pixbuf = new Gdk.Pixbuf.from_stream_at_scale(stream, 16, 16, true, null);
			this.icon_loaded(pixbuf);
			try {
				unowned Soup.URI uri = message.get_uri();
				string filename = @"$(uri.host)_$(uri.port).ico";
				pixbuf.save(@"$(this.cache.FAVICONS)/$filename", "ico");
			} catch (Error e) {
			}
		} catch (Error e) {
			this.icon_loaded(null);
		}
    }

    //private bool load_error_cb(WebKit.WebView view, WebKit.WebFrame frame, string uri) {
    //    return false;
    //}

    private void load_started_cb(WebKit.WebView view, WebKit.WebFrame frame) {
        this.toolbar.set_load_state(LoadState.FINISHED);
        //this.entry.set_progress_fraction(0.0);
        this.tab.set_icon(LoadState.LOADING);
    }

    private void load_progress_changed_cb(WebKit.WebView view, int progress) {
        if (progress < 100) {
            //this.entry.set_progress_fraction((double)progress / 100);
        } else {
            //this.entry.set_progress_fraction(0.0);
            this.tab.set_icon(LoadState.FINISHED);
        }
    }

    private void load_finishied_cb(WebKit.WebView view, WebKit.WebFrame frame) {
        this.toolbar.set_load_state(LoadState.LOADING);
        //this.entry.set_progress_fraction(0.0);
        this.tab.set_icon(LoadState.FINISHED);
    }

    public void load_committed_cb(WebKit.WebView view, WebKit.WebFrame frame) {
        this.entry.set_text(this.view.get_uri());
        this.button_back.set_sensitive(this.view.can_go_back());
        this.button_forward.set_sensitive(this.view.can_go_forward());
    }

    public bool mime_type_policy_decision_requested_cb(WebKit.WebView view, WebKit.WebFrame frame,
        WebKit.NetworkRequest network_request, string thing, WebKit.WebPolicyDecision decision) {

        return true;
    }

    public void open(string uri) {
        this.view.open(parse_uri(uri));

        //if not uri.startswith('ontis://'):
        //    url = parse_uri(uri)

        //    if url:
        //        self.entry.set_text(url)
        //        self.view.open(url)

        //else:
        //    if uri == 'ontis://history':
        //        self.open_history()
    }

    public void back(Gtk.Button? button=null) {
        if (this.view.can_go_back()) {
            this.view.go_back();
        }
    }

    public void forward(Gtk.Button? button=null) {
        if (this.view.can_go_forward()) {
            this.view.go_forward();
        }
    }

    public void reload_stop(Gtk.Button? button=null) {
        if (this.toolbar.state == LoadState.LOADING) {
            this.reload();
        } else if (this.toolbar.state == LoadState.FINISHED) {
            this.stop();
        }
    }

    public void stop() {
        this.view.stop_loading();
    }

    public void reload() {
        this.view.reload();
    }

    public void set_tab(NotebookTab tab) {
        this.tab = tab;
    }
}

public class DownloadsViewer: Gtk.Window {

    public DownloadManager download_manager;
    public Gtk.ListBox listbox;

    public DownloadsViewer(DownloadManager download_manager) {
        this.download_manager = download_manager;
        this.download_manager.new_download.connect(new_download_cb);

        Gtk.ScrolledWindow scroll = new Gtk.ScrolledWindow(null, null);
        this.add(scroll);

        this.listbox = new Gtk.ListBox();
        scroll.add(this.listbox);
    }

    private void new_download_cb(DownloadManager dm, Download download) {
        Gtk.ListBoxRow row = new Gtk.ListBoxRow();
        this.listbox.add(row);

        Gtk.Box hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        hbox.set_border_width(10);
        row.add(hbox);

        hbox.pack_start(get_image_from_name("text-x-generic", 48), false, false, 0);

        Gtk.Box vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        hbox.pack_start(vbox, true, true, 0);

        Gtk.LevelBar levelbar = new Gtk.LevelBar.for_interval(0, download.get_total_size());
        download.progress_changed.connect((progress) => {
            levelbar.set_max_value(download.get_total_size());
            levelbar.set_value(progress);
        });
        vbox.pack_start(levelbar, true, true, 0);

        Gtk.Label label = new Gtk.Label(download.get_filename());
        vbox.pack_start(label, false, false, 0);

        hbox.pack_end(get_image_from_name("window-close"), false, false, 0);

        this.show_all();

        download.start_now();
    }
}
