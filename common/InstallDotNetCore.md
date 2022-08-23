# Installing .Net Core

Download installer from https://dotnet.microsoft.com/

Run Installer

## Cleanup Old Versions

List SDK versions: `dotnet --list-sdks`

List runtime versions: `dotnet --list-runtimes`

Download the uninstaller tool from https://github.com/dotnet/cli-lab/releases

See what SDKs could be removed: ./dotnet-core-uninstall whatif --sdk --all-but-latest
Remove SDKs: sudo ./dotnet-core-uninstall remove --sdk --all-but-latest

See what runtimes could be removed: ./dotnet-core-uninstall whatif --runtime --all-but-latest
Remove SDKs: sudo ./dotnet-core-uninstall remove --runtime --all-but-latest

## Selecting a Specific Version

If you have multiple SDKs installed, the dotnet CLI will pick the latest one by default. If you want to override this, then
create a file `global.json` in the directory where the app will be created, then set it to something like this:

```json
{
  "sdk": {
    "version": "3.1.408"
  }
}
```

Do this BEFORE running `dotnet new ...`
