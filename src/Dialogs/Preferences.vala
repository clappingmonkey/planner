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

public class Dialogs.Preferences : Gtk.Dialog {
    public string view { get; construct; }
    private Gtk.Stack stack;
    private uint timeout = 0;

    private const Gtk.TargetEntry[] TARGET_ENTRIES_LABELS = {
        {"LABELROW", Gtk.TargetFlags.SAME_APP, 0}
    };

    public Preferences (string view="home") {
        Object (
            view: view,
            transient_for: Planner.instance.main_window,
            deletable: false,
            resizable: true,
            destroy_with_parent: true,
            window_position: Gtk.WindowPosition.CENTER_ON_PARENT,
            modal: false
        );
    }

    construct {
        width_request = 525;
        height_request = 600;

        stack = new Gtk.Stack ();
        stack.expand = true;
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

        stack.add_named (get_home_widget (), "home");
        stack.add_named (get_homepage_widget (), "homepage");
        stack.add_named (get_badge_count_widget (), "badge-count");
        stack.add_named (get_theme_widget (), "theme");
        stack.add_named (get_quick_add_widget (), "quick-add");
        stack.add_named (get_todoist_widget (), "todoist");
        stack.add_named (get_general_widget (), "general");
        stack.add_named (get_labels_widget (), "labels");
        stack.add_named (get_keyboard_shortcuts_widget (), "keyboard_shortcuts");
        stack.add_named (get_calendar_widget (), "calendar");
        stack.add_named (get_about_widget (), "about");
        stack.add_named (get_fund_widget (), "fund");
        stack.add_named (get_credits_widget (), "credits");

        Timeout.add (125, () => {
            stack.visible_child_name = view;
            return false;
        });

        var stack_scrolled = new Gtk.ScrolledWindow (null, null);
        stack_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        stack_scrolled.vscrollbar_policy = Gtk.PolicyType.NEVER;
        stack_scrolled.width_request = 246;
        stack_scrolled.expand = true;
        stack_scrolled.add (stack);

        get_content_area ().pack_start (stack_scrolled, true, true, 0);

        add_button (_("Close"), Gtk.ResponseType.CLOSE);

        response.connect ((response_id) => {
            destroy ();
        });
    }

    private Gtk.Widget get_home_widget () {
        /* General */
        var general_label = new Granite.HeaderLabel (_("General"));
        general_label.margin_start = 6;

        var start_page_item = new PreferenceItem ("go-home", _("Homepage"));
        var badge_item = new PreferenceItem ("planner-badge-count", _("Badge Count"));
        var theme_item = new PreferenceItem ("night-light", _("Theme"));
        var quick_add_item = new PreferenceItem ("planner-quick-add", _("Quick Add"));
        var general_item = new PreferenceItem ("preferences-system", _("General"), true);

        var general_grid = new Gtk.Grid ();
        general_grid.valign = Gtk.Align.START;
        general_grid.get_style_context ().add_class ("view");
        general_grid.orientation = Gtk.Orientation.VERTICAL;
        general_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        general_grid.add (start_page_item);
        general_grid.add (badge_item);
        general_grid.add (theme_item);
        general_grid.add (quick_add_item);
        general_grid.add (general_item);
        general_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        /* Addons */
        var addons_label = new Granite.HeaderLabel (_("Add-ons"));
        addons_label.margin_start = 6;

        var todoist_item = new PreferenceItem ("planner-todoist", "Todoist");
        var calendar_item = new PreferenceItem ("x-office-calendar", _("Calendar Events"));
        var labels_item = new PreferenceItem ("tag", _("Labels"));
        var shortcuts_item = new PreferenceItem ("preferences-desktop-keyboard", _("Keyboard Shortcuts"), true);

        var addons_grid = new Gtk.Grid ();
        addons_grid.margin_top = 18;
        addons_grid.valign = Gtk.Align.START;
        addons_grid.get_style_context ().add_class ("view");
        addons_grid.orientation = Gtk.Orientation.VERTICAL;
        addons_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        addons_grid.add (todoist_item);
        addons_grid.add (calendar_item);
        addons_grid.add (labels_item);
        addons_grid.add (shortcuts_item);
        addons_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        /* Others */
        var about_item = new PreferenceItem ("dialog-information", _("About"));
        var fund_item = new PreferenceItem ("emblem-favorite", _("Fund"));
        var credits_item = new PreferenceItem ("help-about", _("Credits"), true);

        var others_grid = new Gtk.Grid ();
        others_grid.margin_top = 18;
        others_grid.margin_bottom = 3;
        others_grid.valign = Gtk.Align.START;
        others_grid.get_style_context ().add_class ("view");
        others_grid.orientation = Gtk.Orientation.VERTICAL;
        others_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        others_grid.add (about_item);
        others_grid.add (fund_item);
        others_grid.add (credits_item);
        others_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        var main_grid = new Gtk.Grid ();
        main_grid.orientation = Gtk.Orientation.VERTICAL;
        main_grid.valign = Gtk.Align.START;
        main_grid.add (general_grid);
        main_grid.add (addons_grid);
        main_grid.add (others_grid);

        var main_scrolled = new Gtk.ScrolledWindow (null, null);
        main_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        main_scrolled.expand = true;
        main_scrolled.add (main_grid);

        start_page_item.activated.connect (() => {
            stack.visible_child_name = "homepage";
        });

        badge_item.activated.connect (() => {
            stack.visible_child_name = "badge-count";
        });

        theme_item.activated.connect (() => {
            stack.visible_child_name = "theme";
        });

        quick_add_item.activated.connect (() => {
            stack.visible_child_name = "quick-add";
        });

        general_item.activated.connect (() => {
            stack.visible_child_name = "general";
        });

        todoist_item.activated.connect (() => {
            if (Planner.settings.get_boolean ("todoist-account")) {
                stack.visible_child_name = "todoist";
            } else {
                var todoist_oauth = new Dialogs.TodoistOAuth ();
                todoist_oauth.show_all ();
            }
        });

        labels_item.activated.connect (() => {
            stack.visible_child_name = "labels";
        });

        shortcuts_item.activated.connect (() => {
            stack.visible_child_name = "keyboard_shortcuts";
        });

        calendar_item.activated.connect (() => {
            stack.visible_child_name = "calendar";
        });

        about_item.activated.connect (() => {
            stack.visible_child_name = "about";
        });

        fund_item.activated.connect (() => {
            stack.visible_child_name = "fund";
        });

        credits_item.activated.connect (() => {
            stack.visible_child_name = "credits";
        });

        return main_scrolled;
    }

