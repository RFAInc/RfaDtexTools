# RfaDtexTools
Dtex Systems utilizes user behavior intelligence to help enterprises detect cybersecurity threats without compromising privacy.

## Example of how to call from www:
```
# The installer must auto-remove any older versions, and the supplied InstallCode is required for this to work correctly.
(new-object Net.WebClient).DownloadString( 'https://raw.githubusercontent.com/RFAInc/RfaDtexTools/master/RfaDtexTools.psm1' ) | iex; Invoke-ClientDtexInstall -Address 'subdomain.dtexservices.com' -InstallCode 'P@ssw0rd' -Guid '47e4d5ea-033a-48fb-aa5f-2abc8b308e19'
```
```
# Gets the file version number for the currently installed Dtex program.
(new-object Net.WebClient).DownloadString( 'https://raw.githubusercontent.com/RFAInc/RfaDtexTools/master/RfaDtexTools.psm1' ) | iex; Get-DtexVersion
```
