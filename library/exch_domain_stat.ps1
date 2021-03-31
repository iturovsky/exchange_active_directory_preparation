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
$module.Result.Add('domain_prepared', $false)

$params = @{}

if ($module.Params.username -and $module.Params.password)
{
    [securestring]$secStringPassword = ConvertTo-SecureString $module.Params.password -AsPlainText -Force
    [pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)
    $params.Add('Credentials', $credObject)
}

Try
{
    $domainNC = Get-ADRootDSE -ErrorAction Stop @params | select -ExpandProperty DefaultNamingContext
    $SystemObjectsContainer = 'CN=Microsoft Exchange System Objects'+','+$domainNC
    $ExchangeSystemObjectsContainer = Get-ADObject -Identity $SystemObjectsContainer -ErrorAction Stop @params -Properties objectVersion
    $module.Result.exch_system_object_version = $ExchangeSystemObjectsContainer.objectVersion
    $module.Result.domain_prepared = $true
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
{
    # it is ok if Exchange is not installed yet
}
catch
{
    Write-Error -Message "Unable to query AD for Exchange System Object Container: $($_.exception.message)"
}
$module.ExitJson()