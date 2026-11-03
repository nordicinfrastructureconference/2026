# Deployment Stacks What-If demos (NIC 2026)

The demos from the NIC 2026 session **Beyond the Basics: Using the New What-If for Deployment
Stacks, Debugging, and AI-Assisted Bicep**, in Oslo on 14 October 2026.

There are three parts:

- **Stacks What-If.** Three resources are deployed with a regular deployment. Regular What-If on the
  same template, with no change, already shows noise, and a one-line change, the storage SKU, shows up
  with the same noise around it. Then the template gets deployed as a deployment stack. Regular What-If
  still shows the noise, and Stacks What-If on the same change shows only that line. Then the virtual
  network comes out of the template: Stacks What-If shows it as a delete, the stack deletes it, and the
  stack's deny settings block deleting one of its resources outside the stack.
- **Debugging.** `bicep snapshot` on a refactor that passes and a pull request that doesn't, then
  `bicep lint`. It all runs locally, with no Azure.
- **AI-assisted Bicep.** Resources built by hand in the portal get brought under a new stack by
  GitHub Copilot, using a skill, and Stacks What-If checks that nothing changes. Then Copilot
  switches a GitHub Actions pipeline over to the stack, with a Stacks What-If step before the
  deploy.

## What's in here

| File or folder | What it is |
| --- | --- |
| `stacks-whatif-demo\` | `app.v1.bicep` is what's deployed, `app.v2.bicep` changes the storage SKU, and `app.v3.bicep` is `app.v1.bicep` without the virtual network. `commands.ps1` has the commands in order, with the Azure CLI version under each one |
| `Start-Terminal.ps1` | The demo terminal: loads Azure PowerShell, picks your subscription and opens in `stacks-whatif-demo` |
| `Start-PressEnter.ps1` | Optional: Enter puts the next command from `commands.ps1` at the prompt, and Enter again runs it |
| `Show-Saved.ps1`, `_saved\` | What each step printed in a rehearsal, with the colors, for when Azure can't be reached. `..\Show-Saved.ps1 3` shows step 3 |
| `ai-demo\` | The AI demo: the two skills in `.github\skills`, the recorded Copilot chat in `chat\`, the files Copilot wrote, the pipeline, and the prompts to run it live |
| `stacks-whatif-demo-debug\`, `Start-ValidationDemo.ps1` | The debugging demo: `commands.ps1` takes a snapshot, checks a refactor that passes and a change that doesn't, then runs lint. `Start-ValidationDemo.ps1` is its terminal |
| `Prepare-Stage.ps1`, `Prepare-Brownfield.ps1` | Create the Azure side, and put it back to the starting point after a run |
| `Setup-Laptop.ps1` | Checks the tools, sets everything up, and opens the demo windows |
| `demo.config.json` | Your subscription, resource group names and region |

## Before you start

- A **test** subscription you can create resource groups in. The demo creates
  `rg-demo-nic2026-stacks` and `rg-demo-nic2026-brownfield`. Steps 3 and 7 really deploy, and step 7
  deletes the virtual network.
- Windows, PowerShell 7, Az.Resources 10.2.1 or later, the Bicep CLI (0.41.2 or later for
  `bicep snapshot`), and VS Code with the Bicep extension. The Azure CLI 2.88 or later is optional,
  for `az stack-whatif`.

## Run it

1. Put your subscription ID in `demo.config.json`, and change the region if you want.
2. Double-click `SETUP-LAPTOP.cmd`. It asks before it installs anything. It also adds two VS Code
   keyboard shortcuts that only work in the two `commands.ps1` files: Ctrl+Enter runs the line the
   cursor is on in the terminal, and Enter just moves down a line.
3. In the VS Code window for `stacks-whatif-demo`, open a terminal and run `..\Start-Terminal.ps1`. It
   loads Azure PowerShell and picks your subscription. Then click a command in `commands.ps1` and press
   Ctrl+Enter, or copy it into the terminal. The debugging demo works the same way in the
   `stacks-whatif-demo-debug` window, with `..\Start-ValidationDemo.ps1`, and only needs the Bicep CLI.
   This copy has no `.vscode` folders, so the terminals don't start by themselves.
4. After a run, double-click `SETUP-LAPTOP.cmd` again, or run `Prepare-Stage.ps1`, to put Azure back
   at the starting point. It takes about a minute and a half.

A few things to know:

- The noise in the regular What-If came from a tag policy on our test subscription. On yours it
  may look different, or there may be none.
- The Stacks What-If retention interval is 1 to 3 hours right now.
- The deploy in step 7 takes about 3 minutes, because deleting the virtual network takes a while.
- `_saved\` and the recorded chat in `ai-demo\chat` come from our test subscription, with the IDs
  taken out. If you run the AI demo live, Copilot's answers can be a bit different.

## Clean up

- Run `Remove-Demo.ps1` to delete the demo resource group, and delete `rg-demo-nic2026-brownfield`
  in the portal.
- Take the demo shortcuts out of VS Code: File > Preferences > Keyboard Shortcuts (JSON), and delete
  the two entries under the comment that says Stacks What-If demo V4.

## Learn more

- Stacks What-If docs: aka.ms/stackswhatif
- The GA announcement: aka.ms/stackswhatifGA
- bicep snapshot: aka.ms/bicep/snapshot
- Bicep MCP server: aka.ms/bicep/mcp
- Deployment Stacks feedback and issues: aka.ms/stacks-feedback
