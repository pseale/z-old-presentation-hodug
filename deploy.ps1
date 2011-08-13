param($name, $port, $sourceFolder)

import-module WebAdministration

$site = new-website -force $name
$site.PhysicalPath = "C:\inetpub\sites\$name"
$websiteFolder = join-path $sourceFolder "_PublishedWebsites\MvcApplication3"
copy -recurse -force $websiteFolder $site.PhysicalPath
