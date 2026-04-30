import { Command, Flags } from '@oclif/core'
import dedupeDb from '../../lib/uploader/dedupeDb.js'
import path from 'path'
import untildify from 'untildify'

export default class DbExport extends Command {
  static override description = 'Export dedupe DB contents to a JSON file'

  static override flags = {
    out: Flags.string({ char: 'o', description: 'output file path', required: true }),
    db: Flags.string({ char: 'd', description: 'path to dedupe DB file' }),
  }

  public async run(): Promise<void> {
    const { flags } = await this.parse(DbExport)
    const dbPath = dedupeDb.initDedupeDb(flags.db)
    const outPath = untildify(flags.out)
    dedupeDb.exportDbToFile(outPath)
    this.log(`Exported DB to: ${outPath} (source: ${dbPath})`)
  }
}
