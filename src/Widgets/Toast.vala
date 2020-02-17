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

public class Widgets.Toast : Gtk.Revealer {
    private Gtk.Stack main_stack;

    private Gtk.Label simple_message_label;
    private Gtk.Label delete_message_label;

    private uint timeout_id;

    construct {
        margin = 3;
        margin_bottom = 15;
        halign = Gtk.Align.CENTER;
        valign = Gtk.Align.END;
        transition_type = Gtk.RevealerTransitionType.SLIDE_UP;

        main_stack = new Gtk.Stack ();
        main_stack.hexpand = true;
        main_stack.transition_type = Gtk.StackTransitionType.NONE;

        main_stack.add_named (get_simple_toast (), "simple_toast");
        main_stack.add_named (get_delete_toast (), "delete_toast");

        var notification_frame = new Gtk.Frame (null);
        notification_frame.get_style_context ().add_class ("app-notification");
        notification_frame.add (main_stack);

        add (notification_frame);

        Planner.notifications.send_notification.connect ((type, message) => {
            if (type == 0) {
                send_simple_notification (message);
            } else if (type == 1) {
                send_delete_notification (message);
            }
        });
    }

    private Gtk.Widget get_simple_toast () {
        var close_button = new Gtk.Button.from_icon_name ("close-symbolic", Gtk.IconSize.MENU);
        close_button.get_style_context ().add_class ("close-button");

        simple_message_label = new Gtk.Label (null);
        simple_message_label.use_markup = true;

        var notification_box = new Gtk.Grid ();
        notification_box.margin_end = 12;
        notification_box.column_spacing = 12;
        notification_box.add (close_button);
        notification_box.add (simple_message_label);

        close_button.clicked.connect (() => {
            reveal_child = false;
        });

        return notification_box;
    }

    private Gtk.Widget get_delete_toast () {
        var close_button = new Gtk.Button.from_icon_name ("close-symbolic", Gtk.IconSize.MENU);
        close_button.get_style_context ().add_class ("close-button");

        delete_message_label = new Gtk.Label (null);
        delete_message_label.use_markup = true;

        var undo_button = new Gtk.Button ();
        undo_button.valign = Gtk.Align.CENTER;
        undo_button.label = _("Undo");

        var notification_box = new Gtk.Grid ();
        notification_box.column_spacing = 12;
        notification_box.add (close_button);
        notification_box.add (delete_message_label);
        notification_box.add (undo_button);

        close_button.clicked.connect (() => {
            reveal_child = false;
            Planner.database.remove_item_to_delete ();
        });

        undo_button.clicked.connect (() => {
            if (timeout_id != 0) {
                Source.remove (timeout_id);
                timeout_id = 0;
            }

            reveal_child = false;
            Planner.database.clear_item_to_delete ();
        });

        return notification_box;
    }

    public void send_simple_notification (string message) {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }

        main_stack.visible_child_name = "simple_toast";
        simple_message_label.label = message;
        reveal_child = true;

        timeout_id = GLib.Timeout.add (2500, () => {
            reveal_child = false;
            simple_message_label.label = "";

            Source.remove (timeout_id);
            timeout_id = 0;

            return false;
        });
    }

    public void send_delete_notification (string message) {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }

        main_stack.visible_child_name = "delete_toast";
        delete_message_label.label = message;
        reveal_child = true;

        timeout_id = GLib.Timeout.add (4500, () => {
            reveal_child = false;
            delete_message_label.label = "";

            Planner.database.remove_item_to_delete ();

            Source.remove (timeout_id);
            timeout_id = 0;

            return false;
        });
    }
}
