import { Command, Flags } from '@oclif/core'
import dedupeDb from '../../lib/uploader/dedupeDb.js'

export default class DbInit extends Command {
  static override description = 'Initialize the dedupe SQLite DB (creates file if missing)'

  static override flags = {
    db: Flags.string({ char: 'd', description: 'path to dedupe DB file' }),
  }

  public async run(): Promise<void> {
    const { flags } = await this.parse(DbInit)
    const path = dedupeDb.initDedupeDb(flags.db)
    this.log(`Dedupe DB initialized at: ${path}`)
  }
}
