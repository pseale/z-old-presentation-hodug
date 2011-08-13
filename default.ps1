properties {
  $buildDropFolder = 'C:\temp\build'
  $packageDropFolder = 'C:\temp\package'
  $environments = @('dev', 'qa', 'staging', 'test', 'training', 'acceptance')
  
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
  & 'C:\windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe' 'MvcApplication3\MvcApplication3.csproj' "/t:Package" "/p:OutDir=$($buildDropFolder)\"
}

task build -depends compile {
    $environments | % {
        $folder = join-path $packageDropFolder $_
        del -force -recurse $folder -errorAction silentlycontinue
        mkdir $folder
        copy -force -recurse $buildDropFolder $folder
        Change-WebConfigUsingNativeXmlSupport $folder $_
    }
}

task deploy {
  powershell ./deploy.ps1 -name dev6 -port 81 -sourceFolder "'$buildDropFolder'"
}

function Change-WebConfigUsingNativeXmlSupport($folder, $environ) {
  $filename = join-path $folder "web.config"
  $webConfig = [xml](cat ($filename))
  $webConfig.configuration.appSettings.add `
    | ? { $appSettings[$environ].Keys -contains $_.key } `
    | % { $_.value = $appSettings[$environ][$_.key] } 
      
  $webConfig.Save($filename)
}