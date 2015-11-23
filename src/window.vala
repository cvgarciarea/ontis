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

    public class Window: Gtk.ApplicationWindow {

        //public WebKit.Settings settings;
        public Ontis.Canvas canvas;
        public Ontis.DownloadManager download_manager;
        public Ontis.Notebook notebook;

        public bool full_screen;

        public Window() {
            this.set_default_size(620, 420);
            //this.set_app_paintable(true);
            //this.set_visual(screen.get_rgba_visual());

            this.canvas = new Ontis.Canvas();
            this.add(this.canvas);

            this.download_manager = new Ontis.DownloadManager();

            this.notebook = new Ontis.Notebook();
            this.notebook.set_show_buttons(true);
            this.notebook.remove(this.notebook.switcher);
            this.notebook.new_tab.connect(() => { this.new_page(); });
            this.notebook.minimize.connect(this.minimize_cb);
            this.notebook.turn_maxmizie.connect(this.turn_maximize_cb);
            this.notebook.close.connect(() => { this.destroy(); });
            this.notebook.page_removed.connect(this.page_removed_cb);
            this.canvas.pack_start(this.notebook, true, true, 0);

            this.set_titlebar(this.notebook.switcher);

            this.key_release_event.connect(this.key_release_event_cb);
            this.new_page();
            this.show_all();
        }

        private bool key_release_event_cb(Gtk.Widget self, Gdk.EventKey event) {
            switch(event.keyval) {
                case 65480:  // F11
                    this.change_full_screen();
                    break;

                case 65307:  // Scape
                    if (this.full_screen) {
                        this.change_full_screen();
                    }
                    break;
            }

            return false;
        }

        private void minimize_cb(Ontis.Notebook notebook) {
            this.iconify();
        }

        private void turn_maximize_cb(Ontis.Notebook notebook) {
            if (this.is_maximized) {
                this.unmaximize();
            } else {
                this.maximize();
            }
        }

        private void page_removed_cb(Ontis.Notebook notebook) {
            if (this.notebook.n_pages == 0) {
                this.destroy();
            }
        }

        public void full_screen_mode(Ontis.Notebook notebook) {
            this.change_full_screen();
        }

        public void change_full_screen() {
            this.full_screen = !this.full_screen;
            //this.notebook.set_topbar_visible(!this.full_screen);

            if (this.full_screen) {
                this.fullscreen();
            } else {
                this.unfullscreen();
            }
        }

        public void close_now() {
            this.destroy();
        }

        public Ontis.View get_current_view() {
            Ontis.View view = null;

            int current = 0;
            int page = this.notebook.current_page;
            foreach (Gtk.Widget widget in this.notebook.childs) {
                if (current == page) {
                    view = (widget as Ontis.View);
                    break;
                }

                current ++;
            }

            return view;
        }

        public void new_page(string? url="google.com") {
            Ontis.View view = new Ontis.View(this.download_manager);
            view.set_vexpand(true);
            //view.icon_loaded.connect(this.icon_loaded_cb);
            //view.new_download.connect(this.new_download_cb);

            //NotebookTab tab = new NotebookTab("New page", view);
            //tab.close_now.connect(this.close_tab);
            //view.set_tab(tab);

            Ontis.NotebookTab tab = this.notebook.append_page("Google", view);
            view.set_tab(tab);
            this.notebook.set_current_page(this.notebook.n_pages - 1);

            view.open(url);
            this.show_all();
        }

        public void new_page_from_widget(Gtk.Widget widget) {
            //Ontis.View view = (widget as Ontis.View);
            //this.notebook.append_page(view.title, view);
        }

        /*public void set_topbar_visible(bool visible) {
            this.set_show_tabs(visible);

            foreach (Gtk.Widget widget in this.get_children()) {
                View view = (View)widget;
                if (visible) {
                    view.toolbar.show_all();
                } else {
                    view.toolbar.hide();
                }
            }
        }*/

        //public void close_tab(Gtk.Box vbox) {
        //    this.remove_page(this.get_children().index(vbox));

        //    if (this.get_children().length() == 0) {
        //        this.close();
        //    }
        //}

        private void icon_loaded_cb(View view, Gdk.Pixbuf? pixbuf) {
            //view.tab.set_pixbuf(pixbuf);
        }

        private void new_download_cb(WebKit.Download download) {
            this.download_manager.add_download(download);
        }

        private void show_special_page(Utils.ViewMode mode) {
            if (this.get_current_view().get_mode() == mode) {
                return;
            }

            string url = "";

            switch (mode) {
                case Utils.ViewMode.HISTORY:
                    url = Utils.URL_HISTORY;
                    break;

                case Utils.ViewMode.DOWNLOADS:
                    url = Utils.URL_DOWNLOADS;
                    break;

                case Utils.ViewMode.CONFIG:
                    url = Utils.URL_CONFIG;
                    break;
            }


            int current = 0;
            foreach (Gtk.Widget widget in this.notebook.childs) {
                Ontis.View view = (widget as Ontis.View);
                if (view.get_mode() == mode) {
                    this.notebook.set_current_page(current);
                    return;
                }

                current ++;
            }

            this.new_page(url);
        }

        public void show_history() {
            this.show_special_page(Utils.ViewMode.HISTORY);
        }

        public void show_downloads() {
            this.show_special_page(Utils.ViewMode.DOWNLOADS);
        }

        public void show_settings() {
            this.show_special_page(Utils.ViewMode.CONFIG);
        }
    }
}
