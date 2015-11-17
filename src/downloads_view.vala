namespace Ontis {

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
}
