# PowerCLI Cmdlet Reference

Quick reference for essential VMware PowerCLI cmdlets organized by category.

## Connection Management

| Cmdlet | Description | Example |
|--------|-------------|---------|
| `Connect-VIServer` | Connect to vCenter/ESXi | `Connect-VIServer -Server vcenter.example.com` |
| `Disconnect-VIServer` | Disconnect from server | `Disconnect-VIServer -Server * -Confirm:$false` |
| `Get-VIServer` | Get connected servers | `Get-VIServer` |

## Virtual Machine Management

| Cmdlet | Description | Example |
|--------|-------------|---------|
| `Get-VM` | Get virtual machines | `Get-VM -Name "Web*"` |
| `Start-VM` | Power on VM | `Start-VM -VM "WebServer01"` |
| `Stop-VM` | Power off VM | `Stop-VM -VM "WebServer01" -Confirm:$false` |
| `Restart-VM` | Restart VM | `Restart-VM -VM "WebServer01"` |
| `New-VM` | Create new VM | `New-VM -Name "NewVM" -VMHost $host -Datastore $ds` |
| `Remove-VM` | Delete VM | `Remove-VM -VM "OldVM" -DeletePermanently` |

## Host Management

| Cmdlet | Description | Example |
|--------|-------------|---------|
| `Get-VMHost` | Get ESXi hosts | `Get-VMHost` |
| `Set-VMHost` | Configure host | `Set-VMHost -VMHost $host -State Maintenance` |
| `Restart-VMHost` | Restart host | `Restart-VMHost -VMHost $host -Confirm:$false` |

## Storage Management

| Cmdlet | Description | Example |
|--------|-------------|---------|
| `Get-Datastore` | Get datastores | `Get-Datastore` |
| `Get-HardDisk` | Get VM hard disks | `Get-VM "WebServer01" \| Get-HardDisk` |
| `New-HardDisk` | Add disk to VM | `New-HardDisk -VM $vm -CapacityGB 50` |

## Network Management

| Cmdlet | Description | Example |
|--------|-------------|---------|
| `Get-NetworkAdapter` | Get VM network adapters | `Get-VM "WebServer01" \| Get-NetworkAdapter` |
| `Set-NetworkAdapter` | Configure network adapter | `Get-NetworkAdapter -VM $vm \| Set-NetworkAdapter -NetworkName "Production"` |
| `Get-VirtualSwitch` | Get virtual switches | `Get-VirtualSwitch` |

## Snapshot Management

| Cmdlet | Description | Example |
|--------|-------------|---------|
| `Get-Snapshot` | Get VM snapshots | `Get-VM "WebServer01" \| Get-Snapshot` |
| `New-Snapshot` | Create snapshot | `New-Snapshot -VM $vm -Name "Backup" -Description "Pre-update"` |
| `Remove-Snapshot` | Delete snapshot | `Get-Snapshot -VM $vm \| Remove-Snapshot -Confirm:$false` |