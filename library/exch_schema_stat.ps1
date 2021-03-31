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


$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$module.Result.Add('schema_version', $null)
$module.Result.Add('schema_expanded', $false)

$AdModule = Get-Module ActiveDirectory -ListAvailable
if (-not $Admodule)
{
    $module.FailJson("ActiveDirectory module is not found")
}

$params = @{}

if ($module.Params.username -and $module.Params.password)
{
    [securestring]$secStringPassword = ConvertTo-SecureString $module.Params.password -AsPlainText -Force
    [pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)
    $params.Add('Credentials', $credObject)
}

Try
{
    $SchemaNC = Get-ADRootDSE -ErrorAction Stop @params | select -ExpandProperty schemaNamingContext
    $SchemaVersionPath = 'CN=ms-Exch-Schema-Version-Pt' + ',' + $SchemaNC
}
catch
{
    Write-Error -Message "Unable to get root DSE: $($_.exception.message)" -ErrorAction Stop
}

try
{
    $schemaVersion =  Get-ADObject -Identity $SchemaVersionPath -Properties rangeUpper -ErrorAction Stop @params  | select -ExpandProperty rangeUpper
    $module.Result.schema_expanded = $true
    $module.Result.schema_version =  $schemaVersion 
}

catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
{
    # it is ok if Exchange is not installed yet
}
catch
{
    Write-Error -Message "Unable to query schema version object: $($_.exception.message)" -ErrorAction Stop
}

$module.ExitJson()