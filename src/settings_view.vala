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

    public class ListBox: Gtk.Box {

        public Gtk.Box scrolled_box;
        public Gtk.ListBox listbox;

        public ListBox() {
            this.set_orientation(Gtk.Orientation.HORIZONTAL);

            Gtk.ScrolledWindow scroll = new Gtk.ScrolledWindow(null, null);
            scroll.set_size_request(400, 1);
            this.pack_start(scroll, true, true, 0);

            Gtk.Box hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            scroll.add(hbox);

            this.scrolled_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            this.scrolled_box.set_size_request(400, 1);
            hbox.set_center_widget(this.scrolled_box);
        }

        public void new_section(string name) {
            Gtk.Box space = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            space.set_size_request(1, 20);
            this.scrolled_box.pack_start(space, false, false, 0);

            Gtk.Box box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            this.scrolled_box.pack_start(box, false, false, 5);

            Gtk.Label label = new Gtk.Label(null);
            label.set_markup(@"<b>$name</b>");
            box.pack_start(label, false, false, 2);

            this.listbox = new Gtk.ListBox();
            this.listbox.set_selection_mode(Gtk.SelectionMode.NONE);
            this.scrolled_box.pack_start(this.listbox, false, false, 0);
        }

        public Gtk.Box new_row(string name, string? help=null) {
            Gtk.ListBoxRow row = new Gtk.ListBoxRow();
            row.set_size_request(1, 50);
            this.listbox.add(row);

            Gtk.Box box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            box.set_border_width(5);
            row.add(box);

            Gtk.Box vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            box.pack_start(vbox, false, true, 0);

            Gtk.Box hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            vbox.pack_start(hbox, true, true, 0);

            hbox.pack_start(new Gtk.Label(name), false, false, 0);

            if (help != null) {
                hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
                vbox.pack_start(hbox, false, true, 0);

                Gtk.Label label = new Gtk.Label(null);
                label.set_sensitive(false);
                label.set_markup(@"<small>$help</small>");
                hbox.pack_start(label, false, false, 0);
            }

            return box;
        }
    }

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
            this.popover.hide.connect(this.hide_cb);

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

        private void hide_cb(Gtk.Widget popover) {
            this.set_active(false);
            this.chooser.show_editor = false;
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

    public class SettingsView: Ontis.BaseView {

        public Ontis.SettingsManager settings_manager;
        public Ontis.ListBox listbox;

        public SettingsView(Ontis.SettingsManager settings_manager) {
            this.settings_manager = settings_manager;

            this.remove(this.scroll);

            this.listbox = new Ontis.ListBox();
            this.pack_start(this.listbox, true, true, 0);

            this.listbox.new_section("Startup");

            Gtk.Box box = this.listbox.new_row("When Ontis start:");
            //box.pack_end(new Gtk.Button.with_label("Start on:"), false, false, 0);
            //box.pack_end(new Gtk.Button.with_label("Restore last session"), false, false, 0);
            //box.pack_end(new Gtk.Button.with_label("Start with a 'NetTab'"), false, false, 0);

            box = this.listbox.new_row("");
            Gtk.Entry entry = new Gtk.Entry();
            entry.set_sensitive(false);
            box.pack_start(entry, true, true, 0);

            this.listbox.new_section("Style");

            box = this.listbox.new_row("Theme");
            Gtk.Box vbox = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            box.pack_end(vbox, false, false, 0);

            Gtk.Box hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            vbox.pack_start(hbox, false, false, 0);

            /*
            Ontis.ColorButton button = new Ontis.ColorButton("Background color");
            button.set_color(this.notebook.bg_color);
            button.color_changed.connect(this.bg_color_changed);
            //hbox.pack_end(button, false, false, 2);

            button = new Ontis.ColorButton("Tab background color");
            button.set_color(this.notebook.tab_bg_color);
            button.color_changed.connect(this.tab_bg_color_changed);
            //hbox.pack_end(button, false, false, 2);

            button = new Ontis.ColorButton("Tab selected background color");
            button.set_color(this.notebook.tab_selected_bg_color);
            button.color_changed.connect(this.tab_selected_bg_color_changed);
            //hbox.pack_end(button, false, false, 2);

            button = new Ontis.ColorButton("The color when the mouse is above it");
            button.set_color(this.notebook.tab_mouse_in_bg_color);
            button.color_changed.connect(this.tab_mouse_in_bg_color_changed);
            //hbox.pack_end(button, false, false, 2);

            button = new Ontis.ColorButton("Tab label color");
            button.set_color(this.notebook.tab_label_color);
            button.color_changed.connect(this.tab_label_color_changed);
            //hbox.pack_end(button, false, false, 2);

            button = new Ontis.ColorButton("Tab label color when the tab is selected");
            button.set_color(this.notebook.tab_selected_label_color);
            button.color_changed.connect(this.tab_selected_label_color_changed);
            //hbox.pack_end(button, false, false, 2);

            hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
            vbox.pack_start(hbox, false, false, 0);

            button = new Ontis.ColorButton("Tab close button color");
            button.set_color(this.notebook.tab_bg_close_button);
            button.color_changed.connect(this.tab_bg_close_button_changed);
            //hbox.pack_end(button, false, false, 2);

            button = new Ontis.ColorButton("Tab close button when the mouse is above it");
            button.set_color(this.notebook.tab_mouse_in_bg_close_button);
            button.color_changed.connect(this.tab_mouse_in_bg_close_button_changed);
            //hbox.pack_end(button, false, false, 2);

            button = new Ontis.ColorButton("Window control buttons background color");
            button.set_color(this.notebook.button_bg_color);
            button.color_changed.connect(this.button_bg_color_changed);
            //hbox.pack_end(button, false, false, 2);

            button = new Ontis.ColorButton("Window control buttons when the mouse is above it");
            button.set_color(this.notebook.button_mouse_in_bg_color);
            button.color_changed.connect(this.button_mouse_in_bg_color_changed);
            //hbox.pack_end(button, false, false, 2);

            button = new Ontis.ColorButton("Window control buttons label color");
            button.set_color(this.notebook.button_label_color);
            button.color_changed.connect(this.button_label_color_changed);
            //hbox.pack_end(button, false, false, 2);
            */
            this.listbox.new_section("Downloads");

            box = this.listbox.new_row("Save files to:");

            Gtk.FileChooserButton chooser_button = new Gtk.FileChooserButton("Select a folder for save your downloads", Gtk.FileChooserAction.SELECT_FOLDER);
            chooser_button.set_focus_on_click(false);
            //chooser_button.file_set.connect(this.downloads_dir_changed);
            box.pack_end(chooser_button, false, false, 0);

            this.listbox.new_section("Search");

            box = this.listbox.new_row("Google", "google.com");
            box = this.listbox.new_row("DuckDuckGo", "duckduckgo.com");
            box = this.listbox.new_row("Yahoo", "yahoo.com");
            box = this.listbox.new_row("Bing", "bing.com");

            this.listbox.new_section("Content");

            box = this.listbox.new_row("Block pop-up windows");
            box.pack_end(new Gtk.Button.with_label("Exeptions..."), false, false, 0);

            box = this.listbox.new_row("Default font:");
            Gtk.FontButton font_button = new Gtk.FontButton();
            font_button.set_font(this.settings_manager.font);
            font_button.font_set.connect(() => { this.settings_manager.font = font_button.get_font_name(); });
            box.pack_end(font_button, false, false, 0);

            box = this.listbox.new_row("Default font color:");
            Ontis.ColorButton button = new Ontis.ColorButton("Font color");
            box.pack_end(button, false, false, 0);

            this.show_all();
        }

        /*
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
        */
    }
}