    private Gtk.Widget get_homepage_widget () {
        var top_box = new PreferenceTopBox ("go-home", _("Homepage"));

        var description_label = new Gtk.Label (
            _("When you open up Planner, make sure you see the tasks that are most important. The default homepage is your <b>Inbox</b> view, but you can change it to whatever you'd like.") // vala-lint=line-length
        );
        description_label.justify = Gtk.Justification.FILL;
        description_label.use_markup = true;
        description_label.wrap = true;
        description_label.xalign = 0;
        description_label.margin_bottom = 6;
        description_label.margin_top = 6;
        description_label.margin_start = 12;
        description_label.margin_end = 12;

        var inbox_radio = new Gtk.RadioButton.with_label (null, _("Inbox"));
        inbox_radio.margin_top = 12;
        inbox_radio.get_style_context ().add_class ("preference-item-radio");

        var today_radio = new Gtk.RadioButton.with_label_from_widget (inbox_radio, _("Today"));
        today_radio.get_style_context ().add_class ("preference-item-radio");

        var upcoming_radio = new Gtk.RadioButton.with_label_from_widget (inbox_radio, _("Upcoming"));
        upcoming_radio.get_style_context ().add_class ("preference-item-radio");

        if (!Planner.settings.get_boolean ("homepage-project")) {
            int type = Planner.settings.get_int ("homepage-item");
            if (type == 0) {
                inbox_radio.active = true;
            } else if (type == 1) {
                today_radio.active = true;
            } else {
                upcoming_radio.active = true;
            }
        }

        var project_header = new Granite.HeaderLabel (_("Projects"));
        project_header.margin_start = 12;

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.margin_top = 6;
        box.valign = Gtk.Align.START;
        box.hexpand = true;
        box.pack_start (description_label, false, true, 0);
        box.pack_start (inbox_radio, false, true, 0);
        box.pack_start (today_radio, false, true, 0);
        box.pack_start (upcoming_radio, false, true, 0);
        box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);
        box.pack_start (project_header, false, true, 0);

        foreach (var project in Planner.database.get_all_projects ()) {
            if (project.inbox_project == 0) {
                var project_radio = new Gtk.RadioButton.with_label_from_widget (inbox_radio, project.name);
                project_radio.get_style_context ().add_class ("preference-item-radio");
                box.pack_start (project_radio, false, false, 0);

                project_radio.toggled.connect (() => {
                    Planner.settings.set_boolean ("homepage-project", true);
                    Planner.settings.set_int64 ("homepage-project-id", project.id);
                });

                if (Planner.settings.get_boolean ("homepage-project")) {
                    if (Planner.settings.get_int64 ("homepage-project-id") == project.id) {
                        project_radio.active = true;
                    }
                }
            }
        }

