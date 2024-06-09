# frozen_string_literal: true

require 'sqlite3'
require 'yaml'

module Database
  def self.initialize_database
    db = SQLite3::Database.new db_file
    create_tables(db)
    create_triggers(db)

    db.close
  end

  def self.db_file
    config = YAML.load_file('config.yml')
    config['db_file']
  end

  def self.create_tables(db)
    db.execute <<-SQL
        CREATE TABLE IF NOT EXISTS notes (
        id INTEGER PRIMARY KEY,
        title TEXT UNIQUE,
        discourse_url TEXT,
        discourse_post_id INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    SQL
  end

  def self.create_triggers(db)
    db.execute <<-SQL
        CREATE TRIGGER IF NOT EXISTS update_notes_updated_at
        AFTER UPDATE ON notes
        FOR EACH ROW
        WHEN NEW.updated_at <= OLD.updated_at
        BEGIN
          UPDATE notes SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
        END;
    SQL
  rescue SQLite3::SQLException => e
    puts "Trigger creation error: #{e.message}"
  end

  def self.get_discourse_post_id(title)
    db = SQLite3::Database.new db_file
    result = db.get_first_value(
      'SELECT discourse_post_id FROM notes WHERE title = ?', [title]
    )
    db.close
    result
  end

  def self.update_unadjusted_links(title, unadjusted)
    db = SQLite3::Database.new db_file
    db.execute('UPDATE notes SET unadjusted_links = ? WHERE title = ?',
               [unadjusted, title])
    db.close
  end

  def self.create_note(title:, discourse_url:, discourse_post_id:)
    db = SQLite3::Database.new db_file
    db.execute(create_note_sql, [title, discourse_url, discourse_post_id])
    db.close
  end

  def self.query_notes_by_title(title)
    db = SQLite3::Database.new db_file
    result = db.execute(
      'SELECT * FROM notes WHERE title = ?', [title]
    )
    db.close
    result
  end

  def self.create_note_sql
    <<-SQL
    INSERT INTO notes (title, discourse_url, discourse_post_id)
    VALUES (?, ?, ?)
    SQL
  end
end
