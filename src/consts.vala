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

    namespace Colors {
        public const double[] BG_COLOR = { 0, 0, 0 };
        public const double[] TAB_BG_COLOR = { 0.3764705882352941, 0.49019607843137253, 0.5450980392156862 };
        public const double[] TAB_SELECTED_BG_COLOR = { 0.9215686274509803, 0.9372549019607843, 0.9490196078431372 };
        public const double[] TAB_MOUSE_OVER_BG_COLOR = { 0.5568627450980392, 0.6352941176470588, 0.6784313725490196 };
        public const double[] TAB_LABEL_COLOR = { 0.9215686274509803, 0.9372549019607843, 0.9490196078431372 };
        public const double[] TAB_SELECTED_LABEL_COLOR = { 0.0, 0.0, 0.0 };
        public const double[] TAB_BG_CLOSE_BUTTON = { 0.5568627450980392, 0.6352941176470588, 0.6784313725490196 };
        public const double[] MOUSE_OVER_BG_CLOSE_BUTTON = { 0.9176470588235294, 0.592156862745098, 0.5568627450980392 };
        public const double[] BUTTON_BG_COLOR = { 0.3764705882352941, 0.49019607843137253, 0.5450980392156862 };
        public const double[] BUTTON_MOUSE_OVER_BG_COLOR = { 0.5568627450980392, 0.6352941176470588, 0.6784313725490196 };
        public const double[] BUTTON_LABEL_COLOR = { 1, 1, 1 };
    }

    namespace Consts {
        // Some tabs things
        public const int TAB_LABEL_SIZE = 15;
        public const int MAX_TAB_WIDTH = 200;
        public const string TAB_LABEL_FONT = "DejaVu Sans";

        // Urls
        public const string URL_NEWTAB = "ontis://newtab";
        public const string URL_HISTORY = "ontis://history";
        public const string URL_DOWNLOADS = "ontis://downloads";
        public const string URL_SETTINGS = "ontis://settings";
        public const string[] SPECIAL_URLS = {
            Ontis.Consts.URL_NEWTAB,
            Ontis.Consts.URL_HISTORY,
            Ontis.Consts.URL_DOWNLOADS,
            Ontis.Consts.URL_SETTINGS
        };
    }

    public enum TabState {
        NORMAL,
        MOUSE_OVER,
        SELECTED,
        DRAGGING,
    }
}