        box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);

        var box_scrolled = new Gtk.ScrolledWindow (null, null);
        box_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        box_scrolled.vscrollbar_policy = Gtk.PolicyType.EXTERNAL;
        box_scrolled.expand = true;
        box_scrolled.add (box);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;

        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (box_scrolled, false, true, 0);

        top_box.back_activated.connect (() => {
            stack.visible_child_name = "home";
        });

        inbox_radio.toggled.connect (() => {
            Planner.settings.set_boolean ("homepage-project", false);
            Planner.settings.set_int ("homepage-item", 0);
        });

        today_radio.toggled.connect (() => {
            Planner.settings.set_boolean ("homepage-project", false);
            Planner.settings.set_int ("homepage-item", 1);
        });

        upcoming_radio.toggled.connect (() => {
            Planner.settings.set_boolean ("homepage-project", false);
            Planner.settings.set_int ("homepage-item", 2);
        });

        return main_box;
    }

    private Gtk.Widget get_badge_count_widget () {
        var top_box = new PreferenceTopBox ("planner-badge-count", _("Badge Count"));

        var description_label = new Gtk.Label (
            _("Choose which items should be counted for the badge on the application icon.")
        );
        description_label.justify = Gtk.Justification.FILL;
        description_label.wrap = true;
        description_label.xalign = 0;
        description_label.margin_bottom = 6;
        description_label.margin_top = 6;
        description_label.margin_start = 12;
        description_label.margin_end = 12;

        var none_radio = new Gtk.RadioButton.with_label (null, _("None"));
        none_radio.margin_top = 12;
        none_radio.get_style_context ().add_class ("preference-item-radio");

        var inbox_radio = new Gtk.RadioButton.with_label_from_widget (none_radio, _("Inbox"));
        inbox_radio.get_style_context ().add_class ("preference-item-radio");

        var today_radio = new Gtk.RadioButton.with_label_from_widget (none_radio, _("Today"));
        today_radio.get_style_context ().add_class ("preference-item-radio");

        var today_inbox_radio = new Gtk.RadioButton.with_label_from_widget (none_radio, _("Today + Inbox"));
        today_inbox_radio.get_style_context ().add_class ("preference-item-radio");

        int type = Planner.settings.get_enum ("badge-count");
        if (type == 0) {
            none_radio.active = true;
        } else if (type == 1) {
            inbox_radio.active = true;
        } else if (type == 2) {
            today_radio.active = true;
        } else {
            today_inbox_radio.active = true;
        }

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.margin_top = 6;
        main_box.valign = Gtk.Align.START;
        main_box.hexpand = true;
        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (description_label, false, true, 0);
        main_box.pack_start (none_radio, false, true, 0);
        main_box.pack_start (inbox_radio, false, true, 0);
        main_box.pack_start (today_radio, false, true, 0);
        main_box.pack_start (today_inbox_radio, false, true, 0);
        main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);

        top_box.back_activated.connect (() => {
            stack.visible_child_name = "home";
        });

        none_radio.toggled.connect (() => {
            Planner.settings.set_enum ("badge-count", 0);
        });

        inbox_radio.toggled.connect (() => {
            Planner.settings.set_enum ("badge-count", 1);
        });

        today_radio.toggled.connect (() => {
            Planner.settings.set_enum ("badge-count", 2);
        });

        today_inbox_radio.toggled.connect (() => {
            Planner.settings.set_enum ("badge-count", 3);
        });

        return main_box;
    }

    private Gtk.Widget get_theme_widget () {
        var info_box = new PreferenceTopBox ("night-light", _("Theme"));

        var description_label = new Gtk.Label (
            _("Personalize the look and feel of your Planner by choosing the theme that best suits you.")
        );
        description_label.margin = 6;
        description_label.margin_bottom = 6;
        description_label.margin_start = 12;
        description_label.margin_end = 12;
        description_label.justify = Gtk.Justification.FILL;
        description_label.wrap = true;
        description_label.xalign = 0;

        var light_radio = new Gtk.RadioButton.with_label (null, _("Light"));
        light_radio.margin_top = 12;
        light_radio.get_style_context ().add_class ("preference-item-radio");

        var night_radio = new Gtk.RadioButton.with_label_from_widget (light_radio, _("Night"));
        night_radio.get_style_context ().add_class ("preference-item-radio");

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;

        main_box.pack_start (info_box, false, false, 0);
        main_box.pack_start (description_label, false, false, 0);
        main_box.pack_start (light_radio, false, false, 0);
        main_box.pack_start (night_radio, false, false, 0);
        main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);

        if (Planner.settings.get_boolean ("prefer-dark-style")) {
            night_radio.active = true;
        }

        info_box.back_activated.connect (() => {
            stack.visible_child_name = "home";
        });

        light_radio.toggled.connect (() => {
            Planner.settings.set_boolean ("prefer-dark-style", false);
        });

        night_radio.toggled.connect (() => {
            Planner.settings.set_boolean ("prefer-dark-style", true);
        });

        return main_box;
    }

    private Gtk.Widget get_quick_add_widget () {
        var info_box = new PreferenceTopBox ("night-light", _("Quick Add"));

        var description_label = new Gtk.Label (
            _("Don't worry about which app you're using. You can use a keyboard shortcut to open the Quick Add window, where you can enter a pending task and quickly return to work.") // vala-lint=line-length
        );
        description_label.margin = 6;
        description_label.margin_bottom = 6;
        description_label.margin_start = 12;
        description_label.margin_end = 12;
        description_label.justify = Gtk.Justification.FILL;
        description_label.wrap = true;
        description_label.xalign = 0;

        var shortcut_label = new Gtk.Label (_("Keyboard Shortcuts"));
        shortcut_label.get_style_context ().add_class ("font-weight-600");

        string keys = Planner.settings.get_string ("quick-add-shortcut");
        uint accelerator_key;
        Gdk.ModifierType accelerator_mods;
        Gtk.accelerator_parse (keys, out accelerator_key, out accelerator_mods);
        var shortcut_hint = Gtk.accelerator_get_label (accelerator_key, accelerator_mods);

        var accels = new ShortcutLabel (shortcut_hint.split ("+"));
        accels.halign = Gtk.Align.END;

        var keybinding_toggle_recording_button = new Gtk.ToggleButton.with_label (_ ("Change"));
        keybinding_toggle_recording_button.valign = Gtk.Align.CENTER;

        var shortcut_stack = new Gtk.Stack ();
        shortcut_stack.transition_type = Gtk.StackTransitionType.CROSSFADE;

        shortcut_stack.add_named (accels, "accels");
        shortcut_stack.add_named (keybinding_toggle_recording_button, "button");

        var shortcut_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        shortcut_box.margin_start = 12;
        shortcut_box.margin_top = 3;
        shortcut_box.margin_bottom = 3;
        shortcut_box.margin_end = 12;
        shortcut_box.pack_start (shortcut_label, false, false, 0);
        shortcut_box.pack_end (shortcut_stack, false, false, 0);

        var shortcut_v_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        shortcut_v_box.margin_top = 6;
        shortcut_v_box.get_style_context ().add_class ("view");
        shortcut_v_box.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        shortcut_v_box.add (shortcut_box);
        //shortcut_v_box.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        var shortcut_eventbox = new Gtk.EventBox ();
        shortcut_eventbox.add (shortcut_v_box);

        var save_last_switch = new PreferenceItemSwitch (
            _("Save Last Selected Project"),
            Planner.settings.get_boolean ("quick-add-save-last-project")
        );
        //save_last_switch.margin_top = 6;

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;
        main_box.pack_start (info_box, false, false, 0);
        main_box.pack_start (description_label, false, false, 0);
        main_box.pack_start (shortcut_eventbox, false, false, 0);
        main_box.pack_start (save_last_switch, false, false, 0);

        shortcut_eventbox.enter_notify_event.connect ((event) => {
            shortcut_stack.visible_child_name = "button";
            return true;
        });

        shortcut_eventbox.leave_notify_event.connect ((event) => {
            if (event.detail == Gdk.NotifyType.INFERIOR) {
                return false;
            }

            if (keybinding_toggle_recording_button.active == false) {
                shortcut_stack.visible_child_name = "accels";
            }

            return true;
        });

        info_box.back_activated.connect (() => {
            stack.visible_child_name = "home";
        });

        save_last_switch.activated.connect ((value) => {
            Planner.settings.set_boolean ("quick-add-save-last-project", value);
        });

        keybinding_toggle_recording_button.toggled.connect (() => {
            if (keybinding_toggle_recording_button.active) {
                keybinding_toggle_recording_button.label = _ ("Press keys…");
            } else {
                keybinding_toggle_recording_button.label = _ ("Change");
            }
        });

         // Listen to key events on the window for setting keyboard shortcuts
        this.key_release_event.connect ((event) => {
            if (keybinding_toggle_recording_button.active) {
                keybinding_toggle_recording_button.active = false;

                if (event.keyval == Gdk.Key.Escape && no_modifier_set (event.state)) {
                    return true;
                } else if (event.keyval == Gdk.Key.BackSpace && no_modifier_set (event.state)) {
                    Planner.settings.set_string ("quick-add-shortcut", "");
                } else if (event.is_modifier == 0) {
                    var mods = event.state & Gtk.accelerator_get_default_mod_mask ();
                    string accelerator = Gtk.accelerator_name (event.keyval, mods);
                    Planner.settings.set_string ("quick-add-shortcut", accelerator);
                }

                return true;
            }

            shortcut_stack.visible_child_name = "accels";

            return false;
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "quick-add-shortcut") {
                string _keys = Planner.settings.get_string ("quick-add-shortcut");
                uint _accelerator_key;
                Gdk.ModifierType _accelerator_mods;
                Gtk.accelerator_parse (_keys, out _accelerator_key, out _accelerator_mods);
                var _shortcut_hint = Gtk.accelerator_get_label (_accelerator_key, _accelerator_mods);

                accels.update_accels (_shortcut_hint.split ("+"));

                // Set shortcut
                Planner.utils.set_quick_add_shortcut (_keys);
            }
        });

        return main_box;
    }

    private static bool no_modifier_set (Gdk.ModifierType mods) {
        return (mods & Gtk.accelerator_get_default_mod_mask ()) == 0;
    }

    private Gtk.Widget get_general_widget () {
        var top_box = new PreferenceTopBox ("night-light", _("General"));
        top_box.margin_bottom = 12;

        var de_header = new Granite.HeaderLabel (_("DE Integration"));
        de_header.margin_start = 12;

        var run_background_switch = new PreferenceItemSwitch (
            _("Run in background"), Planner.settings.get_boolean ("run-in-background")
        );

        var run_background_label = new Gtk.Label (
            _("Enable this setting to keep Planner running in the background when it closes. This will allow Planner to continue updating and sending reminder notifications.") // vala-lint=line-length
        );
        run_background_label.wrap = true;
        run_background_label.xalign = 0;
        run_background_label.margin_start = 12;
        run_background_label.halign = Gtk.Align.START;

        var run_startup_switch = new PreferenceItemSwitch (
            _("Run on startup"), Planner.settings.get_boolean ("run-on-startup")
        );
        run_startup_switch.margin_top = 6;

        var run_startup_label = new Gtk.Label (_("Enable this setting to make Planner startup with the system."));
        run_startup_label.wrap = true;
        run_startup_label.xalign = 0;
        run_startup_label.margin_start = 12;
        run_startup_label.halign = Gtk.Align.START;

        var help_header = new Granite.HeaderLabel (_("Help"));
        help_header.margin_start = 12;
        help_header.margin_top = 6;

        var tutorial_item = new PreferenceItemButton (_("Create tutorial project"), _("Create"));

        var dz_header = new Granite.HeaderLabel (_("Danger zone"));
        dz_header.margin_start = 12;
        dz_header.margin_top = 6;

        var clear_db_item = new PreferenceItemButton (_("Reset all"), _("Reset"));
        clear_db_item.title_label.get_style_context ().add_class ("label-danger");

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;

        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (de_header, false, false, 0);
        main_box.pack_start (run_background_switch, false, false, 0);
        main_box.pack_start (run_background_label, false, false, 0);
        main_box.pack_start (run_startup_switch, false, false, 0);
        main_box.pack_start (run_startup_label, false, false, 0);
        main_box.pack_start (help_header, false, false, 0);
        main_box.pack_start (tutorial_item, false, false, 0);
        main_box.pack_start (dz_header, false, false, 0);
        main_box.pack_start (clear_db_item, false, false, 0);

        var main_box_scrolled = new Gtk.ScrolledWindow (null, null);
        main_box_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        main_box_scrolled.vscrollbar_policy = Gtk.PolicyType.EXTERNAL;
        main_box_scrolled.expand = true;
        main_box_scrolled.add (main_box);

        run_startup_switch.activated.connect ((val) => {
            Planner.settings.set_boolean ("run-on-startup", val);
            Planner.utils.set_autostart (val);
        });

        run_background_switch.activated.connect ((val) => {
            Planner.settings.set_boolean ("run-in-background", val);
        });

        top_box.back_activated.connect (() => {
            stack.visible_child_name = "home";
        });

        tutorial_item.activated.connect (() => {
            int64 id = Planner.utils.create_tutorial_project ().id;

            Planner.utils.pane_project_selected (id, 0);
            Planner.notifications.send_notification (
                0,
                _("Your tutorial project was created")
            );

            Planner.utils.select_pane_project (id);

            destroy ();
        });

        clear_db_item.activated.connect (() => {
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("Are you sure you want to reset all?"),
                _("It process removes all stored information without the possibility of undoing it."),
                "edit-delete",
            Gtk.ButtonsType.CANCEL);

            var remove_button = new Gtk.Button.with_label (_("Reset all"));
            remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
            message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

            message_dialog.show_all ();

            if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                Planner.database.reset_all ();
                destroy ();
            }

            message_dialog.destroy ();
        });

        return main_box_scrolled;
    }

    private Gtk.Widget get_labels_widget () {
        var top_box = new PreferenceTopBox ("tag", _("Labels"));

        var description_label = new Gtk.Label (
            _("Save time by batching similar tasks together using labels. You’ll be able to pull up a list of all tasks with any given label in a matter of seconds.") // vala-lint=line-length
        );
        description_label.margin = 6;
        description_label.margin_bottom = 12;
        description_label.margin_start = 12;
        description_label.margin_end = 12;
        description_label.justify = Gtk.Justification.FILL;
        description_label.wrap = true;
        description_label.xalign = 0;

        var listbox = new Gtk.ListBox ();
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.get_style_context ().add_class ("background");
        listbox.expand = true;

        Gtk.drag_dest_set (listbox, Gtk.DestDefaults.ALL, TARGET_ENTRIES_LABELS, Gdk.DragAction.MOVE);
        listbox.drag_data_received.connect ((context, x, y, selection_data, target_type, time) => {
            Widgets.LabelRow target;
            Widgets.LabelRow source;
            Gtk.Allocation alloc;
            int new_pos;

            target = (Widgets.LabelRow) listbox.get_row_at_y (y);
            target.get_allocation (out alloc);

            var row = ((Gtk.Widget[]) selection_data.get_data ())[0];
            source = (Widgets.LabelRow) row;

            int last_index = (int) listbox.get_children ().length;

            if (target == null) {
                new_pos = last_index - 1;
            } else {
                new_pos = target.get_index () + 1;
            }

            source.get_parent ().remove (source);

            listbox.insert (source, new_pos);
            listbox.show_all ();

            update_label_order (listbox);
        });

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.hexpand = true;

        var new_label = new Widgets.NewLabel ();

        box.pack_start (description_label, false, false, 0);
        box.pack_start (new_label, false, true, 0);
        box.pack_start (listbox, false, true, 0);

        var box_scrolled = new Gtk.ScrolledWindow (null, null);
        box_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        box_scrolled.vscrollbar_policy = Gtk.PolicyType.EXTERNAL;
        box_scrolled.expand = true;
        box_scrolled.add (box);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        main_box.expand = true;

        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (box_scrolled, false, true, 0);

        add_all_labels (listbox, box_scrolled);

        Planner.database.label_added.connect ((label) => {
            var row = new Widgets.LabelRow (label, box_scrolled);

            listbox.insert (row, 0);
            listbox.show_all ();

            update_label_order (listbox);
        });

        top_box.back_activated.connect (() => {
            stack.visible_child_name = "home";
        });

        listbox.row_activated.connect ((row) => {
            var item = ((Widgets.LabelRow) row);
            item.edit ();
        });

        new_label.insert_row.connect ((row, position) => {
            listbox.insert (row, position);
            listbox.show_all ();
        });

        return main_box;
    }

    private void update_label_order (Gtk.ListBox listbox) {
        timeout = Timeout.add (150, () => {
            new Thread<void*> ("update_label_order", () => {
                listbox.foreach ((widget) => {
                    var row = (Gtk.ListBoxRow) widget;
                    int index = row.get_index ();

                    var label = ((Widgets.LabelRow) row).label;

                    new Thread<void*> ("update_label_order", () => {
                        Planner.database.update_label_item_order (label.id, index);

                        return null;
                    });
                });

                return null;
            });

            Source.remove (timeout);
            timeout = 0;

            return false;
        });
    }

    private Gtk.Widget get_keyboard_shortcuts_widget () {
        var top_box = new PreferenceTopBox ("tag", _("Keyboard Shortcuts"));

        var description_label = new Gtk.Label (
            _("All the shortcuts to save you time! Some can be used anywhere in the app, while others only work when adding or editing tasks.") // vala-lint=line-length
        );
        description_label.margin = 6;
        description_label.margin_bottom = 12;
        description_label.margin_start = 12;
        description_label.margin_end = 12;
        description_label.justify = Gtk.Justification.FILL;
        description_label.wrap = true;
        description_label.xalign = 0;

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_bottom = 1;

        var listbox = new Gtk.ListBox ();
        listbox.valign = Gtk.Align.START;
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.expand = true;

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.hexpand = true;

        foreach (var shortcut in Planner.utils.get_shortcuts ()) {
            var row = new ShortcutRow (shortcut.name, shortcut.accels);
            listbox.add (row);
            listbox.show_all ();
        }

        box.pack_start (description_label, false, false, 0);
        box.pack_start (separator, false, true, 0);
        box.pack_start (listbox, false, true, 0);

        var box_scrolled = new Gtk.ScrolledWindow (null, null);
        box_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        box_scrolled.vscrollbar_policy = Gtk.PolicyType.EXTERNAL;
        box_scrolled.expand = true;
        box_scrolled.add (box);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        main_box.expand = true;

        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (box_scrolled, false, true, 0);

        top_box.back_activated.connect (() => {
            stack.visible_child_name = "home";
        });

        return main_box;
    }

    private Gtk.Widget get_todoist_widget () {
        var top_box = new PreferenceTopBox ("planner-todoist", _("Todoist"));

        Granite.Widgets.Avatar user_avatar;
        if (Planner.settings.get_string ("todoist-user-image-id") != "") {
            user_avatar = new Granite.Widgets.Avatar.from_file (
                GLib.Path.build_filename (
                    Planner.utils.AVATARS_FOLDER,
                    Planner.settings.get_string ("todoist-user-image-id") + ".jpg"
                ),
                64
            );
        } else {
            user_avatar = new Granite.Widgets.Avatar.with_default_icon (64);
        }

        user_avatar.margin_top = 12;

        var username_label = new Gtk.Label (Planner.settings.get_string ("user-name"));
        username_label.margin_top = 6;
        username_label.get_style_context ().add_class ("h3");

        var email_label = new Gtk.Label (Planner.settings.get_string ("todoist-user-email"));
        email_label.get_style_context ().add_class ("dim-label");

        var last_update = new Gtk.Label (_("Last successful sync: %s".printf (
            Planner.utils.get_relative_datetime_from_string (Planner.settings.get_string ("todoist-last-sync"))
        )));
        last_update.margin_top = 12;

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;

        var sync_server_switch = new PreferenceItemSwitch (
            _("Sync server"), Planner.settings.get_boolean ("todoist-sync-server")
        );
        sync_server_switch.margin_top = 24;

        var sync_server_label = new Gtk.Label (
            _("Activate this setting so that Planner automatically synchronizes with your Todoist account every 15 minutes.") // vala-lint=line-length
        );
        sync_server_label.halign = Gtk.Align.START;
        sync_server_label.wrap = true;
        sync_server_label.margin_start = 12;
        sync_server_label.margin_top = 3;
        sync_server_label.xalign = (float) 0.0;

        var delete_image = new Gtk.Image ();
        delete_image.pixel_size = 16;
        delete_image.gicon = new ThemedIcon ("user-trash-symbolic");

        var delete_label = new Gtk.Label (_("Log out"));
        delete_label.get_style_context ().add_class ("font-weight-600");
        delete_label.get_style_context ().add_class ("label-danger");
        delete_label.ellipsize = Pango.EllipsizeMode.END;
        delete_label.halign = Gtk.Align.START;
        delete_label.valign = Gtk.Align.CENTER;

        var create_button = new Gtk.Button.from_icon_name ("pan-end-symbolic", Gtk.IconSize.MENU);
        create_button.get_style_context ().add_class ("flat");
        create_button.can_focus = false;
        create_button.valign = Gtk.Align.CENTER;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.hexpand = true;
        box.margin = 3;
        box.margin_start = 12;
        box.margin_end = 6;
        box.pack_start (delete_label, false, false, 0);
        box.pack_end (create_button, false, true, 0);

        var d_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        d_box.margin_top = 16;
        d_box.get_style_context ().add_class ("view");
        d_box.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        d_box.add (box);
        d_box.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        var eventbox = new Gtk.EventBox ();
        eventbox.add (d_box);

        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (user_avatar, false, false, 0);
        main_box.pack_start (username_label, false, false, 0);
        main_box.pack_start (email_label, false, false, 0);
        main_box.pack_start (last_update, false, false, 0);
        main_box.pack_start (sync_server_switch, false, true, 0);
        main_box.pack_start (sync_server_label, false, true, 0);
        main_box.pack_start (eventbox, false, true, 0);

        top_box.back_activated.connect (() => {
            stack.visible_child_name = "home";
        });

        sync_server_switch.activated.connect ((val) => {
            Planner.settings.set_boolean ("todoist-sync-server", val);
        });

        eventbox.button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS) {
                var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
                    _("Are you sure you want to log out?"),
                    _("This process will close your Todoist session on this device."),
                    "system-log-out",
                Gtk.ButtonsType.CANCEL);

                var remove_button = new Gtk.Button.with_label (_("Log out"));
                remove_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
                message_dialog.add_action_widget (remove_button, Gtk.ResponseType.ACCEPT);

                message_dialog.show_all ();

                if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
                    // Log out Todoist
                    Planner.todoist.log_out ();

                    // Save user name
                    Planner.settings.set_string ("user-name", GLib.Environment.get_real_name ());

                    // Create Inbox Project
                    var inbox_project = Planner.database.create_inbox_project ();

                    // Set settings
                    Planner.settings.set_boolean ("inbox-project-sync", false);
                    Planner.settings.set_int64 ("inbox-project", inbox_project.id);

                    destroy ();
                }

                message_dialog.destroy ();

                return true;
            }

            return false;
        });

        return main_box;
    }

    private Gtk.Widget get_calendar_widget () {
        var top_box = new PreferenceTopBox ("office-calendar", _("Calendar Events"));

        var description_label = new Gtk.Label (
            _("You can connect your <b>Calendar</b> app to Planner to see your events and to-dos together in one place. You’ll see events from both personal and shared calendars in <b>Today</b> and <b>Upcoming</b>. This is useful when you’re managing your day, and as you plan the week ahead.") // vala-lint=line-length
        );
        description_label.margin = 6;
        description_label.use_markup = true;
        description_label.margin_bottom = 12;
        description_label.margin_start = 12;
        description_label.margin_end = 12;
        description_label.justify = Gtk.Justification.FILL;
        description_label.wrap = true;
        description_label.xalign = 0;

        var enabled_switch = new PreferenceItemSwitch (_("Enabled"), Planner.settings.get_boolean ("calendar-enabled"));

        var listbox = new Gtk.ListBox ();
        listbox.margin_top = 12;
        listbox.valign = Gtk.Align.START;
        listbox.selection_mode = Gtk.SelectionMode.NONE;
        listbox.hexpand = true;
        listbox.get_style_context ().add_class ("background");
        listbox.set_sort_func ((child1, child2) => {
            var comparison = ((Widgets.SourceItem)child1).location.collate (((Widgets.SourceItem)child2).location);
            if (comparison == 0)
                return ((Widgets.SourceItem)child1).label.collate (((Widgets.SourceItem)child2).label);
            else
                return comparison;
        });

        var listbox_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        listbox_box.hexpand = true;
        listbox_box.pack_start (listbox, false, false, 0);
        listbox_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);

        var revealer = new Gtk.Revealer ();
        revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
        revealer.add (listbox_box);
        revealer.reveal_child = Planner.settings.get_boolean ("calendar-enabled");

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.hexpand = true;

        box.pack_start (description_label, false, false, 0);
        box.pack_start (enabled_switch, false, true, 0);
        box.pack_start (revealer, false, true, 0);

        var box_scrolled = new Gtk.ScrolledWindow (null, null);
        box_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        box_scrolled.vscrollbar_policy = Gtk.PolicyType.EXTERNAL;
        box_scrolled.expand = true;
        box_scrolled.add (box);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        main_box.expand = true;

        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (box_scrolled, false, true, 0);

        Planner.calendar_model.get_all_sources.begin (listbox);

        top_box.back_activated.connect (() => {
            stack.visible_child_name = "home";
        });

        enabled_switch.activated.connect ((val) => {
            Planner.settings.set_boolean ("calendar-enabled", val);
        });

        Planner.settings.changed.connect ((key) => {
            if (key == "calendar-enabled") {
                revealer.reveal_child = Planner.settings.get_boolean ("calendar-enabled");
            }
        });

        return main_box;
    }

    private Gtk.Widget get_fund_widget () {
        var top_box = new PreferenceTopBox ("face-heart", _("Fund"));

        var description_label = new Gtk.Label (
            _("If you like Planner and you want to support its development, consider donating via:")
        );
        description_label.margin = 6;
        description_label.use_markup = true;
        description_label.margin_bottom = 12;
        description_label.margin_start = 12;
        description_label.margin_end = 12;
        description_label.justify = Gtk.Justification.FILL;
        description_label.wrap = true;
        description_label.xalign = 0;

        var paypal_icon = new Gtk.Image.from_resource ("/com/github/alainm23/planner/paypal.svg");

        var paypal_button = new Gtk.Button ();
        paypal_button.can_focus = false;
        paypal_button.get_style_context ().add_class ("flat");
        paypal_button.margin_start = paypal_button.margin_end = 12;
        paypal_button.image = paypal_icon;

        var patreon_icon = new Gtk.Image.from_resource ("/com/github/alainm23/planner/become_a_patron.svg");

        var patreon_button = new Gtk.Button ();
        patreon_button.can_focus = false;
        patreon_button.get_style_context ().add_class ("flat");
        patreon_button.margin_start = patreon_button.margin_end = 12;
        patreon_button.image = patreon_icon;

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.hexpand = true;

        box.pack_start (description_label, false, false, 0);
        box.pack_start (paypal_button, false, false, 12);
        box.pack_start (patreon_button, false, false, 6);

        var box_scrolled = new Gtk.ScrolledWindow (null, null);
        box_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        box_scrolled.vscrollbar_policy = Gtk.PolicyType.EXTERNAL;
        box_scrolled.expand = true;
        box_scrolled.add (box);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        main_box.expand = true;

        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (box_scrolled, false, true, 0);

        top_box.back_activated.connect (() => {
            stack.visible_child_name = "home";
        });

        paypal_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("https://www.paypal.me/alainm23", null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });

        patreon_button.clicked.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("https://www.patreon.com/alainm23", null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });

        return main_box;
    }

    private Gtk.Widget get_credits_widget () {
        var top_box = new PreferenceTopBox ("face-heart", _("Credits"));

        var description_label = new Gtk.Label (
            _("If you like Planner and you want to support its development, consider donating via:")
        );
        description_label.margin = 6;
        description_label.use_markup = true;
        description_label.margin_bottom = 12;
        description_label.margin_start = 12;
        description_label.margin_end = 12;
        description_label.justify = Gtk.Justification.FILL;
        description_label.wrap = true;
        description_label.xalign = 0;

        var listbox = new Gtk.ListBox ();
        listbox.activate_on_single_click = true;
        listbox.selection_mode = Gtk.SelectionMode.SINGLE;
        listbox.get_style_context ().add_class ("background");
        listbox.expand = true;

        var person_1 = new PreferencePerson ("Alain");
        var person_2 = new PreferencePerson ("Juan Aascas");
        var person_3 = new PreferencePerson ("Pedro Aascas Aaasc");

        listbox.add (person_1);
        listbox.add (person_2);
        listbox.add (person_3);
        listbox.show_all ();

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        box.hexpand = true;
        box.pack_start (description_label, false, false, 0);
        box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, false, 0);
        box.pack_start (listbox, false, true, 0);

        var box_scrolled = new Gtk.ScrolledWindow (null, null);
        box_scrolled.hscrollbar_policy = Gtk.PolicyType.NEVER;
        box_scrolled.vscrollbar_policy = Gtk.PolicyType.EXTERNAL;
        box_scrolled.expand = true;
        box_scrolled.add (box);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        main_box.expand = true;

        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (box_scrolled, false, true, 0);

        top_box.back_activated.connect (() => {
            stack.visible_child_name = "home";
        });

        return main_box;
    }

    private Gtk.Widget get_about_widget () {
        var top_box = new PreferenceTopBox ("office-calendar", _("About"));

        var app_icon = new Gtk.Image ();
        app_icon.gicon = new ThemedIcon ("com.github.alainm23.planner");
        app_icon.pixel_size = 64;
        app_icon.margin_top = 12;

        var app_name = new Gtk.Label ("Planner");
        app_name.get_style_context ().add_class ("h3");
        app_name.margin_top = 6;

        var version_label = new Gtk.Label (Constants.VERSION);
        version_label.get_style_context ().add_class ("dim-label");

        var web_item = new PreferenceItem ("web-browser", _("Homepage"));
        var issue_item = new PreferenceItem ("bug", _("Report a Problem"));
        var translation_item = new PreferenceItem ("config-language", _("Suggest Translations"), true);

        var grid = new Gtk.Grid ();
        grid.margin_top = 24;
        grid.valign = Gtk.Align.START;
        grid.get_style_context ().add_class ("view");
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        grid.add (web_item);
        grid.add (issue_item);
        grid.add (translation_item);
        grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.expand = true;

        main_box.pack_start (top_box, false, false, 0);
        main_box.pack_start (app_icon, false, true, 0);
        main_box.pack_start (app_name, false, true, 0);
        main_box.pack_start (version_label, false, true, 0);
        main_box.pack_start (grid, false, false, 0);

        top_box.back_activated.connect (() => {
            stack.visible_child_name = "home";
        });

        web_item.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("https://planner-todo.web.app", null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });

        issue_item.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri ("https://github.com/alainm23/planner/issues", null);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });

        translation_item.activated.connect (() => {
            try {
                AppInfo.launch_default_for_uri (
                    "https://github.com/alainm23/planner/tree/master/po#translating-planner", null
                );
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        });

        return main_box;
    }

    private void add_all_labels (Gtk.ListBox listbox, Gtk.ScrolledWindow scrolled) {
        foreach (Objects.Label label in Planner.database.get_all_labels ()) {
            var row = new Widgets.LabelRow (label, scrolled);
            listbox.add (row);
        }

        listbox.show_all ();
    }
}

