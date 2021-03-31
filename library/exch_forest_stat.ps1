#!powershell

# Copyright: (c) 2020 Igor Turovsky, igturovsky@gmail.com
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#Requires -Modules ActiveDirectory

$spec = @{
    options = @{
        usernname = @{type = 'str'}
        password  = @{type = 'str'; no_log = $true}
    }
    required_together = @(
            ,@('username', 'password')
    )
    supports_check_mode = $true
}

$AdModule = Get-Module ActiveDirectory -ListAvailable
if (-not $Admodule)
{
    $module.FailJson("ActiveDirectory module is not found")
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$module.Result.Add('exch_system_object_version', $null)
$module.Result.Add('forest_prepared', $false)
$module.Result.Add('exch_organization_name', $null)



$params = @{}

if ($module.Params.username -and $module.Params.password)
{
    [securestring]$secStringPassword = ConvertTo-SecureString $module.Params.password -AsPlainText -Force
    [pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)
    $params.Add('Credentials', $credObject)
}

Try
{
    $configurationNC = Get-ADRootDSE -ErrorAction Stop @params | select -ExpandProperty configurationNamingContext
    $ServicesContainer = 'CN=Services'+','+$configurationNC
    $ExchangeConfigurationContainer = Get-ADObject -SearchBase  $ServicesContainer -SearchScope Onelevel -Filter {name -eq 'Microsoft Exchange'} -ErrorAction Stop @params
    If ($ExchangeConfigurationContainer)
    {
        $ExchangeOrganizationContainer = Get-ADObject -SearchBase $ExchangeConfigurationContainer.DistinguishedName -SearchScope Onelevel @params -ErrorAction Stop `
        -Filter {ObjectClass -eq 'msExchOrganizationContainer'} -Properties objectVersion
        if ($ExchangeOrganizationContainer)
        {
            $module.Result.forest_prepared = $true
            $module.Result.exch_system_object_version = $ExchangeOrganizationContainer.objectVersion
            $module.Result.exch_organization_name = $ExchangeOrganizationContainer.name
        }
    }
}
catch
{
    Write-Error -Message "Unable to query AD for Exchange Organization Container: $($_.exception.message)"
}
$module.ExitJson()