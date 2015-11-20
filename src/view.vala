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
        public Gtk.Button button_reload;
        public Gtk.Entry entry;
        public Ontis.NotebookTab tab;
        public Gtk.Box hbox;
        public Ontis.WebView web_view;
        public Ontis.HistoryView history_view;
        public Ontis.DownloadsView downloads_view;
        public Ontis.ConfigView config_view;
        public Ontis.DownloadManager download_manager;

        public Utils.ViewMode mode;

        public View(Ontis.DownloadManager download_manager) {
            this.set_orientation(Gtk.Orientation.VERTICAL);

            this.mode = Utils.ViewMode.WEB;
            this.download_manager = download_manager;

            this.history_view = new Ontis.HistoryView();
            this.history_view.open_url.connect((url) => { this.open(url); });

            this.downloads_view = new Ontis.DownloadsView(this.download_manager);
            this.config_view = new Ontis.ConfigView();

            this.toolbar = new Ontis.Toolbar();
            this.toolbar.go_back.connect(this.back);
            this.toolbar.go_forward.connect(this.forward);
            this.pack_start(this.toolbar, false, false, 0);

            this.web_view = new Ontis.WebView();
            this.web_view.title_changed.connect(this.title_changed_cb);
            this.web_view.icon_loaded.connect((pixbuf) => { this.icon_loaded(pixbuf); });
            this.web_view.new_download.connect((download) => { this.new_download(download); });
            this.web_view.load_state_changed.connect((state) => this.toolbar.set_load_state(state));
            this.web_view.uri_changed.connect(this.uri_changed_cb);
            this.pack_start(this.web_view, true, true, 0);

            this.button_reload = this.toolbar.button_reload;
            this.button_reload.clicked.connect(this.reload_stop);

            this.entry = this.toolbar.entry;
            this.entry.activate.connect(() => {
                this.open(this.entry.get_text());
            });
        }

        private void title_changed_cb(Ontis.WebView view, string title, string uri) {
            this.tab.set_title(title);
            Utils.save_to_history(uri, title);
        }

        private void uri_changed_cb(Ontis.WebView view, string uri) {
            this.entry.set_text(uri);
            this.toolbar.set_back_forward_list(this.web_view.view.get_back_forward_list(), this.web_view.view.can_go_back(), this.web_view.view.can_go_forward());
        }

        public void open(string uri) {
            if (uri in Utils.SPECIAL_URLS) {
                Ontis.BaseView view = this.history_view;
                Utils.ViewMode mode = Utils.ViewMode.HISTORY;
                string title = "History";

                switch (uri) {
                    case Utils.URL_HISTORY:
                        view = this.history_view;
                        mode = Utils.ViewMode.HISTORY;
                        title = "History";
                        break;

                    case Utils.URL_DOWNLOADS:
                        view = this.downloads_view;
                        mode = Utils.ViewMode.DOWNLOADS;
                        title = "Downloads";
                        break;

                    case Utils.URL_CONFIG:
                        view = this.config_view;
                        mode = Utils.ViewMode.CONFIG;
                        title = "Settings";
                        break;
                }

                this.entry.set_text(uri);
                this.set_view_mode(mode);
                this.tab.set_title(title);
                view.update();

            } else {
                this.set_view_mode(Utils.ViewMode.WEB);
                this.web_view.view.open(Utils.parse_uri(uri));
            }
        }

        public void set_view_mode(Utils.ViewMode view) {
            if (this.get_mode() == view) {
                return;
            }

            switch(this.get_mode()) {
                case Utils.ViewMode.WEB:
                    this.remove(this.web_view);
                    break;

                case Utils.ViewMode.HISTORY:
                    this.remove(this.history_view);
                    break;

                case Utils.ViewMode.DOWNLOADS:
                    this.remove(this.downloads_view);
                    break;
            }

            this.mode = view;
            switch(this.get_mode()) {
                case Utils.ViewMode.WEB:
                    this.pack_start(this.web_view, true, true, 0);
                    break;

                case Utils.ViewMode.HISTORY:
                    this.pack_start(this.history_view, true, true, 0);
                    break;

                case Utils.ViewMode.DOWNLOADS:
                    this.pack_start(this.downloads_view, true, true, 0);
                    break;
            }

            this.show_all();
        }

        public void back(Ontis.Toolbar toolbar, int step=1) {
            if (this.web_view.view.can_go_back()) {
                this.web_view.view.go_back(); // FIXME: need go back the needed steps
            }
        }

        public void forward(Ontis.Toolbar toolbar, int step=1) {
            if (this.web_view.view.can_go_forward()) {
                this.web_view.view.go_forward();  // FIXME: need go forward the needed steps
            }
        }

        public void reload_stop(Gtk.Button? button=null) {
            if (this.toolbar.state == Utils.LoadState.LOADING) {
                this.reload();
            } else if (this.toolbar.state == Utils.LoadState.FINISHED) {
                this.stop();
            }
        }

        public void stop() {
            this.web_view.view.stop_loading();
        }

        public void reload() {
            this.web_view.view.reload();
        }

        public void set_tab(Ontis.NotebookTab tab) {
            this.tab = tab;
        }

        public int get_mode() {
            return this.mode;
        }
    }
}