public class PreferenceItemRadio : Gtk.RadioButton {
    public PreferenceItemRadio () {
        get_style_context ().add_class ("view");
    }
}

public class PreferenceItem : Gtk.EventBox {
    private Gtk.Image icon_image;
    private Gtk.Label title_label;

    public string _title;
    public string title {
        get {
            return _title;
        }

        set {
            _title = value;
            title_label.label = _title;
        }
    }

    public string _icon;
    public string icon {
        get {
            return _icon;
        }

        set {
            _icon = value;
            icon_image.gicon = new ThemedIcon (_icon);
        }
    }

    public bool last { get; construct; }

    public signal void activated ();

    public PreferenceItem (string icon, string title, bool last=false) {
        Object (
            icon: icon,
            title: title,
            last: last
        );
    }

    construct {
        icon_image = new Gtk.Image ();
        icon_image.pixel_size = 24;

        title_label = new Gtk.Label (null);
        title_label.get_style_context ().add_class ("h3");
        title_label.ellipsize = Pango.EllipsizeMode.END;
        title_label.halign = Gtk.Align.START;
        title_label.valign = Gtk.Align.CENTER;

        var button_icon = new Gtk.Image ();
        button_icon.gicon = new ThemedIcon ("pan-end-symbolic");
        button_icon.valign = Gtk.Align.CENTER;
        button_icon.pixel_size = 16;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.hexpand = true;
        box.margin = 6;
        box.margin_end = 12;
        box.pack_start (icon_image, false, false, 0);
        box.pack_start (title_label, false, false, 0);
        box.pack_end (button_icon, false, true, 0);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.margin_start = 32;

        if (last) {
            separator.visible = false;
            separator.no_show_all = true;
        }

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.add (box);
        main_box.add (separator);

        add (main_box);

        button_press_event.connect ((sender, evt) => {
            if (evt.type == Gdk.EventType.BUTTON_PRESS) {
                activated ();

                return true;
            }

            return false;
        });
    }
}

