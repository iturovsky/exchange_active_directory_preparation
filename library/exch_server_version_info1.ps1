#!powershell

# Copyright: (c) 2020 Igor Turovsky, igturovsky@gmail.com
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{

    }
    supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)
$module.Result.Add('ExchangeInstalled', $false)
$module.Result.Add('ExchangeVersion', $null)
$module.Result.Add('ExchangeSetupCompleted', $false)


$params = @{}


Try
{
    $ExSetup = Get-Command -Name 'exsetup.exe'
    $ExVersion = $exSetup.version.ToString()
    $module.Result['ExchangeInstalled'] =$true
    $module.Result['ExchangeVersion'] = $ExVersion
}
catch [System.Management.Automation.CommandNotFoundException]
{
    $module.Result['ExchangeInstalled'] =$false
    $module.Result['ExchangeVersion'] = $null

}
catch
{
    $module.FailJson("Unable to get Exchange version by checking exsetup.exe command: $($_.exception.message)")
}
$module.ExitJson()