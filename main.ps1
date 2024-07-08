#$mainPath = [System.IO.Path]::GetDirectoryName($MyInvocation.MyCommand.Definition)
$mainPath = ""

# Output for report
$outputpath = ""

# Unlock all files in project
Get-ChildItem -Path $mainPath -recurse | ForEach-Object {Unblock-File -Path $_.FullName}

# API Information
$tenantId = ""
$clientId = ""
$authority = "https://login.microsoftonline.com/$TenantId"
$redirectUri = "https://login.microsoftonline.com/common/oauth2/nativeclient"

# Load dll, this fuck
$mic = Join-Path "$mainPath\net462" "Microsoft.Identity.Client.dll"
[System.Reflection.Assembly]::LoadFrom($mic) | Out-Null
# Load dll, this another fuck
$mia = Join-Path "$mainPath\net462" "Microsoft.IdentityModel.Abstractions.dll"
[System.Reflection.Assembly]::LoadFrom($mia) | Out-Null

# Build the client Web App
$PublicClientApp = [Microsoft.Identity.Client.PublicClientApplicationBuilder]::create($clientId).WithRedirectUri($redirectUri).WithAuthority($authority).Build()

# Build the token with Interactive Log-In or Silently if already exist an account
$varaccount = $PublicClientApp.GetAccountsAsync()
If ($null -eq $varaccount.Result.username) {
    $tokenResult = $PublicClientApp.AcquireTokenInteractive($null).ExecuteAsync().Result
    $varaccount = $PublicClientApp.GetAccountsAsync()
} else {
    $tokenResult = $PublicClientApp.AcquireTokenSilent($null, $varaccount.Result.username).ExecuteAsync().Result
    $varaccount = $PublicClientApp.GetAccountsAsync()
}

### ALL CSP ###
# Administrative Templates ALL
$uri = "https://graph.microsoft.com/beta/deviceManagement/groupPolicyConfigurations?`$top=1500&expand=assignments"
$result = Invoke-RestMethod -uri $uri -Method GET -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken}
$Pages = $result."@odata.nextLink"
If ($null -eq $Pages) {
    $results =@()
    $results += $result.value
} Else {
    $results =@()
    $results += $result.value
    While($null -ne $Pages) {
        Write-Host "Analyse de la page suivante" -ForegroundColor Yellow
        $Additional = Invoke-RestMethod -Uri $Pages -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get
        $results += $Additional.value
        If ($Pages) {
            $Pages = $Additional."@odata.nextLink"
        }
    }
}
$rapport = @()
foreach ($a in ($results | Where-Object {$_.assignments})) {
    # At Information $a
    foreach ($b in $a.assignments) {
        # Assignements Info in $b
        if ($b.target.groupId) {
            $uri = "https://graph.microsoft.com/beta/groups/$($b.target.groupId)"
            try {
                # Retrieving the group name and group id
                $grp_name = (Invoke-RestMethod -uri $uri -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get).displayName
            } catch {
                $grp_name = $($error[0].Exception.Response.StatusCode.Value__)
            }
            $grp_id = $b.target.groupId
        } else {
            $grp_name = ""
            $grp_id = ($b.id -split "_")[1]
        }
        if ($b.target.deviceAndAppManagementAssignmentFilterId) {
            $uri = "https://graph.microsoft.com/beta/deviceManagement/assignmentFilters/$($b.target.deviceAndAppManagementAssignmentFilterId)"
            try {
                ## Retrieving the filter name and more information
                $c = Invoke-RestMethod -uri $uri -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get
                $grp_filtername = $c.displayName
                $grp_filterplatform = $c.platform
                $grp_filterrule = $c.rule
                $grp_filterassignmenttype = $c.assignmentFilterManagementType
            } catch {
                $grp_filtername = $($error[0].Exception.Response.StatusCode.Value__)
                $grp_filterplatform = ""
                $grp_filterrule = ""
                $grp_filterassignmenttype = ""
            }
        } else {
            $grp_filtername = ""
            $grp_filterplatform = ""
            $grp_filterrule = ""
            $grp_filterassignmenttype = ""
        }
        $rapport += [pscustomobject]@{
            at_displayName = $a.displayName;
            at_id = $a.id;
            grp_name = $grp_name;            
            grp_type = ($b.target.'@odata.type' -split "\.")[-1];
            grp_id = $grp_id;
            grp_filtername = $grp_filtername;
            grp_filtertype = $b.target.deviceAndAppManagementAssignmentFilterType;
            grp_filterplatform = $grp_filterplatform;
            grp_filterrule = $grp_filterrule;
            grp_filterassignmenttype = $grp_filterassignmenttype;
            grp_filterid = $b.target.deviceAndAppManagementAssignmentFilterId
        }
    }
}
$rapport | Export-Csv -Path "$outputpath\Administrative Templates $(Get-Date -Format yyyy-MM-dd_hh-mm-ss).csv" -NoTypeInformation -Encoding Unicode

