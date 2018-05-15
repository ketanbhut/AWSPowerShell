<#
.Synopsis
    Obtain Cost data utilizing AWS Cost Explorer API

.DESCRIPTION
    Cost details depending on various parameters provided. 

.EXAMPLE
   Get-MyCostDetails

.INPUTS
    No inputs, it is assumed that the user has proper access to call AWS API

.OUTPUTS
    Function Get-MyCostDetails

.NOTES
    Get-MyCostDetails will ustilize Cost Explorer APIs which are chargeable
    That's why we are not using right away. Please use if needed. 
    Source: https://blogs.msdn.microsoft.com/neo/2018/04/21/aws-obtain-blendedcost-billing-data/

.FUNCTIONALITY
    Billing
   
    Script by         : Ketan Thakkar (KetanBhut@live.com)
    Script version    : v1.0
    Release date      : 11-May-2018
#>

function Get-MyCostDetails
{
    #Print cost details for the Account for current month 
    '*'*44
    Write-Host "Printing cost details for the Account for current month" -BackgroundColor White -ForegroundColor DarkBlue
    '*'*44


    $currDate = Get-Date
    $firstDay = Get-Date $currDate -Day 1 -Hour 0 -Minute 0 -Second 0
    $lastDay = Get-Date $firstDay.AddMonths(1).AddSeconds(-1)
    $firstDayFormat = Get-Date $firstDay -Format 'yyyy-MM-dd'
    $lastDayFormat = Get-Date $lastDay -Format 'yyyy-MM-dd'



    $interval = New-Object Amazon.CostExplorer.Model.DateInterval
    $interval.Start = $firstDayFormat
    $interval.End = $lastDayFormat

    $costUsage = Get-CECostAndUsage -TimePeriod $interval -Granularity MONTHLY -Metric BlendedCost

    $costUsage.ResultsByTime.Total["BlendedCost"]

    # Valid Dimension values are: AZ, INSTANCE_TYPE, LINKED_ACCOUNT,OPERATION, PURCHASE_TYPE, 
    # SERVICE, USAGE_TYPE, USAGE_TYPE_GROUP, PLATFORM, TENANCY, RECORD_TYPE,LEGAL_ENTITY_NAME, 
    # DEPLOYMENT_OPTION, DATABASE_ENGINE, CACHE_ENGINE, INSTANCE_TYPE_FAMILY, REGION

    #$serviceDimention = Get-CEDimensionValue -TimePeriod $interval -Dimension SERVICE
}
