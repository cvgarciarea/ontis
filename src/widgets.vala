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

        this.icon = get_image_from_name("text-x-generic-symbolic", 16);
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
            this.icon = get_image_from_name("text-x-generic-symbolic", 16);
        }

        if (this.state == LoadState.FINISHED) {
            this.pack_start(this.icon, false, false, 0);
            this.show_all();
        }
    }
}

public class Notebook: Gtk.Notebook {

    public signal void full_screen();
    public signal void close();

    public DownloadManager download_manager;

    public Notebook(DownloadManager download_manager) {
        this.download_manager = download_manager;

        Gtk.Button button = new Gtk.Button();
        button.set_relief(Gtk.ReliefStyle.NONE);
        button.set_image(get_image_from_name("tab-new-symbolic", 16));
        button.clicked.connect(this.new_page_from_widget);
        this.set_action_widget(button, Gtk.PackType.END);
        button.show_all();

        this.set_scrollable(true);
        this.add_events(Gdk.EventMask.SCROLL_MASK);
        this.scroll_event.connect(scroll_event_cb);
    }

    public void set_topbar_visible(bool visible) {
        this.set_show_tabs(visible);

        foreach (Gtk.Widget widget in this.get_children()) {
            View view = (View)widget;
            if (visible) {
                view.toolbar.show_all();
            } else {
                view.toolbar.hide();
            }
        }
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

    public void new_page(string? url="google.com") {
        View view = new View(this.download_manager);
        view.set_vexpand(true);
        view.icon_loaded.connect(this.icon_loaded_cb);
        view.new_download.connect(this.new_download_cb);

        NotebookTab tab = new NotebookTab("New page", view);
        tab.close_now.connect(this.close_tab);
        view.set_tab(tab);

        this.insert_page(view, tab, -2);
        this.show_all();
        this.set_current_page(-2);

        this.set_tab_reorderable(view, true);
        view.open(url);
    }

    public void new_page_from_widget(Gtk.Widget widget) {
        this.new_page();
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
    public Gtk.Popover popover;
    public Gtk.ToggleButton button_menu;

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
        this.override_font(Pango.FontDescription.from_string("10"));
        this.pack_start(this.entry, true, true, 0);

        this.button_menu = new Gtk.ToggleButton();
        this.button_menu.set_image(get_image_from_name("preferences-system", 20));
        this.button_menu.set_relief(Gtk.ReliefStyle.NONE);
        this.button_menu.toggled.connect(this.show_popover);
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
        menu.append_item(get_item("Print", "app.print"));
        menu.append_item(get_item("Save page as", "app.download-page"));
        menu.append_item(get_item("Find", "app.find"));
        menu.append_item(get_item("Settings", "app.settings"));
        menu.append_item(get_item("About Ontis", "app.about"));
        menu.append_item(get_item("Exit", "app.exit"));

        this.popover = new Gtk.Popover.from_model(this.button_menu, menu);
        this.popover.closed.connect(this.popover_closed_cb);
    }

    public void set_load_state(int state) {
        this.state = state;
        if (this.state == LoadState.LOADING) {
            this.button_reload.set_image(get_image_from_name("view-refresh"));
        } else if (this.state == LoadState.FINISHED) {
            this.button_reload.set_image(get_image_from_name("window-close"));
        }
    }

    private GLib.MenuItem get_item(string name, string? action=null) {
        GLib.MenuItem item = new GLib.MenuItem(name, null);
        if (action != null) {
            item.set_detailed_action(action);
        }
        return item;
    }

    private void show_popover(Gtk.ToggleButton button) {
        if (this.button_menu.get_active()) {
            this.popover.show_all();
        } else {
            this.popover.hide();
        }
    }

    private void popover_closed_cb(Gtk.Popover popover) {
        this.button_menu.set_active(false);
    }
}

public class View: Gtk.Box {

    public signal void icon_loaded(Gdk.Pixbuf? pixbuf);
    public signal void new_download(WebKit.Download download); // pixbuf;

    public Toolbar toolbar;
    public DownPanel down_panel;
    public Gtk.Button button_back;
    public Gtk.Button button_forward;
    public Gtk.Button button_reload;
    public Gtk.Entry entry;
    public NotebookTab tab;
    public Gtk.Box hbox;
    public Gtk.ScrolledWindow scroll;
    public WebKit.WebView view;
    public HistoryView history_view;
    public DownloadsView downloads_view;
    public Cache cache;
    public DownloadManager download_manager;

    public int actual_view;