public class PreferenceTopBox : Gtk.Box {
    private Gtk.Button default_button;

    public signal void back_activated ();
    public signal void action_activated ();

    public string action_button {
        set {
            var image = new Gtk.Image ();
            image.gicon = new ThemedIcon (value);
            image.pixel_size = 16;

            default_button.image = image;
            default_button.visible = true;
        }
    }

    public PreferenceTopBox (string icon, string title) {
        var back_button = new Gtk.Button.from_icon_name ("arrow-back-symbolic", Gtk.IconSize.MENU);
        back_button.always_show_image = true;
        back_button.can_focus = false;
        back_button.label = _("Back");
        back_button.margin = 3;
        back_button.valign = Gtk.Align.CENTER;
        back_button.get_style_context ().add_class ("flat");
        back_button.get_style_context ().add_class ("dim-label");

        var title_button = new Gtk.Label (title);
        title_button.valign = Gtk.Align.CENTER;
        title_button.get_style_context ().add_class ("font-bold");
        title_button.get_style_context ().add_class ("h3");

        default_button = new Gtk.Button ();
        default_button.margin = 3;
        default_button.valign = Gtk.Align.CENTER;
        default_button.get_style_context ().add_class ("flat");
        default_button.get_style_context ().add_class ("dim-label");
        default_button.visible = false;
        default_button.no_show_all = true;

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        header_box.pack_start (back_button, false, false, 0);
        header_box.set_center_widget (title_button);
        header_box.pack_end (default_button, false, false, 0);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.hexpand = true;
        main_box.valign = Gtk.Align.START;
        main_box.pack_start (header_box);

        back_button.clicked.connect (() => {
            back_activated ();
        });

        default_button.clicked.connect (() => {
            action_activated ();
        });

        add (main_box);
    }
}