# Setting Catalog ALL :
$uri = "https://graph.microsoft.com/beta/deviceManagement/configurationPolicies?`$top=100&expand=assignments"
$result = Invoke-RestMethod -uri $uri -Method GET -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken}
$Pages = $result."@odata.nextLink"
If ($null -eq $Pages) {
    $results =@()
    $results += $result.value
} Else {
    $results =@()
    $results += $result.value
    While($null -ne $Pages) {
        Write-Host "Analyse de la page suivante" -ForegroundColor Yellow
        $Additional = Invoke-RestMethod -Uri $Pages -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get
        $results += $Additional.value
        If ($Pages) {
            $Pages = $Additional."@odata.nextLink"
        }
    }
}
$rapport = @()
foreach ($a in ($results | Where-Object {$_.assignments})) {
    # Setting Catalog Information $a
    foreach ($b in $a.assignments) {
        # Assignements Info in $b
        if ($b.target.groupId) {
            $uri = "https://graph.microsoft.com/beta/groups/$($b.target.groupId)"
            try {
                # Retrieving the group name and group id
                $grp_name = (Invoke-RestMethod -uri $uri -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get).displayName
            } catch {
                $grp_name = $($error[0].Exception.Response.StatusCode.Value__)
            }
            $grp_id = $b.target.groupId
        } else {
            $grp_name = ""
            $grp_id = ($b.id -split "_")[1]
        }
        if ($b.target.deviceAndAppManagementAssignmentFilterId) {
            $uri = "https://graph.microsoft.com/beta/deviceManagement/assignmentFilters/$($b.target.deviceAndAppManagementAssignmentFilterId)"
            try {
                ## Retrieving the filter name and more information
                $c = Invoke-RestMethod -uri $uri -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get
                $grp_filtername = $c.displayName
                $grp_filterplatform = $c.platform
                $grp_filterrule = $c.rule
                $grp_filterassignmenttype = $c.assignmentFilterManagementType
            } catch {
                $grp_filtername = $($error[0].Exception.Response.StatusCode.Value__)
                $grp_filterplatform = ""
                $grp_filterrule = ""
                $grp_filterassignmenttype = ""
            }
        } else {
            $grp_filtername = ""
            $grp_filterplatform = ""
            $grp_filterrule = ""
            $grp_filterassignmenttype = ""
        }
        $rapport += [pscustomobject]@{
            sc_displayName = $a.name;
            sc_id = $a.id;
            grp_name = $grp_name;            
            grp_type = ($b.target.'@odata.type' -split "\.")[-1];
            grp_id = $grp_id;
            grp_filtername = $grp_filtername;
            grp_filtertype = $b.target.deviceAndAppManagementAssignmentFilterType;
            grp_filterplatform = $grp_filterplatform;
            grp_filterrule = $grp_filterrule;
            grp_filterassignmenttype = $grp_filterassignmenttype;
            grp_filterid = $b.target.deviceAndAppManagementAssignmentFilterId
        }
    }
}
$rapport | Export-Csv -Path "$outputpath\Setting Catalog $(Get-Date -Format yyyy-MM-dd_hh-mm-ss).csv" -NoTypeInformation -Encoding Unicode

