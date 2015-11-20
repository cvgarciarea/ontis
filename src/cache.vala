namespace Ontis {

    public class Cache: Object {

        public string BASE_DIRECTORY;
        public string FAVICONS;
        public string DATABASES;
        public string COOKIES;
	    public string DOWNLOADS;

        public Cache () {
            BASE_DIRECTORY = Utils.get_cache_dir();
            FAVICONS = Utils.get_favicons_path();
            DATABASES = GLib.Path.build_filename(BASE_DIRECTORY, "databases");
            COOKIES = GLib.Path.build_filename(BASE_DIRECTORY, "cookies.txt");
            DOWNLOADS = Utils.get_download_dir();
            GLib.File favicons = GLib.File.new_for_path(FAVICONS);

            if (!favicons.query_exists()) {
                try {
                    favicons.make_directory_with_parents(null);
                } catch(GLib.Error e) {}
            }
        }
    }
}
