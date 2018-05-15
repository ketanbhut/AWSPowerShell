<#
.Synopsis
    Export AWS resources to an HTML file for reporting 

.DESCRIPTION
    The Script will ask for the CSV path where credentials for the user is stored. The credentials file would look like this:
    
    User name,Password,Access key ID,Secret access key,Console login link
    myAPIUser,[*0s5F5Yds9N,AKIdJaJ3BTK242HGBJ,kW9)H5VtESj&CqXO#bKdmj#Q9y877Vs0Ij0sZRuejBw,https://myaws-babysteps.signin.aws.amazon.com/console
    
    It will export below resources, assuming user provided has access, for all regions:
    1.  EC2 Instances 
    2.  EC2 Security Groups
    3.  EC2 KeyPairs
    4.  EC2 Volumes
    5.  EFS FileSystem
    6.  ELB2:  Elastic Load Balancer (Application / HTTP/s)
    7.  ELB :  Elastic Load Balancer Classic
    8.  IAM Roles
    9.  S3 Buckets and S3 Objects
    10. DynamoDB Tables
    11. Lambda Functions
    12. API Gateways
    13. RDS Instances
    14. CloudFront Distribution List
    15. CloudFront Origin Access Identities

.EXAMPLE
   .\AWSHtmlExport.ps1 E:\myAPIUser_credentials.csv

.INPUTS
    CSV file with User credentials for API access. This is the same file that is saved while creating User for API access

.OUTPUTS
    Html file saved at $PSScriptRoot

.NOTES
    Get-MyCostDetails will ustilize Cost Explorer APIs which are chargeable
    That's why we are not using right away. Please use if needed. 
    Source: https://blogs.msdn.microsoft.com/neo/2018/04/21/aws-obtain-blendedcost-billing-data/

.FUNCTIONALITY
    Export AWS resources to HTML
   
    Script by         : Ketan Thakkar (KetanBhut@live.com)
    Script version    : v1.0
    Release date      : 11-May-2018
#>



function TDwithHeading{
<#
    This function is created to return <HR> with heading text in the center. 
    This function will return a table which can be used anywhere to embed in HTML
#>
    param(
        [string]$tdString
    )
 
    $lineTable = "
                <table width='100%' style='background-color:rgb(0,0,111);color:white;'>
                  <tr>
                    <td style='border:none;'><hr /></td>
                    <td style='width:1px; padding: 0 10px; border:none; white-space: nowrap;'>$tdString</td>
                    <td style='border:none;'><hr /></td>
                  </tr>
                </table>
            "
    return $lineTable
}

function DisplayInBytes($num) 
{
    ##########
    # Utilizing code from https://stackoverflow.com/users/11421/mladen-mihajlovic
    # As per the stakeoverflow query https://stackoverflow.com/questions/24616806/powershell-display-files-size-as-kb-mb-or-gb/24617034#24617034: 
    # in order to display size in mb, gb etc.
    ##########

    $suffix = "B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"
    $index = 0
    while ($num -gt 1kb) 
    {
        $num = $num / 1kb
        $index++
    } 

    "{0:N1} {1}" -f $num, $suffix[$index]
}

$awsRegions = Get-AWSRegion

