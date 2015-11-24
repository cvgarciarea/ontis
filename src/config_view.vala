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

    public class ColorButton: Gtk.ToggleButton {

        public signal void color_changed(double[] color);

        public double[] color = { 0, 0, 0, 0 };
        public int area_width = 50;
        public int area_height = 20;

        public Gtk.DrawingArea area;
        public Gtk.Popover popover;
        public Gtk.ColorChooserWidget chooser;

        public class ColorButton(string name) {
            this.set_border_width(2);
            this.set_tooltip_text(name);

            this.area = new Gtk.DrawingArea();
            this.area.set_size_request(area_width, area_height);
            this.area.draw.connect(this.draw_cb);
            this.add(this.area);
            this.area.show();

            this.popover = new Gtk.Popover(this);
            this.popover.set_border_width(8);
            this.popover.hide.connect(() => {
                this.set_active(false);
            });

            Gtk.Box popover_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            this.popover.add(popover_box);

            this.chooser = new Gtk.ColorChooserWidget();
            this.chooser.color_activated.connect(this.color_activated_cb);
            popover_box.pack_start(this.chooser, false, false, 8);

            Gtk.Box box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            popover_box.pack_end(box, false, false, 0);

            Gtk.Button button = new Gtk.Button.with_label("Select");
            button.clicked.connect(() => { this.emit_changed(); });
            box.pack_end(button, false, false, 0);

            button = new Gtk.Button.with_label("Cancel");
            button.clicked.connect(() => { this.popover.hide(); });
            box.pack_end(button, false, false, 0);

            this.toggled.connect(this.toggled_cb);
        }

        private bool draw_cb(Gtk.Widget area, Cairo.Context context) {
            context.set_source_rgb(this.color[0], this.color[1], this.color[2]);
            context.rectangle(0, 0, this.area_width, this.area_height);
            context.fill();
            return false;
        }

        private void color_activated_cb(Gtk.ColorChooser chooser, Gdk.RGBA color) {
            this.emit_changed();
        }

        private void emit_changed() {
            Gdk.RGBA rgba = this.chooser.get_rgba();
            this.color = { rgba.red, rgba.green, rgba.blue, rgba.alpha };
            GLib.Idle.add(() => { this.area.queue_draw(); return false; });
            this.color_changed(this.color);
        }

        private void toggled_cb(Gtk.ToggleButton self) {
            if (this.get_active()) {
                this.popover.show_all();
            } else {
                this.popover.hide();
            }
        }

        public void set_color(double[] color) {
            this.color = color;
            Gdk.RGBA rgba = Gdk.RGBA();
            rgba.red = color[0];
            rgba.green = color[1];
            rgba.blue = color[2];
            this.chooser.set_rgba(rgba);
        }
    }

    public class ConfigView: Ontis.BaseView {

        public Gtk.Box scrolled_box;
        public Gtk.Box current_box;
        public Ontis.Notebook notebook;

        public ConfigView(Ontis.Notebook notebook) {
            this.notebook = notebook;

            this.scroll.set_border_width(30);

            this.scrolled_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            this.scroll.add_with_viewport(this.scrolled_box);

            this.new_section("Start", Gtk.Orientation.VERTICAL);
		    Gtk.RadioButton first_button = new Gtk.RadioButton.with_label_from_widget (null, "Start on 'New tab'");
            this.current_box.pack_start(first_button, false, false, 2);

            Gtk.RadioButton rbutton = new Gtk.RadioButton.with_label_from_widget(first_button, "Restore the last session");
            this.current_box.pack_start(rbutton, false, false, 2);

            Gtk.Box hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            this.current_box.pack_start(hbox, false, false, 2);

            rbutton = new Gtk.RadioButton.with_label_from_widget(first_button, "Start on:");
            hbox.pack_start(rbutton, false, false, 0);

            Gtk.Entry entry = new Gtk.Entry();
            entry.set_size_request(200, 0);
            entry.set_sensitive(false);
            hbox.pack_start(entry, false, false, 10);

            this.new_section("Style", Gtk.Orientation.HORIZONTAL);

            Ontis.ColorButton button = new Ontis.ColorButton("Background color");
            button.set_color(this.notebook.bg_color);
            button.color_changed.connect(this.bg_color_changed);
            this.current_box.pack_start(button, false, false, 2);

            button = new Ontis.ColorButton("Tab background color");
            button.set_color(this.notebook.tab_bg_color);
            button.color_changed.connect(this.tab_bg_color_changed);
            this.current_box.pack_start(button, false, false, 2);

            button = new Ontis.ColorButton("Tab selected background color");
            button.set_color(this.notebook.tab_selected_bg_color);
            button.color_changed.connect(this.tab_selected_bg_color_changed);
            this.current_box.pack_start(button, false, false, 2);

            button = new Ontis.ColorButton("The color when the mouse is above it");
            button.set_color(this.notebook.tab_mouse_in_bg_color);
            button.color_changed.connect(this.tab_mouse_in_bg_color_changed);
            this.current_box.pack_start(button, false, false, 2);

            button = new Ontis.ColorButton("Tab label color");
            button.set_color(this.notebook.tab_label_color);
            button.color_changed.connect(this.tab_label_color_changed);
            this.current_box.pack_start(button, false, false, 2);

            button = new Ontis.ColorButton("Tab label color when the tab is selected");
            button.set_color(this.notebook.tab_selected_label_color);
            button.color_changed.connect(this.tab_selected_label_color_changed);
            this.current_box.pack_start(button, false, false, 2);

            this.new_box(Gtk.Orientation.HORIZONTAL);

            button = new Ontis.ColorButton("Tab close button color");
            button.set_color(this.notebook.tab_bg_close_button);
            button.color_changed.connect(this.tab_bg_close_button_changed);
            this.current_box.pack_start(button, false, false, 2);

            button = new Ontis.ColorButton("Tab close button when the mouse is above it");
            button.set_color(this.notebook.tab_mouse_in_bg_close_button);
            button.color_changed.connect(this.tab_mouse_in_bg_close_button_changed);
            this.current_box.pack_start(button, false, false, 2);

            button = new Ontis.ColorButton("Window control buttons background color");
            button.set_color(this.notebook.button_bg_color);
            button.color_changed.connect(this.button_bg_color_changed);
            this.current_box.pack_start(button, false, false, 2);

            button = new Ontis.ColorButton("Window control buttons when the mouse is above it");
            button.set_color(this.notebook.button_mouse_in_bg_color);
            button.color_changed.connect(this.button_mouse_in_bg_color_changed);
            this.current_box.pack_start(button, false, false, 2);

            button = new Ontis.ColorButton("Window control buttons label color");
            button.set_color(this.notebook.button_label_color);
            button.color_changed.connect(this.button_label_color_changed);
            this.current_box.pack_start(button, false, false, 2);

            //this.new_section("Search");

            this.show_all();
        }

        private void new_section(string name, Gtk.Orientation? orientation=null) {
            Gtk.Box hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            this.scrolled_box.pack_start(hbox, false, false, 2);

            Gtk.Label label = new Gtk.Label(null);
            label.set_markup(@"<b>$name</b>");
            label.set_justify(Gtk.Justification.LEFT);
            hbox.pack_start(label, false, false, 0);

            this.new_box(orientation);
        }

        private void new_box(Gtk.Orientation? orientation=null) {
            this.current_box = new Gtk.Box(orientation != null? orientation: Gtk.Orientation.VERTICAL, 0);
            this.scrolled_box.pack_start(this.current_box, false, false, 2);
        }

        private void bg_color_changed(Ontis.ColorButton button, double[] color) {
            this.notebook.bg_color = color;
        }

        private void tab_bg_color_changed(Ontis.ColorButton button, double[] color) {
            this.notebook.tab_bg_color = color;
        }

        private void tab_selected_bg_color_changed(Ontis.ColorButton button, double[] color) {
            this.notebook.tab_selected_bg_color = color;
        }

        private void tab_mouse_in_bg_color_changed(Ontis.ColorButton button, double[] color) {
            this.notebook.tab_mouse_in_bg_color = color;
        }

        private void tab_label_color_changed(Ontis.ColorButton button, double[] color) {
            this.notebook.tab_label_color = color;
        }

        private void tab_selected_label_color_changed(Ontis.ColorButton button, double[] color) {
            this.notebook.tab_selected_label_color = color;
        }

        private void tab_bg_close_button_changed(Ontis.ColorButton button, double[] color) {
            this.notebook.tab_bg_close_button = color;
        }

        private void tab_mouse_in_bg_close_button_changed(Ontis.ColorButton button, double[] color) {
            this.notebook.tab_mouse_in_bg_close_button = color;
        }

        private void button_bg_color_changed(Ontis.ColorButton button, double[] color) {
            this.notebook.button_bg_color = color;
        }

        private void button_mouse_in_bg_color_changed(Ontis.ColorButton button, double[] color) {
            this.notebook.button_mouse_in_bg_color = color;
        }

        private void button_label_color_changed(Ontis.ColorButton button, double[] color) {
            this.notebook.button_label_color = color;
        }
    }
}
