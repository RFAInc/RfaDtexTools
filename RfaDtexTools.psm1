# v1.3.4.45

function Install-Dtex {
    <#
    .SYNOPSIS
    Installs Dtex.
    .DESCRIPTION
    Runs MSIEXEC against the local computer, given a path to the MSI file and an address. Note that the file must exist in a folder with other requisute files.
    .EXAMPLE
    if (-not (Test-DtexInstalled) -and -not (Test-OldDtexPath)) {Install-Dtex -MsiInstallerPath 'C:\temp.ms1' -Address 'sub.domain.com'}
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
                    Position=0)]
        [ValidateScript({Test-Path $_})]
        [string]
        $MsiInstallerPath,

        [Parameter(Mandatory=$true,
                    Position=1)]
        [ValidateScript({ -not [string]::IsNullOrEmpty((
            [system.net.dns]::Resolve($_).AddressList[0].IPAddressToString
        ))})]
        [string]
        $Address,

        [Parameter(Position=2)]
        [ValidateScript({Test-Path (Split-Path $_ -Parent)})]
        [string]
        $Log = 'output.log'
    )

    Begin {
        $RawInstallParams = '/i "{0}" ALLUSERS=1 /qn /norestart ADDRESS="{1}" /log "{2}"'
    }
    Process {
        $MsiInstallerParent = Split-Path $MsiInstallerPath -Parent
        $MsiInstallerLeaf = Split-Path $MsiInstallerPath -Leaf
        Set-Location $MsiInstallerParent
        
        # Run the Installer
        $InstallParams = $RawInstallParams -f $MsiInstallerLeaf, $Address, $Log
        Start-Process 'msiexec.exe' -ArgumentList $InstallParams
        Write-Verbose "MSI Installer Executed as: msiexec.exe $InstallParams"
    }
    End {}
}

function Uninstall-Dtex {
    <#
    .SYNOPSIS
    Uninstalls Dtex.
    .DESCRIPTION
    Runs MSIEXEC against the local computer, given a path to the MSI file and an address. Note that the file must exist in a folder with other requisute files.
    .EXAMPLE
    if ((Test-DtexInstalled)) {Uninstall-Dtex -MsiInstallerPath 'C:\temp.ms1' -Address 'sub.domain.com'}
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position=2)]
        [ValidateScript({Test-Path (Split-Path $_ -Parent)})]
        [string]
        $Log = "$($env:temp)\dtex-uninstall.log",

        # Removal Account Name in plain text
        [Parameter()]
        [string]
        $AccountName,

        # Removal Password in plain text
        [Parameter()]
        [string]
        $Password
    )

    Begin {

        $RawInstallParams = '/X "{0}" ALLUSERS=1 /qn /norestart ACCOUNTNAME="{1}" PASSWORD="{2}" KEEPLOCALDATA=0 DELETELOGDATA=1 /log "{3}"'
        
        $IdentifyingNumber = Get-WmiObject win32_product |
            Where-Object {$_.Name -like '*dtex*'} |
            Select-Object -ExpandProperty IdentifyingNumber

    }

    Process {

        # Run the Installer
        $InstallParams = $RawInstallParams -f 
            $IdentifyingNumber,
            $AccountName,
            #([Runtime.interopServices.marshal]::prtToStringAuto([runtime.Interservices.Marshal]::SecurestringToBstr($Password))),
            $Password,
            $Log

        #$InstallParams = $RawInstallParams -f $IdentifyingNumber, $Log
        Write-Verbose "MSI Uninstaller Executing as: msiexec.exe $InstallParams"
        Start-Process 'msiexec.exe' -ArgumentList $InstallParams

    }

    End {}

}

function Get-DtexVersion {
    <#
    .SYNOPSIS
    Gets the version from the path of Dtex.
    .DESCRIPTION
    Returns a boolean after verifying if the hard-coded service names or paths exists.
    .EXAMPLE
    Get-DtexVersion
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        $Path = (Join-Path $env:ProgramFiles (
                "Windows Event Reporting\Core\EventReporting.AgentService.exe"
            )
        )
    )
    
    if (Test-Path $Path) {
        (Get-Item $Path).VersionInfo | foreach {
            "$($_.FileMajorPart).$($_.FileMinorPart).$($_.FileBuildPart).$($_.FilePrivatePart)"
        }
    } else {
        $null
    }
}