public class PreferenceItemSwitch : Gtk.EventBox {
    public signal void activated (bool active);

    public PreferenceItemSwitch (string title, bool active=false, bool visible_separator=true) {
        var title_label = new Gtk.Label (title);
        title_label.get_style_context ().add_class ("font-weight-600");

        var button_switch = new Gtk.Switch ();
        button_switch.valign = Gtk.Align.CENTER;
        button_switch.get_style_context ().add_class ("active-switch");
        button_switch.active = active;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.margin_start = 12;
        box.margin_end = 12;
        box.margin_top = 6;
        box.margin_bottom = 6;
        box.hexpand = true;
        box.pack_start (title_label, false, true, 0);
        box.pack_end (button_switch, false, true, 0);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.get_style_context ().add_class ("view");
        main_box.hexpand = true;
        main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);
        main_box.pack_start (box, false, true, 0);

        if (visible_separator == true) {
            main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);
        }

        button_switch.notify["active"].connect (() => {
            activated (button_switch.active);
        });

        add (main_box);
    }
}

public class PreferenceItemButton : Gtk.EventBox {
    public signal void activated ();
    public Gtk.Label title_label;

    public PreferenceItemButton (string title, string button_text, bool visible_separator=true) {
        title_label = new Gtk.Label (title);
        title_label.get_style_context ().add_class ("font-weight-600");

        var default_button = new Gtk.Button.with_label (button_text);
        default_button.can_focus = false;
        default_button.get_style_context ().add_class ("no-padding");
        default_button.valign = Gtk.Align.CENTER;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.margin_start = 12;
        box.margin_end = 12;
        box.margin_top = 6;
        box.margin_bottom = 6;
        box.hexpand = true;
        box.pack_start (title_label, false, true, 0);
        box.pack_end (default_button, false, true, 0);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.get_style_context ().add_class ("view");
        main_box.hexpand = true;
        main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);
        main_box.pack_start (box, false, true, 0);

