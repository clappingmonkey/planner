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

public class Widgets.ActionRow : Gtk.ListBoxRow {
    public Gtk.Label title_name;
    public Gtk.Image icon { get; set; }

    public string icon_name { get; construct; }
    public string item_name { get; construct; }
    public string item_base_name { get; construct; }

    private Gtk.Label count_label;
    private Gtk.Revealer count_revealer;
    private Gtk.Label count_past_label;
    private Gtk.Revealer count_past_revealer;
    private Gtk.Revealer main_revealer;

    private int count = 0;
    private int count_past = 0;
    private uint timeout_id = 0;

    private const Gtk.TargetEntry[] TARGET_ENTRIES_ITEM = {
        {"ITEMROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public bool reveal_child {
        get {
            return main_revealer.reveal_child;
        }
        set {
            main_revealer.reveal_child = value;
        }
    }

    public ActionRow (string name, string icon, string item_base_name, string tooltip_text) {
        Object (
            item_name: name,
            icon_name: icon,
            item_base_name: item_base_name,
            tooltip_text: tooltip_text
        );
    }

    construct {
        margin_start = margin_end = 6;
        margin_bottom = 3;
        get_style_context ().add_class ("pane-row");

        icon = new Gtk.Image ();
        icon.halign = Gtk.Align.CENTER;
        icon.valign = Gtk.Align.CENTER;
        icon.gicon = new ThemedIcon (icon_name);
        icon.pixel_size = 16;

        title_name = new Gtk.Label (item_name);
        title_name.margin_bottom = 1;
        title_name.get_style_context ().add_class ("pane-item");
        title_name.use_markup = true;

        count_past_label = new Gtk.Label (null);
        count_past_label.get_style_context ().add_class ("duedate-expired");
        count_past_label.valign = Gtk.Align.CENTER;
        count_past_label.use_markup = true;
        count_past_label.opacity = 0.7;
        count_past_label.width_chars = 3;

        count_past_revealer = new Gtk.Revealer ();
        count_past_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        count_past_revealer.add (count_past_label);

        count_label = new Gtk.Label (null);
        count_label.valign = Gtk.Align.CENTER;
        count_label.use_markup = true;
        count_label.opacity = 0.7;
        count_label.width_chars = 3;

        count_revealer = new Gtk.Revealer ();
        count_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_RIGHT;
        count_revealer.add (count_label);

        var main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        main_box.margin = 3;
        main_box.pack_start (icon, false, false, 0);
        main_box.pack_start (title_name, false, false, 6);
        main_box.pack_end (count_revealer, false, false, 0);
        main_box.pack_end (count_past_revealer, false, false, 0);

        main_revealer = new Gtk.Revealer ();
        main_revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        main_revealer.add (main_box);
        main_revealer.reveal_child = true;

        add (main_revealer);
        build_drag_and_drop ();

        if (item_base_name == "search") {
            icon.get_style_context ().add_class ("search-icon");
        } else if (item_base_name == "inbox") {
            icon.get_style_context ().add_class ("inbox-icon");
            check_inbox_count_update ();
        } else if (item_base_name == "today") {
            if (icon_name == "planner-today-day-symbolic") {
                icon.get_style_context ().add_class ("today-day-icon");
            } else {
                icon.get_style_context ().add_class ("today-night-icon");
            }

            check_today_count_update ();
        } else if (item_base_name == "upcoming") {
            icon.get_style_context ().add_class ("upcoming-icon");
        }
    }

    private void check_inbox_count_update () {
        Timeout.add (125, () => {
            Planner.database.get_project_count (Planner.settings.get_int64 ("inbox-project"));
            return false;
        });

        Planner.database.update_project_count.connect ((id, items_0, items_1) => {
            if (Planner.settings.get_int64 ("inbox-project") == id) {
                count = items_0;
                check_count_label ();
            }
        });

        Planner.database.check_project_count.connect ((id) => {
            if (Planner.settings.get_int64 ("inbox-project") == id) {
                update_count ();
            }
        });
    }

    private void check_today_count_update () {
        Timeout.add (125, () => {
            Planner.database.get_today_count ();
            return false;
        });

        Planner.database.update_today_count.connect ((past, today) => {
            count = today;
            count_past = past;
            check_count_label ();
        });

        Planner.database.add_due_item.connect ((item) => {
            update_count (true);
        });

        Planner.database.update_due_item.connect ((item) => {
            update_count (true);
        });

        Planner.database.remove_due_item.connect ((item) => {
            update_count (true);
        });

        Planner.database.item_deleted.connect ((item) => {
            update_count (true);
        });
    }

    private void update_count (bool today=false) {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }

        timeout_id = Timeout.add (250, () => {
            if (today == false) {
                Planner.database.get_project_count (Planner.settings.get_int64 ("inbox-project"));
            } else {
                Planner.database.get_today_count ();
            }

            return false;
        });
    }

    private void check_count_label () {
        count_label.label = "<small>%i</small>".printf (count);
        count_past_label.label = "<small>%i</small>".printf (count_past);

        if (count <= 0) {
            count_revealer.reveal_child = false;
        } else {
            count_revealer.reveal_child = true;
        }

        if (count_past <= 0) {
            count_past_revealer.reveal_child = false;
        } else {
            count_past_revealer.reveal_child = true;
        }
    }

    private void build_drag_and_drop () {
        Gtk.drag_dest_set (this, Gtk.DestDefaults.ALL, TARGET_ENTRIES_ITEM, Gdk.DragAction.MOVE);
        drag_motion.connect (on_drag_item_motion);
        drag_leave.connect (on_drag_item_leave);

        if (item_base_name == "inbox") {
            drag_data_received.connect (on_drag_imbox_item_received);
        } else if (item_base_name == "today") {
            drag_data_received.connect (on_drag_today_item_received);
        } else if (item_base_name == "upcoming") {
            drag_data_received.connect (on_drag_upcoming_item_received);
        }
    }

    private void on_drag_imbox_item_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type) {
        Widgets.ItemRow source;
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        Planner.database.move_item (source.item, Planner.settings.get_int64 ("inbox-project"));
        if (source.item.is_todoist == 0) {
            Planner.todoist.move_item (source.item, Planner.settings.get_int64 ("inbox-project"));
        }
    }

    private void on_drag_today_item_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type) {
        Widgets.ItemRow source;
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        bool new_date = false;
        var date = new GLib.DateTime.now_local ();
        if (source.item.due_date == "") {
            new_date = true;
        }

        source.item.due_date = date.to_string ();

        Planner.database.set_due_item (source.item, new_date);

        if (source.item.is_todoist == 1) {
            Planner.todoist.update_item (source.item);
        }
    }

    private void on_drag_upcoming_item_received (Gdk.DragContext context, int x, int y,
        Gtk.SelectionData selection_data, uint target_type) {
        Widgets.ItemRow source;
        var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
        source = (Widgets.ItemRow) row;

        bool new_date = false;
        var date = new GLib.DateTime.now_local ().add_days (1);
        if (source.item.due_date == "") {
            new_date = true;
        }

        source.item.due_date = date.to_string ();

        Planner.database.set_due_item (source.item, new_date);

        if (source.item.is_todoist == 1) {
            Planner.todoist.update_item (source.item);
        }
    }

    public bool on_drag_item_motion (Gdk.DragContext context, int x, int y, uint time) {
        get_style_context ().add_class ("highlight");
        return true;
    }

    public void on_drag_item_leave (Gdk.DragContext context, uint time) {
        get_style_context ().remove_class ("highlight");
    }
}
