<#
RegistryValueTool Remediate

Registry Type    ->     Powershell Type     ->      .NET Type         ->    Value Type
REG_SZ           ->     String              ->      System.String     ->    String
REG_EXPAND_SZ    ->     ExpandString        ->      System.String     ->    String
REG_BINARY       ->     Binary              ->      System.Byte[]     ->    Array (ex: @(1,2,3))
REG_DWORD        ->     DWord               ->      System.UInt32     ->    Decimal value (ex : 12345)
REG_MULTI_SZ     ->     MultiString         ->      System.String[]   ->    Array (ex: @(1,2,3,"four","five"))
REG_QWORD        ->     Qword               ->      System.Int64      ->    Decimal value (ex: 12345)
#>

$DetectInfo = @(
    [pscustomobject]@{Info="RegKeyValue";Path="HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell";Name="ExecutionPolicy";Type="REG_SZ";Value="Restricted";Present=$true}
    [pscustomobject]@{Info="RegKeyValue";Path="HKLM:\SOFTWARE\WOW6432Node\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell";Name="ExecutionPolicy";Type="REG_SZ";Value="Restricted";Present=$true}
)
$RegInfo = @(
    [pscustomobject]@{RegeditType="REG_SZ";PSType="String";dotNETType="System.String"}
    [pscustomobject]@{RegeditType="REG_EXPAND_SZ";PSType="ExpandString";dotNETType="System.String"}
    [pscustomobject]@{RegeditType="REG_BINARY";PSType="Binary";dotNETType="System.Byte[]"}
    [pscustomobject]@{RegeditType="REG_DWORD";PSType="DWord";dotNETType="System.UInt32"}
    [pscustomobject]@{RegeditType="REG_MULTI_SZ";PSType="MultiString";dotNETType="System.String[]"}
    [pscustomobject]@{RegeditType="REG_QWORD";PSType="Qword";dotNETType="System.Int64"}
)

Foreach ($a in $DetectInfo) {
    if ($a.Present) {
        if (Get-Item -Path $a.Path -ErrorAction SilentlyContinue) {
            if(Get-ItemProperty -Path $a.Path -Name $a.Name -ErrorAction SilentlyContinue) {
                if (($RegInfo | Where-Object {$_.RegeditType -eq $a.Type}).dotNETType -eq ((Get-ItemProperty -Path $a.Path -Name $a.Name -ErrorAction SilentlyContinue).PSObject.Properties | Where-Object {$_.Name -eq $a.Name}).TypeNameOfValue) {
                    if ($null -eq (Compare-Object (Get-ItemPropertyValue -Path $a.Path -Name $a.Name -ErrorAction SilentlyContinue) $a.Value -SyncWindow 0)) {
                    } else {
                        Set-ItemProperty -Path $a.Path -Name $a.Name -Value $a.Value -Force -ErrorAction SilentlyContinue | Out-Null
                    }
                } else {
                    New-ItemProperty -Path $a.Path -Name $a.Name -Value $a.Value -PropertyType ($RegInfo | Where-Object {$_.RegeditType -eq $a.Type}).PSType -Force -ErrorAction SilentlyContinue | Out-Null
                }
            } else {
                New-ItemProperty -Path $a.Path -Name $a.Name -Value $a.Value -PropertyType ($RegInfo | Where-Object {$_.RegeditType -eq $a.Type}).PSType -Force -ErrorAction SilentlyContinue | Out-Null
            }
        } else {
            New-Item -Path $a.Path -Force -ErrorAction SilentlyContinue | Out-Null
            New-ItemProperty -Path $a.Path -Name $a.Name -Value $a.Value -PropertyType ($RegInfo | Where-Object {$_.RegeditType -eq $a.Type}).PSType -Force -ErrorAction SilentlyContinue | Out-Null
        }
    } else {
        if (Get-Item -Path $a.Path -ErrorAction SilentlyContinue) {
            if(Get-ItemProperty -Path $a.Path -Name $a.Name -ErrorAction SilentlyContinue) {
                if (($RegInfo | Where-Object {$_.RegeditType -eq $a.Type}).dotNETType -eq ((Get-ItemProperty -Path $a.Path -Name $a.Name -ErrorAction SilentlyContinue).PSObject.Properties | Where-Object {$_.Name -eq $a.Name}).TypeNameOfValue) {
                    if ($null -eq (Compare-Object (Get-ItemPropertyValue -Path $a.Path -Name $a.Name -ErrorAction SilentlyContinue) $a.Value -SyncWindow 0)) {
                        Remove-ItemProperty -Path $a.Path -Name $a.Name -Force -ErrorAction SilentlyContinue | Out-Null
                    }
                }
            }
        }
    }
}

$Log = ""
$i = 1
Foreach ($a in $DetectInfo) {
    $Log += "$($a.Info) : [$($a.Path)]:" + "'" + $a.Name + "'" +" $($a.Type):"+ "'" + $a.Value + "'" + " Present:" + "'" + $a.Present + "'"

    if ($a.Present) {
        if (Get-Item -Path $a.Path -ErrorAction SilentlyContinue) {
            if(Get-ItemProperty -Path $a.Path -Name $a.Name -ErrorAction SilentlyContinue) {
                if (($RegInfo | Where-Object {$_.RegeditType -eq $a.Type}).dotNETType -eq ((Get-ItemProperty -Path $a.Path -Name $a.Name -ErrorAction SilentlyContinue).PSObject.Properties | Where-Object {$_.Name -eq $a.Name}).TypeNameOfValue) {
                    if ($null -eq (Compare-Object (Get-ItemPropertyValue -Path $a.Path -Name $a.Name -ErrorAction SilentlyContinue) $a.Value -SyncWindow 0)) {
                        $log += " -> compliant"
                    } else {
                        $log += " --> Value -> Non compliant"
                    }
                } else {
                    $log += " --> Type -> Non compliant"
                }
            } else {
                $log += " --> Name -> Non compliant"
            }
        } else {
            $log += " --> Path -> Non compliant"
        }
    } else {
        if (Get-Item -Path $a.Path -ErrorAction SilentlyContinue) {
            if(Get-ItemProperty -Path $a.Path -Name $a.Name -ErrorAction SilentlyContinue) {
                if (($RegInfo | Where-Object {$_.RegeditType -eq $a.Type}).dotNETType -eq ((Get-ItemProperty -Path $a.Path -Name $a.Name -ErrorAction SilentlyContinue).PSObject.Properties | Where-Object {$_.Name -eq $a.Name}).TypeNameOfValue) {
                    if ($null -eq (Compare-Object (Get-ItemPropertyValue -Path $a.Path -Name $a.Name -ErrorAction SilentlyContinue) $a.Value -SyncWindow 0)) {
                        $log += " --> Value -> Non compliant"
                    } else {
                        $log += " --> Value -> Compliant"
                    }
                } else {
                    $log += " --> Type -> Compliant"
                }
            } else {
                $log += " --> Name -> Compliant"
            }
        } else {
            $log += " --> Path -> Compliant"
        }
    }

    if ($i -lt $DetectInfo.Count) {$Log += " @return@ "}
    $i++
}

Write-Output $Log
