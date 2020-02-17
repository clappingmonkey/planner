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

public class Services.Database : GLib.Object {
    private Sqlite.Database db;
    private string db_path;

    public signal void update_today_count (int items_0, int items_1);

    public signal void area_added (Objects.Area area);
    public signal void area_deleted (Objects.Area area);

    public signal void project_added (Objects.Project project);
    public signal void project_updated (Objects.Project project);
    public signal void project_deleted (int64 id);
    public signal void project_moved (Objects.Project project);
    public signal void update_project_count (int64 id, int items_0, int items_1);
    public signal void project_id_updated (int64 current_id, int64 new_id);

    public signal void subtract_task_counter (int64 id);

    public signal void section_added (Objects.Section section);
    public signal void section_deleted (Objects.Section section);
    public signal void section_updated (Objects.Section section);
    public signal void section_moved (Objects.Section section, int64 project_id, int64 old_project_id);
    public signal void section_id_updated (int64 current_id, int64 new_id);

    public signal void item_added (Objects.Item item);
    public signal void item_added_with_index (Objects.Item item, int index);
    public signal void item_updated (Objects.Item item);
    public signal void item_deleted (Objects.Item item);
    public signal void add_due_item (Objects.Item item);
    public signal void update_due_item (Objects.Item item);
    public signal void remove_due_item (Objects.Item item);
    public signal void item_label_added (int64 id, int64 item_id, Objects.Label label);
    public signal void item_label_deleted (int64 id, int64 item_id, Objects.Label label);
    public signal void item_completed (Objects.Item item);
    public signal void item_moved (Objects.Item item, int64 project_id, int64 old_project_id);
    public signal void item_section_moved (Objects.Item item, int64 section_id, int64 old_section_id);
    public signal void item_id_updated (int64 current_id, int64 new_id);

    public signal void label_added (Objects.Label label);
    public signal void label_deleted (Objects.Label label);
    public signal void label_updated (Objects.Label label);

    public signal void reminder_added (Objects.Reminder reminder);
    public signal void reminder_deleted (int64 id);

    public signal void check_project_count (int64 project_id);

    public signal void reset ();

    public Gee.ArrayList<Objects.Item?> items_to_delete;
    public signal void show_toast_delete (int count);
    public signal void show_undo_item (int64 id);

    public Database () {
        int rc = 0;
        db_path = Environment.get_user_data_dir () + "/com.github.alainm23.planner/database.db";

        if (create_tables () != Sqlite.OK) {
            stderr.printf ("Error creating db table: %d, %s\n", rc, db.errmsg ());
            Gtk.main_quit ();
        }

        rc = Sqlite.Database.open (db_path, out db);
        rc = db.exec ("PRAGMA foreign_keys = ON;");

        if (rc != Sqlite.OK) {
            stderr.printf ("Can't open database: %d, %s\n", rc, db.errmsg ());
            Gtk.main_quit ();
        }

        items_to_delete = new Gee.ArrayList<Objects.Item?> ();
    }

    public void patch_database () {
        //  if (Planner.database.column_exists ("Areas", "is_kanban") == false) {
        //        Planner.database.add_text_column ("Areas", "abc", "hola mundo");
        //  }

        //  if (Planner.database.column_exists ("Projects", "is_kanban") == false) {
        //      Planner.database.add_int_column ("Projects", "is_kanban", 0);
        //  }

        //  if (Planner.database.column_exists ("Areas", "aaaa") == false) {
        //      Planner.database.add_int_column ("Areas", "aaaa", 123);
        //  }

        //  if (Planner.database.column_exists ("Areas", "ascascascas") == false) {
        //      Planner.database.add_int64_column ("Areas", "ascascascas", 1234567890);
        //  }
    }

    public void reset_all () {
        File db_path = File.new_for_path (db_path);
        try {
            db_path.delete ();
        } catch (Error err) {
            warning (err.message);
        }

        // Log out Todoist
        Planner.todoist.log_out ();

        create_tables ();
        reset ();

        File directory = File.new_for_path (Planner.utils.AVATARS_FOLDER);
        try {
            var children = directory.enumerate_children ("", 0);
            FileInfo file_info;
            while ((file_info = children.next_file ()) != null) {
                FileUtils.remove (GLib.Path.build_filename (Planner.utils.AVATARS_FOLDER, file_info.get_name ()));
            }

            children.close ();
            children.dispose ();
        } catch (Error err) {
            warning (err.message);
        }

        directory.dispose ();
    }

    public bool add_item_to_delete (Objects.Item item) {
        if (items_to_delete.add (item)) {
            show_toast_delete (items_to_delete.size);
            return true;
        }

        return false;
    }

    public void remove_item_to_delete () {
        new Thread<void*> ("remove_item_to_delete", () => {
            foreach (var item in items_to_delete) {
                delete_item (item);
                if (item.is_todoist == 1) {
                    Planner.todoist.add_delete_item (item);
                }
            }

            items_to_delete.clear ();

            return null;
        });
    }

    public void clear_item_to_delete () {
        foreach (var item in items_to_delete) {
            show_undo_item (item.id);
        }

        items_to_delete.clear ();
    }