# CUSTOM + Trusted Certificate
$uri = "https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations?`$top=1000&expand=assignments"
$result = Invoke-RestMethod -uri $uri -Method GET -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken}
$Pages = $result."@odata.nextLink"
If ($null -eq $Pages) {
    $results =@()
    $results += $result.value
} Else {
    $results =@()
    $results += $result.value
    While($null -ne $Pages) {
        Write-Host "Analyse de la page suivante" -ForegroundColor Yellow
        $Additional = Invoke-RestMethod -Uri $Pages -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get
        $results += $Additional.value
        If ($Pages) {
            $Pages = $Additional."@odata.nextLink"
        }
    }
}
$rapport = @()
foreach ($a in ($results | Where-Object {$_.assignments})) {
    # At Information $a
    foreach ($b in $a.assignments) {
        # Assignements Info in $b
        if ($b.target.groupId) {
            $uri = "https://graph.microsoft.com/beta/groups/$($b.target.groupId)"
            try {
                # Retrieving the group name and group id
                $grp_name = (Invoke-RestMethod -uri $uri -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get).displayName
            } catch {
                $grp_name = $($error[0].Exception.Response.StatusCode.Value__)
            }
            $grp_id = $b.target.groupId
        } else {
            $grp_name = ""
            $grp_id = ($b.id -split "_")[1]
        }
        if ($b.target.deviceAndAppManagementAssignmentFilterId) {
            $uri = "https://graph.microsoft.com/beta/deviceManagement/assignmentFilters/$($b.target.deviceAndAppManagementAssignmentFilterId)"
            try {
                ## Retrieving the filter name and more information
                $c = Invoke-RestMethod -uri $uri -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get
                $grp_filtername = $c.displayName
                $grp_filterplatform = $c.platform
                $grp_filterrule = $c.rule
                $grp_filterassignmenttype = $c.assignmentFilterManagementType
            } catch {
                $grp_filtername = $($error[0].Exception.Response.StatusCode.Value__)
                $grp_filterplatform = ""
                $grp_filterrule = ""
                $grp_filterassignmenttype = ""
            }
        } else {
            $grp_filtername = ""
            $grp_filterplatform = ""
            $grp_filterrule = ""
            $grp_filterassignmenttype = ""
        }
        $rapport += [pscustomobject]@{
            oma_displayName = $a.displayName;
            oma_id = $a.id;
            grp_name = $grp_name;            
            grp_type = ($b.target.'@odata.type' -split "\.")[-1];
            grp_id = $grp_id;
            grp_filtername = $grp_filtername;
            grp_filtertype = $b.target.deviceAndAppManagementAssignmentFilterType;
            grp_filterplatform = $grp_filterplatform;
            grp_filterrule = $grp_filterrule;
            grp_filterassignmenttype = $grp_filterassignmenttype;
            grp_filterid = $b.target.deviceAndAppManagementAssignmentFilterId
        }
    }
}
$rapport | Export-Csv -Path "$outputpath\Custom $(Get-Date -Format yyyy-MM-dd_hh-mm-ss).csv" -NoTypeInformation -Encoding Unicode
###

