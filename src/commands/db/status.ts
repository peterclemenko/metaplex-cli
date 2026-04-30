import { Command, Flags } from '@oclif/core'
import dedupeDb from '../../lib/uploader/dedupeDb.js'

export default class DbStatus extends Command {
  static override description = 'Show dedupe DB status and counts'

  static override flags = {
    db: Flags.string({ char: 'd', description: 'path to dedupe DB file' }),
  }

  public async run(): Promise<void> {
    const { flags } = await this.parse(DbStatus)
    const dbPath = dedupeDb.initDedupeDb(flags.db)
    const status = dedupeDb.dbStatus()
    if (!status.initialized) {
      this.log('DB not initialized')
      return
    }
    this.log(`Dedupe DB: ${dbPath}`)
    this.log(`Uploads: ${status.uploads}`)
    this.log(`Assets: ${status.assets}`)
  }
}
