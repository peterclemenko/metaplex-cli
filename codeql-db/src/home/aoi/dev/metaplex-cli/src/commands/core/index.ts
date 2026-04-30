import {Args, Command, Flags} from '@oclif/core'

export default class Core extends Command {
  static override description = 'MPL Core Program'

  static override examples = [
    '<%= config.bin %> <%= command.id %>',
  ]

  static override flags = {

  }

  public async run(): Promise<void> {
    const {args, flags} = await this.parse(Core)

  }
}