### ALL APPS and assignments
$uri =  "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps?`$expand=assignments"
$result = Invoke-RestMethod -uri $uri -Method GET -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken}
$Pages = $result."@odata.nextLink"
If ($null -eq $Pages) {
    $results =@()
    $results += $result.value
} Else {
    $results =@()
    $results += $result.value
    While($null -ne $Pages) {
        Write-Host "Analyse de la page suivante" -ForegroundColor Yellow
        $Additional = Invoke-RestMethod -Uri $Pages -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get
        $results += $Additional.value
        If ($Pages) {
            $Pages = $Additional."@odata.nextLink"
        }
    }
}
$rapport = @()
foreach ($a in ($results | Where-Object {$_.assignments})) {
    # App Information $a
    foreach ($b in $a.assignments) {
        # Assignements Info in $b
        if ($b.target.groupId) {
            $uri = "https://graph.microsoft.com/beta/groups/$($b.target.groupId)"
            try {
                #  Retrieving the group name and group id
                $grp_name = (Invoke-RestMethod -uri $uri -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get).displayName
            } catch {
                $grp_name = $($error[0].Exception.Response.StatusCode.Value__)
            }
            $grp_id = $b.target.groupId
        } else {
            $grp_name = ""
            $grp_id = ($b.id -split "_")[0]
        }
        if ($b.target.deviceAndAppManagementAssignmentFilterId) {
            $uri = "https://graph.microsoft.com/beta/deviceManagement/assignmentFilters/$($b.target.deviceAndAppManagementAssignmentFilterId)"
            try {
                ## Retrieving the filter name and more information
                $c = Invoke-RestMethod -uri $uri -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get
                $grp_filtername = $c.displayName
                $grp_filterplatform = $c.platform
                $grp_filterrule = $c.rule
                $grp_filterassignmenttype = $c.assignmentFilterManagementType
            } catch {
                $grp_filtername = $($error[0].Exception.Response.StatusCode.Value__)
                $grp_filterplatform = ""
                $grp_filterrule = ""
                $grp_filterassignmenttype = ""
            }
        } else {
            $grp_filtername = ""
            $grp_filterplatform = ""
            $grp_filterrule = ""
            $grp_filterassignmenttype = ""
        }
        $rapport += [pscustomobject]@{
            app_displayName = $a.displayName;
            app_displayVersion = $a.displayVersion;
            app_id = $a.id;
            app_type = $(($a."@odata.type" -split "\.")[-1]);
            grp_name = $grp_name;
            grp_intent = $b.intent;
            grp_source = $b.source;
            grp_notifications = $b.settings.notifications;
            grp_restartSettings = $b.settings.restartSettings;
            grp_installTimeSettings = $b.settings.installTimeSettings;
            grp_deliveryOptimizationPriority = $b.settings.deliveryOptimizationPriority;
            grp_autoUpdateSettings = $b.settings.autoUpdateSettings.autoUpdateSupersededAppsState;
            grp_id = $grp_id;
            grp_filtername = $grp_filtername;
            grp_filtertype = $b.target.deviceAndAppManagementAssignmentFilterType;
            grp_filterplatform = $grp_filterplatform;
            grp_filterrule = $grp_filterrule;
            grp_filterassignmenttype = $grp_filterassignmenttype;
            grp_filterid = $b.target.deviceAndAppManagementAssignmentFilterId
        }
    }
}
$rapport | Export-Csv -Path "$outputpath\Applications $(Get-Date -Format yyyy-MM-dd_hh-mm-ss).csv" -NoTypeInformation -Encoding Unicode
###

# Compliance ALL
$uri = "https://graph.microsoft.com/beta/deviceManagement/deviceCompliancePolicies?`$expand=assignments"
$result = Invoke-RestMethod -uri $uri -Method GET -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken}
$Pages = $result."@odata.nextLink"
If ($null -eq $Pages) {
    $results =@()
    $results += $result.value
} Else {
    $results =@()
    $results += $result.value
    While($null -ne $Pages) {
        Write-Host "Analyse de la page suivante" -ForegroundColor Yellow
        $Additional = Invoke-RestMethod -Uri $Pages -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get
        $results += $Additional.value
        If ($Pages) {
            $Pages = $Additional."@odata.nextLink"
        }
    }
}
$rapport = @()
foreach ($a in ($results | Where-Object {$_.assignments})) {
    # Compliance Information in $a
    foreach ($b in $a.assignments) {
        # Assignements Info in $b
        if ($b.target.groupId) {
            $uri = "https://graph.microsoft.com/beta/groups/$($b.target.groupId)"
            try {
                #  Retrieving the group name and group id
                $grp_name = (Invoke-RestMethod -uri $uri -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get).displayName
            } catch {
                $grp_name = $($error[0].Exception.Response.StatusCode.Value__)
            }
            $grp_id = $b.target.groupId
            $grp_type = $(($b.target."@odata.type" -split "\.")[-1])
        } else {
            $grp_name = ""
            $grp_id = ($b.id -split "_")[-1]
            $grp_type = ""
        }
        if ($b.target.deviceAndAppManagementAssignmentFilterId) {
            $uri = "https://graph.microsoft.com/beta/deviceManagement/assignmentFilters/$($b.target.deviceAndAppManagementAssignmentFilterId)"
            try {
                ## Retrieving the filter name and more information
                $c = Invoke-RestMethod -uri $uri -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get
                $grp_filtername = $c.displayName
                $grp_filterplatform = $c.platform
                $grp_filterrule = $c.rule
                $grp_filterassignmenttype = $c.assignmentFilterManagementType
            } catch {
                $grp_filtername = $($error[0].Exception.Response.StatusCode.Value__)
                $grp_filterplatform = ""
                $grp_filterrule = ""
                $grp_filterassignmenttype = ""
            }
        } else {
            $grp_filtername = ""
            $grp_filterplatform = ""
            $grp_filterrule = ""
            $grp_filterassignmenttype = ""
        }
        $rapport += [pscustomobject]@{
            comp_displayName = $a.displayName;
            comp_version = $a.version;
            comp_id = $a.id;
            comp_type = $(($a."@odata.type" -split "\.")[-1]);
            grp_name = $grp_name;
            grp_id = $grp_id;
            grp_type = $grp_type;
            grp_filtername = $grp_filtername;
            grp_filtertype = $b.target.deviceAndAppManagementAssignmentFilterType;
            grp_filterplatform = $grp_filterplatform;
            grp_filterrule = $grp_filterrule;
            grp_filterassignmenttype = $grp_filterassignmenttype;
            grp_filterid = $b.target.deviceAndAppManagementAssignmentFilterId
        }
    }
}
$rapport | Export-Csv -Path "$outputpath\Compliances $(Get-Date -Format yyyy-MM-dd_hh-mm-ss).csv" -NoTypeInformation -Encoding Unicode

