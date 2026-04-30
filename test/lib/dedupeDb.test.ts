import { expect } from 'chai'
import os from 'os'
import path from 'path'
import fs from 'fs'
import dedupeDb from '../../src/lib/uploader/dedupeDb'

describe('dedupeDb', () => {
  const tmpDir = os.tmpdir()
  const dbFile = path.join(tmpDir, `mplx-dedupe-test-${Date.now()}.db`)
  const exportFile = path.join(tmpDir, `mplx-dedupe-export-${Date.now()}.json`)

  after(() => {
    try { dedupeDb.closeDedupeDb() } catch (e) {}
    try { fs.unlinkSync(dbFile) } catch (e) {}
    try { fs.unlinkSync(exportFile) } catch (e) {}
  })

  it('initializes and reports status', () => {
    const p = dedupeDb.initDedupeDb(dbFile)
    expect(p).to.equal(dbFile)
    const s = dedupeDb.dbStatus()
    expect(s.initialized).to.be.true
    expect(s.uploads).to.equal(0)
    expect(s.assets).to.equal(0)
  })

  it('inserts and looks up uploads', () => {
    const hash = 'sha256:deadbeef'
    const uri = 'https://arweave.net/abcd'
    dedupeDb.insertUpload(hash, uri, 'image')
    const found = dedupeDb.lookupByHash(hash)
    expect(found).to.not.be.null
    expect(found.uri).to.equal(uri)
  })

  it('upserts and retrieves asset entries', () => {
    const key = 'asset-1'
    dedupeDb.upsertAsset(key, { image_hash: 'h1', image_uri: 'u1' })
    const asset = dedupeDb.getAsset(key)
    expect(asset).to.not.be.null
    expect(asset.image_hash).to.equal('h1')
    expect(asset.image_uri).to.equal('u1')
  })

  it('exports and imports db', () => {
    dedupeDb.exportDbToFile(exportFile)
    expect(fs.existsSync(exportFile)).to.be.true
    // reset then import
    dedupeDb.resetDb()
    const s1 = dedupeDb.dbStatus()
    expect(s1.uploads).to.equal(0)
    expect(s1.assets).to.equal(0)
    const res = dedupeDb.importDbFromFile(exportFile)
    expect(res.uploads).to.be.greaterThan(0)
    expect(res.assets).to.be.greaterThan(0)
    const s2 = dedupeDb.dbStatus()
    expect(s2.uploads).to.equal(res.uploads)
  })
})
