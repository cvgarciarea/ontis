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
            this.pack_start(this.label, false, true, 0);

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
}
