<#
RegistryValueTool Detect

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

$Exit = 0
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
Exit $Exit
