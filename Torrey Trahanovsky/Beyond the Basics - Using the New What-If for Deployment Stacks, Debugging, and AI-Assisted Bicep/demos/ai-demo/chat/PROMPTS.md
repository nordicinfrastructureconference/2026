# Prompts for running the AI demo live

Copy each prompt into Copilot Chat in Agent mode, in the AI demo window. Approve each command
when Copilot asks. Keep this file on your laptop screen, not the projector.

## 1. Bring the resources under a stack (the same prompt as the recorded chat)

The resources in rg-demo-nic2026-brownfield were built by hand in the portal, and nothing manages them. Bring them under a new deployment stack called stack-brownfield without changing anything. Put the template in a brownfield folder and show me the Stacks What-If before anything gets deployed.

## 2. Switch the pipeline (the same prompt as the recorded chat)

Our pipeline in .github/workflows/deploy.yml still does a regular deployment of that template. Switch it to deploy stack-brownfield instead, and add a Stacks What-If step before the deploy that stops the run if anything would get deleted or detached.

## 3. Optional: best practices with a snapshot check (tried on a copy, about 15 minutes)

Apply the Bicep best practices to brownfield/main.bicep. Before you change anything, take a bicep snapshot of it, and after your changes, validate against that snapshot so no resource changes. Don't deploy anything.

Tried on a copy of this folder on 8 October. Copilot had to add brownfield/main.bicepparam first (`using 'main.bicep'`), because bicep snapshot needs a parameters file. It moved the subnet into its own resource, the snapshot check failed on that, and it put the subnet back. The final template built, passed the linter and validated against the snapshot. Nothing was deployed.