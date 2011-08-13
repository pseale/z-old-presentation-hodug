param($name, $port)
import-module WebAdministration

$site = new-website $name
$site.PhysicalPath = "C:\inetpub\sites\$name"
$websiteFolder = join-path $buildDropFolder "_PublishedWebsites\MvcApplication3"
copy -recurse $websiteFolder $site.PhysicalPath