    public View(DownloadManager download_manager) {
        this.set_orientation(Gtk.Orientation.VERTICAL);

        this.actual_view = ViewMode.WEB;
        this.download_manager = download_manager;
        this.history_view = new HistoryView();
        this.downloads_view = new DownloadsView(this.download_manager);
        this.cache = new Cache();

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

        this.scroll = new Gtk.ScrolledWindow(null, null);
        this.pack_start(this.scroll, true, true, 0);

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
        this.view.status_bar_text_changed.connect(this.status_bar_text_changed_cb);
        this.view.hovering_over_link.connect(this.hovering_over_link_cb);
        this.scroll.add(this.view);

        this.down_panel = new DownPanel();
        this.down_panel.zoom_level_changed.connect(this.zoom_level_changed_cb);
        this.pack_end(this.down_panel, false, false, 0);
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

    public void status_bar_text_changed_cb(WebKit.WebView view, string text) {
        this.down_panel.set_text(text);
    }

    public void hovering_over_link_cb(WebKit.WebView view, string? link, string? title) {
        if (link != null) {
            this.down_panel.set_text(link);
        } else {
            this.down_panel.set_text("");
        }
    }

    public void open(string uri) {
        switch(uri) {
            case "ontis://history":
                this.entry.set_text("ontis://history");
                this.set_current_view(ViewMode.HISTORY);
                this.tab.set_title("History");
                this.history_view.update();
                break;

            case "ontis://downloads":
                this.entry.set_text("ontis://downloads");
                this.set_current_view(ViewMode.DOWNLOADS);
                this.tab.set_title("Downloads");
                this.downloads_view.update();
                break;

            default:
                this.set_current_view(ViewMode.WEB);
                this.view.open(parse_uri(uri));
                break;
        }
    }

    public void set_current_view(int view) {
        if (this.actual_view == view) {
            return;
        }

        switch(this.actual_view) {
            case ViewMode.WEB:
                this.remove(this.scroll);
                break;

            case ViewMode.HISTORY:
                this.remove(this.history_view);
                break;

            case ViewMode.DOWNLOADS:
                this.remove(this.downloads_view);
                break;
        }

        this.actual_view = view;
        switch(this.actual_view) {
            case ViewMode.WEB:
                this.pack_start(this.scroll, true, true, 0);
                break;

            case ViewMode.HISTORY:
                this.pack_start(this.history_view, true, true, 0);
                break;

            case ViewMode.DOWNLOADS:
                this.pack_start(this.downloads_view, true, true, 0);
                break;
        }

        this.show_all();
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

    public void zoom_level_changed_cb(DownPanel down_panel, int zoom) {
        this.view.set_zoom_level((float)zoom / (float)100);
    }
}

public class HistoryView: Gtk.ScrolledWindow {

    public signal void open_url(string url);

    public Gtk.ListBox listbox;

    public HistoryView() {
        this.listbox = new Gtk.ListBox();
        this.listbox.set_selection_mode(Gtk.SelectionMode.NONE);
        this.add(this.listbox);
    }

    public void update(string search="") {
        foreach (Gtk.Widget lrow in this.listbox.get_children()) {
            this.listbox.remove(lrow);
        }

        Json.Array history = get_history();
        GLib.List<unowned Json.Node> elements = history.get_elements();
        elements.reverse();

        foreach (Json.Node node in elements) {
            string data = node.dup_string();
            string date = data.split(" ")[0];
            string time = data.split(" ")[1];
            string name = data.split(" ")[2];
            string url = data.split(" ")[3];

            if (search != "" || (!(search in name) && !(search in url))) {
                continue;
            }

            Gtk.ListBoxRow row = new Gtk.ListBoxRow();
            this.listbox.add(row);

            Gtk.Box hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 10);
            row.add(hbox);

            Gtk.CheckButton cbutton = new Gtk.CheckButton();
            cbutton.set_label("%s %s".printf(date, time));
            hbox.pack_start(cbutton, false, false, 0);

            Gtk.LinkButton lbutton = new Gtk.LinkButton.with_label(url, name + " " + url);
            lbutton.activate_link.connect(this.open_link);
            hbox.pack_start(lbutton, false, false, 0);
        }

        this.show_all();
    }

    private bool open_link(Gtk.LinkButton button) {
        this.open_url(button.get_uri());
        return true;
    }
}

public class DownloadsView: Gtk.Box {

    public DownloadManager download_manager;
    public Gtk.ListBox listbox;

    public DownloadsView(DownloadManager download_manager) {
        this.set_orientation(Gtk.Orientation.VERTICAL);

        this.download_manager = download_manager;
        this.download_manager.new_download.connect(new_download_cb);

        Gtk.ScrolledWindow scroll = new Gtk.ScrolledWindow(null, null);
        this.pack_start(scroll, true, true, 0);

        this.listbox = new Gtk.ListBox();
        scroll.add(this.listbox);
    }

