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

    public class SettingsManager: GLib.Object {

        // Note for me: Remember see "WebKit.WebSettings.enable_private_browsing

        public signal void changed();

        public WebKit.WebSettings web_settings;

        private bool _load_images;
        private string _font;
        private int _font_size;
        private bool _print_backgrounds;
        private string[] _startup = { };
        private string _downloads_dir;
        private string _searcher;
        private string[] _ignored_popups = { };

        public SettingsManager() {
            this.web_settings = new WebKit.WebSettings();
        }

        public bool load_images {
            set {
                this._load_images = value;
                this.web_settings.auto_load_images = value;
            }
            get { return this.web_settings.auto_load_images; }
        }

        public string font {
            set {
                this._font = value;
                this.web_settings.default_font_family = value;
            }
            get {
                string family = "Serif";
                string? current = this.web_settings.default_font_family;
                return (current != null)? current: family;
            }
        }

        public int font_size {
            set {
                this._font_size = value;
                this.web_settings.default_font_size = value;
            }
            get {
                int size = 12;
                int? current = this.web_settings.default_font_size;
                return (current != null)? current: size;
            }
        }

        public bool print_backgrounds {
            set {
                this._print_backgrounds = value;
                this.web_settings.print_backgrounds = value;
            }
            get { return this.web_settings.print_backgrounds; }
        }

        public string[] startup {
            set { this._startup = value; }
            get { return this._startup; }
        }

        public void add_startup_page(string url) {
            string[] current = this.startup;
            current += url;
            this.startup = current;
        }

        // Colors

        public string downloads_dir {
            set { this._downloads_dir = value; }
            get { return this._downloads_dir; }
        }

        public string searcher {
            set { this._searcher = value; }
            get { return this._searcher; }
        }

        public string[] ignored_popups {
            set { this._ignored_popups = value; }
            get { return this._ignored_popups; }
        }

        public void add_ignored_popup(string url) {
            string[] current = this.ignored_popups;
            current += url;
            this.ignored_popups = current;
        }
    }
}
