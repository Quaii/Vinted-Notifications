import sqlite3
import traceback
from logger import get_logger

logger = get_logger(__name__)


def get_db_connection():
    conn = sqlite3.connect("vinted_notifications.db")
    conn.execute("PRAGMA foreign_keys = ON")
    return conn

def migrate_db_if_needed():
    """Check if database needs migration and add missing columns/tables if needed"""
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Check if all required tables exist
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        existing_tables = [row[0] for row in cursor.fetchall()]
        
        # Create missing tables
        if 'queries' not in existing_tables:
            cursor.execute("CREATE TABLE queries (id INTEGER PRIMARY KEY AUTOINCREMENT, query TEXT, last_item NUMERIC, name TEXT)")
            logger.info("Database migrated: Created 'queries' table")
            
        if 'items' not in existing_tables:
            cursor.execute("CREATE TABLE items (item NUMERIC, title TEXT, price NUMERIC, currency TEXT, timestamp NUMERIC, photo_url TEXT, query_id INTEGER, FOREIGN KEY(query_id) REFERENCES queries(id))")
            logger.info("Database migrated: Created 'items' table")
            
        if 'allowlist' not in existing_tables:
            cursor.execute("CREATE TABLE allowlist (country TEXT)")
            logger.info("Database migrated: Created 'allowlist' table")
            
        if 'parameters' not in existing_tables:
            cursor.execute("CREATE TABLE parameters (key TEXT, value TEXT)")
            # Add default parameters
            default_params = [
                ("telegram_enabled", "False"),
                ("telegram_token", ""),
                ("telegram_chat_id", ""),
                ("telegram_process_running", "False"),
                ("rss_enabled", "False"),
                ("rss_port", "8080"),
                ("rss_max_items", "100"),
                ("rss_process_running", "False"),
                ("version", "1.0.1"),
                ("github_url", "https://github.com/Fuyucch1/Vinted-Notifications"),
                ("items_per_query", "20"),
                ("query_refresh_delay", "60"),
                ("dark_mode", "false"),
                ("proxy_list", ""),
                ("proxy_list_link", ""),
                ("check_proxies", "False"),
                ("last_proxy_check_time", "0")
            ]
            cursor.executemany("INSERT INTO parameters (key, value) VALUES (?, ?)", default_params)
            logger.info("Database migrated: Created 'parameters' table with default values")
        
        # Check for missing columns in other tables (run regardless of parameters table existence)
        # Check if name column exists in queries table
        cursor.execute("PRAGMA table_info(queries)")
        columns = [column[1] for column in cursor.fetchall()]
        
        if 'name' not in columns:
            # Add name column to queries table
            cursor.execute("ALTER TABLE queries ADD COLUMN name TEXT")
            logger.info("Database migrated: Added 'name' column to queries table")
        
        # Check if dark_mode parameter exists (only if parameters table exists)
        if 'parameters' in existing_tables:
            cursor.execute("SELECT value FROM parameters WHERE key = 'dark_mode'")
            result = cursor.fetchone()
            if not result:
                # Add dark_mode parameter
                cursor.execute("INSERT INTO parameters (key, value) VALUES (?, ?)", ("dark_mode", "false"))
                logger.info("Database migrated: Added 'dark_mode' parameter")
        
        # Add unique constraints to prevent duplicate entries
        # Check if unique constraint exists on items table
        cursor.execute("PRAGMA index_list(items)")
        indexes = [index[1] for index in cursor.fetchall()]
        if 'unique_item_query' not in indexes:
            try:
                cursor.execute("CREATE UNIQUE INDEX unique_item_query ON items(item, query_id)")
                logger.info("Database migrated: Added unique constraint to items table")
            except Exception as e:
                logger.warning(f"Could not add unique constraint to items table: {e}")
        
        # Check if unique constraint exists on parameters table
        cursor.execute("PRAGMA index_list(parameters)")
        indexes = [index[1] for index in cursor.fetchall()]
        if 'unique_parameter_key' not in indexes:
            try:
                cursor.execute("CREATE UNIQUE INDEX unique_parameter_key ON parameters(key)")
                logger.info("Database migrated: Added unique constraint to parameters table")
            except Exception as e:
                logger.warning(f"Could not add unique constraint to parameters table: {e}")
        
        conn.commit()
        return True
            
    except Exception as e:
        logger.error(f"Database migration failed: {str(e)}")
        logger.error("Full traceback:", exc_info=True)
        return False
    finally:
        if conn:
            conn.close()

