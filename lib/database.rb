# frozen_string_literal: true

require 'sqlite3'
require 'yaml'

module Database
  def self.initialize_database
    config = YAML.load_file('config.yml')
    db = SQLite3::Database.new config['db_file']
    create_tables(db)
    create_triggers(db)
  end

  def self.create_tables(db)
    db.execute <<-SQL
        CREATE TABLE IF NOT EXISTS notes (
        id INTEGER PRIMARY KEY,
        title TEXT UNIQUE,
        discourse_url TEXT,
        discourse_post_id INTEGER,
        unadjusted_links BOOLEAN DEFAULT 0,
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

  # example queries, remove if unused
  def self.get_discourse_url(title)
    db = SQLite3::Database.new DB_FILE
    result = db.get_first_value(
      'SELECT discourse_url FROM notes WHERE title = ?', title
    )
    db.close
    result
  end

  def self.update_unadjusted_links(title, unadjusted)
    db = SQLite3::Database.new DB_FILE
    db.execute('UPDATE notes SET unadjusted_links = ? WHERE title = ?',
               [unadjusted, title])
    db.close
  end
end