    public void update() {
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
        levelbar.set_vexpand(false);
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

public class ZoomScale: Gtk.Box {

    public signal void zoom_changed(int z);

    Gtk.DrawingArea area;
    Gtk.Label label;

    public int area_width = 150;
    public int zoom = 100;
    public int min_zoom = 28;
    public int max_zoom = 342;

    public ZoomScale() {
        this.set_orientation(Gtk.Orientation.HORIZONTAL);

        this.area = new Gtk.DrawingArea();
        this.area.set_size_request(this.area_width, 1);
        this.area.draw.connect(this.area_draw_cb);
        this.area.motion_notify_event.connect(this.motion_event_cb);
        this.pack_start(this.area, false, false, 5);

        this.area.add_events(Gdk.EventMask.BUTTON_MOTION_MASK |
                             Gdk.EventMask.BUTTON_PRESS_MASK |
                             Gdk.EventMask.BUTTON_RELEASE_MASK);

        this.label = new Gtk.Label("100 %");
        this.label.override_font(Pango.FontDescription.from_string("10"));
        this.pack_start(this.label, false, false, 0);
    }

    private bool area_draw_cb(Gtk.Widget area, Cairo.Context context) {
        Gtk.Allocation allocation;
        this.area.get_allocation(out allocation);

        double line_width = 1.0;
        double height = allocation.height / 2 - line_width / 2;
        double circle_line_width = 2;
        double circle_radius = allocation.height / 4;
        double circle_x;
        double default_x = 47.7;

        if (this.zoom < 110 && this.zoom > 90) {
            circle_x = default_x;
        } else {
            circle_x = (double)this.area_width / (double)(this.max_zoom - this.min_zoom) * this.zoom;
        }

        if (circle_x < circle_radius + circle_line_width) {
            circle_x = circle_radius + circle_line_width;
        } else if (circle_x + circle_radius + circle_line_width > this.area_width) {
            circle_x = this.area_width - circle_radius - circle_line_width;
        }

        context.set_source_rgb(0.5, 0.5, 0.5);
        context.set_line_width(line_width);
        context.move_to(0, height);
        context.line_to(this.area_width, height);
        context.stroke();

        context.move_to(default_x, 0);
        context.line_to(default_x, height - 4);
        context.stroke();

        context.set_source_rgb(0.7, 0.7, 0.7);
        context.set_line_width(circle_line_width);
        context.arc(circle_x, allocation.height / 2, circle_radius, 0, 2 * Math.PI);
        context.stroke();

        context.set_source_rgb(1, 1, 1);
        context.arc(circle_x, allocation.height / 2, circle_radius, 0, 2 * Math.PI);
        context.fill();

        return true;
    }

    private bool motion_event_cb(Gtk.Widget widget, Gdk.EventMotion event) {
        double x;

        if (event.x < 0) {
            x = 1;
        } else if (event.x > this.area_width) {
            x = this.area_width;
        } else {
            x = event.x;
        }

        this.zoom = (int)((this.max_zoom - this.min_zoom) / this.area_width * x);

        var window = this.area.get_window();
        var region = window.get_clip_region();
        window.invalidate_region(region, true);
        window.process_updates(true);

        if (this.zoom < 110 && this.zoom > 90) {
            this.zoom = 100;
        }

        if (this.zoom >= 100) {
            this.label.set_label(this.zoom.to_string() + " %");
        } else if (this.zoom < 100 && this.zoom > 10) {
            this.label.set_label("0" + this.zoom.to_string() + " %");
        } else if (this.zoom < 10) {
            this.label.set_label("00" + this.zoom.to_string() + " %");
        }

        this.zoom_changed(this.zoom);

        return false;
    }
}

public class DownPanel: Gtk.Box {

    public signal void zoom_level_changed(int zoom_level);

    public Gtk.Label label;
    public ZoomScale zoom_scale;

    public DownPanel() {
        this.label = new Gtk.Label(null);
        this.label.set_ellipsize(Pango.EllipsizeMode.END);
        this.label.override_font(Pango.FontDescription.from_string("10"));
        this.pack_start(this.label, true, true, 0);

        this.zoom_scale = new ZoomScale();
        this.zoom_scale.zoom_changed.connect(this.zoom_changed_cb);
        this.pack_end(zoom_scale, false, false, 0);
    }

    public void set_text(string label) {
        this.label.set_label(label);
    }

    private void zoom_changed_cb(int zoom) {
        this.zoom_level_changed(zoom);
    }
}