function Test-DtexInstalled {
    <#
    .SYNOPSIS
    Check for the known service names or paths of Dtex.
    .DESCRIPTION
    Returns a boolean after verifying if the hard-coded service names or paths exists.
    .EXAMPLE
    if (Test-DtexInstalled) {echo 'Installed!'} else {if (Test-OldDtexPath) {Remove-OldDtex} else {echo 'Dtex Not Found on $($env:COMPUTERNAME)!'}}
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position=0)]
        [ValidateSet('Service','Path','All')]
        [string]
        $Type = 'Service'
    )
    
    # This list is for multiple, possible service paths to exe. 
    $Paths = @(
        "$($env:ProgramFiles)\Windows Event Reporting\Core\EventReporting.AgentService.exe"
    )
    
    # This list is for multiple, possible service names. 
    $Services = @(
        'WindowsEventReportingService'
    )
    
    $isFound = $False
    if ($Type -eq 'Path' -or $Type -eq 'All') {
        # If any path in the list is found, it's found
        $Paths | foreach {
            if (Test-Path $_) {$isFound = $true}
        }
    }
    if ($Type -eq 'Service' -or $Type -eq 'All') {
        # If any service in the list is found, it's found
        $Services | foreach {
            if (Get-Service $_ -ea 0) {$isFound = $true}
        }
    }
    $isFound
}

function Test-OldDtexPath {
    <#
    .SYNOPSIS
    Check for the known paths of old version of Dtex.
    .DESCRIPTION
    Returns a boolean after verifying if the hard-coded path exists.
    .EXAMPLE
    if (Test-DtexInstalled) {echo 'Installed!'} else {if (Test-OldDtexPath) {Remove-OldDtex} else {echo 'Dtex Not Found on $($env:COMPUTERNAME)!'}}
    #>
    $Paths = @(
        "c:\Program Files (x86)\Dtex Systems\dnapackageinstaller.exe",
        "c:\Program Files\Dtex Systems\dnapackageinstaller.exe"
    )
    $isFound = $False
    $Paths | foreach {
        if (Test-Path $_) {$isFound = $true}
    }
    $isFound
}

function Remove-OldDtex {
    <#
    .SYNOPSIS
    Remove OldDtex.
    .DESCRIPTION
    Executes MSIExec.exe to remove the old version of Dtex software.
    .EXAMPLE
    if (Test-DtexInstalled) {echo 'Installed!'} else {if (Test-OldDtexPath) {Remove-OldDtex} else {echo 'Dtex Not Found on $($env:COMPUTERNAME)!'}}
    #>
    [CmdletBinding()]
    param (
        # GUID related to MSIInstaller uninstall string
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true)]
        [string]
        $Guid,

        # Removal Password in plain text
        [Parameter()]
        [string]
        $InstallCode
    )
    
    begin {
        $RemoveCMD = 'msiexec.exe /x {{{0}}} /qn Reboot=ReallySuppress INSTALLCODE={1}'
    }
    
    process {
    }
    
    end {
        & ([scriptblock]::Create(($RemoveCMD -f $Guid, $InstallCode)))
    }
}

function Remove-DtexInstallerParent {
    <#
    .SYNOPSIS
    Silently removes a folder and subfolder even if not found.
    .DESCRIPTION
    Silently removes a folder and subfolder even if not found. Returns error message if another error is found.
    #>
    param (
        # Path to remove when completed
        [Parameter(Mandatory=$true)]
        [string]
        $Path
    )
    
    begin {
    }
    
    process {
        Try{
            Remove-Item -Path $Path -Recurse -Force
        }Catch{
            if ($_ -notlike '*ItemNotFound*') {
                $_.Exception.Message
            }
        }
    }
    
    end {
    }
}

