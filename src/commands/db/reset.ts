import { Command, Flags } from '@oclif/core'
import dedupeDb from '../../lib/uploader/dedupeDb.js'
import prompts from 'prompts'

export default class DbReset extends Command {
  static override description = 'Clear all records from the dedupe DB'

  static override flags = {
    yes: Flags.boolean({ char: 'y', description: 'skip confirmation' }),
    db: Flags.string({ char: 'd', description: 'path to dedupe DB file' }),
  }

  public async run(): Promise<void> {
    const { flags } = await this.parse(DbReset)
    const dbPath = dedupeDb.initDedupeDb(flags.db)
    if (!flags.yes) {
      const res = await prompts({ type: 'confirm', name: 'value', message: `Are you sure you want to clear DB at ${dbPath}?`, initial: false })
      if (!res.value) {
        this.log('Aborted')
        return
      }
    }
    dedupeDb.resetDb()
    this.log(`Cleared DB at: ${dbPath}`)
  }
}