Function Get-EC2InstanceHTML {
<#
    Function to return EC2 instances details HTML format. 
    It will return $ec2Output which contains all Instance details acroos regions in HTML.
#>
    $ec2Output = ""
    foreach ($Region in $awsRegions){
        
        $Instances = Get-EC2Instance -Region $region | Select-Object -ExpandProperty instances 
        if($Instances -ne $null){
            $ec2Output +="<h4>"
            $ec2Output += TDwithHeading "EC2 Instances for the Region: $(($region.Region).ToUpper()) <> $($Region.Name)"
            $ec2Output +="</h4>"
        }
    
        foreach ($instance in $instances){
            $instanceTable =""
            $instanceTable +="<style>td {border-bottom: 1px solid black;}</style>"

            $instanceTable += "<table style='border-top: 3px solid black;border-top-color:green;'>"

            $instanceTable += "<tr> <td>InstanceId: " ;$instanceTable += "<td> $($instance.InstanceId) </tr>" 
            $instanceTable += "<tr> <td>Image ID: " ;$instanceTable += "<td> $($instance.ImageId) </tr>" 
            $instanceTable += "<tr> <td>InstanceType: " ;$instanceTable += "<td> $($instance.InstanceType) </tr>" 
            $instanceTable += "<tr> <td>PublicIpAddress: " ;$instanceTable += "<td> $($instance.PublicIpAddress) </tr>" 
            $instanceTable += "<tr> <td>PublicDnsName: " ;$instanceTable += "<td> $($instance.PublicDnsName) </tr>" 
            $instanceTable += "<tr> <td>KeyName: " ;$instanceTable += "<td> $($instance.KeyName) </tr>" 
            $instanceTable += "<tr> <td>State: " ;$instanceTable += "<td> $($instance.State.Name.Value) </tr>" 
        
            $instanceTable += "</table>"    
            $ec2Output+= $instanceTable
        }
    
    
    }

    return $ec2Output
}

Function Get-EC2VolumeHTML {
<#
    Function to return EC2 volumes details HTML format. 
    It will return $Output which contains all Volume details acroos regions in HTML.
#>
    $Output = ""
    foreach ($Region in $awsRegions){
        
        $Volumes = Get-EC2Volume -Region $region 
        if($Volumes -ne $null){
            $Output +="<h4>"
            $Output += TDwithHeading "EC2 Volumes for the Region: $(($region.Region).ToUpper()) <> $($Region.Name)"
            $Output +="</h4>"
        }

        foreach ($obj in $Volumes){
            $objTable =""
            $objTable +="<style>td {border-bottom: 1px solid black;}</style>"

            $objTable += "<table style='border-top: 3px solid black;border-top-color:green'>"

            $objTable += "<tr> <td>VolumeId: "        ; $objTable += "<td> $($obj.VolumeId) </tr>" 
            $objTable += "<tr> <td>Volume Type: "        ; $objTable += "<td> $($obj.VolumeType) </tr>" 
            $objTable += "<tr> <td>Size: "    ; $objTable += "<td> $($obj.Size) </tr>" 
            $objTable += "<tr> <td>State: " ; $objTable += "<td> $($obj.State) </tr>" 
            $objTable += "<tr> <td>AvailabilityZone: "   ; $objTable += "<td> $($obj.AvailabilityZone) </tr>" 
            $objTable += "<tr> <td>Attachment InstanceId: "         ; $objTable += "<td> $($obj.Attachment.instanceid) </tr>" 
            $objTable += "<tr> <td>Attachment State: "           ; $objTable += "<td> $($obj.Attachment.state.value) </tr>" 
        
            $objTable += "</table>"    
            $Output+= $objTable
        }
    }
    return $Output
}
    