function Invoke-ClientDtexInstall {
    [CmdletBinding()]
    param (
        # Address of the client portal (EX: 'subdomain.dtexservices.com')
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        $Address,

        # Full Path to the MSI installer for Dtex
        [Parameter(Position=1)]
        [string]
        $MsiInstallerPath
    )
    
    begin {
        $defaultMsiInstallerPath="$($env:WINDIR)\LtSvc\Packages\Dtex\DtexMicroAgentX64.msi"
        $u1='https://automate.rfa.com/hidden/install/dtex/DtexMicroAgentX64.msi'
        $u2='https://automate.rfa.com/hidden/install/dtex/DtexMicroAgentX64.msi.sha1.txt'
        $Output = ''
    }
    
    process {
        # Verify the package
        if ([string]::IsNullOrEmpty($MsiInstallerPath)) {
            $MsiInstallerPath=$defaultMsiInstallerPath
        }
        $MsiInstallerParent= Split-Path $MsiInstallerPath -Parent
        if (-not (Test-Path $MsiInstallerParent)) {
            New-Item $MsiInstallerParent -ItemType Directory -Force | Out-Null
        }
        $d2="$($MsiInstallerPath).sha1"

        if ( -not (Test-Path $MsiInstallerPath)) {
            # Download the files
            $web=new-object Net.WebClient
            $web.DownloadFile($u1,$MsiInstallerPath); Start-Sleep 2
            $web.DownloadFile($u2,$d2); Start-Sleep 2
        }

        # Test the downloads
        if ( -not (Test-Path $MsiInstallerPath)) {
            Throw "MSI File not found!"
        }

        # Perform the install and handle old version
        if (Test-DtexInstalled) {
            $Version = Get-DtexVersion
            $Output += 'Dtex v{0} was already installed! ' -f $Version
        } else {
            if (Test-OldDtexPath) {
                Remove-OldDtex
                Sleep 60
                if (Test-OldDtexPath) {
                    $Output += 'Old Dtex Removal Failed! '
                } else {
                    $Output += 'Old Dtex Removed! Now running Installer... '
                    Install-Dtex -MsiInstallerPath $MsiInstallerPath -Address $Address | Out-Null
                    Sleep 60
                    if (Test-DtexInstalled) {
                        $Version = Get-DtexVersion
                        $Output += 'Dtex v{0} Successfully Installed! ' -f $Version
                    } else {
                        $Output += 'Dtex install failed! '
                    }
                }
            } else {
                $Output += 'Dtex Not Found on this Computer. Running Installer... '
                Install-Dtex -MsiInstallerPath $MsiInstallerPath -Address $Address | Out-Null
                Sleep 60
                if (Test-DtexInstalled) {
                    $Version = Get-DtexVersion
                    $Output += 'Dtex v{0} Successfully Installed! ' -f $Version
                } else {
                    $Output += 'Dtex install failed! '
                }
            }
        }
    }
    
    end {
        Write-Output $Output
    }
}


function Invoke-ClientDtexUninstall {
    [CmdletBinding()]
    param (
        # Removal Account Name in plain text
        [Parameter()]
        [string]
        $AccountName,

        # Removal Password in plain text
        [Parameter()]
        [string]
        $Password,

        # Path to remove when completed
        [Parameter(Mandatory=$true)]
        [string]
        $MsiInstallerParent
    )
    
    begin {
        (new-object Net.WebClient).DownloadString('http://bit.ly/ltposh') | iex
        $info = Get-LTServiceInfo
        $users = (dir c:\users | select -exp basename) -join ', '
        $Output = "$($env:COMPUTERNAME) ($($info.ID)-$($info.MAC)) [users: $($users)] "
    }
    
    process {

        # Perform the uninstall and handle old version
        if ( -not (Test-DtexInstalled)) {
            $Output += 'Dtex was not found to be installed! '
        } else {
            $Version = Get-DtexVersion
            $Output += 'Dtex Found on this Computer. Running Uninstaller... '
            $props = @{
                AccountName = $AccountName
                #Password = ([Runtime.interopServices.marshal]::prtToStringAuto([runtime.Interservices.Marshal]::SecurestringToBstr($Password)))
                Password = $Password
            }
            Uninstall-Dtex @props | Out-Null
            Start-Sleep 60
            if ( -not (Test-DtexInstalled)) {
                $Output += 'Dtex v{0} Successfully Uninstalled! ' -f $Version
                Remove-DtexInstallerParent -Path $MsiInstallerParent
            } else {
                $Output += 'Dtex v{0} Uninstall Failed! ' -f $Version
            }
        }
    }
    
    end {
        Write-Output $Output
    }
}
# End of module
