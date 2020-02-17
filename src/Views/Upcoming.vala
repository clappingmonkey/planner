/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 3 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alainmh23@gmail.com>
*/

public class Views.Upcoming : Gtk.EventBox {
    public GLib.DateTime date { get; set; default = new GLib.DateTime.now_local (); }
    private Gtk.ListBox listbox;

    construct {
        var icon_image = new Gtk.Image ();
        icon_image.valign = Gtk.Align.CENTER;
        icon_image.gicon = new ThemedIcon ("x-office-calendar-symbolic");
        icon_image.get_style_context ().add_class ("upcoming-icon");
        icon_image.pixel_size = 19;

        var title_label = new Gtk.Label ("<b>%s</b>".printf (_("Upcoming")));
        title_label.get_style_context ().add_class ("title-label");
        title_label.use_markup = true;

        var top_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        top_box.hexpand = true;
        top_box.valign = Gtk.Align.START;
        top_box.margin_start = 41;
        top_box.margin_end = 24;

        top_box.pack_start (icon_image, false, false, 0);
        top_box.pack_start (title_label, false, false, 6);

        listbox = new Gtk.ListBox ();
        listbox.margin_top = 18;
        listbox.valign = Gtk.Align.START;
        listbox.get_style_context ().add_class ("welcome");
        listbox.get_style_context ().add_class ("listbox");
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.hexpand = true;

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (listbox, false, false, 0);

        var main_scrolled = new Gtk.ScrolledWindow (null, null);
        main_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        main_scrolled.expand = true;
        main_scrolled.add (main_box);

        add (main_scrolled);

        Planner.calendar_model.month_start = Util.get_start_of_month ();

        add_upcomings ();

        main_scrolled.edge_reached.connect ((pos) => {
            if (pos == Gtk.PositionType.BOTTOM) {
                add_upcomings ();
            }
        });

        show_all ();
    }

    private void add_upcomings () {
        for (int i = 0; i < 14; i++) {
            date = date.add_days (1);

            var row = new Widgets.UpcomingRow (date);

            listbox.add (row);
            listbox.show_all ();

            Planner.calendar_model.month_start = Util.get_start_of_month (date);
        }
    }
}
