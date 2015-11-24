/*
Compile with:
    valac --pkg gtk+-3.0 notebook.vala

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

    public class Tab: GLib.Object {

        public signal void redraw();

        public int x = 0;
        public int y = 0;
        public int width = 0;
        public int height = 0;

        public bool selected = false;
        public bool mouse_in = false;

        public Tab() {
        }

    }

    public class NotebookTab: Tab {

        public string label = "";
        public int position = 0;
        public Gdk.Pixbuf? pixbuf = null;

        public int close_x = 0;
        public int close_y = 0;
        public int close_width = 0;
        public int close_height = 0;

        public bool mouse_in_close_button = false;

        public NotebookTab(string label, int position) {
            this.label = label;
            this.position = position;
            this.pixbuf = Utils.get_image_from_name("gtk-missing-image", 24).get_pixbuf();
        }

        public void set_title(string label) {
            this.label = label;
        }

        public string get_title() {
            return this.label;
        }

        public void set_pixbuf(Gdk.Pixbuf pixbuf) {
            this.pixbuf = pixbuf;
        }

        public Gdk.Pixbuf get_pixbuf() {
            return this.pixbuf;
        }
    }

    public class NotebookAdd: Tab {

        public NotebookAdd() {
            this.width = 30;
        }
    }

    public class NotebookButton: GLib.Object {

        public int x = 0;
        public int y = 0;
        public int width = 0;
        public int height = 0;
        public string label = "";

        public bool mouse_in = false;

        public NotebookButton(string label) {
            this.label = label;
        }
    }

    public class Notebook: Gtk.Box {

        public signal void new_tab();       // When user click on "new tab"
        public signal void page_added();    // When a new tab is added
        public signal void page_removed();  // When a tab is removed
        public signal void page_switched(); // When the current tab is changed
        public signal void minimize();
        public signal void turn_maxmizie();
        public signal void close();

        public double[] bg_color = { 0, 0, 0 };//{ 0.9215686274509803, 0.9372549019607843, 0.9490196078431372 };

        public double[] tab_bg_color = { 0.3764705882352941, 0.49019607843137253, 0.5450980392156862 };
        public double[] tab_selected_bg_color = { 0.9215686274509803, 0.9372549019607843, 0.9490196078431372 };
        public double[] tab_mouse_in_bg_color = { 0.5568627450980392, 0.6352941176470588, 0.6784313725490196 };

        public double[] tab_label_color = { 0.9215686274509803, 0.9372549019607843, 0.9490196078431372 };
        public double[] tab_selected_label_color = { 0.0, 0.0, 0.0 };

        public double[] tab_bg_close_button = { 0.5568627450980392, 0.6352941176470588, 0.6784313725490196 };
        public double[] tab_mouse_in_bg_close_button = { 0.9176470588235294, 0.592156862745098, 0.5568627450980392 };

        public double[] button_bg_color = { 0.3764705882352941, 0.49019607843137253, 0.5450980392156862 };
        public double[] button_mouse_in_bg_color = { 0.5568627450980392, 0.6352941176470588, 0.6784313725490196 };
        public double[] button_label_color = { 1, 1, 1 };

        private int mouse_x = 0;
        private int mouse_y = 0;

        public int tab_label_size = 15;
        public string tab_label_font = "DejaVu Sans";
        public int default_tab_width = 200;
        public int buttons_space = 70;
        public bool show_buttons = false;
        public int top_space = 15;

        private bool mouse_pressed = false;

        public Gtk.DrawingArea switcher;
        public Gtk.Box box;

        public Gtk.Widget? current_child = null;
        public int n_pages = 0;
        public int? current_page = null;

        public GLib.List<Gtk.Widget> childs;
        public GLib.List<NotebookTab> tabs;

        public NotebookAdd tab_add;

        public NotebookButton button_minimize;
        public NotebookButton button_maximize;
        public NotebookButton button_close;

        public Notebook() {
            this.set_orientation(Gtk.Orientation.VERTICAL);

            this.childs = new GLib.List<Gtk.Widget>();
            this.tabs = new GLib.List<NotebookTab>();

            this.tab_add = new NotebookAdd();

            this.button_minimize = new NotebookButton("_");
            this.button_maximize = new NotebookButton("-");
            this.button_close = new NotebookButton("x");

            this.switcher = new Gtk.DrawingArea();
            this.switcher.set_size_request(1, 45);
            this.switcher.draw.connect(this.redraw_switcher);
            this.pack_start(this.switcher, false, false, 0);

            this.switcher.add_events(Gdk.EventMask.POINTER_MOTION_MASK |
                                     Gdk.EventMask.BUTTON_PRESS_MASK |
                                     Gdk.EventMask.BUTTON_RELEASE_MASK);

            this.switcher.motion_notify_event.connect(this.motion_notify_cb);
            this.switcher.button_press_event.connect(this.button_press_cb);
            this.switcher.button_release_event.connect(this.button_release_cb);

            this.box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            this.pack_start(this.box, true, true, 0);
            this.show_all();
        }

        private bool motion_notify_cb(Gtk.Widget switcher, Gdk.EventMotion event) {
            int x = (int)event.x;
            int y = (int)event.y - this.top_space;
            this.mouse_x = x;
            this.mouse_y = y;
            this.update_switcher();

            return false;
        }

        private bool button_press_cb(Gtk.Widget switcher, Gdk.EventButton event) {
            // For drag and drop
            if (event.button != 1) {
                this.mouse_pressed = true;
                return false;
            }

            return false;
        }

        private bool button_release_cb(Gtk.Widget switcher, Gdk.EventButton event) {
            if (event.button != 1) {  // FIXME: Check button == 3, for popup menu
                this.mouse_pressed = false;
                return false;
            }

            int current = 0;

            foreach (NotebookTab tab in this.tabs) {
                if (tab.mouse_in && !tab.mouse_in_close_button) {
                    this.set_current_page(current);
                    return true;
                } else if (tab.mouse_in && tab.mouse_in_close_button) {
                    this.remove_page(current);
                    return true;
                }

                current ++;
            }

            if (this.tab_add.mouse_in) {
                this.new_tab();
                return true;
            }

            if (this.button_minimize.mouse_in) {
                this.minimize();
                return true;
            }

            if (this.button_maximize.mouse_in) {
                this.turn_maxmizie();
                return true;
            }

            if (this.button_close.mouse_in) {
                this.close();
                return true;
            }

            return false;
        }

        public void set_current_page(int page) {
            //if (page > this.childs.length) {
            //    print("Error: Index < childs.length: FAILED\n");
            //}

            //if (page == this.current_page) {
            //    return;
            //}

            if (this.current_child != null && this.current_child.get_parent() == this.box) {
                this.box.remove(this.current_child);
            }

            this.current_page = page;
            int current1 = 0;

            foreach (Gtk.Widget widget in this.childs) {
                if (current1 == page) {
                    this.current_child = widget;
                    this.box.pack_start(this.current_child, true, true, 0);
                    break;
                }
                current1 ++;
            }

            int current2 = 0;
            foreach (NotebookTab tab in this.tabs) {
                tab.selected = (current2 == current1);
                current2 ++;
            }

            this.box.show();
            this.current_child.show();

            this.page_switched();
        }

        public NotebookTab append_page(string tab_label, Gtk.Widget child) {
            this.childs.append(child);
            this.n_pages ++;

            NotebookTab tab = new NotebookTab(tab_label, this.n_pages);
            //tab.redraw.connect(this.redraw_from_tab);
            this.tabs.append(tab);

            if (this.n_pages == 1) {
                this.set_current_page(0);
            }

            this.page_added();
            return tab;
        }

        public void remove_page(int index) {
            if (this.n_pages == 0) {
                return;
            }

            int current1 = 0;
            int current2 = 0;
            int current3 = 1;

            foreach (NotebookTab tab in this.tabs) {
                if (current1 == index) {
                    this.tabs.remove(tab);
                    break;
                }

                current1 ++;
            }

            foreach (Gtk.Widget widget in this.childs) {
                if (current2 == index) {
                    this.childs.remove(widget);
                    break;
                }

                current2 ++;
            }

            this.n_pages -= 1;

            foreach (NotebookTab tab in this.tabs) {
                tab.position = current3;
                current3 ++;
            }

            if (index == this.current_page) {
                if (this.n_pages >= index) {
                    this.set_current_page(this.current_page);
                } else if (this.n_pages < index && this.n_pages >= 1) {
                    this.set_current_page(index - 1);
                }
            }

            if (this.current_page >= this.current_page) {
                this.set_current_page(this.current_page - 1);
            }

            if (this.current_page == -1) {
                this.set_current_page(0);
            }

            this.page_removed();
        }

        public void set_tab_label(int index, string label) {
            NotebookTab tab = this.get_tab(index);
            tab.label = label;
        }

        public string get_tab_label(int index) {
            NotebookTab tab = this.get_tab(index);
            return tab.label;
        }

        public void set_show_buttons(bool show) {
            this.show_buttons = show;
            this.buttons_space = (show)? 120: 50;
            this.update_switcher();
        }

        public bool get_show_buttons() {
            return this.show_buttons;
        }

        public NotebookTab? get_tab(int index) {
            if (this.n_pages > 0) {
                int current = 0;
                foreach (NotebookTab tab in this.tabs) {
                    if (current == index) {
                        return tab;
                    }

                    current ++;
                }
            }

            return null;
        }

        private void update_switcher() {
            GLib.Idle.add(() => { this.switcher.queue_draw(); return true; });
        }

        private bool redraw_switcher(Gtk.Widget switcher, Cairo.Context context) {
            Gtk.Allocation alloc;
            this.switcher.get_allocation(out alloc);

            int width = alloc.width - this.buttons_space;  // 50 for "add tab" and window buttons
            int height = alloc.height - top_space;

            // Check the mouse position
            int x = this.mouse_x;
            int y = this.mouse_y;

            foreach (NotebookTab tab in this.tabs) {
                tab.mouse_in = x >= tab.x && x <= tab.x + tab.width && y >= tab.y && y <= tab.y + tab.height;
                tab.mouse_in_close_button = x >= tab.close_x && x <= tab.close_x + tab.close_width && y >= tab.close_y && y <= tab.close_y + tab.close_height;
            }

            this.tab_add.mouse_in = x >= this.tab_add.x && x <= this.tab_add.x + this.tab_add.width + 6 && y >= this.tab_add.y && y <= this.tab_add.y + this.tab_add.height;


            if (this.show_buttons) {
                y += this.top_space;
                this.button_minimize.mouse_in = x >= this.button_minimize.x && x <= this.button_minimize.x + this.button_minimize.width && y >= this.button_minimize.y && y <= this.button_minimize.y + this.button_minimize.height;
                this.button_maximize.mouse_in = x >= this.button_maximize.x && x <= this.button_maximize.x + this.button_maximize.width && y >= this.button_maximize.y && y <= this.button_maximize.y + this.button_maximize.height;
                this.button_close.mouse_in = x >= this.button_close.x && x <= this.button_close.x + this.button_close.width && y >= this.button_close.y && y <= this.button_close.y + this.button_close.height;
            }

            // Draw background
            context.set_source_rgb(this.bg_color[0], this.bg_color[1], this.bg_color[2]);
            context.rectangle(0, 0, width + this.buttons_space, height + this.top_space);
            context.fill();

            // Draw tabs
            int max_width = this.default_tab_width;
            if (this.n_pages > 0) {
                if (width / this.n_pages < max_width) {
                    max_width = width / this.n_pages;
                }
            }

            context.translate(0, this.top_space);

            int current = 0;

            foreach (NotebookTab tab in this.tabs) {
                current = tab.position - 1;
                double br, bg, bb;
                double tr, tg, tb;

                if (tab.selected) {
                    br = this.tab_selected_bg_color[0];
                    bg = this.tab_selected_bg_color[1];
                    bb = this.tab_selected_bg_color[2];
                    tr = this.tab_selected_label_color[0];
                    tg = this.tab_selected_label_color[1];
                    tb = this.tab_selected_label_color[2];
                } else if (tab.mouse_in) {
                    br = this.tab_mouse_in_bg_color[0];
                    bg = this.tab_mouse_in_bg_color[1];
                    bb = this.tab_mouse_in_bg_color[2];
                    tr = this.tab_label_color[0];
                    tg = this.tab_label_color[1];
                    tb = this.tab_label_color[2];
                } else {
                    br = this.tab_bg_color[0];
                    bg = this.tab_bg_color[1];
                    bb = this.tab_bg_color[2];
                    tr = this.tab_label_color[0];
                    tg = this.tab_label_color[1];
                    tb = this.tab_label_color[2];
                }

                tab.x = max_width * current;
                tab.y = 2;
                tab.width = max_width;
                tab.height = height - 4;
                tab.close_x = tab.x + tab.width - 25;
                tab.close_y = tab.y + 5;
                tab.close_width = 10;
                tab.close_height = 15;

                // First rectangle
                context.set_source_rgb(br, bg, bb);
                context.rectangle(max_width * current + 10, 2, max_width - 20, height - 2);
                context.fill();

                // Draw triangles
                context.set_line_width(2);

                context.new_path();
                context.move_to(max_width * current, height);
                context.line_to(max_width * current + 10, 2);
                context.line_to(max_width * current + 10, height);
                context.close_path();
                context.fill();

                context.new_path();
                context.move_to(max_width * (current + 1), height);
                context.line_to(max_width * (current + 1) - 10, 2);
                context.line_to(max_width * (current + 1) - 10, height);
                context.close_path();
                context.fill();

                // Paint the favicon
                Gdk.Pixbuf pixbuf = tab.pixbuf;
                int px = max_width * current + 10;
                int py = tab.y + tab.height / 2 - pixbuf.height / 2;
                Gdk.cairo_set_source_pixbuf(context, pixbuf, px, py);
                context.paint();

                // Render the label
                int max_label_width = tab.width - pixbuf.width - 20 - 10 - 5; // 20 for the triangles, 10 for the close button and 5 for space
            	Cairo.TextExtents extents;
	            context.text_extents(tab.label, out extents);

                context.move_to(tab.width * current + pixbuf.width + 15, tab.y + tab.height / 2 + extents.height / 2);
                context.set_font_size(this.tab_label_size);
                context.select_font_face(this.tab_label_font, Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);
                context.set_source_rgb(tr, tg, tb);

                if (extents.width <= max_label_width) {
                    context.show_text(tab.label);
                } else {
                    string a = "";
                    for (int i=1; i <= tab.label.length; i++) {
                        string b = tab.label.slice(0, i) + "...";
                        Cairo.TextExtents e;
                        context.text_extents(b, out e);
                        if (e.width > max_label_width) {
                            context.show_text(a);
                            break;
                        }
                        a = b;
                    }
                }

                // Render the close button
                if (tab.mouse_in_close_button) {
                    context.set_source_rgb(this.tab_mouse_in_bg_close_button[0], this.tab_mouse_in_bg_close_button[1], this.tab_mouse_in_bg_close_button[2]);
                } else {
                    context.set_source_rgb(this.tab_bg_close_button[0], this.tab_bg_close_button[1], this.tab_bg_close_button[2]);
                }

                context.arc(max_width * (current + 1) - 20, height / 2, 8, 0, 2 * Math.PI);
                context.fill();
            }

            // Draw new tab button
            this.tab_add.x = max_width * this.n_pages + 5;
            this.tab_add.y = height / 2 - this.tab_add.height / 2;
            this.tab_add.height = height - 14;
            this.tab_add.width = this.tab_add.height + 5;

            if (this.tab_add.mouse_in) {
                context.set_source_rgb(this.tab_mouse_in_bg_color[0], this.tab_mouse_in_bg_color[1], this.tab_mouse_in_bg_color[1]);
            } else {
                context.set_source_rgb(this.tab_bg_color[0], this.tab_bg_color[1], this.tab_bg_color[2]);
            }

            context.new_path();
            context.move_to(this.tab_add.x, this.tab_add.y);
            context.line_to(this.tab_add.x + this.tab_add.width, this.tab_add.y);
            context.line_to(this.tab_add.x + this.tab_add.width + 6, this.tab_add.y + this.tab_add.height);
            context.line_to(this.tab_add.x + 6, this.tab_add.y + this.tab_add.height);
            context.close_path();
            context.fill();

            context.restore();

            // Draw minimize, maximize/unmaximize, close buttons
            if (this.show_buttons) {
                int button_height = 20;
                int button_width = (this.buttons_space - this.tab_add.width - 10) / 3;

                context.set_font_size(15);
            	Cairo.TextExtents extents;

                this.button_minimize.x = width + this.tab_add.width + 10;
                this.button_minimize.y = 2;
                this.button_minimize.width = button_width;
                this.button_minimize.height = button_height;
                this.button_maximize.x = this.button_minimize.x + button_width + 1;
                this.button_maximize.y = 2;
                this.button_maximize.width = button_width;
                this.button_maximize.height = button_height;
                this.button_close.x = this.button_maximize.x + button_width + 1;
                this.button_close.y = 2;
                this.button_close.width = button_width;
                this.button_close.height = button_height;

                if (this.button_minimize.mouse_in) {
                    context.set_source_rgb(this.button_mouse_in_bg_color[0], this.button_mouse_in_bg_color[1], this.button_mouse_in_bg_color[2]);
                } else {
                    context.set_source_rgb(this.button_bg_color[0], this.button_bg_color[1], this.button_bg_color[2]);
                }

                context.rectangle(this.button_minimize.x, this.button_minimize.y, button_width - 1, button_height);
                context.fill();

	            context.text_extents(this.button_minimize.label, out extents);
                context.set_source_rgb(this.button_label_color[0], this.button_label_color[1], this.button_label_color[2]);
                context.move_to(this.button_minimize.x + button_width / 2 - extents.width / 2, this.button_minimize.y + button_height / 2 + extents.height / 2);
                context.show_text(this.button_minimize.label);

                if (this.button_maximize.mouse_in) {
                    context.set_source_rgb(this.button_mouse_in_bg_color[0], this.button_mouse_in_bg_color[1], this.button_mouse_in_bg_color[2]);
                } else {
                    context.set_source_rgb(this.button_bg_color[0], this.button_bg_color[1], this.button_bg_color[2]);
                }

                context.rectangle(this.button_maximize.x, this.button_maximize.y, button_width - 1, button_height);
                context.fill();

	            context.text_extents(this.button_maximize.label, out extents);
                context.set_source_rgb(this.button_label_color[0], this.button_label_color[1], this.button_label_color[2]);
                context.move_to(this.button_maximize.x + button_width / 2 - extents.width / 2, this.button_maximize.y + button_height / 2 + extents.height / 2);
                context.show_text(this.button_maximize.label);

                if (this.button_close.mouse_in) {
                    context.set_source_rgb(this.button_mouse_in_bg_color[0], this.button_mouse_in_bg_color[1], this.button_mouse_in_bg_color[2]);
                } else {
                    context.set_source_rgb(this.button_bg_color[0], this.button_bg_color[1], this.button_bg_color[2]);
                }

                context.rectangle(this.button_close.x, this.button_close.y, button_width - 1, button_height);
                context.fill();

	            context.text_extents(this.button_close.label, out extents);
                context.set_source_rgb(this.button_label_color[0], this.button_label_color[1], this.button_label_color[2]);
                context.move_to(this.button_close.x + button_width / 2 - extents.width / 2, this.button_close.y + button_height / 2 + extents.height / 2);
                context.show_text(this.button_close.label);
            }
            return false;
        }
    }
}
