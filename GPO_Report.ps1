<#
	.SYNOPSIS
  		Grabs various GPO and ADMX activity to streamline GPO investigations within Active Directory.
    
	.DESCRIPTION
		A description of the file.
	
	.PARAMETER Path
		A description of the Path parameter.
	
	.PARAMETER UserList
		A description of the UserList parameter.
	
	.NOTES
		===========================================================================
		Created on:   	8/23/2024 14:03
		Created by:   	Noah Rincon
		Usage: Run script, no arguments needed
		===========================================================================
#>

#Definte Results Directory
$ResultsDirectory = C:\Windows\Temp\Unit42_GPOReport\Unit42_GPOReport
$SYSVOLFolder = Get-ChildItem -Path $env:SystemRoot | Where-Object {$_.PsIsContainer -and $PSItem.Name -like "*sysvol*"} | Select -ExpandProperty FullName

function Check-Results-Directory {
	if ((Test-Path $ResultsDirectory) -eq $True) {
	#Clear files

	Write-Host "Creating directory..."
	[void](New-Item -ItemType "directory" -Path $ResultsDirectory)
	}
	else {
		[void]New-Item -ItemType "directory" -Path $ResultsDirectory 
	}
}


function Check-Cmdlets {
}

function GenerateGPOReport {
	#Create directory
	Write-Host "Generating GPO Report..."

	$Report = Join-Path $ResultsDirectory "GPOReport.html"
	Get-GPOReport -All -ReportType Html -Path $Report
}

function List-ADMX-Directories {
	#Define pathways
	#$LocalADMX = "C:\Windows\PolicyDefinitions"
	$DomainADMX = Join-Path $SYSVOLFolder "domain\Policies\PolicyDefinitions"
	
	#Define results path
	$Results = Join-Path $ResultsDirectory "ADMX_PolicyDefinitions_ModTimes.csv"

	#Grab results and export CSV
	Write-Host "Grabbing ADMX Central Store file tree..."
	Get-ChildItem -Path $DomainADMX -Recurse -Directory -Force -ErrorAction SilentlyContinue | Sort-Object ModificationTime -Descending | Select-Object FullName, CreationTime, LastWriteTime, LastAccessTime, Mode, LinkType, Target | export-csv -NoTypeInformation -path $Results
}

function List-GPOModifications { 
	#Define results path
    $Results = Join-Path $ResultsDirectory "GPO_ModTimes.csv"
	
	#Grab results and export CSV
	Write-Host "Grabbing GPO modification times..."
	Get-GPO -All | Sort-Object ModificationTime -Descending | Select-Object DisplayName, ModificationTime, CreationTime, DomainName, Owner, Id, GpoStatus, Description, UserVersion, ComputerVersion, WmiFilter  | export-csv -NoTypeInformation -path $Results
}

function List-GPO-File-Modiciations {
	#Define pathways
	$DomainPolicies = Join-Path $SYSVOLFolder "domain\Policies"

	#Define results path
	$Results = Join-Path $ResultsDirectory "GPO_File_ModTimes.csv"

	#Grab results and export CSV
	Write-Host "Grabbing GPO policiy file tree..."
    Get-ChildItem -Path $DomainPolicies -Recurse -Directory -Force -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object FullName, CreationTime, LastWriteTime, LastAccessTime, Mode, LinkType, Target | export-csv -NoTypeInformation -path $Results
}

function List-GPO-ACls {
	
}

function Check-GPO-Password {
	#Search for passwords in GPO
	#findstr /S /I cpassword \\<FQDN>\sysvol\<FQDN>\policies\*.xml
}

function Zip-Results {
	#Zip results directory
	$ZipOutput = Join-Path $ResultsDirectory "GPOResults.zip"
	Compress-Archive -Path $ResultsDirectory\* -DestinationPath $ZipOutput
	#Cleanup files
}

Check-Results-Directory
GenerateGPOReport
List-ADMX-Directories
List-GPOModifications
List-GPO-File-Modiciations
Zip-Results
