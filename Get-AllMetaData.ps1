#Requires -Module AWSPowerShell
<#PSScriptInfo

.VERSION 1.0

.GUID 1cf016fc-8860-46df-bc50-b5cd08c1b7a0

.AUTHOR thaketan

.COMPANYNAME Amazon

.COPYRIGHT 2017 Amazon

.TAGS EC2 Amazon AWS

.LICENSEURI https://code.amazon.com/licenseuri

.PROJECTURI https://github.com/ketanbhut/AWSPowerShell/blob/master/Get-AllMetaData.ps1

.ICONURI 

.EXTERNALMODULEDEPENDENCIES AWSPowerShell

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES


#>

<# 
.SYNOPSIS
    Displays EC2-metadata

.DESCRIPTION 
    This script collects all instance meta-data from http://169.254.169.254/latest/meta-data
    and extracts values of each property. We can filter it and/or can 
    include all network information, and returns a custom collection psobject
    This Script is supposed to be run within the EC2-Windows Instance.  

#> 



<#

.EXAMPLES
    1. PS C:\Users\kt\Documents> .\Get-AllMetaData.ps1 public
        
    public-hostname                                    public-ipv4    public-keys
    ---------------                                    -----------    -----------
    ec2-34-248-252-238.eu-west-1.compute.amazonaws.com 34.248.252.238 0=ireland-jul18

    - Above command obtains EC2 instance metadata and filters properties matching 'public'

    2.  PS C:\Users\kt\Documents> .\Get-AllMetaData.ps1 -Filter subnet -IncludeNetworkInfo

        mac-0-subnet-id mac-0-subnet-ipv4-cidr-block
        --------------- ----------------------------
        subnet-7d478827 172.31.32.0/20

    - Above command filters metadata for properties matching 'subnet' with all Mac info
    
    3.  PS C:\Users\kt\Documents> $device = "block"
        PS C:\Users\kt\Documents> $device | .\Get-AllMetaData.ps1

        block-device-mapping/ami block-device-mapping/root
        ------------------------ -------------------------
        /dev/sda1                /dev/sda1
    
    - Above command receives string from the pipeline and filters metadata output on the 
    basis of properties matching with the string input.

.PARAMETER IncludeNetworkInfo
    Switch parameter: It will include all metadata under meta-data/network/interfaces/macs/

.PARAMETER Filter
    String parameter: It will perform wild card filter the output by reducing 
    properties we want to focus
    
.NOTES
    Version  : 1.0
    Date     : 8-Aug-18
    Contact  : thaketan@amazon.com
#>
param(
    [Parameter(Mandatory=$false)]
    [switch]$IncludeNetworkInfo,
    [Parameter(Mandatory=$false,Position=0,ValueFromPipeline=$true)]
    [string]$Filter

)
function get-metadata{
	param(
		[parameter(mandatory=$true)]
		[string]$FragmentPart
	)
	try{
		$iMetadataUrl = "http://169.254.169.254/latest/$($FragmentPart)"
		$request = [System.Net.HttpWebRequest]::CreateHttp($iMetadataUrl)
		$response = $request.GetResponseAsync().Result
		$stream = $response.GetResponseStream()
		$streamReader = New-object System.IO.StreamReader($stream)
		$result = $streamReader.ReadToEnd()
	}
	catch {
		Write-Output "Failed to get metadata: $($_.Exception.Message)"
	}
	return $result
}

$UrlParts = (Get-Metadata meta-data).Split([Environment]::NewLine)

$metadataHash = [System.Collections.SortedList]@{}
foreach ($fragment in $UrlParts) {
    if($fragment -eq 'block-device-mapping/'){
        $metadata = (Get-Metadata "meta-data/$($fragment)").split([System.Environment]::NewLine)
        foreach($metaDevice in $metadata){
            $metaDeviceValue = (Get-Metadata "meta-data/$($fragment)/$($metaDevice)")
            $metadataHash.Add("$fragment$metaDevice",$metaDeviceValue)
        }
    }
    elseif($fragment -eq 'iam/'){
        $metadata = (Get-Metadata "meta-data/$($fragment)").split([System.Environment]::NewLine)
        foreach ($meta in $metadata){
            if($meta -eq 'security-credentials/'){
                $metadataCreds = Get-Metadata "meta-data/$($fragment)/$($meta)"
                foreach ($cred in $metadataCreds){
                    $metaCred = Get-Metadata "meta-data/$($fragment)/$($meta)/$($cred)"
                    $metadataHash.Add([string]::Concat($fragment,$meta,$cred),$metaCred)
                }
            }
            else {
                $metaValue = Get-Metadata "meta-data/$($fragment)/$($meta)"
                $metadataHash.Add([string]::Concat($fragment,$meta),$metaValue)
            }
        }
    }
    elseif($fragment -eq 'network/'){
        $macsPath = "meta-data/network/interfaces/macs/"
        $macs =(Get-Metadata $macsPath).split([System.Environment]::NewLine)

        if($IncludeNetworkInfo){
            foreach ($mac in $macs) {
                $macDataPath = [string]::Concat($macsPath,$mac)
                $macDataIPath = (Get-Metadata $macDataPath).Split([System.Environment]::NewLine) #getting leafs after mac path as array
                foreach ($macDataLeaf in $macDataIPath) {
                    $macDataValue = Get-Metadata ([string]::Concat($macDataPath,$macDataLeaf))
                    $metadataHash.Add([string]::Concat("mac-$($macs.IndexOf($mac))-", $macDataLeaf.Replace('/','')),$macDataValue)
                }
            }
        }
    }
    elseif($fragment -eq 'Services/'){
        $servicesPath = "meta-data/services/"
        $srvMembers =(Get-Metadata $servicesPath).Split([System.Environment]::NewLine)
        foreach ($srvMem in $srvMembers){
            $srvData = Get-Metadata ([string]::Concat($servicesPath,$srvMem))
            if(!($metadataHash.ContainsKey($srvMem))){
                $metadataHash.Add([string]::Concat($fragment,$srvMem),$srvData)
            }
        }
    }
    elseif($fragment -eq 'metrics/'){
        $metricsMems = (Get-Metadata "meta-data/$($fragment)").Split([System.Environment]::NewLine)
        foreach($metric in $metricsMems){
            $metricData = Get-Metadata "meta-data/$($fragment)/$($metric)"
            $metadataHash.Add([string]::Concat($fragment,$metricsMems),$metricData)
        }
    }
    elseif($fragment -eq 'placement/'){
        $fragData = Get-Metadata "meta-data/$($fragment)/availability-zone"
        $metadataHash.Add("availability-zone",$fragData)
    }
    
    else {
        $metadata = Get-Metadata "meta-data/$($fragment)"
        if(!($metadataHash.ContainsKey($fragment.Replace('/','')))){
            $metadataHash.Add($($fragment.Replace('/','')),$metadata)
        }
    }
}

