#!/usr/bin/env node
/**
 * scripts/dump-db.js
 * Dumps current SQLite database tables and rows to an SQL script (data/init_data.sql).
 * 
 * Usage:
 *   node scripts/dump-db.js [--db data/hr.db] [--out data/init_data.sql]
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const args = process.argv.slice(2);
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
const defaultOutPath = path.join(rootDir, 'data', 'init_data.sql');
const outPath = path.resolve(rootDir, getArgValue('--out', defaultOutPath));

console.log('----------------------------------------------------');
console.log('   PulseHR - SQLite Database Dump / Export');
console.log('----------------------------------------------------');
console.log(`[INFO] Source DB : ${dbPath}`);
console.log(`[INFO] Output SQL: ${outPath}`);

if (!fs.existsSync(dbPath)) {
  console.error(`[ERROR] Database file not found at: ${dbPath}`);
  process.exit(1);
}

// 1. Ensure WAL is checkpointed cleanly
try {
  const Database = require('better-sqlite3');
  const db = new Database(dbPath);
  db.pragma('wal_checkpoint(TRUNCATE)');
  db.close();
  console.log('[INFO] SQLite WAL checkpointed successfully.');
} catch (e) {
  console.warn(`[WARN] WAL checkpoint warning: ${e.message}`);
}

// 2. Dump via sqlite3 CLI if available, else via node export
let dumped = false;
try {
  execSync(`sqlite3 "${dbPath}" .dump > "${outPath}"`, { stdio: 'inherit' });
  dumped = true;
} catch (err) {
  console.log('[INFO] sqlite3 CLI not available or failed, using better-sqlite3 exporter fallback...');
}

if (!dumped) {
  // Pure JavaScript dump fallback
  const Database = require('better-sqlite3');
  const db = new Database(dbPath, { readonly: true });
  const tables = db.prepare("SELECT name, sql FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'").all();
  const indices = db.prepare("SELECT sql FROM sqlite_master WHERE type='index' AND sql IS NOT NULL").all();

  const lines = [
    'PRAGMA foreign_keys=OFF;',
    'BEGIN TRANSACTION;',
    ''
  ];

  for (const table of tables) {
    lines.push(`${table.sql};`);
    const rows = db.prepare(`SELECT * FROM "${table.name}"`).all();
    for (const row of rows) {
      const keys = Object.keys(row);
      const vals = keys.map((k) => {
        const v = row[k];
        if (v === null || v === undefined) return 'NULL';
        if (typeof v === 'number') return v;
        return `'${String(v).replace(/'/g, "''")}'`;
      });
      lines.push(`INSERT INTO "${table.name}" VALUES(${vals.join(',')});`);
    }
    lines.push('');
  }

  for (const idx of indices) {
    lines.push(`${idx.sql};`);
  }

  lines.push('COMMIT;');
  lines.push('');

  fs.writeFileSync(outPath, lines.join('\n'), 'utf8');
  db.close();
}

console.log(`[SUCCESS] Database dumped to ${outPath} (${(fs.statSync(outPath).size / 1024).toFixed(1)} KB)`);
