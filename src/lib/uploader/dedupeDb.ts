import fs from 'fs'
import path from 'path'
import untildify from 'untildify'
import Database from 'better-sqlite3'
import { drizzle } from 'drizzle-orm/better-sqlite3'
import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core'

const DEFAULT_DB_PATH = untildify('~/.config/mplx/upload-dedupe.db')

export const uploads = sqliteTable('uploads', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  hash: text('hash').notNull().unique(),
  uri: text('uri').notNull(),
  type: text('type').notNull(),
  created_at: text('created_at').notNull(),
})

export const assets = sqliteTable('assets', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  asset_key: text('asset_key').notNull().unique(),
  image_hash: text('image_hash'),
  json_hash: text('json_hash'),
  image_uri: text('image_uri'),
  json_uri: text('json_uri'),
  created_at: text('created_at').notNull(),
})

let client: Database | null = null
let orm: ReturnType<typeof drizzle> | null = null

function ensureDirExists(filePath: string) {
  const dir = path.dirname(filePath)
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true })
}

export function initDedupeDb(dbPath?: string) {
  const resolved = untildify(dbPath ?? DEFAULT_DB_PATH)
  ensureDirExists(resolved)
  if (!client) {
    client = new Database(resolved)
    orm = drizzle(client)
    // Create tables if they don't exist
    client.exec(`
      CREATE TABLE IF NOT EXISTS uploads (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        hash TEXT NOT NULL UNIQUE,
        uri TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL
      );
    `)
    client.exec(`
      CREATE TABLE IF NOT EXISTS assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        asset_key TEXT NOT NULL UNIQUE,
        image_hash TEXT,
        json_hash TEXT,
        image_uri TEXT,
        json_uri TEXT,
        created_at TEXT NOT NULL
      );
    `)
  }
  return resolved
}

export function closeDedupeDb() {
  if (client) {
    client.close()
    client = null
    orm = null
  }
}

export function lookupByHash(hash: string) {
  if (!client) return null
  const row = client.prepare('SELECT * FROM uploads WHERE hash = ?').get(hash)
  return row ?? null
}

export function insertUpload(hash: string, uri: string, type: string) {
  if (!client) throw new Error('Database not initialized. Call initDedupeDb()')
  const now = new Date().toISOString()
  const stmt = client.prepare(`INSERT OR REPLACE INTO uploads (hash, uri, type, created_at) VALUES (?, ?, ?, ?)`)
  return stmt.run(hash, uri, type, now)
}

export function upsertAsset(
  assetKey: string,
  data: { image_hash?: string; json_hash?: string; image_uri?: string; json_uri?: string }
) {
  if (!client) throw new Error('Database not initialized. Call initDedupeDb()')
  const now = new Date().toISOString()
  const existing = client.prepare('SELECT * FROM assets WHERE asset_key = ?').get(assetKey)
  if (existing) {
    const stmt = client.prepare(`UPDATE assets SET image_hash = COALESCE(?, image_hash), json_hash = COALESCE(?, json_hash), image_uri = COALESCE(?, image_uri), json_uri = COALESCE(?, json_uri) WHERE asset_key = ?`)
    return stmt.run(data.image_hash ?? null, data.json_hash ?? null, data.image_uri ?? null, data.json_uri ?? null, assetKey)
  } else {
    const stmt = client.prepare(`INSERT INTO assets (asset_key, image_hash, json_hash, image_uri, json_uri, created_at) VALUES (?, ?, ?, ?, ?, ?)`)
    return stmt.run(assetKey, data.image_hash ?? null, data.json_hash ?? null, data.image_uri ?? null, data.json_uri ?? null, now)
  }
}

export function getAsset(assetKey: string) {
  if (!client) return null
  return client.prepare('SELECT * FROM assets WHERE asset_key = ?').get(assetKey)
}

export function exportDbToFile(outPath: string) {
  if (!client) throw new Error('Database not initialized. Call initDedupeDb()')
  const uploadsRows = client.prepare('SELECT hash, uri, type, created_at FROM uploads').all()
  const assetsRows = client.prepare('SELECT asset_key, image_hash, json_hash, image_uri, json_uri, created_at FROM assets').all()
  const payload = { uploads: uploadsRows, assets: assetsRows }
  ensureDirExists(outPath)
  fs.writeFileSync(outPath, JSON.stringify(payload, null, 2), 'utf8')
  return outPath
}

export function importDbFromFile(inPath: string) {
  if (!fs.existsSync(inPath)) throw new Error(`Import file not found: ${inPath}`)
  if (!client) throw new Error('Database not initialized. Call initDedupeDb()')
  const raw = fs.readFileSync(inPath, 'utf8')
  const payload = JSON.parse(raw)
  const uploadsRows = payload.uploads ?? []
  const assetsRows = payload.assets ?? []
  const insertUploadStmt = client.prepare('INSERT OR REPLACE INTO uploads (hash, uri, type, created_at) VALUES (?, ?, ?, ?)')
  const insertAssetStmt = client.prepare('INSERT OR REPLACE INTO assets (asset_key, image_hash, json_hash, image_uri, json_uri, created_at) VALUES (?, ?, ?, ?, ?, ?)')
  const insertUploadTxn = client.transaction((rows: any[]) => {
    for (const r of rows) insertUploadStmt.run(r.hash, r.uri, r.type, r.created_at)
  })
  const insertAssetTxn = client.transaction((rows: any[]) => {
    for (const r of rows) insertAssetStmt.run(r.asset_key, r.image_hash ?? null, r.json_hash ?? null, r.image_uri ?? null, r.json_uri ?? null, r.created_at ?? new Date().toISOString())
  })
  insertUploadTxn(uploadsRows)
  insertAssetTxn(assetsRows)
  return { uploads: uploadsRows.length, assets: assetsRows.length }
}

export function resetDb() {
  if (!client) throw new Error('Database not initialized. Call initDedupeDb()')
  client.exec('DELETE FROM uploads')
  client.exec('DELETE FROM assets')
}

export function dbStatus() {
  if (!client) return { initialized: false }
  const uploadsCount = client.prepare('SELECT COUNT(*) as c FROM uploads').get().c
  const assetsCount = client.prepare('SELECT COUNT(*) as c FROM assets').get().c
  return { initialized: true, uploads: uploadsCount, assets: assetsCount }
}

export default {
  initDedupeDb,
  closeDedupeDb,
  lookupByHash,
  insertUpload,
  upsertAsset,
  getAsset,
  exportDbToFile,
  importDbFromFile,
  resetDb,
  dbStatus,
}
