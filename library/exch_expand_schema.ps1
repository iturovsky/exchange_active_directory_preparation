#!powershell

# Copyright: (c) 2020 Igor Turovsky, igturovsky@gmail.com
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic
#Requires -Module Ansible.ModuleUtils.CommandUtil

$spec = @{
    options = @{
        usernname = @{type = 'str'}
        password  = @{type = 'str'}
        setup_binary_path = @{type='path'}
    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$SetupPath = $module.Params.setup_path
 if  (-not (Test-Path $SetupPath -pathType Leaf ))
 {
     Write-Error -Message "Unable to find $($SetupPath)"
 }



$SchemaExpandCommand = $SetupPath + '/IAcceptExchangeServerLicenseTerms /PrepareSchema'

$SchemaExpansion = Run-Command -Command $SchemaExpandCommand 