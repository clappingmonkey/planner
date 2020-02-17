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

public class MainWindow : Gtk.Window {
    private Widgets.Pane pane;
    public Gee.HashMap<string, bool> projects_loaded;
    private string visible_child_name = "";

    private Widgets.MagicButton magic_button;
    private Gtk.Stack stack;
    private Views.Inbox inbox_view = null;
    private Views.Today today_view = null;
    private Views.Upcoming upcoming_view = null;

    private Widgets.QuickFind quick_find;
    private uint timeout_id = 0;
    private uint configure_id;

    private Services.DBusServer dbus_server;

    public MainWindow (Planner application) {
        Object (
            application: application,
            icon_name: "com.github.alainm23.planner",
            title: _("Planner")
        );
    }

    construct {
        dbus_server = Services.DBusServer.get_default ();
        dbus_server.item_added.connect ((id) => {
            var item = Planner.database.get_item_by_id (id);
            Planner.database.item_added (item);
        });

        projects_loaded = new Gee.HashMap<string, bool> ();

        var sidebar_header = new Gtk.HeaderBar ();
        sidebar_header.decoration_layout = "close:";
        sidebar_header.has_subtitle = false;
        sidebar_header.show_close_button = true;
        sidebar_header.get_style_context ().add_class ("sidebar-header");
        sidebar_header.get_style_context ().add_class ("titlebar");
        sidebar_header.get_style_context ().add_class ("default-decoration");
        sidebar_header.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var projectview_header = new Gtk.HeaderBar ();
        projectview_header.has_subtitle = false;
        projectview_header.decoration_layout = ":maximize";
        projectview_header.show_close_button = true;
        projectview_header.get_style_context ().add_class ("projectview-header");
        projectview_header.get_style_context ().add_class ("titlebar");
        projectview_header.get_style_context ().add_class ("default-decoration");
        projectview_header.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

        var header_paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        header_paned.pack1 (sidebar_header, false, false);
        header_paned.pack2 (projectview_header, true, false);

        pane = new Widgets.Pane ();

        var welcome_view = new Views.Welcome ();

        stack = new Gtk.Stack ();
        stack.margin_end = stack.margin_bottom = 3;
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.NONE;
        stack.add_named (welcome_view, "welcome-view");
        var toast = new Widgets.Toast ();
        magic_button = new Widgets.MagicButton ();

        quick_find = new Widgets.QuickFind ();

        var projectview_overlay = new Gtk.Overlay ();
        projectview_overlay.expand = true;
        projectview_overlay.add_overlay (magic_button);
        projectview_overlay.add_overlay (toast);
        projectview_overlay.add (stack);

        var paned = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
        paned.pack1 (pane, false, false);
        paned.pack2 (projectview_overlay, true, true);

        var paned_overlay = new Gtk.Overlay ();
        paned_overlay.expand = true;
        paned_overlay.add_overlay (quick_find);
        paned_overlay.add (paned);

        set_titlebar (header_paned);
        add (paned_overlay);

        // This must come after setting header_paned as the titlebar
        header_paned.get_style_context ().remove_class ("titlebar");
        get_style_context ().add_class ("rounded");
        Planner.settings.bind ("pane-position", header_paned, "position", GLib.SettingsBindFlags.DEFAULT);
        Planner.settings.bind ("pane-position", paned, "position", GLib.SettingsBindFlags.DEFAULT);

        Timeout.add (125, () => {
            if (Planner.database.is_database_empty ()) {
                stack.visible_child_name = "welcome-view";
                pane.sensitive_ui = false;
                magic_button.reveal_child = false;
            } else {
                // Remove Trash Data
                Planner.database.remove_trash ();

                if (Planner.settings.get_boolean ("homepage-project")) {
                    int64 project_id = Planner.settings.get_int64 ("homepage-project-id");
                    if (Planner.database.project_exists (project_id)) {
                        projects_loaded.set (project_id.to_string (), true);
                        var project_view = new Views.Project (Planner.database.get_project_by_id (project_id));
                        stack.add_named (project_view, "project-view-%s".printf (project_id.to_string ()));
                        stack.visible_child_name = "project-view-%s".printf (project_id.to_string ());
                    } else {
                        go_view (0);
                    }
                } else {
                    go_view (Planner.settings.get_int ("homepage-item"));
                    pane.select_item (Planner.settings.get_int ("homepage-item"));
                }

                // Run Todoisr Sync server
                Planner.todoist.run_server ();

                pane.add_all_areas ();
                pane.add_all_projects ();

                pane.sensitive_ui = true;
                magic_button.reveal_child = true;
            }

            return false;
        });

        Planner.database.reset.connect (() => {
            stack.visible_child_name = "welcome-view";
        });

        welcome_view.activated.connect ((index) => {
            if (index == 0) {
                // Save user name
                Planner.settings.set_string ("user-name", GLib.Environment.get_real_name ());

                // To do: Create a tutorial project
                Planner.utils.pane_project_selected (Planner.utils.create_tutorial_project ().id, 0);

                // Create Inbox Project
                var inbox_project = Planner.database.create_inbox_project ();

                // Cretae Default Labels
                Planner.utils.create_default_labels ();

                // Set settings
                Planner.settings.set_boolean ("inbox-project-sync", false);
                Planner.settings.set_int64 ("inbox-project", inbox_project.id);

                stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
                stack.visible_child_name = "inbox-view";
                pane.sensitive_ui = true;
                magic_button.reveal_child = true;
                stack.transition_type = Gtk.StackTransitionType.NONE;
            } else {
                var todoist_oauth = new Dialogs.TodoistOAuth ();
                todoist_oauth.show_all ();
            }
        });

        pane.activated.connect ((id) => {
            go_view (id);
        });

        pane.show_quick_find.connect (show_quick_find);

        Planner.utils.pane_project_selected.connect ((project_id, area_id) => {
            if (projects_loaded.has_key (project_id.to_string ())) {
                stack.visible_child_name = "project-view-%s".printf (project_id.to_string ());
            } else {
                projects_loaded.set (project_id.to_string (), true);
                var project_view = new Views.Project (Planner.database.get_project_by_id (project_id));
                stack.add_named (project_view, "project-view-%s".printf (project_id.to_string ()));
                stack.visible_child_name = "project-view-%s".printf (project_id.to_string ());
            }

            magic_button.reveal_child = true;
        });

        Planner.todoist.first_sync_finished.connect (() => {
            stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
            stack.visible_child_name = "inbox-view";
            pane.sensitive_ui = true;
            magic_button.reveal_child = true;
            stack.transition_type = Gtk.StackTransitionType.NONE;
        });

        Planner.database.project_deleted.connect ((id) => {
            if ("project-view-%s".printf (id.to_string ()) == stack.visible_child_name) {
                stack.visible_child.destroy ();
                stack.visible_child_name = "inbox-view";

                pane.select_item (0);
            }
        });

        magic_button.clicked.connect (() => {
            visible_child_name = stack.visible_child_name;

            if (visible_child_name == "inbox-view") {
                int is_todoist = 0;
                if (Planner.settings.get_boolean ("inbox-project-sync")) {
                    is_todoist = 1;
                }

                Planner.utils.magic_button_activated (
                    Planner.settings.get_int64 ("inbox-project"),
                    0,
                    is_todoist,
                    true
                );
            } else if (visible_child_name == "today-view") {
                today_view.toggle_new_item ();
            } else if (visible_child_name == "upcoming-view") {

            } else {
                var project = ((Views.Project) stack.get_child_by_name (visible_child_name)).project;
                Planner.utils.magic_button_activated (
                    project.id,
                    0,
                    project.is_todoist,
                    true
                );
            }
        });

        // Label Controller
        var labels_controller = new Services.LabelsController ();

        Planner.database.label_added.connect_after ((label) => {
            Idle.add (() => {
                labels_controller.add_label (label);

                return false;
            });
        });

        Planner.database.label_updated.connect ((label) => {
            Idle.add (() => {
                labels_controller.update_label (label);

                return false;
            });
        });

        delete_event.connect (() => {
            if (Planner.settings.get_boolean ("run-in-background")) {
                return hide_on_delete ();
            } else {
                return false;
            }
        });

        Planner.instance.go_view.connect ((type, id, id2) => {
            if (type == "project") {
                if (projects_loaded.has_key (id.to_string ())) {
                    stack.visible_child_name = "project-view-%s".printf (id.to_string ());
                } else {
                    projects_loaded.set (id.to_string (), true);
                    var project_view = new Views.Project (Planner.database.get_project_by_id (id));
                    stack.add_named (project_view, "project-view-%s".printf (id.to_string ()));
                    stack.visible_child_name = "project-view-%s".printf (id.to_string ());
                }
            } else if (type == "item") {
                if (projects_loaded.has_key (id2.to_string ())) {
                    stack.visible_child_name = "project-view-%s".printf (id2.to_string ());
                } else {
                    projects_loaded.set (id2.to_string (), true);
                    var project_view = new Views.Project (Planner.database.get_project_by_id (id2));
                    stack.add_named (project_view, "project-view-%s".printf (id2.to_string ()));
                    stack.visible_child_name = "project-view-%s".printf (id2.to_string ());
                }
            }
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "prefer-dark-style") {
                Planner.utils.apply_theme_changed ();
            } else if (key == "badge-count") {
                set_badge_visible ();
            } else if (key == "todoist-sync-token") {
                Planner.settings.set_string (
                    "todoist-last-sync",
                    new GLib.DateTime.now_local ().to_string ()
                );
            }
        });

