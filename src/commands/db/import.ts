import { Command, Flags } from '@oclif/core'
import dedupeDb from '../../lib/uploader/dedupeDb.js'
import untildify from 'untildify'

export default class DbImport extends Command {
  static override description = 'Import dedupe DB contents from a JSON file'

  static override flags = {
    in: Flags.string({ char: 'i', description: 'input JSON file path', required: true }),
    db: Flags.string({ char: 'd', description: 'path to dedupe DB file' }),
  }

  public async run(): Promise<void> {
    const { flags } = await this.parse(DbImport)
    const dbPath = dedupeDb.initDedupeDb(flags.db)
    const inPath = untildify(flags.in)
    const result = dedupeDb.importDbFromFile(inPath)
    this.log(`Imported ${result.uploads} uploads and ${result.assets} assets into ${dbPath}`)
  }
}