Function Get-EC2SecurityGroupHTML {
<#
    Function to return EC2 Security Group details HTML format. 
    It will return $Output which contains all Security details acroos regions in HTML.
#>
    $Output = ""
    foreach ($Region in $awsRegions){
        
        $SecurityGroups = Get-EC2SecurityGroup -Region $region 
        if($SecurityGroups -ne $null){
            $Output +="<h4>"
            $Output += TDwithHeading "EC2 Security Groups for the Region: $(($region.Region).ToUpper()) <> $($Region.Name)"
            $Output +="</h4>"
        }

        foreach ($obj in $SecurityGroups){
            $objTable =""
            $objTable +="<style>td {border-bottom: 1px solid black;}</style>"

            $objTable += "<table style='border-top: 3px solid black;border-top-color:green'>"

            $objTable += "<tr> <td>Description: "        ; $objTable += "<td> $($obj.Description) </tr>" 
            $objTable += "<tr> <td>GroupId: "        ; $objTable += "<td> $($obj.GroupId) </tr>" 
            $objTable += "<tr> <td>Group Name: "    ; $objTable += "<td> $($obj.GroupName) </tr>" 
            $objTable += "<tr> <td>VpcId: " ; $objTable += "<td> $($obj.VpcId) </tr>" 

            $objTable += "<tr> <td colspan=2 > ==> Inbound: " ; $objTable += "</tr>" 
            foreach($inboundPermissions in $obj.IpPermissions) {
                $objTable += "<tr> <td>Port Range: " ; $objTable += "<td> $($inboundPermissions.FromPort) - $($inboundPermissions.ToPort)</tr>"     
                $objTable += "<tr> <td>&nbsp;&nbsp; Protocol: " ; $objTable += "<td> $($inboundPermissions.IpProtocol) </tr>"     
                $objTable += "<tr> <td>&nbsp;&nbsp; IPv4 Range: " ; $objTable += "<td> $($inboundPermissions.Ipv4Ranges.CidrIp) </tr>"   
            }
            $objTable += "<tr> <td colspan=2>==>  Outbound: " ; $objTable += "</tr>" 
            foreach($outboundPermissions in $obj.IpPermissionsEgress) {
                $objTable += "<tr> <td>Port Range: " ; $objTable += "<td> $($outboundPermissions.FromPort) - $($outboundPermissions.ToPort)</tr>"     
                $objTable += "<tr> <td>&nbsp;&nbsp; Protocol: " ; $objTable += "<td> $($outboundPermissions.IpProtocol) </tr>"     
                $objTable += "<tr> <td>&nbsp;&nbsp; IPv4 Range: " ; $objTable += "<td> $($outboundPermissions.Ipv4Ranges.CidrIp) </tr>"   
            }


            $objTable += "</table>"    
            $Output+= $objTable
        }
    }
    return $Output
}
    


Function Get-EC2KeyPairHTML {
<#
    Function to return EC2 KeyPairs details HTML format. 
    It will return $Output which contains all KeyPair details acroos regions in HTML.
#>
    $Output = ""
    foreach ($Region in $awsRegions){
        
        $KeyPairs = Get-EC2KeyPair -Region $region 
        if($KeyPairs -ne $null){
            $Output +="<h4>"
            $Output += TDwithHeading "EC2 KeyPairs for the Region: $(($region.Region).ToUpper()) <> $($Region.Name)"
            $Output +="</h4>"
        }

        foreach ($obj in $KeyPairs){
            $objTable =""
            $objTable +="<style>td {border-bottom: 1px solid black;}</style>"

            $objTable += "<table style='border-top: 3px solid black;border-top-color:green'>"

            $objTable += "<tr> <td>KeyFingerprint: "        ; $objTable += "<td> $($obj.KeyFingerprint) </tr>" 
            $objTable += "<tr> <td>Key Name: "        ; $objTable += "<td> $($obj.KeyName) </tr>" 
        
            $objTable += "</table>"    
            $Output+= $objTable
        }
    }
    return $Output
}



Function Get-EFSFileSystemHTML {
<#
    Function to return EFS File system details in HTML format. 
    It will return $Output with EFS across regions in HTML.
#>
    # Limiting regions for EFS query to only regions with this service
    # as per below document as on 24APR2018
    # https://docs.aws.amazon.com/general/latest/gr/rande.html

    $efsRegions = ('us-east-2','us-east-1','us-west-1','us-west-2','eu-central-1','eu-west-1','ap-southeast-2')

    $Output = ""

    foreach ($Region in $efsRegions){
        
        $EFSystems = Get-EFSFileSystem -Region $region 
        if($EFSystems -ne $null){
            $Output +="<h4>"
            $Output += TDwithHeading "Elastic File Systems for the Region: $(($region).ToUpper())"
            $Output +="</h4>"
        }

        foreach ($obj in $EFSystems){
            $objTable =""
            $objTable +="<style>td {border-bottom: 1px solid black;}</style>"

            $objTable += "<table style='border-top: 3px solid black;border-top-color:green'>"

            $objTable += "<tr> <td>FileSystemId: "        ; $objTable += "<td> $($obj.FileSystemId) </tr>" 
            $objTable += "<tr> <td>PerformanceMode: "        ; $objTable += "<td> $($obj.PerformanceMode) </tr>" 
            $objTable += "<tr> <td>LifeCycleState: "        ; $objTable += "<td> $($obj.LifeCycleState) </tr>" 
            $objTable += "<tr> <td>SizeInBytes: "        ; $objTable += "<td> $(DisplayInBytes $obj.SizeInBytes.Value) </tr>" 
            $objTable += "<tr> <td>CreationTime: "        ; $objTable += "<td> $($obj.CreationTime) </tr>" 

            $objTable += "</table>"    
            $Output+= $objTable
        }
    }
    return $Output
}



