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
        this.button.set_image(get_image_from_name("window-close"));
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
                // load favicon
                break;
        }

        this.show_all();
    }
}

public class Notebook: Gtk.Notebook {

    public signal void close();
    public signal void move_to(int x, int y);
    public signal void minimize();
    public signal void maximize();
    public signal void show_download_manager();

    public bool dragging;
    public int dragging_x;
    public int dragging_y;

    public DownloadManager download_manager;

    public Notebook(DownloadManager download_manager) {
        this.download_manager = download_manager;

        Gtk.Box hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);

        Gtk.Button button = new Gtk.Button();
        button.set_relief(Gtk.ReliefStyle.NONE);
        button.set_image(get_image_from_name("list-add", 16));
        button.clicked.connect(this.new_page);
        hbox.pack_start(button, false, false, 5);

        button = new Gtk.Button();
        button.set_relief(Gtk.ReliefStyle.NONE);
        button.set_image(get_image_from_name("window-close", 16));
        button.clicked.connect(this.close_now);
        hbox.pack_end(button, false, false, 0);

        button = new Gtk.Button();
        button.set_relief(Gtk.ReliefStyle.NONE);
        button.set_image(get_image_from_name("window-maximize", 16));
        button.clicked.connect(this.maximize_now);
        hbox.pack_end(button, false, false, 0);

        button = new Gtk.Button();
        button.set_relief(Gtk.ReliefStyle.NONE);
        button.set_image(get_image_from_name("window-minimize", 16));
        button.clicked.connect(this.minimize_now);
        hbox.pack_end(button, false, false, 0);

        hbox.show_all();

        this.set_action_widget(hbox, Gtk.PackType.END);
        this.set_scrollable(true);
        this.add_events(Gdk.EventMask.SCROLL_MASK |
                        Gdk.EventMask.BUTTON_PRESS_MASK |
                        Gdk.EventMask.BUTTON_RELEASE_MASK |
                        Gdk.EventMask.POINTER_MOTION_MASK);

        this.scroll_event.connect(scroll_event_cb);
        this.motion_notify_event.connect(motion_event_cb);
        this.button_press_event.connect(button_press_event_cb);
        this.button_release_event.connect(button_release_event_cb);
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

    private bool motion_event_cb(Gtk.Widget self, Gdk.EventMotion event) {
        if (!this.dragging) {
            return false;
        }

        //this.move_to((int)(event.x - this.dragging_x), (int)(event.y - this.dragging_y));
        return false;
    }

    private bool button_press_event_cb(Gtk.Widget self, Gdk.EventButton event) {
        if (event.button != 1) {
            return false;
        }

        this.dragging = true;
        this.dragging_x = (int)event.x;
        this.dragging_y = (int)event.y;
        return false;
    }

    private bool button_release_event_cb(Gtk.Widget self, Gdk.EventButton event) {
        if (event.button != 1) {
            return false;
        }

        this.dragging = false;
        return false;
    }

    public void new_page() {
        Gtk.Box vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        NotebookTab tab = new NotebookTab("New page", vbox);

        Toolbar toolbar = new Toolbar();
        vbox.pack_start(toolbar, false, false, 0);

        View view = new View();//this.settings);
        view.set_toolbar(toolbar);
        view.set_tab(tab);
        view.new_download.connect(this.new_download_cb);
        vbox.pack_start(view, true, true, 0);
        tab.close_now.connect(this.close_tab);

        this.insert_page(vbox, tab, -1);
        this.show_all();

        this.set_current_page(-1);
        this.set_tab_reorderable(vbox, true);
        view.open("google.com");
    }

    public void close_tab(Gtk.Box vbox) {
        this.remove_page(this.get_children().index(vbox));

        if (this.get_children().length() == 0) {
            this.close();
        }
    }

    private void minimize_now(Gtk.Button button) {
        this.minimize();
    }

    private void maximize_now(Gtk.Button button) {
        this.maximize();
    }

    private void close_now(Gtk.Button button) {
        this.close();
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
        this.button_back.set_image(get_image_from_name("go-previous"));
        this.button_back.set_relief(Gtk.ReliefStyle.NONE);
        this.pack_start(this.button_back, false, false, 0);

        this.button_forward = new Gtk.Button();
        this.button_forward.set_image(get_image_from_name("go-next"));
        this.button_forward.set_relief(Gtk.ReliefStyle.NONE);
        this.pack_start(this.button_forward, false, false, 0);

        this.button_reload = new Gtk.Button();
        this.button_reload.set_image(get_image_from_name("view-refresh"));
        this.button_reload.set_relief(Gtk.ReliefStyle.NONE);
        this.pack_start(this.button_reload, false, false, 0);

        this.entry = new Gtk.Entry();
        this.pack_start(this.entry, true, true, 0);

        this.button_preferences = new Gtk.Button();
        this.button_preferences.set_image(get_image_from_name("preferences-system"));
        this.button_preferences.set_relief(Gtk.ReliefStyle.NONE);
        this.pack_start(this.button_preferences, false, false, 0);
    }

    public void set_load_state(int state) {
        this.state = state;
        if (this.state == LoadState.LOADING) {
            this.button_reload.set_image(get_image_from_name("view-refresh"));
        } else if (this.state == LoadState.FINISHED) {
            this.button_reload.set_image(get_image_from_name("process-stop"));
        }
    }
}

public class View: Gtk.ScrolledWindow {

    public signal void icon_loaded(Gdk.Pixbuf pixbuf);
    public signal void new_download(WebKit.Download download); // pixbuf;

    public Toolbar toolbar;
    public Gtk.Button button_back;
    public Gtk.Button button_forward;
    public Gtk.Button button_reload;
    public Gtk.Entry entry;
    public NotebookTab tab;
    public WebKit.WebView view;

    public View() {
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
        this.add(this.view);
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
        Gdk.Pixbuf pixbuf;

        if (this.view.get_uri() != null) {
            bool download = check_needs_download_favicon(this.view.get_uri());
            if (download) {
                //FaviconDownloader fdownloader = new FaviconDownloader(icon_uri, this.view.get_uri());
                //fdownloader.finish.connect(this.icon_changed);
                //var database = new WebKit.FaviconDatabase();
                //pixbuf = database.try_get_favicon_pixbuf(this.view.get_uri(), 16, 16);
                //this.icon_loaded(pixbuf);
            } else {
                pixbuf = new Gdk.Pixbuf.from_file_at_size(get_favicon_file(this.view.get_uri()), 16, 16);
                this.icon_loaded(pixbuf);
            }
        }
    }

    private void icon_changed(FaviconDownloader downloader, string path) {
        //this.icon_loaded(path);
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

    public void set_toolbar(Toolbar toolbar) {
        this.toolbar = toolbar;

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
            stdout.printf("progress %d %d\n", progress, download.total_size);
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