def create_sqlite_db():
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        # Using proper foreign key relationship between items and queries
        cursor.execute("CREATE TABLE queries (id INTEGER PRIMARY KEY AUTOINCREMENT, query TEXT, last_item NUMERIC, name TEXT)")
        cursor.execute(
            "CREATE TABLE items (item NUMERIC, title TEXT, price NUMERIC, currency TEXT, timestamp NUMERIC, photo_url TEXT, query_id INTEGER, FOREIGN KEY(query_id) REFERENCES queries(id))")
        cursor.execute("CREATE TABLE allowlist (country TEXT)")
        # Add a parameters table
        cursor.execute("CREATE TABLE parameters (key TEXT, value TEXT)")
        
        # Add unique constraints to prevent duplicate entries
        cursor.execute("CREATE UNIQUE INDEX unique_item_query ON items(item, query_id)")
        cursor.execute("CREATE UNIQUE INDEX unique_parameter_key ON parameters(key)")
        # Telegram parameters
        cursor.execute("INSERT INTO parameters (key, value) VALUES (?, ?)", ("telegram_enabled", "False"))
        cursor.execute("INSERT INTO parameters (key, value) VALUES (?, ?)", ("telegram_token", ""))
        cursor.execute("INSERT INTO parameters (key, value) VALUES (?, ?)", ("telegram_chat_id", ""))
        cursor.execute("INSERT INTO parameters (key, value) VALUES (?, ?)", ("telegram_process_running", "False"))

        # RSS parameters
        cursor.execute("INSERT INTO parameters (key, value) VALUES (?, ?)", ("rss_enabled", "False"))
        cursor.execute("INSERT INTO parameters (key, value) VALUES (?, ?)", ("rss_port", "8080"))
        cursor.execute("INSERT INTO parameters (key, value) VALUES (?, ?)", ("rss_max_items", "100"))
        cursor.execute("INSERT INTO parameters (key, value) VALUES (?, ?)", ("rss_process_running", "False"))

        # Version of the bot
        cursor.execute("INSERT INTO parameters (key, value) VALUES (?, ?)", ("version", "1.0.1"))
        # GitHub URL
        cursor.execute("INSERT INTO parameters (key, value) VALUES (?, ?)",
                       ("github_url", "https://github.com/Fuyucch1/Vinted-Notifications"))

        # System parameters
        cursor.execute("INSERT INTO parameters (key, value) VALUES (?, ?)", ("items_per_query", "20"))
        cursor.execute("INSERT INTO parameters (key, value) VALUES (?, ?)", ("query_refresh_delay", "60"))
        cursor.execute("INSERT INTO parameters (key, value) VALUES (?, ?)", ("dark_mode", "false"))

        # Proxy parameters
        cursor.execute("INSERT INTO parameters (key, value) VALUES (?, ?)", ("proxy_list", ""))
        cursor.execute("INSERT INTO parameters (key, value) VALUES (?, ?)", ("proxy_list_link", ""))
        cursor.execute("INSERT INTO parameters (key, value) VALUES (?, ?)", ("check_proxies", "False"))
        cursor.execute("INSERT INTO parameters (key, value) VALUES (?, ?)", ("last_proxy_check_time", "0"))

        conn.commit()
        logger.info("Database created successfully with all tables and default parameters")
        return True
    except Exception as e:
        logger.error(f"Failed to create database: {str(e)}")
        logger.error("Full traceback:", exc_info=True)
        return False
    finally:
        if conn:
            conn.close()


def is_item_in_db_by_id(id):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT() FROM items WHERE item=?", (id,))
        count = cursor.fetchone()[0]
        return count > 0
    except Exception as e:
        logger.error(f"Failed to check if item {id} exists in database: {str(e)}")
        logger.error("Full traceback:", exc_info=True)
        return False
    finally:
        if conn:
            conn.close()