    private int create_tables () {
        int rc;
        string sql;

        rc = Sqlite.Database.open (db_path, out db);

        if (rc != Sqlite.OK) {
            stderr.printf ("Can't open database: %d, %s\n", rc, db.errmsg ());
            Gtk.main_quit ();
        }

        sql = """
            CREATE TABLE IF NOT EXISTS Areas (
                id              INTEGER PRIMARY KEY,
                name            TEXT,
                date_added      TEXT,
                collapsed       INTEGER,
                item_order      INTEGER
            );
        """;

        rc = db.exec (sql, null, null);
        debug ("Table Areas created");

        sql = """
            CREATE TABLE IF NOT EXISTS Projects (
                id               INTEGER PRIMARY KEY,
                area_id          INTEGER,
                name             TEXT NOT NULL,
                note             TEXT,
                due_date         TEXT,
                color            INTEGER,
                is_todoist       INTEGER,
                inbox_project    INTEGER,
                team_inbox       INTEGER,
                item_order       INTEGER,
                is_deleted       INTEGER,
                is_archived      INTEGER,
                is_favorite      INTEGER,
                is_sync          INTEGER,
                shared           INTEGER,
                is_kanban        INTEGER
            );
        """;

        rc = db.exec (sql, null, null);
        debug ("Table Projects created");

        sql = """
            CREATE TABLE IF NOT EXISTS Sections (
                id              INTEGER PRIMARY KEY,
                name            TEXT,
                project_id      INTEGER,
                item_order      INTEGER,
                collapsed       INTEGER,
                sync_id         INTEGER,
                is_deleted      INTEGER,
                is_archived     INTEGER,
                date_archived   TEXT,
                date_added      TEXT,
                is_todoist      INTEGER
            );
        """;

        rc = db.exec (sql, null, null);
        debug ("Table Sections created");

        sql = """
            CREATE TABLE IF NOT EXISTS Items (
                id                  INTEGER PRIMARY KEY,
                project_id          INTEGER,
                section_id          INTEGER,
                user_id             INTEGER,
                assigned_by_uid     INTEGER,
                responsible_uid     INTEGER,
                sync_id             INTEGER,
                parent_id           INTEGER,
                priority            INTEGER,
                item_order          INTEGER,
                checked             INTEGER,
                is_deleted          INTEGER,
                content             TEXT NOT NULL,
                note                TEXT,
                due_date            TEXT,
                due_timezone        TEXT,
                due_string          TEXT,
                due_lang            TEXT,
                due_is_recurring    INTEGER,
                date_added          TEXT,
                date_completed      TEXT,
                date_updated        TEXT,
                is_todoist          INTEGER
            );
        """;

        rc = db.exec (sql, null, null);
        debug ("Table Items created");

        sql = """
            CREATE TABLE IF NOT EXISTS Reminders (
                id                  INTEGER PRIMARY KEY,
                notify_uid          INTEGER,
                item_id             INTEGER,
                service             TEXT,
                type                TEXT,
                due_date            TEXT,
                due_timezone        TEXT,
                due_is_recurring    INTEGER,
                due_string          TEXT,
                due_lang            TEXT,
                mm_offset           INTEGER,
                is_deleted          INTEGER,
                is_todoist          INTEGER,
                FOREIGN KEY (item_id) REFERENCES Items (id) ON DELETE CASCADE
            );
        """;

        rc = db.exec (sql, null, null);
        debug ("Table Reminders created");

        sql = """
            CREATE TABLE IF NOT EXISTS Labels (
                id              INTEGER PRIMARY KEY,
                name            TEXT,
                color           INTEGER,
                item_order      INTEGER,
                is_deleted      INTEGER,
                is_favorite     INTEGER,
                is_todoist      INTEGER
            );
        """;

        rc = db.exec (sql, null, null);
        debug ("Table Labels created");

        sql = """
            CREATE TABLE IF NOT EXISTS Items_Labels (
                id              INTEGER PRIMARY KEY,
                item_id         INTEGER,
                label_id        INTEGER,
                CONSTRAINT unique_track UNIQUE (item_id, label_id),
                FOREIGN KEY (item_id) REFERENCES Items (id) ON DELETE CASCADE,
                FOREIGN KEY (label_id) REFERENCES Labels (id) ON DELETE CASCADE
            );
        """;

        rc = db.exec (sql, null, null);
        debug ("Table Labels created");

        sql = """
            CREATE TABLE IF NOT EXISTS Collaborators (
                id          INTEGER PRIMARY KEY,
                email       TEXT,
                full_name   TEXT,
                timezone    TEXT,
                image_id    TEXT
            );
        """;

        rc = db.exec (sql, null, null);
        debug ("Table Collaborators created");

        sql = """
            CREATE TABLE IF NOT EXISTS Collaborator_States (
                id                  INTEGER PRIMARY KEY AUTOINCREMENT,
                collaborators_id    INTEGER
                state               TEXT,
                user_id             INTEGER,
                is_deleted          INTEGER,
                project_id          INTEGER,
                FOREIGN KEY (collaborators_id) REFERENCES Collaborators (id) ON DELETE CASCADE
            );
        """;

        rc = db.exec (sql, null, null);
        debug ("Table Collaborator_States created");

        sql = """
            CREATE TABLE IF NOT EXISTS Queue (
                uuid       TEXT PRIMARY KEY,
                object_id  INTEGER,
                query      TEXT,
                temp_id    TEXT,
                args       TEXT,
                date_added TEXT
            );
        """;

        rc = db.exec (sql, null, null);
        debug ("Table Queue created");

        sql = """
            CREATE TABLE IF NOT EXISTS CurTempIds (
                id          INTEGER PRIMARY KEY,
                temp_id     TEXT,
                object      TEXT
            );
        """;

        rc = db.exec (sql, null, null);
        debug ("Table CurTempIds created");

        return rc;
    }

    public bool is_database_empty () {
        bool returned = false;
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT COUNT (*) FROM Projects", -1, out stmt);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            returned = stmt.column_int (0) <= 0;
        }