Function Get-ELB2HTML {
<#
    Function to return ELB2 Load Balancer details in HTML format. 
    It will return $Output which contains all ELB2 Load Balancers across regions in HTML.
#>
    $Output = ""
    foreach ($Region in $awsRegions){
        
        $ELB2s = Get-ELB2LoadBalancer -Region $region 
        if($ELB2s -ne $null){
            $Output +="<h4>"
            $Output += TDwithHeading "ELB2 Load Balancers in Region: $(($region.Region).ToUpper()) <> $($Region.Name)"
            $Output +="</h4>"
        }

        foreach ($obj in $ELB2s){
            $objTable =""
            $objTable +="<style>td {border-bottom: 1px solid black;}</style>"

            $objTable += "<table style='border-top: 3px solid black;border-top-color:green'>"

            $objTable += "<tr> <td>LoadBalancerArn: "        ; $objTable += "<td> $($obj.LoadBalancerArn) </tr>" 
            $objTable += "<tr> <td>DNSName: "        ; $objTable += "<td> $($obj.DNSName) </tr>" 
            $objTable += "<tr> <td>VpcId: "        ; $objTable += "<td> $($obj.VpcId) </tr>" 
            $objTable += "<tr> <td>LoadBalancerName: "        ; $objTable += "<td> $($obj.LoadBalancerName) </tr>" 
            $objTable += "<tr> <td>State: "        ; $objTable += "<td> $($obj.state.code.value) </tr>" 
                        
            $objTable += "</table>"    
            $Output+= $objTable
        }
    }
    return $Output
}



Function Get-ELB2TargetGroupHTML {
<#
    Function to return ELB2 Target Groups details in HTML format. 
    It will return $Output which contains all ELB2 Target Groups across regions in HTML.
#>
    $Output = ""
    foreach ($Region in $awsRegions){
        
        $ELB2TargetGroups = Get-ELB2TargetGroup -Region $region 
        if($ELB2TargetGroups -ne $null){
            $Output +="<h4>"
            $Output += TDwithHeading "ELB2 Target Groups in Region: $(($region.Region).ToUpper()) <> $($Region.Name)"
            $Output +="</h4>"
        }

        foreach ($obj in $ELB2TargetGroups){
            $objTable =""
            $objTable +="<style>td {border-bottom: 1px solid black;}</style>"

            $objTable += "<table style='border-top: 3px solid black;border-top-color:green'>"

            $objTable += "<tr> <td>TargetGroupArn: "        ; $objTable += "<td> $($obj.TargetGroupArn) </tr>" 
            $objTable += "<tr> <td>TargetGroupName: "        ; $objTable += "<td> $($obj.TargetGroupName) </tr>" 
            $objTable += "<tr> <td>TargetType: "        ; $objTable += "<td> $($obj.TargetType) </tr>" 
            $objTable += "<tr> <td>LoadBalancerName: "        ; $objTable += "<td> $($obj.LoadBalancerName) </tr>" 
            $objTable += "<tr> <td>VpcId: "        ; $objTable += "<td> $($obj.VpcId) </tr>" 

            if($obj.LoadBalancerArns.Count -ne 0) {
                $objTable += "<tr> <td colspan=2 > ==> LoadBalancerArns: " ; $objTable += "</tr>" 
            }
            else {
                $objTable += "<tr> <td colspan=2 > No LoadBalancers associated " ; $objTable += "</tr>" 
            }
            foreach($LBArn in $obj.LoadBalancerArns) {
                $objTable += "<tr> <td>&nbsp;&nbsp; LoadBalancerArn: " ; $objTable += "<td> $($LBArn) </tr>"     
 
            }
                        
            $objTable += "</table>"    
            $Output+= $objTable
        }
    }
    return $Output
}



