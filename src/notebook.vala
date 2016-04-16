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

    public struct WidgetGeometry {
        public double x;
        public double y;
        public double width;
        public double height;
    }

    public class BaseWidget: GLib.Object {

        public signal void redraw();
        public signal void state_changed(Ontis.TabState state);

        public Ontis.WidgetGeometry geom;
        public string label = "";
        public Gdk.Pixbuf? pixbuf = null;
        public ulong? connect_id = null;

        public Ontis.TabState state = Ontis.TabState.NORMAL;

        public BaseWidget(double x = 0, double y = 0, double width = 1, double height = 1) {
            this.geom = Ontis.WidgetGeometry() {
                x = x,
                y = y,
                width = width,
                height = height
            };
        }

        public void set_position(int? x = null, int? y = null) {
            if (x != null) {
                this.geom.x = x;
            }

            if (y != null) {
                this.geom.y = y;
            }

            this.redraw();
        }

        public void set_size(int? width = null, int? height = null) {
            if (width != null) {
                this.geom.width = width;
            }

            if (height != null) {
                this.geom.height = height;
            }

            this.redraw();
        }

        public void set_geom(int? x = null, int? y = null, int? width = null, int? height = null) {
            if (x != null) {
                this.geom.x = x;
            }

            if (y != null) {
                this.geom.y = y;
            }

            if (width != null) {
                this.geom.width = width;
            }

            if (height != null) {
                this.geom.height = height;
            }

            this.redraw();
        }

        public void set_state(Ontis.TabState state) {
            this.state = state;
            this.redraw();
            this.state_changed(state);
        }

        public Ontis.TabState get_state() {
            return this.state;
        }

        public void set_selected(bool selected) {
            if (selected && this.get_state() != Ontis.TabState.SELECTED) {
                this.set_state(Ontis.TabState.SELECTED);
            } else if (!selected && this.get_state() == Ontis.TabState.SELECTED) {
                this.set_state(Ontis.TabState.NORMAL);
            }
        }

        public void set_mouse_over(bool mouse_over) {
            Ontis.TabState state = this.get_state();
            if (mouse_over && state != Ontis.TabState.MOUSE_OVER && state != Ontis.TabState.SELECTED) {
                this.set_state(Ontis.TabState.MOUSE_OVER);
            } else if (!mouse_over && state == Ontis.TabState.MOUSE_OVER) {
                this.set_state(Ontis.TabState.NORMAL);
            }
        }

        public void set_connect_id(ulong id) {
            this.connect_id = id;
        }

        public void destroy() {
            this.disconnect(this.connect_id);
            this.connect_id = null;
        }
    }

    public class Tab: Ontis.BaseWidget {

        public int index = 0;
        public Gtk.Widget? widget = null;

        public Tab(string label, int index, Gtk.Widget widget) {
            this.label = label;
            this.index = index;
            this.widget = widget;
            this.pixbuf = Ontis.get_empty_tab_icon();
        }

        public void set_title(string label) {
            this.label = label;
            this.redraw();
        }

        public string get_title() {
            return this.label;
        }

        public void set_pixbuf(Gdk.Pixbuf? pixbuf = null) {
            this.pixbuf = (pixbuf != null)? pixbuf: Ontis.get_empty_tab_icon();
            this.redraw();
        }

        public Gdk.Pixbuf get_pixbuf() {
            return this.pixbuf;
        }
    }

    public class Button: Ontis.BaseWidget {

        public signal void clicked();

        public Button() {
            this.state_changed.connect(this.changed_cb);
        }

        private void changed_cb(Ontis.BaseWidget self, Ontis.TabState state) {
            if (state == Ontis.TabState.SELECTED) {
                this.set_state(Ontis.TabState.NORMAL);
                this.clicked();
            }
        }
    }

    public class CloseButton: Ontis.Button {

        public CloseButton() {
            this.label = "x"; // FIXME: Replace it with a pixbuf
            this.set_geom(-31, 2, 30, 25);
        }
    }

    public class MaximizeButton: Ontis.Button {

        public MaximizeButton() {
            this.label = "-"; // FIXME: Replace it with a pixbuf;
            this.set_geom(-62, 2, 30, 25);
        }
    }

    public class MinimizeButton: Ontis.Button {

        public MinimizeButton() {
            this.label = "_"; // FIXME: Replace it with a pixbuf;
            this.set_geom(-93, 2, 30, 25);
        }
    }

    public class NewTabButton: Ontis.Button {

        public NewTabButton() {
            this.set_geom(0, 0, 20, 15);
        }
    }

    public class TabBox: Gtk.DrawingArea {

        public signal void new_tab();       // When user click on "new tab"
        public signal void page_added();    // When a new tab is added
        public signal void page_removed();  // When a tab is removed
        public signal void page_switched(); // When the current tab is changed
        public signal void minimize();
        public signal void turn_maximize();
        public signal void close();

        private Ontis.Tab[] tabs;

        public Ontis.NewTabButton new_tab_button;
        public Ontis.CloseButton close_button;
        public Ontis.MaximizeButton maximize_button;
        public Ontis.MinimizeButton minimize_button;

        public TabBox() {
            this.tabs = { };

            this.new_tab_button = new Ontis.NewTabButton();
            this.new_tab_button.redraw.connect(() => { this.update(); });
            this.new_tab_button.clicked.connect(() => { this.new_tab(); });

            this.close_button = new Ontis.CloseButton();
            this.close_button.redraw.connect(() => { this.update(); });
            this.close_button.clicked.connect(() => { this.close(); });

            this.maximize_button = new Ontis.MaximizeButton();
            this.maximize_button.redraw.connect(() => { this.update(); });
            this.maximize_button.clicked.connect(() => { this.turn_maximize(); });

            this.minimize_button = new Ontis.MinimizeButton();
            this.minimize_button.redraw.connect(() => { this.update(); });
            this.minimize_button.clicked.connect(() => { this.minimize(); });

            this.set_size_request(1, 35);
            this.add_events(Gdk.EventMask.BUTTON_PRESS_MASK |
                            Gdk.EventMask.BUTTON_RELEASE_MASK |
                            Gdk.EventMask.POINTER_MOTION_MASK |
                            Gdk.EventMask.LEAVE_NOTIFY_MASK);

            this.draw.connect(this.draw_cb);
            this.motion_notify_event.connect(this.pointer_motion_cb);
            this.button_press_event.connect(this.button_press_cb);
            this.button_release_event.connect(this.button_release_cb);
            this.leave_notify_event.connect(this.leave_cb);
        }

        private bool draw_cb(Gtk.Widget self, Cairo.Context context) {
            this.draw_background(context);
            this.draw_widgets(context);
            return false;
        }

        private bool button_press_cb(Gtk.Widget self, Gdk.EventButton event) {
            Ontis.Tab? tab = this.get_tab_at_point(event.x, event.y);

            if (tab != null) {
                // Switch tabs when mouse button is pressed
                if (tab.get_state() == Ontis.TabState.MOUSE_OVER) {
                    foreach (Ontis.Tab ctab in this.tabs) {
                        ctab.set_selected(ctab == tab);
                    }
                }
            }

            return false;
        }

        private bool button_release_cb(Gtk.Widget self, Gdk.EventButton event) {
            // Check if is dragging
            Ontis.Tab? dragging_tab = null;

            foreach (Ontis.Tab tab in this.tabs) {
                if (tab.get_state() == Ontis.TabState.DRAGGING) {
                    dragging_tab = tab;
                    break;
                }
            }

            if (dragging_tab == null) {
                // Active widgets when the mouse button is  released
                this.new_tab_button.set_selected(this.new_tab_button.get_state() == Ontis.TabState.MOUSE_OVER);
                foreach (Ontis.Button button in this.get_buttons()) {
                    button.set_selected(button.get_state() == Ontis.TabState.MOUSE_OVER);
                }
            }

            return false;
        }

        private bool pointer_motion_cb(Gtk.Widget self, Gdk.EventMotion event) {
            Ontis.Tab? tab = this.get_tab_at_point(event.x, event.y);

            Gtk.Allocation alloc;
            this.get_allocation(out alloc);

            if (tab != null) {
                foreach (Ontis.Tab ctab in this.tabs) {
                    if (ctab.get_state() != Ontis.TabState.SELECTED) { // FIXME: and when is dragging?
                        ctab.set_mouse_over(ctab == tab);
                    }
                }
            } else {
                // Set all tabs to normal
                foreach (Ontis.Tab ctab in this.tabs) {
                    ctab.set_mouse_over(false);
                }

                // First check for "New Tab button"
                double x = (this.get_tab_width() * this.tabs.length) + this.new_tab_button.geom.x;
                double y = alloc.height / 2 - this.new_tab_button.geom.height / 4;
                double width = this.new_tab_button.geom.width + 10;
                double height = this.new_tab_button.geom.height;

                this.new_tab_button.set_mouse_over((event.x > x && event.x < x + width &&
                                                    event.y > y && event.y < y + height));

                // Now check for other widgets (no tabs and no button new tab)
                foreach (Ontis.Button button in this.get_buttons()) {
                    x = alloc.width + button.geom.x;
                    y = button.geom.y;
                    width = button.geom.width;
                    height = button.geom.height;

                    button.set_mouse_over((event.x > x && event.x < x - width &&
                                           event.y > y && event.y < y + height));
                }
            }

            return false;
        }

        private bool leave_cb(Gtk.Widget self, Gdk.EventCrossing event) {
            foreach (Ontis.Tab ctab in this.tabs) {
                ctab.set_mouse_over(false);
            }

            return false;
        }

        private void draw_background(Cairo.Context context) {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);

            double r, g, b;
            Ontis.get_rgb(Ontis.Colors.BG_COLOR, out r, out g, out b);

            context.set_source_rgba(r, g, b, 0.5);
            context.rectangle(0, 0, alloc.width, alloc.height);
            context.fill();
        }

        private void draw_widgets(Cairo.Context context) {
            this.draw_tabs(context);
            this.draw_buttons(context);
        }

        private void draw_tabs(Cairo.Context context) {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);

            int sheight = alloc.height;
            double tab_width = this.get_tab_width();

            foreach (Ontis.Tab tab in this.tabs) {
                // Render poligon
                double r, g, b;
                this.get_widget_color(tab, out r, out g, out b);
                context.set_source_rgb(r, g, b);

                int index = tab.index;
                double start_x = tab_width * (index - 1);

                tab.geom.x = start_x;
                tab.geom.y = 10;
                tab.geom.width = tab_width;
                tab.geom.height = sheight - tab.geom.y;

                double p1 = start_x;
                double p2 = start_x + tab_width;
                double p3 = start_x + tab_width - 15;
                double p4 = start_x + 15;

                context.move_to(p1, sheight);
                context.line_to(p2, sheight);
                context.line_to(p3, tab.geom.y);
                context.line_to(p4, tab.geom.y);
                context.fill();

                // Render pixbuf
                double px = start_x + 15;
                double py = tab.geom.y + tab.geom.height / 2 - tab.pixbuf.height / 2;
                Gdk.cairo_set_source_pixbuf(context, tab.pixbuf, px, py);
                context.paint();

                // Render label
                if (tab.get_state() == Ontis.TabState.SELECTED) {
                    Ontis.get_rgb(Ontis.Colors.TAB_SELECTED_LABEL_COLOR, out r, out g, out b);
                } else {
                    Ontis.get_rgb(Ontis.Colors.TAB_LABEL_COLOR, out r, out g, out b);
                }
                
                context.set_source_rgb(r, g, b);

                Cairo.TextExtents extents;
                context.text_extents(tab.label, out extents);

                double max_label_width = tab.geom.width - tab.pixbuf.width - 45;
                double x_label = start_x + tab.pixbuf.width + 20;
                double y_label = tab.geom.y + tab.geom.height / 2 + extents.height / 2 - 2;

                context.move_to(x_label, y_label);
                context.set_font_size(Ontis.Consts.TAB_LABEL_SIZE);
                context.select_font_face(Ontis.Consts.TAB_LABEL_FONT, Cairo.FontSlant.NORMAL, Cairo.FontWeight.NORMAL);

                if (extents.width <= max_label_width) {
                    context.show_text(tab.label);
                } else {
                    string current_text = "";
                    for (int i=1; i <= tab.label.length; i++) {
                        string sub_text = tab.label.slice(0, i) + "...";
                        Cairo.TextExtents sub_extents;
                        context.text_extents(sub_text, out sub_extents);

                        if (sub_extents.width > max_label_width) {
                            context.show_text(current_text);
                            break;
                        }
                        current_text = sub_text;
                    }
                }
            }
        }

        private void draw_buttons(Cairo.Context context) {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);

            double r, g, b;

            foreach (Ontis.Button button in this.get_buttons()) {
                double x, y, width, height;
                x = button.geom.x;
                y = button.geom.y;
                width = button.geom.width;
                height = button.geom.height;

                this.get_widget_color(button, out r, out g, out b);

                context.set_source_rgb(r, g, b);
                context.rectangle(alloc.width + x, y, width, height);
                context.fill();
            }

            double start_x = this.get_tab_width() * this.tabs.length;
            double start_y = alloc.height / 2 - this.new_tab_button.geom.height / 4;
            double border = 10;
            double width = this.new_tab_button.geom.width;
            double height = this.new_tab_button.geom.height;

            this.get_widget_color(this.new_tab_button, out r, out g, out b);
            context.set_source_rgb(r, g, b);

            context.move_to(start_x + border, start_y + height);
            context.line_to(start_x + border + width, start_y + height);
            context.line_to(start_x + width, start_y);
            context.line_to(start_x, start_y);
            context.fill();
        }

        private void state_changed_cb(Ontis.TabState state) {
            if (state == Ontis.TabState.SELECTED) {
                this.page_switched();
            }
        }

        public void update() {
            GLib.Idle.add(() => {
                this.queue_draw();
                return false;
            });
        }

        public Ontis.Tab add_tab(string label, int index, Gtk.Widget widget) {
            Ontis.Tab tab = new Ontis.Tab(label, index, widget);
            tab.set_connect_id(tab.redraw.connect(() => { this.update(); }));
            tab.state_changed.connect(this.state_changed_cb);
            this.tabs += tab;
            this.update();
            return tab;
        }

        public void remove_tab(Ontis.Tab tab) {
            Ontis.Tab[] tabs = { };
            foreach (Ontis.Tab ptab in this.tabs) {
                if (ptab != tab) {
                    tabs += tab;
                }
            }

            tab.destroy();

            this.tabs = tabs;
            this.update();
        }

        public Ontis.Tab[] get_tabs() {
            return this.tabs;
        }

        public double get_tab_width() {
            Gtk.Allocation alloc;
            this.get_allocation(out alloc);

            int swidth, sheight;
            swidth = alloc.width;
            sheight = alloc.height;

            double space = swidth - 150;
            int ctabs = this.tabs.length;
            double tab_width = space / ctabs;

            if (tab_width > Ontis.Consts.MAX_TAB_WIDTH) {
                tab_width = Ontis.Consts.MAX_TAB_WIDTH;
            }

            return tab_width;
        }

        public Ontis.Tab? get_tab_at_point(double px, double py) {
            double tx, ty, twidth, theight;
            Ontis.TabState state;

            Ontis.Tab? tab = null;

            foreach (Ontis.Tab ctab in this.tabs) {
                tx = ctab.geom.x;
                ty = ctab.geom.y;
                twidth = ctab.geom.width;
                theight = ctab.geom.height;
                state = ctab.get_state();

                if (px > tx && px < tx + twidth &&
                    py > ty && py < ty + theight) {
                    // The pointer is over
                    tab = ctab;  // FIXME: And, when a tab is dragging?
                    break;
                }
            }

            return tab;
        }

        public Ontis.Button[] get_buttons() {
            Ontis.Button[] buttons = { this.minimize_button, this.maximize_button, this.close_button };
            return buttons;
        }

        public void get_widget_color(Ontis.BaseWidget widget, out double r, out double g, out double b) {
            switch (widget.get_state()) {
                case Ontis.TabState.NORMAL:
                    Ontis.get_rgb(Ontis.Colors.TAB_BG_COLOR, out r, out g, out b);
                    break;

                case Ontis.TabState.MOUSE_OVER:
                    Ontis.get_rgb(Ontis.Colors.TAB_MOUSE_OVER_BG_COLOR, out r, out g, out b);
                    break;

                case Ontis.TabState.SELECTED:
                    Ontis.get_rgb(Ontis.Colors.TAB_SELECTED_BG_COLOR, out r, out g, out b);
                    break;

                case Ontis.TabState.DRAGGING:
                    Ontis.get_rgb(Ontis.Colors.TAB_SELECTED_BG_COLOR, out r, out g, out b);
                    break;

                default:
                    r = g = b = 0;
                    break;
            }
        }
    }

    public class Notebook: Gtk.Box {

        public signal void new_tab();       // When user click on "new tab"
        public signal void page_added();    // When a new tab is added
        public signal void page_removed();  // When a tab is removed
        public signal void page_switched(); // When the current tab is changed
        public signal void minimize();
        public signal void turn_maximize();
        public signal void close();

        public Ontis.TabBox tabbox;
        public Gtk.Box box;
        public Gtk.Widget? current_child = null;
        public int current_page = 0;

        private Gtk.Widget[] childs;

        public class Notebook() {
            this.childs = { };

            this.set_orientation(Gtk.Orientation.VERTICAL);

            this.tabbox = new Ontis.TabBox();
            this.tabbox.new_tab.connect(() => { this.new_tab(); });
            this.tabbox.page_added.connect(() => { this.page_added(); });
            this.tabbox.page_removed.connect(() => { this.page_removed(); });
            this.tabbox.page_switched.connect(() => { this.page_switched(); });
            this.tabbox.minimize.connect(() => { this.minimize(); });
            this.tabbox.turn_maximize.connect(() => { this.turn_maximize(); });
            this.tabbox.close.connect(() => { this.close(); });
            this.pack_start(this.tabbox, false, false, 0);

            this.box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
            this.pack_start(this.box, true, true, 0);

            this.page_switched.connect(this.page_switched_cb);
        }

        private void page_switched_cb() {
            int i = 0;
            foreach (Ontis.Tab tab in this.tabbox.get_tabs()) {
                if (tab.get_state() == Ontis.TabState.SELECTED) {
                    break;
                }

                i++;
            }

            Gtk.Widget widget = this.childs[i];
            this.set_current_page_from_widget(widget);
        }

        public Ontis.Tab append_page(string label, Gtk.Widget widget) {
            this.childs += widget;

            if (current_child == null) {
                this.set_current_page_from_widget(widget);
            }

            return this.tabbox.add_tab(label, this.childs.length, widget);
        }

        public void remove_page(int index) {
            if (this.get_n_pages() == 0) {
                return;
            }

            int current1 = 0;
            int current2 = 0;
            int current3 = 1;

            foreach (Ontis.Tab tab in this.tabbox.get_tabs()) {
                if (current1 == index) {
                    this.tabbox.remove_tab(tab);
                    break;
                }

                current1 ++;
            }

            Gtk.Widget[] childs = { };
            foreach (Gtk.Widget widget in this.childs) {
                if (current2 != index) {
                    childs += widget;
                }

                current2 ++;
            }

            this.childs = childs;

            foreach (Ontis.Tab tab in this.tabbox.get_tabs()) {
                tab.index = current3;
                current3 ++;
            }

            if (index == this.get_current_page()) {
                if (this.get_n_pages() >= index) {
                    this.set_current_page();
                } else if (this.get_n_pages() < index && this.get_n_pages() >= 1) {
                    this.set_current_page(index - 1);
                }
            }

            if (this.get_current_page() == -1) {
                this.set_current_page(0);
            }

            this.page_removed();
        }

        public void set_show_buttons(bool show) {
        }

        public int get_n_pages() {
            return this.childs.length;
        }

        public void set_current_page(int? page = null, bool change_tab = true) {
            //if (page > this.childs.length) {
            //    ("Error: Index < childs.length: FAILED\n");
            //}

            //if (page == this.current_page) {
            //    return;
            //}

            int index;
            if (page == null) {
                index = this.get_current_page();
            } else {
                index = page;
            }

            if (this.current_child != null && this.current_child.get_parent() == this.box) {
                this.box.remove(this.current_child);
            }

            this.current_page = index;
            int current1 = 0;

            foreach (Gtk.Widget widget in this.childs) {
                if (current1 == index) {
                    this.current_child = widget;
                    this.box.pack_start(this.current_child, true, true, 0);
                    break;
                }
                current1 ++;
            }

            if (change_tab) {
                int current2 = 0;
                foreach (Ontis.Tab tab in this.tabbox.get_tabs()) {
                    tab.set_selected(current2 == current1);
                    current2 ++;
                }
            }

            this.box.show();
            this.current_child.show();

            this.page_switched();
        }

        public int get_current_page() {
            return this.current_page;
        }

        public void set_current_page_from_widget(Gtk.Widget widget) {
            if (this.current_child != null) {
                this.box.remove(this.current_child);
            }

            this.current_child = widget;
            this.box.pack_start(widget, true, true, 0);
        }

        public Ontis.Tab? get_tab(int index) {
            if (this.get_n_pages() > 0) {
                int current = 0;
                foreach (Ontis.Tab tab in this.tabbox.get_tabs()) {
                    if (current == index) {
                        return tab;
                    }

                    current ++;
                }
            }

            return null;
        }

        public void set_tab_label(int index, string label) {
            Ontis.Tab tab = this.get_tab(index);
            tab.label = label;
            this.tabbox.update();
        }

        public string get_tab_label(int index) {
            Ontis.Tab tab = this.get_tab(index);
            return tab.label;
        }

        public Gtk.Widget[] get_childs() {
            return this.childs;
        }
    }
}
