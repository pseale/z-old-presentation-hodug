properties {
  $baseDirectory = resolve-path .
  $buildDropFolder = 'C:\temp\build'
  $packageDropFolder = 'C:\temp\package'
  $environments = @('dev', 'qa', 'staging', 'test', 'training', 'acceptance', 'prod')
  $versionNumber = "1.1.1.1" #Don't do this. for real version numbers, generate the version number in TeamCity and pass it into the script as an argument somehow.
  $assemblyInfo = @{
    "title" = "HODUGWeb";
    "description" = 'Web application demo for HODUG';
    "company" = "HODUG Enterprises";
    "product" = "HODUGWeb";
    "version" = $versionNumber;
    "copyright" = "Copyright 2011 HODUG Enterprises. All Rights Reserved";
  }
  
  $appSettings = @{
    "dev" = @{ "VIPName" = "Peter in our DEV ENVIRONMENT" };
    "qa" = @{ "VIPName" = "Peter in our QA ENVIRONMENT" };
    "staging" = @{ "VIPName" = "Peter in our STAGING ENVIRONMENT" };
    "test" = @{ "VIPName" = "Peter in our TEST ENVIRONMENT" };
    "training" = @{ "VIPName" = "Peter in our TRAINING ENVIRONMENT" };
    "acceptance" = @{ "VIPName" = "Peter in our ACCEPTANCE ENVIRONMENT" }
  }
}

task default -depends build

task compile {
    dir -path $baseDirectory -include "AssemblyInfo.cs" -recurse | foreach {
        write-host "Editing $($_.fullname)"
        $assemblyInfo["file"] = $_.fullname
        Generate-AssemblyInfo @assemblyInfo #Note "@" is the splatting operator. This means dictionary keys of the "$assemblyInfo" hashtable are matched up against function args.
    }

  & 'C:\windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe' 'MvcApplication3\MvcApplication3.csproj' "/t:Package" "/p:OutDir=$($buildDropFolder)\"
}

task build -depends compile {
       Change-WebConfigUsingNativeXmlSupport $folder $_
}

task dbmigrate {
}

task deploy {
  #(Continuous Deployment) deploy from CI build to dev environment automatically
  powershell ./deploy.ps1 -name dev6 -port 81 -sourceFolder "'$buildDropFolder'"
}

#-=-=-=-=-=-=-=-=- -=-=-=-=-=-=-=-=- -=-=-=-=-=-=-=-=-
#stolen from Ayende's rhino-esb psake script
function Generate-AssemblyInfo
{
param(
[string]$clsCompliant = "true",
[string]$title,
[string]$description,
[string]$company,
[string]$product,
[string]$copyright,
[string]$version,
[string]$file = $(throw "file is a required parameter.")
)
  $commit = Get-GitCommit
  $asmInfo = "using System;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

[assembly: CLSCompliantAttribute($clsCompliant )]
[assembly: ComVisibleAttribute(false)]
[assembly: AssemblyTitleAttribute(""$title"")]
[assembly: AssemblyDescriptionAttribute(""$description"")]
[assembly: AssemblyCompanyAttribute(""$company"")]
[assembly: AssemblyProductAttribute(""$product"")]
[assembly: AssemblyCopyrightAttribute(""$copyright"")]
[assembly: AssemblyVersionAttribute(""$version"")]
[assembly: AssemblyInformationalVersionAttribute(""$version / $commit"")]
[assembly: AssemblyFileVersionAttribute(""$version"")]
[assembly: AssemblyDelaySignAttribute(false)]
"

$dir = [System.IO.Path]::GetDirectoryName($file)
if ([System.IO.Directory]::Exists($dir) -eq $false)
{
Write-Host "Creating directory $dir"
[System.IO.Directory]::CreateDirectory($dir)
}
Write-Host "Generating assembly info file: $file"
Write-Output $asmInfo > $file
}

function Get-GitCommit
{
$gitLog = git log --oneline -1
return $gitLog.Split(' ')[0]
}

function Get-VersionFromGitTag
{
  $gitTag = git describe --tags --abbrev=0
  return $gitTag.Replace("v", "") + ".0"
}




function Change-WebConfigUsingNativeXmlSupport($folder, $environ) {
  $filename = join-path $folder "web.config"
  $webConfig = [xml](cat ($filename))
  $webConfig.configuration.appSettings.add `
    | ? { $appSettings[$environ].Keys -contains $_.key } `
    | % { $_.value = $appSettings[$environ][$_.key] } 
      
  $webConfig.Save($filename)
}