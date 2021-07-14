Function Get-VSphereCertificateDetails {
<#
    .NOTES
    ===========================================================================
    Created by:    William Lam
    Organization:  VMware
    Blog:          www.williamlam.com
    Twitter:       @lamw
    ===========================================================================
    .DESCRIPTION
        This function returns the certificate mode of vCenter Server along with
        the certificate details of each ESXi hosts being managed by vCenter Server
    .EXAMPLE
        Get-VSphereCertificateDetails

    if($global:DefaultVIServer.ProductLine -eq "vpx") {
        $vCenterCertMode = (Get-AdvancedSetting -Entity $global:DefaultVIServer -Name vpxd.certmgmt.mode).Value
        Write-Host -ForegroundColor Cyan "`nvCenter $(${global:DefaultVIServer}.Name) Certificate Mode: $vCenterCertMode"
    }
#>
# Shell out details of all connected vCenters
$global:DefaultVIServers | select Name, @{N="Productline"; E={$_.productline}}, @{N="vCenterCertMode"; E={(Get-AdvancedSetting -Entity $_ -Name vpxd.certmgmt.mode).Value}}

$results = @()
    $vmhosts = Get-View -ViewType HostSystem -Property Name,ConfigManager.CertificateManager
    foreach ($vmhost in $vmhosts) {
    # For few hosts the API reported more than 1 certificate so adding another loop to capture them all
        $certConfigs = (Get-View $vmhost.ConfigManager.CertificateManager).CertificateInfo
        foreach ($certConfig in $certConfigs) {
            if($certConfig.Subject -match "vmca@vmware.com") {
                $certType = "VMCA"
            } else {
                $certType = "Custom"
            }
            $tmp = [PSCustomObject] @{
                vCenter = $vmhost.client.ServiceUrl.split("/")[2];
                VMHost = $vmhost.Name;
                CertType = $certType;
                CertCount = $certConfig.count;
                Status = $certConfig.Status;
                Expiry = $certConfig.NotAfter;
                Created = $certConfig.NotBefore;
                Issuer = $certConfig.Issuer;
                Subject = $certConfig.subject;
            }
            $results+=$tmp
        }
    }
    $results
}