### Remediations ALL
$uri = "https://graph.microsoft.com/beta/deviceManagement/deviceHealthScripts?`$expand=assignments"
$result = Invoke-RestMethod -uri $uri -Method GET -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken}
$Pages = $result."@odata.nextLink"
If ($null -eq $Pages) {
    $results =@()
    $results += $result.value
} Else {
    $results =@()
    $results += $result.value
    While($null -ne $Pages) {
        Write-Host "Analyse de la page suivante" -ForegroundColor Yellow
        $Additional = Invoke-RestMethod -Uri $Pages -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get
        $results += $Additional.value
        If ($Pages) {
            $Pages = $Additional."@odata.nextLink"
        }
    }
}
$rapport = @()
foreach ($a in ($results | Where-Object {$_.assignments})) {
    # Remediation Information in $a
    foreach ($b in $a.assignments) {
        # Assignements Info in $b
        if ($b.target.groupId) {
            $uri = "https://graph.microsoft.com/beta/groups/$($b.target.groupId)"
            try {
                #  Retrieving the group name and group id
                $grp_name = (Invoke-RestMethod -uri $uri -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get).displayName
            } catch {
                $grp_name = $($error[0].Exception.Response.StatusCode.Value__)
            }
            $grp_id = $b.target.groupId
            $grp_type = $(($b.target."@odata.type" -split "\.")[-1])
        } else {
            $grp_name = ""
            $grp_id = ($b.id -split ":")[-1]
            $grp_type = ""
        }
        if ($b.target.deviceAndAppManagementAssignmentFilterId -ne "00000000-0000-0000-0000-000000000000") {
            $uri = "https://graph.microsoft.com/beta/deviceManagement/assignmentFilters/$($b.target.deviceAndAppManagementAssignmentFilterId)"
            try {
                ## Retrieving the filter name and more information
                $c = Invoke-RestMethod -uri $uri -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get
                $grp_filtername = $c.displayName
                $grp_filterplatform = $c.platform
                $grp_filterrule = $c.rule
                $grp_filterassignmenttype = $c.assignmentFilterManagementType
            } catch {
                $grp_filtername = $($error[0].Exception.Response.StatusCode.Value__)
                $grp_filterplatform = ""
                $grp_filterrule = ""
                $grp_filterassignmenttype = ""
            }
        } else {
            $grp_filtername = ""
            $grp_filterplatform = ""
            $grp_filterrule = ""
            $grp_filterassignmenttype = ""
        }
        $rapport += [pscustomobject]@{
            rem_displayName = $a.displayName;
            rem_version = $a.version;
            rem_publisher = $a.publisher;
            rem_id = $a.id;
            rem_runAsAccount = $a.runAsAccount;
            rem_runAs32Bit = $a.runAs32Bit;
            rem_type = $a.deviceHealthScriptType;
            grp_name = $grp_name;
            grp_id = $grp_id;
            grp_type = $grp_type;
            grp_scheduletype = $(($b.runSchedule."@odata.type" -split "\.")[-1]);
            grp_scheduleinterval = $b.runSchedule.interval;
            grp_scheduletime = $b.runSchedule.time;
            grp_scheduletimeutc = $b.runSchedule.useUtc;
            grp_filtername = $grp_filtername;
            grp_filtertype = $b.target.deviceAndAppManagementAssignmentFilterType;
            grp_filterplatform = $grp_filterplatform;
            grp_filterrule = $grp_filterrule;
            grp_filterassignmenttype = $grp_filterassignmenttype;
            grp_filterid = $b.target.deviceAndAppManagementAssignmentFilterId
        }
    }
}
$rapport | Export-Csv -Path "$outputpath\Remediations $(Get-Date -Format yyyy-MM-dd_hh-mm-ss).csv" -NoTypeInformation -Encoding Unicode
###

