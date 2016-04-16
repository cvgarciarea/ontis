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

    public class WebView: Ontis.BaseView {

        public signal void title_changed(string title, string url);
        public signal void icon_loaded(Gdk.Pixbuf? pixbuf);
        public signal void new_download(WebKit.Download download);
        public signal void load_state_changed(Ontis.LoadState state);
        public signal void uri_changed(string uri);

        public Ontis.Cache cache;
        public WebKit.WebView view;
        public Ontis.DownPanel down_panel;
        public Ontis.SettingsManager settings_manager;
        
        public Gdk.Pixbuf? pixbuf = null;

        public WebView() {
            this.search_entry.changed.connect(() => { this.search_text(this.search_entry.get_text()); });
            this.cache = new Ontis.Cache();

            this.view = new WebKit.WebView();
            this.view.title_changed.connect(this.title_changed_cb);
            this.view.download_requested.connect(this.download_requested_cb);
            this.view.icon_loaded.connect(this.icon_loaded_cb);
            this.view.load_started.connect(this.load_started_cb);
            this.view.load_progress_changed.connect(this.load_progress_changed_cb);
            this.view.load_finished.connect(this.load_finishied_cb);
            this.view.load_error.connect(this.load_error_cb);
            this.view.load_committed.connect(this.load_committed_cb);
            this.view.mime_type_policy_decision_requested.connect(this.mime_type_policy_decision_requested_cb);
            this.view.status_bar_text_changed.connect(this.status_bar_text_changed_cb);
            this.view.hovering_over_link.connect(this.hovering_over_link_cb);
            this.scroll.add(this.view);

            this.down_panel = new Ontis.DownPanel();
            this.down_panel.zoom_level_changed.connect(this.zoom_level_changed_cb);
            this.pack_end(this.down_panel, false, false, 0);

            this.icon_loaded.connect(this._set_pixbuf);
        }

        private void _set_pixbuf(Ontis.WebView view, Gdk.Pixbuf? pixbuf) {
            this.pixbuf = pixbuf;
        }

        private void title_changed_cb(WebKit.WebView view, WebKit.WebFrame frame, string title) {
            this.title_changed(title, this.view.get_uri());
        }

        private bool download_requested_cb(WebKit.WebView view, WebKit.Download download) {
            this.new_download(download);
            return true;
        }

        private void load_started_cb(WebKit.WebView view, WebKit.WebFrame frame) {
            this.load_state_changed(Ontis.LoadState.FINISHED);
            //this.toolbar.set_load_state(Ontis.LoadState.FINISHED);
        }

        private void load_progress_changed_cb(WebKit.WebView view, int progress) {
            if (progress < 100) {
                //this.entry.set_progress_fraction((double)progress / 100);
            } else {
                //this.entry.set_progress_fraction(0.0);
                // *this.tab.set_icon(Ontis.LoadState.FINISHED);
            }
        }

        private void load_finishied_cb(WebKit.WebView view, WebKit.WebFrame frame) {
            this.load_state_changed(Ontis.LoadState.LOADING);
        }

        private void load_committed_cb(WebKit.WebView view, WebKit.WebFrame frame) {
            this.uri_changed(this.view.get_uri());
        }

        private bool load_error_cb(WebKit.WebView view, WebKit.WebFrame frame, string error, GLib.Error e) {
            // (@"Error $error\n");
            return false;
        }

        private bool mime_type_policy_decision_requested_cb(
                WebKit.WebView view, WebKit.WebFrame frame,
                WebKit.NetworkRequest network_request, string mimetype,
                WebKit.WebPolicyDecision decision) {

            if (!this.view.can_show_mime_type(mimetype)) {
                decision.download();
            }

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

        public void search_text(string text) {
        }

        public void zoom_level_changed_cb(Ontis.DownPanel down_panel, int zoom) {
            this.view.set_zoom_level((float)zoom / (float)100);
        }

        public void status_bar_text_changed_cb(WebKit.WebView view, string text) {
            this.down_panel.set_text(text);
        }

        public void hovering_over_link_cb(WebKit.WebView view, string? link, string? title) {
            this.down_panel.set_text((link != null)? link: "");
        }

        public void set_settings_manager(Ontis.SettingsManager settings_manager) {
            this.settings_manager = settings_manager;
            // connect signals
        }
    }
}