        if (visible_separator == true) {
            main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);
        }

        default_button.clicked.connect (() => {
            activated ();
        });

        add (main_box);
    }
}

public class PreferenceItemSelect : Gtk.EventBox {
    public signal void activated (int active);

    public PreferenceItemSelect (string title, int active, List<string> items, bool visible_separator=true) {
        var title_label = new Gtk.Label (title);
        title_label.get_style_context ().add_class ("font-weight-600");

        var combobox = new Gtk.ComboBoxText ();
        combobox.can_focus = false;
        combobox.valign = Gtk.Align.CENTER;

        foreach (var item in items) {
            combobox.append_text (item);
        }

        combobox.active = active;

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        box.margin_start = 12;
        box.margin_end = 12;
        box.margin_top = 6;
        box.margin_bottom = 6;
        box.hexpand = true;
        box.pack_start (title_label, false, true, 0);
        box.pack_end (combobox, false, true, 0);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.get_style_context ().add_class ("view");
        main_box.hexpand = true;
        main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);
        main_box.pack_start (box, false, true, 0);

        if (visible_separator == true) {
            main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL), false, true, 0);
        }

        combobox.changed.connect (() => {
            activated (combobox.active);
        });

        add (main_box);
    }
}

public class ShortcutLabel : Gtk.Grid {
    public string[] accels { get; construct; }