# Windows Scripts
$uri = "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts?`$expand=assignments"
$result = Invoke-RestMethod -uri $uri -Method GET -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken}
$Pages = $result."@odata.nextLink"
If ($null -eq $Pages) {
    $results =@()
    $results += $result.value
} Else {
    $results =@()
    $results += $result.value
    While($null -ne $Pages) {
        Write-Host "Analyse de la page suivante" -ForegroundColor Yellow
        $Additional = Invoke-RestMethod -Uri $Pages -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get
        $results += $Additional.value
        If ($Pages) {
            $Pages = $Additional."@odata.nextLink"
        }
    }
}
$rapport = @()
foreach ($a in ($results | Where-Object {$_.assignments})) {
    # Windows scripts Information in $a
    foreach ($b in $a.assignments) {
        # Assignements Info in $b
        if ($b.target.groupId) {
            $uri = "https://graph.microsoft.com/beta/groups/$($b.target.groupId)"
            try {
                #  Retrieving the group name and group id
                $grp_name = (Invoke-RestMethod -uri $uri -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get).displayName
            } catch {
                $grp_name = $($error[0].Exception.Response.StatusCode.Value__)
            }
            $grp_id = $b.target.groupId
            $grp_type = $(($b.target."@odata.type" -split "\.")[-1])
        } else {
            $grp_name = ""
            $grp_id = ($b.id -split ":")[-1]
            $grp_type = ""
        }
        if ($b.target.deviceAndAppManagementAssignmentFilterId) {
            $uri = "https://graph.microsoft.com/beta/deviceManagement/assignmentFilters/$($b.target.deviceAndAppManagementAssignmentFilterId)"
            try {
                ## Retrieving the filter name and more information
                $c = Invoke-RestMethod -uri $uri -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get
                $grp_filtername = $c.displayName
                $grp_filterplatform = $c.platform
                $grp_filterrule = $c.rule
                $grp_filterassignmenttype = $c.assignmentFilterManagementType
            } catch {
                $grp_filtername = $($error[0].Exception.Response.StatusCode.Value__)
                $grp_filterplatform = ""
                $grp_filterrule = ""
                $grp_filterassignmenttype = ""
            }
        } else {
            $grp_filtername = ""
            $grp_filterplatform = ""
            $grp_filterrule = ""
            $grp_filterassignmenttype = ""
        }
        $rapport += [pscustomobject]@{
            script_displayName = $a.displayName;
            script_id = $a.id;
            grp_name = $grp_name;
            grp_id = $grp_id;
            grp_type = $grp_type;
            grp_filtername = $grp_filtername;
            grp_filtertype = $b.target.deviceAndAppManagementAssignmentFilterType;
            grp_filterplatform = $grp_filterplatform;
            grp_filterrule = $grp_filterrule;
            grp_filterassignmenttype = $grp_filterassignmenttype;
            grp_filterid = $b.target.deviceAndAppManagementAssignmentFilterId
        }
    }
}
$rapport | Export-Csv -Path "$outputpath\Windows scripts $(Get-Date -Format yyyy-MM-dd_hh-mm-ss).csv" -NoTypeInformation -Encoding Unicode
###

