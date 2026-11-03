# 1. Take a snapshot: every resource the template and its parameters would deploy, in one file.
bicep snapshot main.bicepparam --mode overwrite
code main.snapshot.json

# 2. A refactor: the storage account moves into a module, and nothing else changes.
Copy-Item main.refactor.bicep main.bicep
code --diff main.v1.bicep main.bicep

# 3. Check the refactor against the snapshot.
bicep snapshot main.bicepparam --mode validate; "exit code $LASTEXITCODE"

# 4. The pull request: it adds an SSH rule and takes the virtual network out.
Copy-Item main.v2.bicep main.bicep
code --diff main.v1.bicep main.bicep

# 5. Check the pull request against the snapshot.
bicep snapshot main.bicepparam --mode validate; "exit code $LASTEXITCODE"

# 6. Lint the pull request.
bicep lint main.bicep; "exit code $LASTEXITCODE"

# 7. bicepconfig.json in this folder turns three lint rules up to errors, and mistakes.bicep breaks all three.
code bicepconfig.json mistakes.bicep
bicep lint mistakes.bicep; "exit code $LASTEXITCODE"
