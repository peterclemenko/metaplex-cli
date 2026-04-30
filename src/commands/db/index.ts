import { Command } from '@oclif/core'

export default class Db extends Command {
  static override description = 'Manage the upload dedupe database (init/export/import/status/reset)'

  static override examples = ['<%= config.bin %> <%= command.id %> init', '<%= config.bin %> <%= command.id %> export --out db.json']

  public async run(): Promise<void> {
    this.log('Available db commands:')
    this.log('  init   - Initialize the dedupe DB')
    this.log('  export - Export DB contents to JSON file')
    this.log('  import - Import DB contents from JSON file')
    this.log('  status - Show DB statistics')
    this.log('  reset  - Clear DB contents')
    this.log('')
    this.log('Use --help with any subcommand for details')
  }
}