# macOS Scripts
$uri = "https://graph.microsoft.com/beta/deviceManagement/deviceShellScripts?`$expand=assignments"
$result = Invoke-RestMethod -uri $uri -Method GET -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken}
$Pages = $result."@odata.nextLink"
If ($null -eq $Pages) {
    $results =@()
    $results += $result.value
} Else {
    $results =@()
    $results += $result.value
    While($null -ne $Pages) {
        Write-Host "Analyse de la page suivante" -ForegroundColor Yellow
        $Additional = Invoke-RestMethod -Uri $Pages -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get
        $results += $Additional.value
        If ($Pages) {
            $Pages = $Additional."@odata.nextLink"
        }
    }
}
$rapport = @()
foreach ($a in ($results | Where-Object {$_.assignments})) {
    # Windows scripts Information in $a
    foreach ($b in $a.assignments) {
        # Assignements Info in $b
        if ($b.target.groupId) {
            $uri = "https://graph.microsoft.com/beta/groups/$($b.target.groupId)"
            try {
                #  Retrieving the group name and group id
                $grp_name = (Invoke-RestMethod -uri $uri -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get).displayName
            } catch {
                $grp_name = $($error[0].Exception.Response.StatusCode.Value__)
            }
            $grp_id = $b.target.groupId
            $grp_type = $(($b.target."@odata.type" -split "\.")[-1])
        } else {
            $grp_name = ""
            $grp_id = ($b.id -split ":")[-1]
            $grp_type = ""
        }
        if ($b.target.deviceAndAppManagementAssignmentFilterId) {
            $uri = "https://graph.microsoft.com/beta/deviceManagement/assignmentFilters/$($b.target.deviceAndAppManagementAssignmentFilterId)"
            try {
                ## Retrieving the filter name and more information
                $c = Invoke-RestMethod -uri $uri -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get
                $grp_filtername = $c.displayName
                $grp_filterplatform = $c.platform
                $grp_filterrule = $c.rule
                $grp_filterassignmenttype = $c.assignmentFilterManagementType
            } catch {
                $grp_filtername = $($error[0].Exception.Response.StatusCode.Value__)
                $grp_filterplatform = ""
                $grp_filterrule = ""
                $grp_filterassignmenttype = ""
            }
        } else {
            $grp_filtername = ""
            $grp_filterplatform = ""
            $grp_filterrule = ""
            $grp_filterassignmenttype = ""
        }
        $rapport += [pscustomobject]@{
            script_displayName = $a.displayName;
            script_id = $a.id;
            grp_name = $grp_name;
            grp_id = $grp_id;
            grp_type = $grp_type;
            grp_filtername = $grp_filtername;
            grp_filtertype = $b.target.deviceAndAppManagementAssignmentFilterType;
            grp_filterplatform = $grp_filterplatform;
            grp_filterrule = $grp_filterrule;
            grp_filterassignmenttype = $grp_filterassignmenttype;
            grp_filterid = $b.target.deviceAndAppManagementAssignmentFilterId
        }
    }
}
$rapport | Export-Csv -Path "$outputpath\macOS scripts $(Get-Date -Format yyyy-MM-dd_hh-mm-ss).csv" -NoTypeInformation -Encoding Unicode
###

<# Research d'App
$apptosearch = "Sentinel"
$uri = "https://graph.microsoft.com/beta/deviceManagement/detectedApps?`$filter=(contains(displayName, '$apptosearch'))&`$top=20&`$skip=0"
$result = Invoke-RestMethod -uri $uri -Method GET -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken}
$Pages = $result."@odata.nextLink"
If ($null -eq $Pages) {
    $results =@()
    $results += $result.value
} Else {
    $results =@()
    $results += $result.value
    While($null -ne $Pages) {
        Write-Host "Analyse de la page suivante" -ForegroundColor Yellow
        $Additional = Invoke-RestMethod -Uri $Pages -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get
        $results += $Additional.value
        If ($Pages) {
            $Pages = $Additional."@odata.nextLink"
        }
    }
}
# Research d'App version
$appver = "22.3.612"
$id = ($results | Where-Object {$_.version -match $appver}).id
$uri = "https://graph.microsoft.com/beta/deviceManagement/detectedApps('$id')/managedDevices?`$filter=&`$top=20&`$skip=0"
$result = Invoke-RestMethod -uri $uri -Method GET -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken}
$Pages = $result."@odata.nextLink"
If ($null -eq $Pages) {
    $results =@()
    $results += $result.value
} Else {
    $results =@()
    $results += $result.value
    While($null -ne $Pages) {
        Write-Host "Analyse de la page suivante" -ForegroundColor Yellow
        $Additional = Invoke-RestMethod -Uri $Pages -Headers @{'Authorization'="Bearer " + $tokenResult.AccessToken} -Method Get
        $results += $Additional.value
        If ($Pages) {
            $Pages = $Additional."@odata.nextLink"
        }
    }
}#>