def get_last_timestamp(query_id):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT last_item FROM queries WHERE id=?", (query_id,))
        result = cursor.fetchone()
        if result:
            return result[0]
        return None
    except Exception as e:
        logger.error(f"Failed to get last timestamp for query {query_id}: {str(e)}")
        logger.error("Full traceback:", exc_info=True)
        return None
    finally:
        if conn:
            conn.close()


def update_last_timestamp(query_id, timestamp):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE queries SET last_item=? WHERE id=?", (timestamp, query_id))
        conn.commit()
        return True
    except Exception as e:
        logger.error(f"Failed to update timestamp for query {query_id}: {str(e)}")
        logger.error("Full traceback:", exc_info=True)
        return False
    finally:
        if conn:
            conn.close()


def add_item_to_db(id, title, query_id, price, timestamp, photo_url, currency="EUR"):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        # Insert into db the id and the query_id related to the item
        cursor.execute(
            "INSERT INTO items (item, title, price, currency, timestamp, photo_url, query_id) VALUES (?, ?, ?, ?, ?, ?, ?)",
            (id, title, price, currency, timestamp, photo_url, query_id))
        # Only update the last item timestamp if this item is newer than the current last_item
        cursor.execute("UPDATE queries SET last_item=? WHERE id=? AND (last_item IS NULL OR last_item < ?)", (timestamp, query_id, timestamp))
        conn.commit()
        return True
    except Exception as e:
        logger.error(f"Failed to add item {id} for query {query_id}: {str(e)}")
        logger.error("Full traceback:", exc_info=True)
        if conn:
            conn.rollback()
        return False
    finally:
        if conn:
            conn.close()

def get_queries():
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id, query, last_item, name FROM queries")
        return cursor.fetchall()
    except Exception as e:
        logger.error(f"Failed to get queries from database: {str(e)}")
        logger.error("Full traceback:", exc_info=True)
        return []
    finally:
        if conn:
            conn.close()


def is_query_in_db(processed_query):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        # replace spaces in searched_text by % to match any query containing the searched text

        cursor.execute("SELECT COUNT() FROM queries WHERE query = ?", (processed_query,))
        if cursor.fetchone()[0]:
            return True
        return False
    except Exception as e:
        logger.error(f"Failed to check if query exists in database: {str(e)}")
        logger.error("Full traceback:", exc_info=True)
        return False
    finally:
        if conn:
            conn.close()
            
def update_query_name(query_id, name):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("UPDATE queries SET name=? WHERE id=?", (name, query_id))
        conn.commit()
        return True
    except Exception as e:
        logger.error(f"Failed to update query name for query {query_id}: {str(e)}")
        logger.error("Full traceback:", exc_info=True)
        return False
    finally:
        if conn:
            conn.close()

def add_query_to_db(query, name=None):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO queries (query, last_item, name) VALUES (?, NULL, ?)", (query, name))
        conn.commit()
        return True
    except Exception as e:
        logger.error(f"Failed to add query to database: {str(e)}")
        logger.error("Full traceback:", exc_info=True)
        return False
    finally:
        if conn:
            conn.close()

def remove_query_from_db(query_number):
    conn = None
    try:
        # Validate query_number range
        total_queries = get_total_queries_count()
        if query_number < 1 or query_number > total_queries:
            logger.error(f"Invalid query number {query_number}. Must be between 1 and {total_queries}")
            return False
            
        conn = get_db_connection()
        cursor = conn.cursor()
        # Get the query and its ID based on the row number (SQLite compatible)
        query_string = "SELECT id, query, rowid FROM queries ORDER BY ROWID LIMIT 1 OFFSET ?"
        cursor.execute(query_string, (query_number - 1,))
        query_result = cursor.fetchone()
        if query_result:
            query_id, query_text, rowid = query_result
            # Delete items associated with this query using query_id
            cursor.execute("DELETE FROM items WHERE query_id=?", (query_id,))
            # Delete the query
            cursor.execute("DELETE FROM queries WHERE ROWID=?", (rowid,))
            conn.commit()
            return True
        else:
            logger.error(f"Query number {query_number} not found")
            return False
    except Exception as e:
        logger.error(f"Failed to remove query {query_number} from database: {str(e)}")
        logger.error("Full traceback:", exc_info=True)
        return False
    finally:
        if conn:
            conn.close()


