# RfaDtexTools
Dtex Systems utilizes user behavior intelligence to help enterprises detect cybersecurity threats without compromising privacy.

## Example of how to call from www:
```
(new-object Net.WebClient).DownloadString( 'https://raw.githubusercontent.com/RFAInc/RfaDtexTools/master/RfaDtexTools.psm1' ) | iex; Invoke-ClientDtexInstall -Address 'subdomain.dtexservices.com' 
(new-object Net.WebClient).DownloadString( 'https://raw.githubusercontent.com/RFAInc/RfaDtexTools/master/RfaDtexTools.psm1' ) | iex; Get-DtexVersion
```