Function Get-ELBLoadBalancerHTML {
<#
    Function to return ELB (classic) Load Balancer details in HTML format. 
    It will return $Output which contains all ELB Load Balancers across regions in HTML.
#>
    $Output = ""
    foreach ($Region in $awsRegions){
        
        $ELBLoadBalancers = Get-ELBLoadBalancer -Region $region 
        if($ELBLoadBalancers -ne $null){
            $Output +="<h4>"
            $Output += TDwithHeading "ELB (Classic) Load Balancers in Region: $(($region.Region).ToUpper()) <> $($Region.Name)"
            $Output +="</h4>"
        }

        foreach ($obj in $ELBLoadBalancers){
            $objTable =""
            $objTable +="<style>td {border-bottom: 1px solid black;}</style>"

            $objTable += "<table style='border-top: 3px solid black;border-top-color:green'>"

            $objTable += "<tr> <td>DNSName: "        ; $objTable += "<td> $($obj.DNSName) </tr>" 
            $objTable += "<tr> <td>LoadBalancerName: "        ; $objTable += "<td> $($obj.LoadBalancerName) </tr>" 
            $objTable += "<tr> <td>VPCId: "        ; $objTable += "<td> $($obj.VPCId) </tr>" 
            $objTable += "<tr> <td>LoadBalancerName: "        ; $objTable += "<td> $($obj.LoadBalancerName) </tr>" 
            $objTable += "<tr> <td>VpcId: "        ; $objTable += "<td> $($obj.VpcId) </tr>" 
            $objTable += "<tr> <td>Instances: "        ; $objTable += "<td> <table>"
            
            foreach ($Instance in $obj.Instances){
                $objTable += "<tr><td> $($Instance.InstanceId) </tr>"
            }
            $objTable += "</table></tr>"
            

            $objTable += "<tr> <td colspan=2 > ==> ListnerDescription: " ; $objTable += "</tr>" 
            foreach($ListnerDesc in $obj.ListenerDescriptions) {
                $objTable += "<tr> <td>InstancePort: " ; $objTable += "<td> $($ListnerDesc.Listener.InstancePort) </tr>"     
                $objTable += "<tr> <td>&nbsp;&nbsp; InstanceProtocol: " ; $objTable += "<td> $($ListnerDesc.Listener.InstanceProtocol) </tr>"     
                $objTable += "<tr> <td>&nbsp;&nbsp; LoadBalancerPort: " ; $objTable += "<td> $($ListnerDesc.Listener.LoadBalancerPort) </tr>"     
                $objTable += "<tr> <td>&nbsp;&nbsp; Protocol: " ; $objTable += "<td> $($ListnerDesc.Listener.Protocol) </tr>"     
            }
                        
            $objTable += "</table>"    
            $Output+= $objTable
        }
    }
    return $Output
}



$mainHtmlBody = Get-EC2InstanceHTML
$mainHtmlBody += Get-EC2VolumeHTML
$mainHtmlBody += Get-EC2SecurityGroupHTML
$mainHtmlBody += Get-EC2KeyPairHTML
$mainHtmlBody += Get-EFSFileSystemHTML
$mainHtmlBody += Get-ELB2HTML
$mainHtmlBody += Get-ELB2TargetGroupHTML
$mainHtmlBody += Get-ELBLoadBalancerHTML

ConvertTo-Html -body $mainHtmlBody -Title "some meh"|Out-File "$PSScriptRoot\abcd.html"
