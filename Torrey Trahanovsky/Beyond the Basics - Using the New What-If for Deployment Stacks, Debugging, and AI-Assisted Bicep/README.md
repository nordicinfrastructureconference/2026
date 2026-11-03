# Beyond the Basics: Using the New What-If for Deployment Stacks, Debugging, and AI-Assisted Bicep

**Speaker(s):** Torrey Trahanovsky

## Summary

What-If shows you what a deployment is going to change before you run it. In this session I showed the new What-If for Azure Deployment Stacks and how it compares with regular What-If. It filters out most of the noise, and it shows you when the stack is going to detach or delete a resource. The second part was about catching problems before you deploy, with `bicep snapshot` and `bicep lint`. In the last part, GitHub Copilot brings resources that were built by hand in the portal under a deployment stack, and Stacks What-If checks its work before anything gets deployed.

## Materials

- [Slides (PDF)](slides.pdf)
- [Demo source](demos/): the scripts, Bicep templates and Copilot skills from the demos. [demos/README.md](demos/README.md) says what each file is for.

## Running the demos

The demos run on Windows. Some of the demo paths are long, so put this repository in a short folder like `C:\src`, whether you clone it or download it as a ZIP. If Git still says "Filename too long", run `git config --global core.longpaths true`.

You need PowerShell 7, Az.Resources 10.2.1 or later, the Bicep CLI (0.41.2 or later for `bicep snapshot`), and VS Code with the Bicep extension. The Azure CLI 2.88 or later is optional, for `az stack-whatif`. The AI demo uses GitHub Copilot in VS Code.

1. Put the ID of a test subscription in `demos/demo.config.json`, and change the region if you want.
2. Double-click `demos/SETUP-LAPTOP.cmd`. It asks before it installs anything, signs you in to Azure, creates the demo resource groups, and opens the demo windows.
3. In the VS Code window for `stacks-whatif-demo`, open a terminal and run `..\Start-Terminal.ps1`. It loads Azure PowerShell and picks your subscription. Then run the commands in `commands.ps1` in order. The snapshot and lint demo works the same way in the `stacks-whatif-demo-debug` window, with `..\Start-ValidationDemo.ps1`, and only runs locally. This repository leaves out `.vscode` folders, so the terminals don't start by themselves here. [The demos' own repo](https://github.com/torreymicrosoft/nic2026-stacks-whatif-demos) has them.
4. For the AI demo, the recorded Copilot chat is in `demos/ai-demo/chat/stack-migration-chat.md`, and `demos/ai-demo/chat/PROMPTS.md` has the prompts if you want to run it live.
5. To run it again, double-click `SETUP-LAPTOP.cmd` again. It puts Azure back where the demo starts.

- **Permissions:** Owner on the test subscription, or Contributor plus Azure Deployment Stack Owner, because the stack uses deny settings.
- **Cost:** close to nothing. The demos create two resource groups, each with a virtual network, a network security group and an empty storage account. Deployment stacks and What-If results don't cost anything.
- **Destructive step:** step 7 in `commands.ps1` deploys the stack with action on unmanage set to delete, so it deletes the virtual network. Use a test subscription.
- **Cleanup:** run `demos/Remove-Demo.ps1` to delete `rg-demo-nic2026-stacks` (it asks you to type the name first), and delete `rg-demo-nic2026-brownfield` in the portal. Setup also adds two keyboard shortcuts to VS Code, and `demos/README.md` says how to take them out.

## Related links

- [Stacks What-If docs](https://aka.ms/stackswhatif)
- [The GA announcement](https://aka.ms/stackswhatifGA)
- [A closer look at noise reduction in Stacks What-If](https://aka.ms/bicep/NIC26/noise)
- [bicep snapshot](https://aka.ms/bicep/snapshot)
- [Bicep MCP server](https://aka.ms/bicep/mcp)
- [Deployment Stacks feedback and issues](https://aka.ms/stacks-feedback)
- [The same demos in their own repo](https://github.com/torreymicrosoft/nic2026-stacks-whatif-demos)

## License

These materials are shared under the repository's [MIT license](../../LICENSE). Preserve any required third-party copyright and license notices.
