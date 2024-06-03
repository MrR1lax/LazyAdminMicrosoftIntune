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
    #[pscustomobject]@{Info="RegKeyValue";Path="HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell";Name="ExecutionPolicy";Type="REG_SZ";Value="Restricted";Present=$true}
    #[pscustomobject]@{Info="RegKeyValue";Path="HKLM:\SOFTWARE\WOW6432Node\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell";Name="ExecutionPolicy";Type="REG_SZ";Value="Restricted";Present=$true}
    [pscustomobject]@{Info="RegKeyValue";Path="HKCU:\TestKey";Name="TestREG_SZ";Type="REG_SZ";Value="TesTREG_ZValue";Present=$true}
    [pscustomobject]@{Info="RegKeyValue";Path="HKCU:\TestKey";Name="TestREG_BINARY";Type="REG_BINARY";Value=@(70,0,0,0,3,0,0,0,5,0,0,0,0,0,0,0,0,0,0,0,48,0,0,0,104,116,116,112,58,47,47,112,97,99,46,122,115,99,108,111,117,100,46,110,101,116,47,109,121,109,111,110,101,121,98,97,110,107,46,99,111,109,47,112,114,111,120,121,46,112,97,99,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);Present=$true}
    [pscustomobject]@{Info="RegKeyValue";Path="HKCU:\TestKey";Name="Test_REG_DWORD";Type="REG_DWORD";Value=3791625200;Present=$true}
    [pscustomobject]@{Info="RegKeyValue";Path="HKCU:\TestKey";Name="Test_REG_MULTI_SZ";Type="REG_MULTI_SZ";Value=@("Test_REG_MULTI_SZValue1","Test_REG_MULTI_SZValue2");Present=$true}
    [pscustomobject]@{Info="RegKeyValue";Path="HKCU:\TestKey";Name="Test_REG_EXPAND_SZ";Type="REG_EXPAND_SZ";Value="Test_REG_EXPAND_SZValue";Present=$true}
    [pscustomobject]@{Info="RegKeyValue";Path="HKCU:\TestKey";Name="Test_REG_QWORD";Type="REG_QWORD";Value=3791625200;Present=$true}
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
                        $Exit++
                    }
                } else {
                    $log += " --> Type -> Non compliant"
                    $Exit++
                }
            } else {
                $log += " --> Name -> Non compliant"
                $Exit++
            }
        } else {
            $log += " --> Path -> Non compliant"
            $Exit++
        }
    } else {
        if (Get-Item -Path $a.Path -ErrorAction SilentlyContinue) {
            if(Get-ItemProperty -Path $a.Path -Name $a.Name -ErrorAction SilentlyContinue) {
                if (($RegInfo | Where-Object {$_.RegeditType -eq $a.Type}).dotNETType -eq ((Get-ItemProperty -Path $a.Path -Name $a.Name -ErrorAction SilentlyContinue).PSObject.Properties | Where-Object {$_.Name -eq $a.Name}).TypeNameOfValue) {
                    if ($null -eq (Compare-Object (Get-ItemPropertyValue -Path $a.Path -Name $a.Name -ErrorAction SilentlyContinue) $a.Value -SyncWindow 0)) {
                        $log += " --> Value -> Non compliant"
                        $Exit++
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
