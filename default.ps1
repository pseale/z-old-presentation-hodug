properties {
  $baseDirectory = resolve-path .
  $buildOutputDirectory = [IO.Path]::Combine($baseDirectory, "build")
  $packageOutputDirectory = ([IO.Path]::Combine($baseDirectory, "artifacts"))
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
    "acceptance" = @{ "VIPName" = "Peter in our ACCEPTANCE ENVIRONMENT" };
    "production" = @{ "VIPName" = "Peter" };
  }
}

task clean {
  Compile-Project -msbuildTargetsString "Clean"
  del $buildOutputDirectory -recurse -force -erroraction SilentlyContinue
  del $packageOutputDirectory -recurse -force -erroraction SilentlyContinue
  #what else would you put here? 
  #-Delete the local db?
  #-Clear local cache or other oddball filesystem artifacts you may have?
  #-Shut down IIS? Or at least, bump your app pool?
}

task default -depends build

#default build - build deployable package with MSDeploy
task build {
    Compile-Project -msbuildTargetsString "Package"
}

task buildWithManualXmlEdits {
    if ($environment -eq $null) { throw 'Environment parameter is null but must be set to run a build with manual XML edits! Call psake with it set, e.g. ''psake -parameters @{"environment"="dev"}''' }
    Compile-Project -msbuildTargetsString "Build"
    Copy -recurse -path ([IO.Path]::Combine($buildOutputDirectory, "_PublishedWebsites\MvcApplication3")) -destination $packageOutputDirectory
    Change-WebConfigUsingNativeXmlSupport -folder $packageOutputDirectory -environment $environment
}

task dbmigrate {
}

task deploy {
  #(Continuous Deployment) deploy from CI build to dev environment automatically
  #powershell ./deploy.ps1 -name dev6 -port 81 -sourceFolder "'$buildDropFolder'"
}

#-=-=-=-=-=-=-=-=- -=-=-=-=-=-=-=-=- -=-=-=-=-=-=-=-=-
#stolen from Ayende's rhino-esb psake script

function Compile-Project($msbuildTargetsString) {
    dir -path $baseDirectory -include "AssemblyInfo.cs" -recurse | foreach {
        write-host "CHANGING ASSEMBLYINFO.CS FILE AT: '$($_.fullname)'"
        $assemblyInfo["file"] = $_.fullname
        Generate-AssemblyInfo @assemblyInfo #Note "@" is the splatting operator. This means dictionary keys of the "$assemblyInfo" hashtable are matched up against function args.
    }
    
  & 'C:\windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe' 'MvcApplication3\MvcApplication3.csproj' "/t:$($msbuildTargetsString)" "/p:OutDir=$($buildOutputDirectory)\"
}

function Generate-AssemblyInfo {
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

function Get-GitCommit {
  $gitLog = git log --oneline -1
  return $gitLog.Split(' ')[0]
}

function Get-VersionFromGitTag {
  $gitTag = git describe --tags --abbrev=0
  return $gitTag.Replace("v", "") + ".0"
}

function Change-WebConfigUsingNativeXmlSupport($folder, $environment) {
  $filename = join-path $folder "web.config"
  $webConfig = [xml](cat ($filename))
  $webConfig.configuration.appSettings.add `
    | ? { $appSettings[$environment].Keys -contains $_.key } `
    | % { $_.value = $appSettings[$environment][$_.key] } 
      
  $webConfig.Save($filename)
}