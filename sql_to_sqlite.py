import sqlite3
import os
import time
import logging

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
)
logger = logging.getLogger("sql_to_sqlite")

# Mapa de normalização de caracteres acentuados do Português para seus equivalentes ASCII.
# Cobre todas as vogais acentuadas e o ç.
_ACCENT_MAP = str.maketrans({
    'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
    'é': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ï': 'i',
    'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
    'ú': 'u', 'ü': 'u',
    'ç': 'c',
    'Á': 'A', 'À': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A',
    'É': 'E', 'Ê': 'E', 'Ë': 'E',
    'Í': 'I', 'Ï': 'I',
    'Ó': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
    'Ú': 'U', 'Ü': 'U',
    'Ç': 'C',
})

def normalize_portuguese(word):
    """Remove acentos de vogais e converte ç para c."""
    return word.translate(_ACCENT_MAP)

def parse_statement(statement):
    # Find the start of values
    idx = statement.find("VALUES (")
    if idx == -1:
        idx = statement.find("values (")
    
    # Start scanning from after 'VALUES ('
    cursor = idx + len("VALUES (")
    
    # Find the single-quoted string for 'words'
    # It must start with a single quote
    while cursor < len(statement) and statement[cursor] != "'":
        cursor += 1
    
    if cursor >= len(statement):
        raise ValueError("No starting quote found")
    
    cursor += 1 # Skip starting quote
    word_chars = []
    
    # Scan until the closing quote
    while cursor < len(statement):
        char = statement[cursor]
        if char == "'":
            # Check if it is an escaped quote (two single quotes)
            if cursor + 1 < len(statement) and statement[cursor + 1] == "'":
                word_chars.append("'")
                cursor += 2
                continue
            else:
                # Closing quote found!
                cursor += 1
                break
        else:
            word_chars.append(char)
            cursor += 1
            
    word = "".join(word_chars)
    # Clean up the word by removing newlines and carriage returns
    word = word.replace("\n", "").replace("\r", "")
    
    # Now find the id and is_target parameters
    # The remaining string looks like: ", 1990, false);"
    remaining = statement[cursor:].strip()
    if remaining.startswith(","):
        remaining = remaining[1:].strip()
        
    # Split by comma
    parts = remaining.split(",")
    # The first part after the comma is ID
    word_id = int(parts[0].strip())
    # The second part is is_target
    is_target_str = parts[1].split(")")[0].strip().lower()
    is_target = is_target_str == "true"
    
    return word, word_id, is_target

def parse_sql_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content_buffer = []
        
        for line in f:
            if line.startswith("INSERT INTO public.valid_words"):
                # If there's already an active insert in the buffer, parse and yield it
                if content_buffer:
                    statement = "".join(content_buffer)
                    try:
                        yield parse_statement(statement)
                    except Exception as e:
                        logger.error(
                            "Error parsing statement: %s... Error: %s",
                            statement[:100],
                            e,
                        )
                content_buffer = [line]
            else:
                if content_buffer:
                    content_buffer.append(line)
                    
        # Don't forget to parse the very last statement in the file
        if content_buffer:
            statement = "".join(content_buffer)
            try:
                yield parse_statement(statement)
            except Exception as e:
                logger.error(
                    "Error parsing last statement: %s... Error: %s",
                    statement[:100],
                    e,
                )

def main():
    sql_file_path = "assets/valid_words_rows.sql"
    sqlite_db_path = "assets/words.db"

    # Ensure assets directory exists
    os.makedirs(os.path.dirname(sqlite_db_path), exist_ok=True)

    # Delete existing SQLite DB if it exists
    if os.path.exists(sqlite_db_path):
        os.remove(sqlite_db_path)

    logger.info("Connecting to local SQLite database...")
    start_time = time.time()
    sl_conn = sqlite3.connect(sqlite_db_path)
    sl_cursor = sl_conn.cursor()

    # Create table with normalized column
    sl_cursor.execute("""
        CREATE TABLE valid_words (
            id INTEGER PRIMARY KEY,
            words TEXT NOT NULL,
            normalized TEXT NOT NULL,
            length INTEGER NOT NULL,
            is_target BOOLEAN NOT NULL
        )
    """)
    
    # Create indexes for extreme performance
    sl_cursor.execute("CREATE UNIQUE INDEX idx_words ON valid_words (words)")
    sl_cursor.execute("CREATE INDEX idx_normalized ON valid_words (normalized)")
    sl_cursor.execute("CREATE INDEX idx_length_target ON valid_words (length, is_target)")
    sl_conn.commit()

    logger.info("Parsing SQL dump and inserting into SQLite...")
    
    batch_size = 100000
    batch = []
    total_inserted = 0
    
    for word, word_id, is_target in parse_sql_file(sql_file_path):
        word_cleaned = word.strip().lower()
        length = len(word_cleaned)
        
        if length > 12:
            continue
        
        word_normalized = normalize_portuguese(word_cleaned)
        batch.append((word_id, word_cleaned, word_normalized, length, is_target))
        
        if len(batch) >= batch_size:
            sl_cursor.executemany(
                "INSERT OR IGNORE INTO valid_words (id, words, normalized, length, is_target) VALUES (?, ?, ?, ?, ?)",
                batch
            )
            sl_conn.commit()
            total_inserted += len(batch)
            logger.info("Inserted %d rows...", total_inserted)
            batch = []
            
    # Insert remaining rows
    if batch:
        sl_cursor.executemany(
            "INSERT OR IGNORE INTO valid_words (id, words, normalized, length, is_target) VALUES (?, ?, ?, ?, ?)",
            batch
        )
        sl_conn.commit()
        total_inserted += len(batch)
        logger.info("Inserted %d rows...", total_inserted)

    logger.info("Optimizing SQLite database...")
    sl_cursor.execute("VACUUM")
    sl_conn.commit()

    sl_cursor.close()
    sl_conn.close()

    duration = time.time() - start_time
    file_size = os.path.getsize(sqlite_db_path) / (1024 * 1024)
    logger.info(
        "Done! Processed and imported %d words to %s in %.2f seconds.",
        total_inserted,
        sqlite_db_path,
        duration,
    )
    logger.info("SQLite database file size: %.2f MB", file_size)

if __name__ == "__main__":
    main()