def remove_all_queries_from_db():
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        # Delete all items first to maintain foreign key integrity
        cursor.execute("DELETE FROM items")
        # Then delete all queries
        cursor.execute("DELETE FROM queries")
        conn.commit()
        return True
    except Exception as e:
        logger.error(f"Failed to remove all queries from database: {str(e)}")
        logger.error("Full traceback:", exc_info=True)
        return False
    finally:
        if conn:
            conn.close()


def add_to_allowlist(country):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("INSERT INTO allowlist VALUES (?)", (country,))
        conn.commit()
        return True
    except Exception as e:
        logger.error(f"Failed to add country {country} to allowlist: {str(e)}")
        logger.error("Full traceback:", exc_info=True)
        return False
    finally:
        if conn:
            conn.close()

def remove_from_allowlist(country):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM allowlist WHERE country=?", (country,))
        conn.commit()
        return True
    except Exception as e:
        logger.error(f"Failed to remove country {country} from allowlist: {str(e)}")
        logger.error("Full traceback:", exc_info=True)
        return False
    finally:
        if conn:
            conn.close()

def get_allowlist():
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM allowlist")
        # Get list of countries
        countries = [country[0] for country in cursor.fetchall()]
        # Always return a list for consistency
        return countries
    except Exception as e:
        logger.error(f"Failed to get allowlist from database: {str(e)}")
        logger.error("Full traceback:", exc_info=True)
        return []
    finally:
        if conn:
            conn.close()


def clear_allowlist():
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("DELETE FROM allowlist")
        conn.commit()
        return True
    except Exception as e:
        logger.error(f"Failed to clear allowlist: {str(e)}")
        logger.error("Full traceback:", exc_info=True)
        return False
    finally:
        if conn:
            conn.close()


def get_parameter(key):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT value FROM parameters WHERE key=?", (key,))
        result = cursor.fetchone()
        return result[0] if result else None
    except Exception as e:
        logger.error(f"Failed to get parameter {key} from database: {str(e)}")
        logger.error("Full traceback:", exc_info=True)
        return None
    finally:
        if conn:
            conn.close()


def set_parameter(key, value):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        # Check if parameter exists
        cursor.execute("SELECT COUNT(*) FROM parameters WHERE key=?", (key,))
        exists = cursor.fetchone()[0] > 0
        
        if exists:
            cursor.execute("UPDATE parameters SET value=? WHERE key=?", (value, key))
        else:
            cursor.execute("INSERT INTO parameters (key, value) VALUES (?, ?)", (key, value))
        
        conn.commit()
        return True
    except Exception as e:
        logger.error(f"Failed to set parameter {key} to {value}: {str(e)}")
        logger.error("Full traceback:", exc_info=True)
        return False
    finally:
        if conn:
            conn.close()


def get_all_parameters():
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT key, value FROM parameters")
        return dict(cursor.fetchall())
    except Exception as e:
        logger.error(f"Failed to get all parameters: {e}")
        logger.error(traceback.format_exc())
        return {}
    finally:
        if conn:
            conn.close()


def get_items(limit=50, query=None, sort_by="newest"):
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Whitelist of allowed sort options to prevent SQL injection
        allowed_sorts = {
            "oldest": "ORDER BY i.timestamp ASC",
            "newest": "ORDER BY i.timestamp DESC",
            "price_asc": "ORDER BY i.price ASC",
            "price_desc": "ORDER BY i.price DESC"
        }
        
        # Use whitelist to get safe ORDER BY clause
        order_clause = allowed_sorts.get(sort_by, "ORDER BY i.timestamp DESC")
        
        if query:
            # Get the query_id for the given query
            cursor.execute("SELECT id FROM queries WHERE query=?", (query,))
            result = cursor.fetchone()
            if result:
                query_id = result[0]
                # Get items with the matching query_id
                cursor.execute(
                    f"SELECT i.item, i.title, i.price, i.currency, i.timestamp, q.query, i.photo_url FROM items i JOIN queries q ON i.query_id = q.id WHERE i.query_id=? {order_clause} LIMIT ?",
                    (query_id, limit))
            else:
                return []
        else:
            # Join with queries table to get the query text
            cursor.execute(
                f"SELECT i.item, i.title, i.price, i.currency, i.timestamp, q.query, i.photo_url FROM items i JOIN queries q ON i.query_id = q.id {order_clause} LIMIT ?",
                (limit,))
        return cursor.fetchall()
    except Exception as e:
        logger.error(f"Failed to get items: {e}")
        logger.error(traceback.format_exc())
        return []
    finally:
        if conn:
            conn.close()


