#!/usr/bin/env node
/**
 * scripts/apply-db.js
 * Restores or initializes the SQLite database from data/init_data.sql.
 * 
 * Usage:
 *   node scripts/apply-db.js [--force] [--sql data/init_data.sql] [--db data/hr.db]
 */

const fs = require('fs');
const path = require('path');
const readline = require('readline');

// Parse CLI args
const args = process.argv.slice(2);
const force = args.includes('--force') || args.includes('-f') || args.includes('--yes') || args.includes('-y');

function getArgValue(name, defaultVal) {
  const idx = args.indexOf(name);
  if (idx !== -1 && idx + 1 < args.length) {
    return args[idx + 1];
  }
  return defaultVal;
}

const rootDir = path.resolve(__dirname, '..');
const defaultDbPath = process.env.DATABASE_PATH || path.join(rootDir, 'data', 'hr.db');
const dbPath = path.resolve(rootDir, getArgValue('--db', defaultDbPath));
const defaultSqlPath = path.join(rootDir, 'data', 'init_data.sql');
const sqlPath = path.resolve(rootDir, getArgValue('--sql', defaultSqlPath));

async function confirmPrompt(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
  });
  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim().toLowerCase());
    });
  });
}

async function main() {
  console.log('----------------------------------------------------');
  console.log('   PulseHR - SQLite Database Initialization & Restore');
  console.log('----------------------------------------------------');
  console.log(`[INFO] Target DB Path : ${dbPath}`);
  console.log(`[INFO] Source SQL File: ${sqlPath}`);

  if (!fs.existsSync(sqlPath)) {
    console.error(`[ERROR] SQL file not found at: ${sqlPath}`);
    process.exit(1);
  }

  // Ensure target directory exists
  const targetDir = path.dirname(dbPath);
  if (!fs.existsSync(targetDir)) {
    fs.mkdirSync(targetDir, { recursive: true });
    console.log(`[INFO] Created directory: ${targetDir}`);
  }

  let dbExists = fs.existsSync(dbPath);
  let hasData = false;

  if (dbExists) {
    try {
      const Database = require('better-sqlite3');
      const testDb = new Database(dbPath, { readonly: true });
      const tableCount = testDb.prepare("SELECT count(*) as c FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").get().c;
      if (tableCount > 0) {
        hasData = true;
      }
      testDb.close();
    } catch (e) {
      // If error opening, db might be 0 bytes or corrupted
    }
  }

  if (hasData && !force) {
    console.log(`\n[WARN] An existing database with tables was detected at:\n       ${dbPath}`);
    const ans = await confirmPrompt('Are you sure you want to overwrite it with initial data? (y/N): ');
    if (ans !== 'y' && ans !== 'yes') {
      console.log('[INFO] Operation cancelled. Existing database remains untouched.');
      process.exit(0);
    }
  }

  // If existing DB has data, create a safety backup first
  if (dbExists && fs.statSync(dbPath).size > 0) {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupPath = `${dbPath}.bak.${timestamp}`;
    try {
      fs.copyFileSync(dbPath, backupPath);
      console.log(`[INFO] Created safety backup: ${backupPath}`);
    } catch (err) {
      console.warn(`[WARN] Could not create backup: ${err.message}`);
    }

    // Clean up old DB file and WAL/SHM sidecars
    try {
      fs.unlinkSync(dbPath);
      if (fs.existsSync(`${dbPath}-wal`)) fs.unlinkSync(`${dbPath}-wal`);
      if (fs.existsSync(`${dbPath}-shm`)) fs.unlinkSync(`${dbPath}-shm`);
    } catch (err) {
      console.warn(`[WARN] Could not remove old db files: ${err.message}`);
    }
  }

  console.log('[INFO] Applying SQL data...');
  const Database = require('better-sqlite3');
  const db = new Database(dbPath);

  try {
    db.pragma('foreign_keys = OFF');
    const sql = fs.readFileSync(sqlPath, 'utf8');
    db.exec(sql);
    db.pragma('foreign_keys = ON');
    db.pragma('journal_mode = WAL');
    db.pragma('wal_checkpoint(TRUNCATE)');

    console.log('\n[SUCCESS] Database data successfully applied!');
    console.log('\n--- Applied Database Summary ---');
    const tables = db.prepare("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name").all();
    for (const t of tables) {
      const rowCount = db.prepare(`SELECT count(*) as count FROM "${t.name}"`).get().count;
      console.log(` - ${t.name.padEnd(25)}: ${rowCount} rows`);
    }
    console.log('--------------------------------\n');
  } catch (err) {
    console.error(`[ERROR] Failed to apply database SQL:`, err);
    process.exit(1);
  } finally {
    db.close();
  }
}

main().catch((err) => {
  console.error('[ERROR] Unexpected error:', err);
  process.exit(1);
});
