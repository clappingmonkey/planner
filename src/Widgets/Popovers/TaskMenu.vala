/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
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
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Widgets.Popovers.TaskMenu : Gtk.Popover {
    public signal void on_selected_menu (int index);

    public TaskMenu (Gtk.Widget relative) {
        Object (
            relative_to: relative,
            modal: true,
            position: Gtk.PositionType.TOP
        );
    }

    construct {
        var convert_menu = new Widgets.ModelButton (_("Convert"), "planner-startup-symbolic", _("Convert to Project"));
        var duplicate_menu = new Widgets.ModelButton (_("Duplicate"), "edit-copy-symbolic", _("Duplicate task"));
        var share_menu = new Widgets.ModelButton (_("Share"), "emblem-shared-symbolic", _("Share task"));

        var separator_1 = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator_1.margin_top = 3;
        separator_1.margin_bottom = 3;
        separator_1.expand = true;

        var main_grid = new Gtk.Grid ();
        main_grid.margin_top = 6;
        main_grid.margin_bottom = 6;
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.width_request = 200;

        //main_grid.add (convert_menu);
        main_grid.add (duplicate_menu);
        main_grid.add (separator_1);
        main_grid.add (share_menu);

        add (main_grid);

        // Event
        convert_menu.clicked.connect (() => {
            popdown ();
            on_selected_menu (0);
        });

        duplicate_menu.clicked.connect (() => {
            popdown ();
            on_selected_menu (1);
        });

        share_menu.clicked.connect (() => {
            popdown ();
            on_selected_menu (2);
        });
    }
}
