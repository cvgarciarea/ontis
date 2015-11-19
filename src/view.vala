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

    public class View: Gtk.Box {

        public signal void icon_loaded(Gdk.Pixbuf? pixbuf);
        public signal void new_download(WebKit.Download download);

        public Ontis.Toolbar toolbar;
        public Ontis.DownPanel down_panel;
        public Gtk.Button button_reload;
        public Gtk.Entry entry;
        public Ontis.NotebookTab tab;
        public Gtk.Box hbox;
        public Gtk.ScrolledWindow scroll;
        public WebKit.WebView view;
        public Ontis.HistoryView history_view;
        public Ontis.DownloadsView downloads_view;
        public Ontis.Cache cache;
        public Ontis.DownloadManager download_manager;

        public int mode;

        public View(Ontis.DownloadManager download_manager) {
            this.set_orientation(Gtk.Orientation.VERTICAL);

            this.mode = ViewMode.WEB;
            this.download_manager = download_manager;

            this.history_view = new Ontis.HistoryView();
            this.history_view.open_url.connect((url) => { this.open(url); });

            this.downloads_view = new Ontis.DownloadsView(this.download_manager);
            this.cache = new Ontis.Cache();

            this.toolbar = new Ontis.Toolbar();
            this.toolbar.go_back.connect(this.back);
            this.toolbar.go_forward.connect(this.forward);
            this.pack_start(this.toolbar, false, false, 0);

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
            // *this.tab.set_icon(LoadState.LOADING);
        }

        private void load_progress_changed_cb(WebKit.WebView view, int progress) {
            if (progress < 100) {
                //this.entry.set_progress_fraction((double)progress / 100);
            } else {
                //this.entry.set_progress_fraction(0.0);
                // *this.tab.set_icon(LoadState.FINISHED);
            }
        }

        private void load_finishied_cb(WebKit.WebView view, WebKit.WebFrame frame) {
            this.toolbar.set_load_state(LoadState.LOADING);
            //this.entry.set_progress_fraction(0.0);
            // *this.tab.set_icon(LoadState.FINISHED);
        }

        public void load_committed_cb(WebKit.WebView view, WebKit.WebFrame frame) {
            this.entry.set_text(this.view.get_uri());
            this.toolbar.set_back_forward_list(this.view.get_back_forward_list(), this.view.can_go_back(), this.view.can_go_forward());
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
            if (this.get_mode() == view) {
                return;
            }

            switch(this.get_mode()) {
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

            this.mode = view;
            switch(this.get_mode()) {
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

        public void back(Ontis.Toolbar toolbar, int step=1) {
            if (this.view.can_go_back()) {
                this.view.go_back(); // FIXME: need go back the needed steps
            }
        }

        public void forward(Ontis.Toolbar toolbar, int step=1) {
            if (this.view.can_go_forward()) {
                this.view.go_forward();  // FIXME: need go forward the needed steps
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

        public void set_tab(Ontis.NotebookTab tab) {
            this.tab = tab;
        }

        public int get_mode() {
            return this.mode;
        }

        public void zoom_level_changed_cb(Ontis.DownPanel down_panel, int zoom) {
            this.view.set_zoom_level((float)zoom / (float)100);
        }
    }
}