        init_badge_count ();

        init_progress_controller ();
    }

    private void init_progress_controller () {
        Planner.database.item_added.connect ((item) => {
            Planner.database.check_project_count (item.project_id);
        });

        Planner.database.item_updated.connect ((item) => {
            Planner.database.check_project_count (item.project_id);
        });

        Planner.database.item_added_with_index.connect ((item, index) => {
            Planner.database.check_project_count (item.project_id);
        });

        Planner.database.item_moved.connect ((item, project_id, old_project_id) => {
            Planner.database.check_project_count (project_id);
        });

        Planner.database.item_moved.connect ((item, project_id, old_project_id) => {
            Planner.database.check_project_count (old_project_id);
        });

        Planner.database.item_deleted.connect ((item) => {
            Planner.database.check_project_count (item.project_id);
        });

        Planner.database.item_completed.connect ((item) => {
            Planner.database.check_project_count (item.project_id);
        });

        Planner.database.section_added.connect ((section) => {
            Idle.add (() => {
                Planner.database.check_project_count (section.project_id);
                return false;
            });
        });

        Planner.database.section_deleted.connect ((section) => {
            Planner.database.check_project_count (section.project_id);
        });

        Planner.database.section_moved.connect ((section, id, old_project_id) => {
            Idle.add (() => {
                Planner.database.check_project_count (id);
                return false;
            });
        });

        Planner.database.section_moved.connect ((section, id, old_project_id) => {
            Idle.add (() => {
                Planner.database.check_project_count (old_project_id);
                return false;
            });
        });

        Planner.database.subtract_task_counter.connect ((id) => {
            Idle.add (() => {
                Planner.database.check_project_count (id);
                return false;
            });
        });

        Planner.database.update_project_count.connect ((id, items_0, items_1) => {
            Planner.database.check_project_count (id);
        });
    }

    public void show_quick_find () {
        quick_find.reveal_toggled ();
    }

    public void new_project () {
        if (pane.new_project.reveal) {
            pane.new_project.reveal = false;
        } else {
            pane.new_project.reveal = true;
            pane.new_project.stack.visible_child_name = "box";
            pane.new_project.name_entry.grab_focus ();
        }
    }

    public void go_view (int id) {
        if (id == 0) {
            if (inbox_view == null) {
                inbox_view = new Views.Inbox ();
                stack.add_named (inbox_view, "inbox-view");
            }

            magic_button.reveal_child = true;
            stack.visible_child_name = "inbox-view";
        } else if (id == 1) {
            if (today_view == null) {
                today_view = new Views.Today ();
                stack.add_named (today_view, "today-view");
            }

            magic_button.reveal_child = true;
            stack.visible_child_name = "today-view";
        } else {
            if (upcoming_view == null) {
                upcoming_view = new Views.Upcoming ();
                stack.add_named (upcoming_view, "upcoming-view");
            }

            magic_button.reveal_child = false;
            stack.visible_child_name = "upcoming-view";
        }

        pane.select_item (id);
    }

    private void init_badge_count () {
        set_badge_visible ();

        Planner.database.item_added.connect ((item) => {
            set_badge_visible ();
        });

        Planner.database.item_added_with_index.connect (() => {
            set_badge_visible ();
        });

        Planner.database.item_deleted.connect ((item) => {
            set_badge_visible ();
        });

        Planner.database.item_completed.connect ((item) => {
            set_badge_visible ();
        });

        Planner.database.add_due_item.connect (() => {
            set_badge_visible ();
        });

        Planner.database.update_due_item.connect (() => {
            set_badge_visible ();
        });

        Planner.database.remove_due_item.connect (() => {
            set_badge_visible ();
        });

        Planner.database.item_moved.connect (() => {
            Idle.add (() => {
                set_badge_visible ();

                return false;
            });
        });

        Planner.database.subtract_task_counter.connect ((id) => {
            Idle.add (() => {
                set_badge_visible ();

                return false;
            });
        });
    }

    private void set_badge_visible () {
        if (timeout_id != 0) {
            Source.remove (timeout_id);
            timeout_id = 0;
        }

        timeout_id = Timeout.add (300, () => {
            Granite.Services.Application.set_badge_visible.begin (
                Planner.settings.get_enum ("badge-count") != 0, (obj, res) => {
                try {
                    Granite.Services.Application.set_badge_visible.end (res);
                    update_badge_count ();
                } catch (GLib.Error e) {
                    critical (e.message);
                }
            });

            return false;
        });
    }

    private void update_badge_count () {
        int badge_count = Planner.settings.get_enum ("badge-count");
        int count = 0;

        if (badge_count == 1) {
            count = Planner.database.get_project_count (Planner.settings.get_int64 ("inbox-project"));
        } else if (badge_count == 2) {
            count = Planner.database.get_today_count ();
        } else if (badge_count == 3) {
            count = (Planner.database.get_project_count (
                Planner.settings.get_int64 ("inbox-project")) +
                Planner.database.get_today_count ()) -
                Planner.database.get_today_project_count (Planner.settings.get_int64 ("inbox-project")
            );
        }

        bool badge_visible = false;
        if (count > 0) {
            badge_visible = true;
        }

        Granite.Services.Application.set_badge.begin (count, (obj, res) => {
            try {
                Granite.Services.Application.set_badge.end (res);

                if (badge_visible == false) {
                    Granite.Services.Application.set_badge_visible.begin (badge_visible, (obj, res) => {
                        try {
                            Granite.Services.Application.set_badge_visible.end (res);
                        } catch (GLib.Error e) {
                            critical (e.message);
                        }
                    });
                }
            } catch (GLib.Error e) {
                critical (e.message);
            }
        });
    }

    public void add_task_action (bool last) {
        if (stack.visible_child_name == "inbox-view") {
            int is_todoist = 0;
            if (Planner.settings.get_boolean ("inbox-project-sync")) {
                is_todoist = 1;
            }

            Planner.utils.magic_button_activated (
                Planner.settings.get_int64 ("inbox-project"),
                0,
                is_todoist,
                last
            );
        } else if (stack.visible_child_name == "today-view") {
            today_view.toggle_new_item ();
        } else if (stack.visible_child_name == "upcoming-view") {

        } else {
            var project = ((Views.Project) stack.visible_child).project;
            Planner.utils.magic_button_activated (
                project.id,
                0,
                project.is_todoist,
                last
            );
        }
    }

    public void new_section_action () {
        if (stack.visible_child_name == "inbox-view") {
            inbox_view.section_toggled ();
        } else if (stack.visible_child_name == "today-view") {

        } else if (stack.visible_child_name == "upcoming-view") {

        } else {
            var project_view = (Views.Project) stack.visible_child;
            project_view.section_toggled ();
        }
    }

    public override bool configure_event (Gdk.EventConfigure event) {
        if (configure_id != 0) {
            GLib.Source.remove (configure_id);
        }

        configure_id = Timeout.add (100, () => {
            configure_id = 0;

            if (is_maximized) {
                Planner.settings.set_boolean ("window-maximized", true);
            } else {
                Planner.settings.set_boolean ("window-maximized", false);

                Gdk.Rectangle rect;
                get_allocation (out rect);
                Planner.settings.set ("window-size", "(ii)", rect.width, rect.height);

                int root_x, root_y;
                get_position (out root_x, out root_y);
                Planner.settings.set ("window-position", "(ii)", root_x, root_y);
            }

            return false;
        });
        return base.configure_event (event);
    }
}
