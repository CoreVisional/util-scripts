<#
Author: Alex
Created At: 03/08/2022

Generate a list of programs installed found in REGISTRY EDITOR.
This script will prompt you to select the program you wish to uninstall.

NOTE: This script only works on Windows machine (Duh).
#>

function Get-ValidInput {
    param([Parameter(Mandatory = $true)][String]$Prompt)

    while ($true) {
        $Number = 0
        $IsIntegerNum = [int]::TryParse((Read-Host $Prompt), [ref]$Number)
        if ($IsIntegerNum) {
            return $Number
        }
        Write-Host "`nInput must be an integer..."
    }
}

function Confirm-YesNo {
    param([Parameter(Mandatory)][String]$YesNoQuestion)

    $ChoiceYes = @("yes", 'y')
    $ChoiceNo = @("no", 'n')

    while ($true) {
        $UserChoice = (Read-Host -Prompt $YesNoQuestion).ToLower()

        if ($ChoiceYes -contains $UserChoice) {
            return $true
        }
        elseif ($ChoiceNo -contains $UserChoice) {
            return $false
        }
        Write-Host "`nInvalid Input. Try Again." -ForegroundColor Red
    }
}

function Get-InstalledApps {
    $32BitProgramsList = "\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    $64BitProgramsList = "\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"

    $programsList = @(
        if (Test-Path "HKLM:$32BitProgramsList") { Get-ChildItem "HKLM:$32BitProgramsList" }
        if (Test-Path "HKLM:$64BitProgramsList") { Get-ChildItem "HKLM:$64BitProgramsList" }
        if (Test-Path "HKCU:$32BitProgramsList") { Get-ChildItem "HKCU:$32BitProgramsList" }
        if (Test-Path "HKCU:$64BitProgramsList") { Get-ChildItem "HKCU:$64BitProgramsList" }
    ) |
    ForEach-Object { Get-ItemProperty $_.PSPath } |
    Where-Object { $_.DisplayName -and $_.UninstallString } |
    Sort-Object DisplayName |
    Select-Object DisplayName, DisplayVersion, InstallDate, QuietUninstallString, UninstallString

    $programsList
}

function Select-Item {
    param([Parameter()][string]$PropertyToDisplay,
        [Parameter()][object[]]$ProgramsList)

    $ProgramsList | ForEach-Object -Begin { $Counter = 1 } -Process {
        Write-Host "$Counter. $($_.$PropertyToDisplay)"
        $Counter++
    }

    [int]$Selection = Get-ValidInput "`nSelect Item Number"
    $ProgramsList[$Selection - 1]
}

function Uninstall-Program {
    $AllSoftware = Get-InstalledApps
    $SelectedApp = Select-Item -PropertyToDisplay DisplayName -ProgramsList $AllSoftware

    if ($SelectedApp) {
        Write-Output $SelectedApp
        $AppName = $SelectedApp.DisplayName
        $Response = Confirm-YesNo "`nAre you sure you want to uninstall $AppName ?  Yes[Y] No[N]"

        if ($Response) {
            Start-Process powershell.exe -WindowStyle Hidden -Wait -NoNewWindow -Args @('/c', $SelectedApp.UninstallString)
            [System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic") > $null
            [Microsoft.VisualBasic.Interaction]::MsgBox("Successfully uninstalled $AppName from the computer!", "OKOnly,SystemModal,Information", "Success") > $null
        }
    }
}

function main {
    # Run the program in an elevated PowerShell session if not already running as Administrator
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        $Arguments = "-NoExit -ExecutionPolicy Bypass & '" + $MyInvocation.mycommand.definition + "'"
        Start-Process "$PSHome\powershell.exe" -Verb runAs -ArgumentList $Arguments
        exit
    }

    do {
        Uninstall-Program

        $RerunScript = Confirm-YesNo "`nRun this script again? Yes[Y] No[N] (Default is N)"

        if (!$RerunScript) {
            Write-Host "`nExiting script..."
            break
        }
    } while ($true)
}

main