$MetaDataPS = New-Object psobject -Property $metadataHash
if($Filter){
    $MetaDataPS| Select-Object -Property "*$Filter*"
}

else{
    return $MetaDataPS
}


# SIG # Begin signature block
# MIIFhQYJKoZIhvcNAQcCoIIFdjCCBXICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUWBkbmkiovNDpJIZGfJzvU+IZ
# QV6gggMYMIIDFDCCAfygAwIBAgIQfVFuQooNTI1BB7+F88vuizANBgkqhkiG9w0B
# AQsFADAiMSAwHgYDVQQDDBdQb3dlclNoZWxsIENvZGUgU2lnbmluZzAeFw0xODA3
# MjgwNjExMTBaFw0xOTA3MjgwNjMxMTBaMCIxIDAeBgNVBAMMF1Bvd2VyU2hlbGwg
# Q29kZSBTaWduaW5nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwaeA
# gsWmXGGo25zAmM1Q4Rz/1gPpMRND41fl35yk+5oQ7A4uLOHqnCkw4Q/p7olxPP8V
# MX2EXO4hKsOb13GYUlB/1tWFDjj7FqxAIQPMqNjal7KfSiQRfny8iGRR4L3lum4W
# PD4AL0/3PIv/eN3A91cSVF61o8IiTPJRagILedT/cVaf5CLNWlZLjXOU0bQ7Mkc2
# FbCYad/ksg3V/JJKbYNmm0/WTJ0w4zCSyT2MA40kqyx7GPrQMeRDeDLRKm0zcqyI
# gT9PtF5kvSdUpgPTt2vpnPNkRE6AS1F94r/fWR4Yp56inMotGFbi9nLrrKV+m06T
# wPJoJSRlOEOUYDFp1QIDAQABo0YwRDAOBgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAww
# CgYIKwYBBQUHAwMwHQYDVR0OBBYEFAnYSIXfT5vrjA2//wthxxwguT7KMA0GCSqG
# SIb3DQEBCwUAA4IBAQBzkjyPCBdqDSholyZ9AhzIAhNnLWviW8vfB/ZDsJ7XfNmF
# 2atC/6MqhaFkQA5WsrGtkZMbF0Kg40P1U6/5IE7wt2pX1ZHzXdeDTry1oFIcBnvW
# XLe7NhI2F2ufov1gR6ZS/CdaAMZVX8FDTYpIMrm5K+7IGgNTPU4VK6Q+HzSrpJ/k
# eM7/ej1ZjlNre04+l0HTZf16v9AOkKCH+w8nojTaKETPImAVQUuvcBAf7LftVwOD
# 0IZ1PxQ8SstBTBoBx894K3N4LCzbClQl4mrXzrreNiQhKz5S7cwiyvxsxVoOWSEZ
# yybabhc8y675QXxei7YG0I7HmFF+sV8+WeQCvm4cMYIB1zCCAdMCAQEwNjAiMSAw
# HgYDVQQDDBdQb3dlclNoZWxsIENvZGUgU2lnbmluZwIQfVFuQooNTI1BB7+F88vu
# izAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG
# 9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIB
# FTAjBgkqhkiG9w0BCQQxFgQUgKF7GL7UPp/1Xlx10v09WL+qhkAwDQYJKoZIhvcN
# AQEBBQAEggEAQg3O/XDtoWqIawkMgY4nTSDhxrTVu69yU0ompY4YOuejh9XBt2K/
# uDpdKh9osgYpso8FWrrdgbiXGOaLkQGMRuOaTsOQSgQtBPXWnXu+CCUTIjY0wp0y
# lp6ZvsAuG9+OcDJ4Hjb7h1P+fqFpZXW1D+yMXJOCPfyxZIgqQOanvM9k5K7YD+lI
# m5atjfflZJXNZCR2rwHN6NhNk38cpUGLvHVQi9Wy54dm+sgnkQd8DbIo/RaHvMr3
# gEspiA8P/LyatjekMUGikyVo1BedEZ1b55xRuHc+RAEbhZE/1prFU2yrd2pVFlAz
# ZLozRxTkY0EPOjDOFipYJlxGZqtQwAhmSA==
# SIG # End signature block