    public ShortcutLabel (string[] accels) {
        Object (accels: accels);
    }

    construct {
        valign = Gtk.Align.CENTER;
        column_spacing = 6;

        update_accels (accels);
    }

    public void update_accels (string[] accels) {
        foreach (var child in this.get_children ()) {
            child.destroy ();
        }

        if (accels[0] != "") {
            foreach (unowned string accel in accels) {
                if (accel == "") {
                    continue;
                }
                var label = new Gtk.Label (accel);
                label.get_style_context ().add_class ("keycap");
                add (label);
            }
        } else {
            var label = new Gtk.Label (_("Disabled"));
            label.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);
            add (label);
        }

        show_all ();
    }
}

public class ShortcutRow : Gtk.ListBoxRow {
    public ShortcutRow (string name, string[] accels) {
        var name_label = new Gtk.Label (name);
        name_label.wrap = true;
        name_label.xalign = 0;
        name_label.get_style_context ().add_class ("font-weight-600");

        var shortcuts_labels = new ShortcutLabel (accels);

        var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.margin_start = 12;
        box.margin_top = 3;
        box.margin_bottom = 3;
        box.margin_end = 6;
        box.pack_start (name_label, false, true, 0);
        box.pack_end (shortcuts_labels, false, false, 0);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.pack_start (box);
        main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        add (main_box);
    }
}

public class PreferencePerson : Gtk.ListBoxRow {
    public string fullname { get; construct; }

    public PreferencePerson (string fullname) {
        Object (fullname: fullname);
    }

    construct {
        var avatar = new Granite.Widgets.Avatar.with_default_icon (24);
        avatar.margin_start = 6;

        var name_label = new Gtk.Label (fullname);
        name_label.get_style_context ().add_class ("h3");

        var grid = new Gtk.Grid ();
        grid.get_style_context ().add_class ("view");
        grid.column_spacing = 3;
        grid.add (avatar);
        grid.add (name_label);

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.pack_start (grid);
        main_box.pack_start (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));

        add (main_box);
    }
}
