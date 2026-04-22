$ErrorActionPreference = "Stop"

# Resolve paths from this script location so Windows Task Scheduler can run it
# from any working directory.
$ScriptDir = $PSScriptRoot
$LogDir = Join-Path $ScriptDir "logs"
$LogFile = Join-Path $LogDir ("{0}.log" -f (Get-Date -Format "yyyy-MM-dd"))
$LoginScript = Join-Path $ScriptDir "login.py"

function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$Timestamp] $Message" | Out-File -FilePath $LogFile -Append -Encoding utf8
}

function Format-LogText {
    param(
        [string]$Text,

        [int]$MaxLength = 120
    )

    $Preview = ($Text -replace "\s+", " ").Trim()
    if ($Preview.Length -gt $MaxLength) {
        return $Preview.Substring(0, $MaxLength)
    }

    return $Preview
}

function Test-NetworkAvailable {
    $Probes = @(
        @{
            Uri = "http://www.msftconnecttest.com/connecttest.txt"
            ExpectedBody = "Microsoft Connect Test"
        },
        @{
            Uri = "http://www.msftncsi.com/ncsi.txt"
            ExpectedBody = "Microsoft NCSI"
        }
    )

    $Failures = @()
    foreach ($Probe in $Probes) {
        try {
            $Response = Invoke-WebRequest `
                -Uri $Probe.Uri `
                -UseBasicParsing `
                -TimeoutSec 10 `
                -ErrorAction Stop

            $Body = ([string]$Response.Content).Trim()
            if ($Response.StatusCode -eq 200 -and $Body -eq $Probe.ExpectedBody) {
                return @{
                    Available = $true
                    Detail = $Probe.Uri
                }
            }

            $Failures += ("{0}: status={1}, body={2}" -f $Probe.Uri, $Response.StatusCode, (Format-LogText $Body))
        }
        catch {
            $Failures += ("{0}: {1}" -f $Probe.Uri, $_.Exception.Message)
        }
    }

    return @{
        Available = $false
        Detail = ($Failures -join " | ")
    }
}

function Invoke-LoginScript {
    $env:PYTHONIOENCODING = "utf-8"

    $Python = Get-Command python -ErrorAction SilentlyContinue
    if ($Python) {
        & $Python.Source $LoginScript 2>&1 |
            ForEach-Object {
                $Line = Format-LogText ([string]$_) 240
                if ($Line) {
                    Write-Log ("login.py | {0}" -f $Line)
                }
            }
        return $LASTEXITCODE
    }

    $PyLauncher = Get-Command py -ErrorAction SilentlyContinue
    if ($PyLauncher) {
        & $PyLauncher.Source -3 $LoginScript 2>&1 |
            ForEach-Object {
                $Line = Format-LogText ([string]$_) 240
                if ($Line) {
                    Write-Log ("login.py | {0}" -f $Line)
                }
            }
        return $LASTEXITCODE
    }

    throw "Neither python nor py was found in PATH."
}

New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
Get-ChildItem -Path $LogDir -Filter "*.log" -File |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } |
    Remove-Item -Force

Write-Log "Start network check"

$Network = Test-NetworkAvailable
if ($Network.Available) {
    Write-Log ("Network OK, skip login ({0})" -f $Network.Detail)
    exit 0
}

Write-Log ("Network unavailable, login required ({0})" -f $Network.Detail)
$ExitCode = Invoke-LoginScript
if ($ExitCode -ne 0) {
    Write-Log ("Login failed with exit code {0}" -f $ExitCode)
    exit $ExitCode
}

Write-Log "Login finished"
"==================================================" | Out-File -FilePath $LogFile -Append -Encoding utf8
