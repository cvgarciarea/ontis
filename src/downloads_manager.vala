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

    public class Download: GLib.Object {

        public signal void start();
        public signal void progress_changed(int size);
        public signal void finish();

        public int current_size;
        public int total_size;

        public string uri;
        public string path;

        public WebKit.Download download;

        public Download(WebKit.Download download) {
            this.download = download;
            this.path = GLib.Path.build_filename(Utils.get_download_dir(), this.get_filename());

            this.uri = this.download.get_uri();
            this.download.set_destination_uri("file://" + this.path);
            this.download.notify["status"].connect(this.status_changed_cb);
            this.download.notify["current-size"].connect(this.current_size_changed_cb);
        }

        public void start_now() {
            //this.download.start();
        }

        public string get_filename() {
            return this.download.get_suggested_filename();
        }

        public int get_total_size() {
            return this.total_size;
        }

        private void status_changed_cb(GLib.ParamSpec paramspec) {
            var status = this.download.get_status();
            this.total_size = (int)this.download.get_total_size();

            switch(status) {
                case WebKit.DownloadStatus.ERROR:
                    break;

                case WebKit.DownloadStatus.CREATED:
                    stdout.printf("download created\n");
                    break;

                case WebKit.DownloadStatus.STARTED:
                    break;

                case WebKit.DownloadStatus.CANCELLED:
                    stdout.printf("download cacelled\n");
                    break;

                case WebKit.DownloadStatus.FINISHED:
                    this.finish();
                    break;
            }
        }

        private void current_size_changed_cb(GLib.ParamSpec paramspec) {
            this.current_size = (int)this.download.get_current_size();
            if (this.current_size != this.total_size) {
                this.progress_changed(this.current_size);
            }
        }
    }

    public class DownloadManager: GLib.Object {

        public signal void new_download(Download download);

        GLib.List<Download> downloads;

        public DownloadManager() {
            this.downloads = new GLib.List<Download>();
        }

        public void add_download(WebKit.Download d) {
            Download download = new Download(d);
            downloads.append(download);
            //connect signals;
            this.new_download(download);
        }
    }
}