        return returned;
    }

    public void remove_trash () {
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("DELETE FROM Items WHERE NOT EXISTS (SELECT * FROM Projects WHERE Items.project_id = Projects.id)",
             -1, out stmt);
        assert (res == Sqlite.OK);

        stmt.step ();
    }

    public bool project_exists (int64 id) {
        bool returned = false;
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT COUNT (*) FROM Projects WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            returned = stmt.column_int (0) > 0;
        }

        return returned;
    }

    /*
        Queue
    */

    public bool insert_queue (Objects.Queue queue) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            INSERT OR IGNORE INTO Queue (uuid, object_id, query, temp_id, args, date_added)
            VALUES (?, ?, ?, ?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, queue.uuid);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, queue.object_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, queue.query);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (4, queue.temp_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (5, queue.args);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (6, queue.date_added);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            return true;
        }
    }

    public Objects.Queue get_queue_by_object_id (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Queue WHERE object_id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var queue = new Objects.Queue ();

        if (stmt.step () == Sqlite.ROW) {
            queue.uuid = stmt.column_text (0);
            queue.object_id = stmt.column_int64 (1);
            queue.query = stmt.column_text (2);
            queue.temp_id = stmt.column_text (3);
            queue.args = stmt.column_text (4);
            queue.date_added = stmt.column_text (4);
        }

        return queue;
    }

    public Gee.ArrayList<Objects.Queue?> get_all_queue () {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Queue ORDER BY date_added;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Queue?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var a = new Objects.Queue ();

            a.uuid = stmt.column_text (0);
            a.object_id = stmt.column_int64 (1);
            a.query = stmt.column_text (2);
            a.temp_id = stmt.column_text (3);
            a.args = stmt.column_text (4);
            a.date_added = stmt.column_text (4);

            all.add (a);
        }

        return all;
    }

    public void update_queue (Objects.Queue queue) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Queue SET object_id = ?, query = ?, temp_id = ?, args = ?
            WHERE uuid = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, queue.object_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, queue.query);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, queue.temp_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (4, queue.args);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (5, queue.uuid);
        assert (res == Sqlite.OK);

        res = stmt.step ();
    }

    public void remove_queue (string uuid) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            DELETE FROM Queue WHERE uuid = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, uuid);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
    }

    public void clear_queue () {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            DELETE FROM Queue;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
    }

    public bool insert_CurTempIds (int64 id, string temp_id, string object) { // vala-lint=naming-convention
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            INSERT OR IGNORE INTO CurTempIds (id, temp_id, object)
            VALUES (?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, temp_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, object);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            return true;
        }
    }

    public void remove_CurTempIds (int64 id) { // vala-lint=naming-convention
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            DELETE FROM CurTempIds WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
    }

    public void clear_cur_temp_ids () {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            DELETE FROM CurTempIds;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
    }

    public bool curTempIds_exists (int64 id) { // vala-lint=naming-convention
        bool returned = false;
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT COUNT (*) FROM CurTempIds WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            returned = stmt.column_int (0) > 0;
        }

        return returned;
    }

    public string get_temp_id (int64 id) {
        string returned = "";
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT temp_id FROM CurTempIds WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            returned = stmt.column_text (0);
        }

        return returned;
    }

    public bool column_exists (string table, string col) {
        Sqlite.Statement stmt;

        string sql = """
            SELECT * FROM %s LIMIT 1;
        """.printf (table);

        int res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            for (int i = 0; i < stmt.column_count (); i++) {
                if (stmt.column_name (i) == col) {
                    return true;
                }
            }
        }

        return false;
    }

    public void add_int_column (string table, string col, int default_value) {
        Sqlite.Statement stmt;
        int res;
        string sql;

        sql = """
            ALTER TABLE %s ADD COLUMN %s INTEGER DEFAULT %i;
        """.printf (table, col, default_value);

        print ("%s\n".printf (sql));

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
    }

    public void add_int64_column (string table, string col, int64 default_value) {
        Sqlite.Statement stmt;
        int res;
        string sql;

        sql = """
            ALTER TABLE %s ADD COLUMN %s INTEGER DEFAULT %s;
        """.printf (table, col, default_value.to_string ());

        print ("%s\n".printf (sql));

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
    }

    public void add_text_column (string table, string col, string default_value) {
        Sqlite.Statement stmt;
        int res;
        string sql;

        sql = """
            ALTER TABLE %s ADD COLUMN %s TEXT DEFAULT '%s';
        """.printf (table, col, default_value);

        print ("%s\n".printf (sql));

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }
    }

    /*
        Collaborators
    */

    public bool insert_collaborator (Objects.Collaborator collaborator) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            INSERT OR IGNORE INTO Collaborators (id, email, full_name, timezone, image_id)
            VALUES (?, ?, ?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, collaborator.id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, collaborator.email);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, collaborator.full_name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (5, collaborator.timezone);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (5, collaborator.image_id);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            //area_added (area);
            return true;
        }
    }

    /*
        Areas
    */

    public bool area_exists (int64 id) {
        bool returned = false;
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT COUNT (*) FROM Areas WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            returned = stmt.column_int (0) > 0;
        }

        return returned;
    }

    public bool insert_area (Objects.Area area) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT COUNT (*) FROM Areas;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            area.item_order = stmt.column_int (0);
        }

        stmt.reset ();

        sql = """
            INSERT OR IGNORE INTO Areas (id, name, date_added, collapsed, item_order)
            VALUES (?, ?, ?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, area.id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, area.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, area.date_added);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (5, area.collapsed);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (5, area.item_order);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            area_added (area);
            return true;
        }
    }

    public Gee.ArrayList<Objects.Area?> get_all_areas () {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Areas ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Area?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var a = new Objects.Area ();

            a.id = stmt.column_int64 (0);
            a.name = stmt.column_text (1);
            a.date_added = stmt.column_text (2);
            a.collapsed = stmt.column_int (3);
            a.item_order = stmt.column_int (4);

            all.add (a);
        }

        return all;
    }

    public bool update_area (Objects.Area area) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Areas SET name = ?, collapsed = ?, item_order = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, area.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (2, area.collapsed);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (3, area.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (4, area.id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.DONE) {
            return true;
        } else {
            return false;
        }
    }

    public bool delete_area (Objects.Area area) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            DELETE FROM Areas WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, area.id);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        }

        area_deleted (area);

        return true;
    }

    public Objects.Project create_inbox_project () {
        Sqlite.Statement stmt;
        string sql;
        int res;

        var project = new Objects.Project ();
        project.name = _("Inbox");
        project.id = Planner.utils.generate_id ();
        project.inbox_project = 1;

        sql = """
            INSERT OR IGNORE INTO Projects (id, name, inbox_project, area_id)
            VALUES (?, ?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, project.id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, project.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (3, project.inbox_project);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (4, project.area_id);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        }

        return project;
    }

    public void update_area_item_order (int64 area_id, int item_order) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Areas SET item_order = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, area_id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.DONE) {
            //updated_playlist (playlist);
        }
    }

    /*
        Projects
    */

    public bool insert_project (Objects.Project project) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT COUNT (*) FROM Projects WHERE area_id = 0;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            project.item_order = stmt.column_int (0);
        }

        stmt.reset ();

        sql = """
            INSERT OR IGNORE INTO Projects (id, area_id, name, note, due_date, color, 
                is_todoist, inbox_project, team_inbox, item_order, is_deleted, is_archived, 
                is_favorite, is_sync, shared)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, project.id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, project.area_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, project.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (4, project.note);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (5, project.due_date);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (6, project.color);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (7, project.is_todoist);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (8, project.inbox_project);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (9, project.team_inbox);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (10, project.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (11, project.is_deleted);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (12, project.is_archived);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (13, project.is_favorite);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (14, project.is_sync);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (15, project.shared);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            project_added (project);
            return true;
        }
    }

    public bool update_project (Objects.Project project) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Projects SET name = ?, note = ?, due_date = ?, color = ?, item_order = ?, 
            is_deleted = ?, is_archived = ?, is_favorite = ?, is_sync = ?, shared = ?, is_kanban = ?
            WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, project.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, project.note);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, project.due_date);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (4, project.color);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (5, project.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (6, project.is_deleted);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (7, project.is_archived);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (8, project.is_favorite);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (9, project.is_sync);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (10, project.shared);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (11, project.is_kanban);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (12, project.id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.DONE) {
            project_updated (project);
            return true;
        } else {
            return false;
        }
    }

    public void update_item_id (int64 current_id, int64 new_id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Items SET id = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, new_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, current_id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.DONE) {
            item_id_updated (current_id, new_id);

            stmt.reset ();

            sql = """
                UPDATE Items SET parent_id = ? WHERE parent_id = ?;
            """;

            res = db.prepare_v2 (sql, -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.bind_int64 (1, new_id);
            assert (res == Sqlite.OK);

            res = stmt.bind_int64 (2, current_id);
            assert (res == Sqlite.OK);

            res = stmt.step ();
        }
    }

    public void update_section_id (int64 current_id, int64 new_id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Sections SET id = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, new_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, current_id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.DONE) {
            section_id_updated (current_id, new_id);

            stmt.reset ();

            sql = """
                UPDATE Items SET section_id = ? WHERE section_id = ?;
            """;

            res = db.prepare_v2 (sql, -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.bind_int64 (1, new_id);
            assert (res == Sqlite.OK);

            res = stmt.bind_int64 (2, current_id);
            assert (res == Sqlite.OK);

            res = stmt.step ();
        }
    }

    public void update_project_id (int64 current_id, int64 new_id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Projects SET id = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, new_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, current_id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.DONE) {
            project_id_updated (current_id, new_id);

            stmt.reset ();

            sql = """
                UPDATE Sections SET project_id = ? WHERE project_id = ?;
            """;

            res = db.prepare_v2 (sql, -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.bind_int64 (1, new_id);
            assert (res == Sqlite.OK);

            res = stmt.bind_int64 (2, current_id);
            assert (res == Sqlite.OK);

            if (stmt.step () == Sqlite.DONE) {
                project_id_updated (current_id, new_id);

                stmt.reset ();

                sql = """
                    UPDATE Items SET project_id = ? WHERE project_id = ?;
                """;

                res = db.prepare_v2 (sql, -1, out stmt);
                assert (res == Sqlite.OK);

                res = stmt.bind_int64 (1, new_id);
                assert (res == Sqlite.OK);

                res = stmt.bind_int64 (2, current_id);
                assert (res == Sqlite.OK);

                res = stmt.step ();
            }
        }
    }

    public void delete_project (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            DELETE FROM Projects WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        } else {
            stmt.reset ();

            sql = """
                DELETE FROM Sections WHERE project_id = ?;
            """;

            res = db.prepare_v2 (sql, -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.bind_int64 (1, id);
            assert (res == Sqlite.OK);

            if (stmt.step () != Sqlite.DONE) {
                warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            } else {
                stmt.reset ();

                sql = """
                    DELETE FROM Items WHERE project_id = ?;
                """;

                res = db.prepare_v2 (sql, -1, out stmt);
                assert (res == Sqlite.OK);

                res = stmt.bind_int64 (1, id);
                assert (res == Sqlite.OK);

                res = stmt.step ();

                if (stmt.step () != Sqlite.DONE) {
                    warning ("Error: %d: %s", db.errcode (), db.errmsg ());
                } else {
                    project_deleted (id);
                }
            }
        }
    }

    public bool move_project (Objects.Project project, int64 area_id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        project.area_id = area_id;

        sql = """
            SELECT COUNT (*) FROM Projects WHERE area_id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, area_id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            project.item_order = stmt.column_int (0);
        }

        stmt.reset ();

        sql = """
            UPDATE Projects SET area_id = ?, item_order = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, area_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (2, project.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (3, project.id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.DONE) {
            project_moved (project);
            return true;
        } else {
            return false;
        }
    }

    public Gee.ArrayList<Objects.Project?> get_all_projects_by_area (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Projects WHERE area_id = ? ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Project?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var p = new Objects.Project ();

            p.id = stmt.column_int64 (0);
            p.area_id = stmt.column_int64 (1);
            p.name = stmt.column_text (2);
            p.note = stmt.column_text (3);
            p.due_date = stmt.column_text (4);
            p.color = stmt.column_int (5);
            p.is_todoist = stmt.column_int (6);
            p.inbox_project = stmt.column_int (7);
            p.team_inbox = stmt.column_int (8);
            p.item_order = stmt.column_int (9);
            p.is_deleted = stmt.column_int (10);
            p.is_archived = stmt.column_int (11);
            p.is_favorite = stmt.column_int (12);
            p.is_sync = stmt.column_int (13);
            p.shared = stmt.column_int (14);

            all.add (p);
        }

        return all;
    }

    public Gee.ArrayList<Objects.Project?> get_all_projects_by_todoist () {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Projects WHERE is_todoist = 1;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Project?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var p = new Objects.Project ();

            p.id = stmt.column_int64 (0);
            p.area_id = stmt.column_int64 (1);
            p.name = stmt.column_text (2);
            p.note = stmt.column_text (3);
            p.due_date = stmt.column_text (4);
            p.color = stmt.column_int (5);
            p.is_todoist = stmt.column_int (6);
            p.inbox_project = stmt.column_int (7);
            p.team_inbox = stmt.column_int (8);
            p.item_order = stmt.column_int (9);
            p.is_deleted = stmt.column_int (10);
            p.is_archived = stmt.column_int (11);
            p.is_favorite = stmt.column_int (12);
            p.is_sync = stmt.column_int (13);
            p.shared = stmt.column_int (14);

            all.add (p);
        }

        return all;
    }

    public bool projects_area_exists (int64 id) {
        bool returned = false;
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT COUNT (*) FROM Projects WHERE area_id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            returned = stmt.column_int (0) > 0;
        }

        return returned;
    }

    public Gee.ArrayList<Objects.Project?> get_all_projects () {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Projects ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Project?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var p = new Objects.Project ();

            p.id = stmt.column_int64 (0);
            p.area_id = stmt.column_int64 (1);
            p.name = stmt.column_text (2);
            p.note = stmt.column_text (3);
            p.due_date = stmt.column_text (4);
            p.color = stmt.column_int (5);
            p.is_todoist = stmt.column_int (6);
            p.inbox_project = stmt.column_int (7);
            p.team_inbox = stmt.column_int (8);
            p.item_order = stmt.column_int (9);
            p.is_deleted = stmt.column_int (10);
            p.is_archived = stmt.column_int (11);
            p.is_favorite = stmt.column_int (12);
            p.is_sync = stmt.column_int (13);
            p.shared = stmt.column_int (14);
            p.is_kanban = stmt.column_int (15);

            all.add (p);
        }

        return all;
    }

    public Gee.ArrayList<Objects.Project?> get_all_projects_by_search (string search_text) {
        Sqlite.Statement stmt;
        string sql;
        int res;
        string _search_text = "%" + search_text + "%";

        sql = """
            SELECT * FROM Projects WHERE name LIKE '%s' OR note LIKE '%s';
        """.printf (_search_text, _search_text);

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Project?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var p = new Objects.Project ();

            p.id = stmt.column_int64 (0);
            p.area_id = stmt.column_int64 (1);
            p.name = stmt.column_text (2);
            p.note = stmt.column_text (3);
            p.due_date = stmt.column_text (4);
            p.color = stmt.column_int (5);
            p.is_todoist = stmt.column_int (6);
            p.inbox_project = stmt.column_int (7);
            p.team_inbox = stmt.column_int (8);
            p.item_order = stmt.column_int (9);
            p.is_deleted = stmt.column_int (10);
            p.is_archived = stmt.column_int (11);
            p.is_favorite = stmt.column_int (12);
            p.is_sync = stmt.column_int (13);
            p.shared = stmt.column_int (14);
            p.is_kanban = stmt.column_int (15);

            all.add (p);
        }

        return all;
    }

    public Gee.ArrayList<Objects.Project?> get_all_projects_no_area () {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id, area_id, name, note, due_date, color, is_todoist, inbox_project, team_inbox, 
            item_order, is_deleted, is_archived, is_favorite, is_sync, shared, is_kanban
            FROM Projects WHERE inbox_project = 0 AND area_id = 0 ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Project?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var p = new Objects.Project ();

            p.id = stmt.column_int64 (0);
            p.area_id = stmt.column_int64 (1);
            p.name = stmt.column_text (2);
            p.note = stmt.column_text (3);
            p.due_date = stmt.column_text (4);
            p.color = stmt.column_int (5);
            p.is_todoist = stmt.column_int (6);
            p.inbox_project = stmt.column_int (7);
            p.team_inbox = stmt.column_int (8);
            p.item_order = stmt.column_int (9);
            p.is_deleted = stmt.column_int (10);
            p.is_archived = stmt.column_int (11);
            p.is_favorite = stmt.column_int (12);
            p.is_sync = stmt.column_int (13);
            p.shared = stmt.column_int (14);
            p.is_kanban = stmt.column_int (15);

            all.add (p);
        }

        return all;
    }

    public Objects.Project? get_project_by_id (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Projects WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var p = new Objects.Project ();

        if (stmt.step () == Sqlite.ROW) {
            p.id = stmt.column_int64 (0);
            p.area_id = stmt.column_int64 (1);
            p.name = stmt.column_text (2);
            p.note = stmt.column_text (3);
            p.due_date = stmt.column_text (4);
            p.color = stmt.column_int (5);
            p.is_todoist = stmt.column_int (6);
            p.inbox_project = stmt.column_int (7);
            p.team_inbox = stmt.column_int (8);
            p.item_order = stmt.column_int (9);
            p.is_deleted = stmt.column_int (10);
            p.is_archived = stmt.column_int (11);
            p.is_favorite = stmt.column_int (12);
            p.is_sync = stmt.column_int (13);
            p.shared = stmt.column_int (14);
            p.is_kanban = stmt.column_int (15);
        }

        return p;
    }

    public void update_project_item_order (int64 project_id, int64 area_id, int item_order) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Projects SET area_id = ?, item_order = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, area_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (2, item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (3, project_id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.DONE) {
            //updated_playlist (playlist);
        }
    }

    public void update_label_item_order (int64 id, int item_order) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Labels SET item_order = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.DONE) {
            //updated_playlist (playlist);
        }
    }

    public int get_project_count (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;
        int items_0 = 0;
        int items_1 = 0;

        sql = """
            SELECT checked, count(checked) FROM Items WHERE project_id = ? GROUP BY checked ORDER BY count (checked);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        while ((res = stmt.step ()) == Sqlite.ROW) {
            if (stmt.column_int (0) == 0) {
                items_0 = stmt.column_int (1);
            } else {
                items_1 = stmt.column_int (1);
            }
        }

        update_project_count (id, items_0, items_1);

        return items_0;
    }

    //public int get_parent_

    public int get_today_project_count (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;
        int returned = 0;

        sql = """
            SELECT id, due_date FROM Items WHERE project_id = ? AND due_date != '';
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var due = new GLib.DateTime.from_iso8601 (stmt.column_text (1), new GLib.TimeZone.local ());
            if (Planner.utils.is_today (due)) {
                returned++;
            }
        }

        return returned;
    }

    public int get_today_count () {
        Sqlite.Statement stmt;
        string sql;
        int res;
        int items_today = 0;
        int items_past = 0;

        sql = """
            SELECT due_date FROM Items WHERE checked = 0 AND due_date != '';
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var due = new GLib.DateTime.from_iso8601 (stmt.column_text (0), new GLib.TimeZone.local ());
            if (Planner.utils.is_today (due)) {
                items_today++;
            } else if (Planner.utils.is_past_day (due)) {
                items_past++;
            }
        }

        update_today_count (items_past, items_today);

        return items_today + items_past;
    }

    /*
        Labels
    */

    public bool insert_label (Objects.Label label) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            INSERT OR IGNORE INTO Labels (id, name, color, item_order, is_deleted, is_favorite)
            VALUES (?, ?, ?, ?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, label.id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, label.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (3, label.color);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (4, label.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (5, label.is_deleted);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (6, label.is_favorite);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.DONE) {
            label_added (label);
            return true;
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        }
    }

    public Gee.ArrayList<Objects.Label?> get_all_labels () {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Labels ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Label?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var l = new Objects.Label ();

            l.id = stmt.column_int64 (0);
            l.name = stmt.column_text (1);
            l.color = stmt.column_int (2);
            l.item_order = stmt.column_int (3);
            l.is_deleted = stmt.column_int (4);
            l.is_favorite = stmt.column_int (5);
            l.is_todoist = stmt.column_int (6);

            all.add (l);
        }

        return all;
    }

    public bool delete_label (Objects.Label label) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            DELETE FROM Labels WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, label.id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.DONE) {
            label_deleted (label);
            return true;
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        }
    }

    public bool update_label (Objects.Label label) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Labels SET name = ?, color = ?, item_order = ?, is_deleted = ?, 
            is_favorite = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, label.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (2, label.color);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (3, label.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (4, label.is_deleted);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (5, label.is_favorite);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (6, label.id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.DONE) {
            label_updated (label);
            return true;
        } else {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        }
    }

    /*
        Sections
    */

    public bool section_exists (int64 id) {
        bool returned = false;
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT COUNT (*) FROM Sections WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            returned = stmt.column_int (0) > 0;
        }

        return returned;
    }

    public bool insert_section (Objects.Section section) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        section.item_order = 0;

        sql = """
            INSERT OR IGNORE INTO Sections (id, name, project_id, item_order, collapsed, 
            sync_id, is_deleted, is_archived, date_archived, date_added, is_todoist)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, section.id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, section.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (3, section.project_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (4, section.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (5, section.collapsed);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (6, section.sync_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (7, section.is_deleted);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (8, section.is_archived);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (9, section.date_archived);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (10, section.date_added);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (11, section.is_todoist);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            section_added (section);
            return true;
        }
    }

    public Objects.Section get_section_by_id (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Sections WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var s = new Objects.Section ();

        if (stmt.step () == Sqlite.ROW) {
            s.id = stmt.column_int64 (0);
            s.name = stmt.column_text (1);
            s.project_id = stmt.column_int64 (2);
            s.item_order = stmt.column_int (3);
            s.collapsed = stmt.column_int (4);
            s.sync_id = stmt.column_int64 (5);
            s.is_deleted = stmt.column_int (6);
            s.is_archived = stmt.column_int (7);
            s.date_archived = stmt.column_text (8);
            s.date_added = stmt.column_text (9);
            s.is_todoist = stmt.column_int (10);
        }

        return s;
    }

    public Gee.ArrayList<Objects.Section?> get_all_sections_by_project (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Sections WHERE project_id = ? ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Section?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var s = new Objects.Section ();

            s.id = stmt.column_int64 (0);
            s.name = stmt.column_text (1);
            s.project_id = stmt.column_int64 (2);
            s.item_order = stmt.column_int (3);
            s.collapsed = stmt.column_int (4);
            s.sync_id = stmt.column_int64 (5);
            s.is_deleted = stmt.column_int (6);
            s.is_archived = stmt.column_int (7);
            s.date_archived = stmt.column_text (8);
            s.date_added = stmt.column_text (9);
            s.is_todoist = stmt.column_int (10);

            all.add (s);
        }

        return all;
    }

    public void update_section (Objects.Section section) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Sections SET name = ?, collapsed = ?, item_order = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, section.name);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (2, section.collapsed);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (3, section.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (4, section.id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.DONE) {
            section_updated (section);
        } else {
            print ("Error: %d: %s\n".printf (db.errcode (), db.errmsg ()));
        }
    }

    public void delete_section (Objects.Section section) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            DELETE FROM Sections WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, section.id);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        } else {
            stmt.reset ();

            sql = """
                DELETE FROM Items WHERE section_id = ?;
            """;

            res = db.prepare_v2 (sql, -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.bind_int64 (1, section.id);
            assert (res == Sqlite.OK);

            if (stmt.step () != Sqlite.DONE) {
                warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            } else {
                section_deleted (section);
            }
        }
    }

    public bool move_section (Objects.Section section, int64 project_id) {
        Sqlite.Statement stmt;
        string sql;
        int res;
        int64 old_project_id = section.project_id;

        sql = """
            UPDATE Sections SET project_id = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, project_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, section.id);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            section_moved (section, project_id, old_project_id);

            stmt.reset ();

            sql = """
                UPDATE Items SET project_id = ? WHERE section_id = ?;
            """;

            res = db.prepare_v2 (sql, -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.bind_int64 (1, project_id);
            assert (res == Sqlite.OK);

            res = stmt.bind_int64 (2, section.id);
            assert (res == Sqlite.OK);

            stmt.step ();

            return true;
        }
    }

    public void update_section_item_order (int64 section_id, int item_order) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Sections SET item_order = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, section_id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.DONE) {
            //updated_playlist (playlist);
        }
    }

    /*
        Items
    */

    public bool item_exists (int64 id) {
        bool returned = false;
        Sqlite.Statement stmt;

        int res = db.prepare_v2 ("SELECT COUNT (*) FROM Items WHERE id = ?", -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.ROW) {
            returned = stmt.column_int (0) > 0;
        }

        return returned;
    }

    public bool insert_item (Objects.Item item, int index=0, bool has_index=false) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        if (has_index == false) {
            sql = """
                SELECT COUNT (*) FROM Items WHERE project_id = ? AND section_id = ?;
            """;

            res = db.prepare_v2 (sql, -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.bind_int64 (1, item.project_id);
            assert (res == Sqlite.OK);

            res = stmt.bind_int64 (2, item.section_id);
            assert (res == Sqlite.OK);

            if (stmt.step () == Sqlite.ROW) {
                item.item_order = stmt.column_int (0);
            }

            stmt.reset ();
        } else {
            item.item_order = index;
        }

        sql = """
            INSERT OR IGNORE INTO Items (id, project_id, section_id, user_id, assigned_by_uid,
            responsible_uid, sync_id, parent_id, priority, item_order, checked,
            is_deleted, content, note, due_date, date_added, date_completed, date_updated, 
            due_timezone, due_string, due_lang, due_is_recurring, is_todoist)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, item.id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, item.project_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (3, item.section_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (4, item.user_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (5, item.assigned_by_uid);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (6, item.responsible_uid);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (7, item.sync_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (8, item.parent_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (9, item.priority);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (10, item.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (11, item.checked);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (12, item.is_deleted);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (13, item.content);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (14, item.note);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (15, item.due_date);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (16, item.date_added);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (17, item.date_completed);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (18, item.date_updated);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (19, item.due_timezone);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (20, item.due_string);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (21, item.due_lang);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (22, item.due_is_recurring);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (23, item.is_todoist);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            if (has_index) {
                item_added_with_index (item, index);
            } else {
                item_added (item);
            }

            return true;
        }
    }

    public bool update_item (Objects.Item item) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Items SET content = ?, note = ?, due_date = ?, is_deleted = ?, checked = ?, 
            item_order = ?, project_id = ?, section_id = ?, date_completed = ?, date_updated = ?
            WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, item.content);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, item.note);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, item.due_date);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (4, item.is_deleted);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (5, item.checked);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (6, item.item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (7, item.project_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (8, item.section_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (9, item.date_completed);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (10, item.date_updated);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (11, item.id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.DONE) {
            item_updated (item);
            return true;
        } else {
            return false;
        }
    }

    public Objects.Item? get_item_by_id (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id, project_id, section_id, user_id, assigned_by_uid, responsible_uid,
                sync_id, parent_id, priority, item_order, checked, is_deleted, content, note,
                due_date, date_added, date_completed, date_updated, is_todoist 
            FROM Items WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var i = new Objects.Item ();

        if (stmt.step () == Sqlite.ROW) {
            i.id = stmt.column_int64 (0);
            i.project_id = stmt.column_int64 (1);
            i.section_id = stmt.column_int64 (2);
            i.user_id = stmt.column_int64 (3);
            i.assigned_by_uid = stmt.column_int64 (4);
            i.responsible_uid = stmt.column_int64 (5);
            i.sync_id = stmt.column_int64 (6);
            i.parent_id = stmt.column_int64 (7);
            i.priority = stmt.column_int (8);
            i.item_order = stmt.column_int (9);
            i.checked = stmt.column_int (10);
            i.is_deleted = stmt.column_int (11);
            i.content = stmt.column_text (12);
            i.note = stmt.column_text (13);
            i.due_date = stmt.column_text (14);
            i.date_added = stmt.column_text (15);
            i.date_completed = stmt.column_text (16);
            i.date_updated = stmt.column_text (17);
            i.is_todoist = stmt.column_int (18);
        }

        return i;
    }

    public bool update_item_completed (Objects.Item item) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Items SET checked = ?, date_completed = ? WHERE id = ? OR parent_id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, item.checked);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (2, item.date_completed);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (3, item.id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (4, item.id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.DONE) {
            item_completed (item);
            return true;
        } else {
            return false;
        }
    }

    public void delete_item (Objects.Item item) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            DELETE FROM Items WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, item.id);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        } else {
            stmt.reset ();

            sql = """
                DELETE FROM Items WHERE parent_id = ?;
            """;

            res = db.prepare_v2 (sql, -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.bind_int64 (1, item.id);
            assert (res == Sqlite.OK);

            if (stmt.step () != Sqlite.DONE) {
                warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            } else {
                item_deleted (item);
            }
        }
    }

    public bool move_item (Objects.Item item, int64 project_id) {
        Sqlite.Statement stmt;
        string sql;
        int res;
        int64 old_project_id = item.project_id;
        item.section_id = 0;

        subtract_task_counter (old_project_id);

        sql = """
            UPDATE Items SET project_id = ?, section_id = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, project_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, 0);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (3, item.id);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            item_moved (item, project_id, old_project_id);

            stmt.reset ();

            sql = """
                UPDATE Items SET project_id = ? WHERE parent_id = ?;
            """;

            res = db.prepare_v2 (sql, -1, out stmt);
            assert (res == Sqlite.OK);

            res = stmt.bind_int64 (1, project_id);
            assert (res == Sqlite.OK);

            res = stmt.bind_int64 (2, item.id);
            assert (res == Sqlite.OK);

            stmt.step ();

            return true;
        }
    }

    public void update_item_order (Objects.Item item, int64 section_id, int item_order) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Items SET item_order = ?, section_id = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int (1, item_order);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, section_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (3, item.id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.DONE) {
            //updated_playlist (playlist);
        }
    }

    public bool set_due_item (Objects.Item item, bool new_date) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            UPDATE Items SET due_date = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (1, item.due_date);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, item.id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.DONE) {
            if (new_date) {
                add_due_item (item);
            } else {
                if (item.due_date == "") {
                    remove_due_item (item);
                } else {
                    update_due_item (item);
                }
            }

            return true;
        }

        return false;
    }

    public int get_count_items_by_project (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id FROM Items WHERE project_id = ? AND checked = 0;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var size = 0;
        while ((res = stmt.step ()) == Sqlite.ROW) {
            size++;
        }

        return size;
    }

    public int get_count_checked_items_by_project (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id FROM Items WHERE project_id = ? AND checked = 1;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var size = 0;
        while ((res = stmt.step ()) == Sqlite.ROW) {
            size++;
        }

        return size;
    }

    public int get_count_sections_by_project (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id FROM Sections WHERE project_id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var size = 0;
        while ((res = stmt.step ()) == Sqlite.ROW) {
            size++;
        }

        return size;
    }

    public Gee.ArrayList<Objects.Item?> get_all_completed_items_by_inbox (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id, project_id, section_id, user_id, assigned_by_uid, responsible_uid,
                sync_id, parent_id, priority, item_order, checked, is_deleted, content, note,
                due_date, date_added, date_completed, date_updated, is_todoist
            FROM Items WHERE project_id = ? AND checked = 1 ORDER BY date_completed;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Item?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var i = new Objects.Item ();

            i.id = stmt.column_int64 (0);
            i.project_id = stmt.column_int64 (1);
            i.section_id = stmt.column_int64 (2);
            i.user_id = stmt.column_int64 (3);
            i.assigned_by_uid = stmt.column_int64 (4);
            i.responsible_uid = stmt.column_int64 (5);
            i.sync_id = stmt.column_int64 (6);
            i.parent_id = stmt.column_int64 (7);
            i.priority = stmt.column_int (8);
            i.item_order = stmt.column_int (9);
            i.checked = stmt.column_int (10);
            i.is_deleted = stmt.column_int (11);
            i.content = stmt.column_text (12);
            i.note = stmt.column_text (13);
            i.due_date = stmt.column_text (14);
            i.date_added = stmt.column_text (15);
            i.date_completed = stmt.column_text (16);
            i.date_updated = stmt.column_text (17);
            i.is_todoist = stmt.column_int (18);

            all.add (i);
        }

        return all;
    }

    public Gee.ArrayList<Objects.Item?> get_all_completed_items_by_project (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id, project_id, section_id, user_id, assigned_by_uid, responsible_uid,
                sync_id, parent_id, priority, item_order, checked, is_deleted, content, note,
                due_date, date_added, date_completed, date_updated, is_todoist
            FROM Items WHERE project_id = ? AND checked = 1 AND parent_id = 0 ORDER BY date_completed;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Item?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var i = new Objects.Item ();

            i.id = stmt.column_int64 (0);
            i.project_id = stmt.column_int64 (1);
            i.section_id = stmt.column_int64 (2);
            i.user_id = stmt.column_int64 (3);
            i.assigned_by_uid = stmt.column_int64 (4);
            i.responsible_uid = stmt.column_int64 (5);
            i.sync_id = stmt.column_int64 (6);
            i.parent_id = stmt.column_int64 (7);
            i.priority = stmt.column_int (8);
            i.item_order = stmt.column_int (9);
            i.checked = stmt.column_int (10);
            i.is_deleted = stmt.column_int (11);
            i.content = stmt.column_text (12);
            i.note = stmt.column_text (13);
            i.due_date = stmt.column_text (14);
            i.date_added = stmt.column_text (15);
            i.date_completed = stmt.column_text (16);
            i.date_updated = stmt.column_text (17);
            i.is_todoist = stmt.column_int (18);

            all.add (i);
        }

        return all;
    }

    public Gee.ArrayList<Objects.Item?> get_all_items_by_project (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id, project_id, section_id, user_id, assigned_by_uid, responsible_uid,
                sync_id, parent_id, priority, item_order, checked, is_deleted, content, note,
                due_date, date_added, date_completed, date_updated, is_todoist
            FROM Items WHERE project_id = ? ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Item?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var i = new Objects.Item ();

            i.id = stmt.column_int64 (0);
            i.project_id = stmt.column_int64 (1);
            i.section_id = stmt.column_int64 (2);
            i.user_id = stmt.column_int64 (3);
            i.assigned_by_uid = stmt.column_int64 (4);
            i.responsible_uid = stmt.column_int64 (5);
            i.sync_id = stmt.column_int64 (6);
            i.parent_id = stmt.column_int64 (7);
            i.priority = stmt.column_int (8);
            i.item_order = stmt.column_int (9);
            i.checked = stmt.column_int (10);
            i.is_deleted = stmt.column_int (11);
            i.content = stmt.column_text (12);
            i.note = stmt.column_text (13);
            i.due_date = stmt.column_text (14);
            i.date_added = stmt.column_text (15);
            i.date_completed = stmt.column_text (16);
            i.date_updated = stmt.column_text (17);
            i.is_todoist = stmt.column_int (18);

            all.add (i);
        }

        return all;
    }

    public Gee.ArrayList<Objects.Item?> get_all_items_by_inbox (int64 id, int is_todoist) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id, project_id, section_id, user_id, assigned_by_uid, responsible_uid,
                sync_id, parent_id, priority, item_order, checked, is_deleted, content, note,
                due_date, date_added, date_completed, date_updated, is_todoist
            FROM Items WHERE project_id = ? AND section_id = 0 AND parent_id = 0 AND checked = 0 ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Item?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var i = new Objects.Item ();

            i.id = stmt.column_int64 (0);
            i.project_id = stmt.column_int64 (1);
            i.section_id = stmt.column_int64 (2);
            i.user_id = stmt.column_int64 (3);
            i.assigned_by_uid = stmt.column_int64 (4);
            i.responsible_uid = stmt.column_int64 (5);
            i.sync_id = stmt.column_int64 (6);
            i.parent_id = stmt.column_int64 (7);
            i.priority = stmt.column_int (8);
            i.item_order = stmt.column_int (9);
            i.checked = stmt.column_int (10);
            i.is_deleted = stmt.column_int (11);
            i.content = stmt.column_text (12);
            i.note = stmt.column_text (13);
            i.due_date = stmt.column_text (14);
            i.date_added = stmt.column_text (15);
            i.date_completed = stmt.column_text (16);
            i.date_updated = stmt.column_text (17);
            i.is_todoist = stmt.column_int (18);

            all.add (i);
        }

        return all;
    }

    public Gee.ArrayList<Objects.Item?> get_all_items_by_project_no_section_no_parent (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id, project_id, section_id, user_id, assigned_by_uid, responsible_uid,
                sync_id, parent_id, priority, item_order, checked, is_deleted, content, note,
                due_date, date_added, date_completed, date_updated, is_todoist
            FROM Items WHERE project_id = ? AND section_id = 0 AND parent_id = 0 AND checked = 0 ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Item?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var i = new Objects.Item ();

            i.id = stmt.column_int64 (0);
            i.project_id = stmt.column_int64 (1);
            i.section_id = stmt.column_int64 (2);
            i.user_id = stmt.column_int64 (3);
            i.assigned_by_uid = stmt.column_int64 (4);
            i.responsible_uid = stmt.column_int64 (5);
            i.sync_id = stmt.column_int64 (6);
            i.parent_id = stmt.column_int64 (7);
            i.priority = stmt.column_int (8);
            i.item_order = stmt.column_int (9);
            i.checked = stmt.column_int (10);
            i.is_deleted = stmt.column_int (11);
            i.content = stmt.column_text (12);
            i.note = stmt.column_text (13);
            i.due_date = stmt.column_text (14);
            i.date_added = stmt.column_text (15);
            i.date_completed = stmt.column_text (16);
            i.date_updated = stmt.column_text (17);
            i.is_todoist = stmt.column_int (18);

            all.add (i);
        }

        return all;
    }

    public Gee.ArrayList<Objects.Item?> get_all_items_by_project_no_section (Objects.Project project) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id, project_id, section_id, user_id, assigned_by_uid, responsible_uid,
                sync_id, parent_id, priority, item_order, checked, is_deleted, content, note,
                due_date, date_added, date_completed, date_updated, is_todoist
            FROM Items WHERE project_id = ? AND section_id = 0 ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, project.id);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Item?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var i = new Objects.Item ();

            i.id = stmt.column_int64 (0);
            i.project_id = stmt.column_int64 (1);
            i.section_id = stmt.column_int64 (2);
            i.user_id = stmt.column_int64 (3);
            i.assigned_by_uid = stmt.column_int64 (4);
            i.responsible_uid = stmt.column_int64 (5);
            i.sync_id = stmt.column_int64 (6);
            i.parent_id = stmt.column_int64 (7);
            i.priority = stmt.column_int (8);
            i.item_order = stmt.column_int (9);
            i.checked = stmt.column_int (10);
            i.is_deleted = stmt.column_int (11);
            i.content = stmt.column_text (12);
            i.note = stmt.column_text (13);
            i.due_date = stmt.column_text (14);
            i.date_added = stmt.column_text (15);
            i.date_completed = stmt.column_text (16);
            i.date_updated = stmt.column_text (17);
            i.is_todoist = stmt.column_int (18);

            all.add (i);
        }

        return all;
    }

    public Gee.ArrayList<Objects.Item?> get_all_items_by_section_no_parent (Objects.Section section) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id, project_id, section_id, user_id, assigned_by_uid, responsible_uid,
                sync_id, parent_id, priority, item_order, checked, is_deleted, content, note,
                due_date, date_added, date_completed, date_updated, is_todoist
            FROM Items WHERE section_id = ? AND parent_id = 0 AND checked = 0 ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, section.id);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Item?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var i = new Objects.Item ();

            i.id = stmt.column_int64 (0);
            i.project_id = stmt.column_int64 (1);
            i.section_id = stmt.column_int64 (2);
            i.user_id = stmt.column_int64 (3);
            i.assigned_by_uid = stmt.column_int64 (4);
            i.responsible_uid = stmt.column_int64 (5);
            i.sync_id = stmt.column_int64 (6);
            i.parent_id = stmt.column_int64 (7);
            i.priority = stmt.column_int (8);
            i.item_order = stmt.column_int (9);
            i.checked = stmt.column_int (10);
            i.is_deleted = stmt.column_int (11);
            i.content = stmt.column_text (12);
            i.note = stmt.column_text (13);
            i.due_date = stmt.column_text (14);
            i.date_added = stmt.column_text (15);
            i.date_completed = stmt.column_text (16);
            i.date_updated = stmt.column_text (17);
            i.is_todoist = stmt.column_int (18);

            all.add (i);
        }

        return all;
    }

    public Gee.ArrayList<Objects.Item?> get_all_items_by_section (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id, project_id, section_id, user_id, assigned_by_uid, responsible_uid,
                sync_id, parent_id, priority, item_order, checked, is_deleted, content, note,
                due_date, date_added, date_completed, date_updated, is_todoist
            FROM Items WHERE section_id = ? ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Item?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var i = new Objects.Item ();

            i.id = stmt.column_int64 (0);
            i.project_id = stmt.column_int64 (1);
            i.section_id = stmt.column_int64 (2);
            i.user_id = stmt.column_int64 (3);
            i.assigned_by_uid = stmt.column_int64 (4);
            i.responsible_uid = stmt.column_int64 (5);
            i.sync_id = stmt.column_int64 (6);
            i.parent_id = stmt.column_int64 (7);
            i.priority = stmt.column_int (8);
            i.item_order = stmt.column_int (9);
            i.checked = stmt.column_int (10);
            i.is_deleted = stmt.column_int (11);
            i.content = stmt.column_text (12);
            i.note = stmt.column_text (13);
            i.due_date = stmt.column_text (14);
            i.date_added = stmt.column_text (15);
            i.date_completed = stmt.column_text (16);
            i.date_updated = stmt.column_text (17);
            i.is_todoist = stmt.column_int (18);

            all.add (i);
        }

        return all;
    }

    public Gee.ArrayList<Objects.Item?> get_all_cheks_by_item (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id, project_id, section_id, user_id, assigned_by_uid, responsible_uid,
                sync_id, parent_id, priority, item_order, checked, is_deleted, content, note,
                due_date, date_added, date_completed, date_updated, is_todoist
            FROM Items WHERE parent_id = ? ORDER BY item_order;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Item?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var i = new Objects.Item ();

            i.id = stmt.column_int64 (0);
            i.project_id = stmt.column_int64 (1);
            i.section_id = stmt.column_int64 (2);
            i.user_id = stmt.column_int64 (3);
            i.assigned_by_uid = stmt.column_int64 (4);
            i.responsible_uid = stmt.column_int64 (5);
            i.sync_id = stmt.column_int64 (6);
            i.parent_id = stmt.column_int64 (7);
            i.priority = stmt.column_int (8);
            i.item_order = stmt.column_int (9);
            i.checked = stmt.column_int (10);
            i.is_deleted = stmt.column_int (11);
            i.content = stmt.column_text (12);
            i.note = stmt.column_text (13);
            i.due_date = stmt.column_text (14);
            i.date_added = stmt.column_text (15);
            i.date_completed = stmt.column_text (16);
            i.date_updated = stmt.column_text (17);
            i.is_todoist = stmt.column_int (18);

            all.add (i);
        }

        return all;
    }

    public Gee.ArrayList<Objects.Item?> get_all_today_items () {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Items WHERE checked = 0 AND due_date != '';
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Item?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var i = new Objects.Item ();

            i.id = stmt.column_int64 (0);
            i.project_id = stmt.column_int64 (1);
            i.section_id = stmt.column_int64 (2);
            i.user_id = stmt.column_int64 (3);
            i.assigned_by_uid = stmt.column_int64 (4);
            i.responsible_uid = stmt.column_int64 (5);
            i.sync_id = stmt.column_int64 (6);
            i.parent_id = stmt.column_int64 (7);
            i.priority = stmt.column_int (8);
            i.item_order = stmt.column_int (9);
            i.checked = stmt.column_int (10);
            i.is_deleted = stmt.column_int (11);
            i.content = stmt.column_text (12);
            i.note = stmt.column_text (13);
            i.due_date = stmt.column_text (14);
            i.date_added = stmt.column_text (15);
            i.date_completed = stmt.column_text (16);
            i.date_updated = stmt.column_text (17);
            i.is_todoist = stmt.column_int (18);

            var due = new GLib.DateTime.from_iso8601 (i.due_date, new GLib.TimeZone.local ());
            if (Planner.utils.is_today (due) || Planner.utils.is_past_day (due)) {
                all.add (i);
            }
        }

        return all;
    }

    public Gee.ArrayList<Objects.Item?> get_items_by_date (GLib.DateTime date) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT * FROM Items WHERE checked = 0;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Item?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var i = new Objects.Item ();

            i.id = stmt.column_int64 (0);
            i.project_id = stmt.column_int64 (1);
            i.section_id = stmt.column_int64 (2);
            i.user_id = stmt.column_int64 (3);
            i.assigned_by_uid = stmt.column_int64 (4);
            i.responsible_uid = stmt.column_int64 (5);
            i.sync_id = stmt.column_int64 (6);
            i.parent_id = stmt.column_int64 (7);
            i.priority = stmt.column_int (8);
            i.item_order = stmt.column_int (9);
            i.checked = stmt.column_int (10);
            i.is_deleted = stmt.column_int (11);
            i.content = stmt.column_text (12);
            i.note = stmt.column_text (13);
            i.due_date = stmt.column_text (14);
            i.date_added = stmt.column_text (15);
            i.date_completed = stmt.column_text (16);
            i.date_updated = stmt.column_text (17);
            i.is_todoist = stmt.column_int (18);

            if (i.due_date != "") {
                var due = new GLib.DateTime.from_iso8601 (i.due_date, new GLib.TimeZone.local ());
                if (Granite.DateTime.is_same_day (due, date)) {
                    all.add (i);
                }
            }
        }

        return all;
    }

    public Gee.ArrayList<Objects.Item?> get_items_by_search (string search_text) {
        Sqlite.Statement stmt;
        string sql;
        int res;
        string _search_text = "%" + search_text + "%";

        sql = """
            SELECT * FROM Items WHERE content LIKE '%s' OR note LIKE '%s';
        """.printf (_search_text, _search_text);

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Item?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var i = new Objects.Item ();

            i.id = stmt.column_int64 (0);
            i.project_id = stmt.column_int64 (1);
            i.section_id = stmt.column_int64 (2);
            i.user_id = stmt.column_int64 (3);
            i.assigned_by_uid = stmt.column_int64 (4);
            i.responsible_uid = stmt.column_int64 (5);
            i.sync_id = stmt.column_int64 (6);
            i.parent_id = stmt.column_int64 (7);
            i.priority = stmt.column_int (8);
            i.item_order = stmt.column_int (9);
            i.checked = stmt.column_int (10);
            i.is_deleted = stmt.column_int (11);
            i.content = stmt.column_text (12);
            i.note = stmt.column_text (13);
            i.due_date = stmt.column_text (14);
            i.date_added = stmt.column_text (15);
            i.date_completed = stmt.column_text (16);
            i.date_updated = stmt.column_text (17);
            i.is_todoist = stmt.column_int (18);

            all.add (i);
        }

        return all;
    }

    public bool add_item_label (int64 item_id, Objects.Label label) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        int64 id = Planner.utils.generate_id ();

        sql = """
            INSERT OR IGNORE INTO Items_Labels (id, item_id, label_id)
            VALUES (?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, item_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (3, label.id);
        assert (res == Sqlite.OK);

        if (stmt.step () == Sqlite.DONE) {
            item_label_added (id, item_id, label);
            return true;
        } else {
            return false;
        }
    }

    public Gee.ArrayList<Objects.Label?> get_labels_by_item (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT Items_Labels.id, Items_Labels.label_id, Labels.name, Labels.color FROM Items_Labels
            INNER JOIN Labels ON Items_Labels.label_id = Labels.id
            WHERE item_id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Label?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var l = new Objects.Label ();

            l.item_label_id = stmt.column_int64 (0);
            l.id = stmt.column_int64 (1);
            l.name = stmt.column_text (2);
            l.color = stmt.column_int (3);

            all.add (l);
        }

        return all;
    }

    public bool delete_item_label (int64 id, int64 item_id, Objects.Label label) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            DELETE FROM Items_Labels WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            item_label_deleted (id, item_id, label);
            return true;
        }
    }

    public void move_item_section (Objects.Item item, int64 section_id) {
        Sqlite.Statement stmt;
        string sql;
        int res;
        int64 old_section_id = item.section_id;

        sql = """
            UPDATE Items SET section_id = ? WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, section_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, item.id);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
        } else {
            item_section_moved (item, section_id, old_section_id);
        }
    }

    // Reminders
    public bool insert_reminder (Objects.Reminder reminder) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            INSERT OR IGNORE INTO Reminders (id, item_id, due_date)
            VALUES (?, ?, ?);
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, reminder.id);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (2, reminder.item_id);
        assert (res == Sqlite.OK);

        res = stmt.bind_text (3, reminder.due_date);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            reminder_added (reminder);
            return true;
        }
    }

    public Gee.ArrayList<Objects.Reminder?> get_reminders_by_item (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id, item_id, due_date FROM Reminders WHERE item_id = ? ORDER BY due_date;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Reminder?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var r = new Objects.Reminder ();

            r.id = stmt.column_int64 (0);
            r.item_id = stmt.column_int64 (1);
            r.due_date = stmt.column_text (2);

            all.add (r);
        }

        return all;
    }

    public Objects.Reminder? get_first_reminders_by_item (int64 id) {
        Objects.Reminder? returned = null;
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT id, item_id, due_date FROM Reminders WHERE item_id = ? ORDER BY due_date LIMIT 1;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        while (stmt.step () == Sqlite.ROW) {
            returned = new Objects.Reminder ();

            returned.id = stmt.column_int64 (0);
            returned.item_id = stmt.column_int64 (1);
            returned.due_date = stmt.column_text (2);
        }

        return returned;
    }

    public Gee.ArrayList<Objects.Reminder?> get_reminders () {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            SELECT Reminders.id, Reminders.item_id, Reminders.due_date, Items.content, Items.project_id FROM Reminders
            INNER JOIN Items ON Reminders.item_id = Items.id ORDER BY Reminders.due_date;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        var all = new Gee.ArrayList<Objects.Reminder?> ();

        while ((res = stmt.step ()) == Sqlite.ROW) {
            var r = new Objects.Reminder ();

            r.id = stmt.column_int64 (0);
            r.item_id = stmt.column_int64 (1);
            r.due_date = stmt.column_text (2);
            r.content = stmt.column_text (3);
            r.project_id = stmt.column_int64 (4);

            all.add (r);
        }

        return all;
    }

    public bool delete_reminder (int64 id) {
        Sqlite.Statement stmt;
        string sql;
        int res;

        sql = """
            DELETE FROM Reminders WHERE id = ?;
        """;

        res = db.prepare_v2 (sql, -1, out stmt);
        assert (res == Sqlite.OK);

        res = stmt.bind_int64 (1, id);
        assert (res == Sqlite.OK);

        if (stmt.step () != Sqlite.DONE) {
            warning ("Error: %d: %s", db.errcode (), db.errmsg ());
            return false;
        } else {
            reminder_deleted (id);
            return true;
        }
    }
}
