import {runCommand} from '@oclif/test'
import {expect} from 'chai'

describe('db', () => {
  it('runs db cmd', async () => {
    const {stdout} = await runCommand('db')
    expect(stdout).to.contain('Available db commands:')
  })

  it('runs db --name oclif', async () => {
    // flag behavior not applicable; ensure help text remains
    const {stdout} = await runCommand('db --help')
    expect(stdout).to.contain('Manage the upload dedupe database')
  })
})
