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

    public class DownloadProgressCircle: Gtk.DrawingArea {

        public int total_size = 0;
        public int progress = 0;
        public Gdk.Pixbuf? pixbuf = null;

        public DownloadProgressCircle() {
            this.set_size_request(50, 50);
            this.draw.connect(this.draw_cb);
        }

        private bool draw_cb(Gtk.Widget widget, Cairo.Context context) {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);

            double radius = int.min(alloc.width, alloc.height) / 2;
            double total_angle = GLib.Math.PI * 2;
            double angle = total_angle - (this.progress * GLib.Math.PI * 2 / this.total_size) + GLib.Math.PI_2;
            int x = alloc.width / 2;
            int y = alloc.height / 2;

            context.set_source_rgb(0.4, 0.4, 0.4);

            if (this.total_size > this.progress) {
                context.arc(x, y, radius, -GLib.Math.PI_2, -angle);
            } else {
                context.arc(x, y, radius, -GLib.Math.PI_2, total_angle);
            }

            context.line_to(x, y);
            context.fill();

            if (this.pixbuf == null) {
                this.pixbuf = Utils.get_image_from_name("text-x-generic", (int)(radius * 1.5)).get_pixbuf();
            }

            int px = alloc.width / 2 - pixbuf.width / 2;
            int py = alloc.height / 2 - pixbuf.height / 2;
            Gdk.cairo_set_source_pixbuf(context, this.pixbuf, px, py);
            context.paint();

            return false;
        }

        private void update() {
            GLib.Idle.add(() => {
                this.queue_draw();
                return false;
            });
        }

        public void set_total_size(int size) {
            this.total_size = size;
            this.update();
        }

        public int get_total_size() {
            return this.total_size;
        }

        public void set_progress(int progress) {
            this.progress = progress;
            this.update();
        }

        public int get_progress() {
            return this.progress;
        }

        public void set_pixbuf(Gdk.Pixbuf pixbuf) {
            this.pixbuf = pixbuf;
            this.update();
        }

        public Gdk.Pixbuf get_pixbuf() {
            return this.pixbuf;
        }
    }

    public class DownloadsView: Ontis.BaseView {

        public Ontis.DownloadManager download_manager;
        public Gtk.ListBox listbox;

        public DownloadsView(Ontis.DownloadManager download_manager) {
            this.download_manager = download_manager;
            this.download_manager.new_download.connect(this.new_download_cb);

            this.listbox = new Gtk.ListBox();
            this.scroll.add(this.listbox);

            this.update.connect(this.update_cb);

            this.show_all();
        }

        private void update_cb() {
            foreach (Gtk.Widget widget in this.listbox.get_children()) {
                this.listbox.remove(widget);
            }

            foreach (Ontis.Download download in this.download_manager.downloads) {
                this.new_download_cb(this.download_manager, download);
            }
        }

        private void new_download_cb(DownloadManager dm, Download download) {
            Gtk.ListBoxRow row = new Gtk.ListBoxRow();
            this.listbox.add(row);

            Gtk.Box hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            hbox.set_margin_left(10);
            hbox.set_margin_right(10);
            row.add(hbox);

            Ontis.DownloadProgressCircle circle = new Ontis.DownloadProgressCircle();
            hbox.pack_start(circle, false, false, 0);

            Gtk.Box vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            hbox.pack_start(vbox, true, true, 10);

            Gtk.Box sub_hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            vbox.pack_start(sub_hbox, false, false, 1);

            sub_hbox.pack_start(new Gtk.Label(download.get_filename()), false, false, 0);

            sub_hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            vbox.pack_start(sub_hbox, false, true, 1);

            Gtk.LinkButton lbutton = new Gtk.LinkButton.with_label(download.get_destination_file(), download.get_uri());
            lbutton.set_visited(false);
            lbutton.set_relief(Gtk.ReliefStyle.NONE);
            sub_hbox.pack_start(lbutton, false, false, 0);

            Gtk.Button button_cancel = new Gtk.Button();
            button_cancel.set_image(Utils.get_image_from_name("window-close", 24));
            button_cancel.set_tooltip_text("Cancel");
            button_cancel.clicked.connect(() => { download.stop(); });
            sub_hbox.pack_end(button_cancel, false, false, 0);

            sub_hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            vbox.pack_start(sub_hbox, false, true, 1);

            Gtk.Label label = new Gtk.Label("");
            sub_hbox.pack_start(label, false, false, 0);

            download.progress_changed.connect((p) => {
                double total_size;
                string total_size_unity;
                double progress;
                string progress_unity;
                Utils.convert_size(download.get_total_size(), out total_size, out total_size_unity);
                Utils.convert_size(p, out progress, out progress_unity);

                string str1 = total_size.to_string();
                if ("." in str1) {
                    int dot = str1.index_of(".");
                    str1 = str1.slice(0, dot + 2);
                }

                string str2 = progress.to_string();
                if ("." in str2) {
                    int dot = str2.index_of(".");
                    str2 = str2.slice(0, dot + 2);
                }

                circle.set_total_size(download.get_total_size());
                circle.set_progress(p);

                label.set_label(@"$str2$progress_unity of $str1$total_size_unity");
            });

            download.cancelled.connect(() => {
                label.set_label("Cancelled");
                circle.set_progress(0);
            });

            download.finished.connect(() => {
                label.set_label("Finished");
                circle.set_progress(0);
            });

            this.show_all();
        }
    }
}