def get_total_items_count():
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM items")
        return cursor.fetchone()[0]
    except Exception as e:
        logger.error(f"Failed to get total items count: {e}")
        logger.error(traceback.format_exc())
        return 0
    finally:
        if conn:
            conn.close()


def get_total_queries_count():
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM queries")
        return cursor.fetchone()[0]
    except Exception as e:
        logger.error(f"Failed to get total queries count: {e}")
        logger.error(traceback.format_exc())
        return 0
    finally:
        if conn:
            conn.close()


def export_queries_to_json():
    """
    Export all queries to a JSON format
    Returns a list of dictionaries with query information
    """
    import json
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute("SELECT id, query, name FROM queries")
        queries = cursor.fetchall()
        
        result = []
        for query in queries:
            result.append({
                "id": query[0],
                "query": query[1],
                "name": query[2]
            })
        return json.dumps(result)
    except Exception as e:
        logger.error(f"Failed to export queries to JSON: {e}")
        logger.error(traceback.format_exc())
        return json.dumps({"error": str(e)})
    finally:
        if conn:
            conn.close()


def import_queries_from_json(json_data):
    """
    Import queries from JSON format
    Returns tuple (success, message)
    """
    import json
    conn = None
    try:
        # Parse JSON data
        queries = json.loads(json_data)
        
        # Validate data structure
        if not isinstance(queries, list):
            return False, "Invalid JSON format: expected a list of queries"
        
        # Connect to database
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Track statistics
        added = 0
        skipped = 0
        
        # Process each query
        for query_data in queries:
            # Validate query data
            if not isinstance(query_data, dict):
                continue
                
            query = query_data.get("query")
            name = query_data.get("name")
            
            if not query:
                continue
                
            # Check if query already exists
            if is_query_in_db(query):
                skipped += 1
                continue
                
            # Add query to database
            cursor.execute("INSERT INTO queries (query, last_item, name) VALUES (?, NULL, ?)", 
                          (query, name))
            added += 1
            
        conn.commit()
        return True, f"Import complete: {added} queries added, {skipped} skipped"
    except json.JSONDecodeError:
        return False, "Invalid JSON format"
    except Exception as e:
        logger.error(f"Failed to import queries from JSON: {e}")
        logger.error(traceback.format_exc())
        return False, f"Error importing queries: {str(e)}"
    finally:
        if conn:
            conn.close()


def get_last_found_item():
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute(
            "SELECT i.item, i.title, i.price, i.currency, i.timestamp, q.query, i.photo_url FROM items i JOIN queries q ON i.query_id = q.id ORDER BY i.timestamp DESC LIMIT 1")
        return cursor.fetchone()
    except Exception as e:
        logger.error(f"Failed to get last found item: {e}")
        logger.error(traceback.format_exc())
        return None
    finally:
        if conn:
            conn.close()


def get_items_per_day():
    conn = None
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        # Get total items
        cursor.execute("SELECT COUNT(*) FROM items")
        total_items = cursor.fetchone()[0]

        if total_items == 0:
            return 0

        # Get earliest and latest timestamps
        cursor.execute("SELECT MIN(timestamp), MAX(timestamp) FROM items")
        min_timestamp, max_timestamp = cursor.fetchone()

        # Calculate number of days (add 1 to include both start and end days)
        import datetime
        min_date = datetime.datetime.fromtimestamp(min_timestamp).date()
        max_date = datetime.datetime.fromtimestamp(max_timestamp).date()
        days_diff = (max_date - min_date).days + 1

        # Ensure at least 1 day to avoid division by zero
        days_diff = max(1, days_diff)

        # Calculate items per day
        return round(total_items / days_diff, 1)
    except Exception as e:
        logger.error(f"Failed to get items per day: {e}")
        logger.error(traceback.format_exc())
        return 0
    finally:
        if conn:
            conn.close()
