## vmWare Old Adapters
## Jordan Stoner
## jordanstoner@gmail.com
#
#
## 3/3/2017
#
## This script will query vCenter and display all VM's which are using a network adapter
## other than the preferred Vmxnet3

$vms = Get-VM | Sort Name

foreach ($vm in $vms)
    {
       # Write-Host "$($vm)" 
        Get-NetworkAdapter -VM $vm.Name | Where {$_.Type -ne 'Vmxnet3'} | Select @{N="VName";E={$vm.Name}},Type
        if ($_.Type -ne $null)
        {
            Select $vm.VName,$vm.Type | Format-Table -AutoSizeGet
        }
    }
