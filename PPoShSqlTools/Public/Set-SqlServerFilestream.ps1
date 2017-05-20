function Set-SqlServerFilestream {
    <#
    .SYNOPSIS
    Sets SQL Server Filestream to given level.

    .DESCRIPTION
    It does the following:
    1. Check filestream is at given level globally on SQL Server instance level, and if not set it using Cim/WMI. 
    2. If level has been changed restart SQL Server service.
    3. Check filestream is at given level at T-SQL level, and if not set it using SQL query.
    
    Note if SQL Server is not on local machine, you might need to pass $ConnectionParams, as it needs to open 2 kinds of connections:
    - WinRM to invoke WMI method and restart service (whole $ConnectionParams is used)
    - SQL query ($ConnectionString is used)

    .EXAMPLE
    Set-SqlServerFilestream -ConnectionString 'Data Source=localhost\SQLEXPRESS;Integrated Security=SSPI' -FilestreamLevel 2

    Enables Filestream on local instance SQLEXPRESS.

    .EXAMPLE
    Set-SqlServerFilestream -ConnectionString 'Data Source=server;Integrated Security=SSPI' -FilestreamLevel 2 `
                            -ConnectionParams (New-ConnectionParameters -Nodes 'server' -Credential $cred)

    Enables Filestream on remote default SQL Server instance using non-default credentials.
    #>

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string] 
        $ConnectionString,

        # Filestream level to set: 
        # - 0 - isabled
        # - 1 - enabled for T-SQL access
        # - 2 - enabled for T-SQL and Win32 streaming access
        [Parameter(Mandatory=$true)]
        [int] 
        $FilestreamLevel,

        # ConnectionParameters object as created by [[New-ConnectionParameters]] - required only for configuring remote SQL Server instances
        # using non-current user.
        [Parameter(Mandatory=$false)]
        [object] 
        $ConnectionParams
    )

    Write-Log -Info "Setting filestream level at $ConnectionString to $FilestreamLevel"

    $csb = New-Object -TypeName System.Data.SqlClient.SqlConnectionStringBuilder -ArgumentList $ConnectionString
    $dataSource = $csb.'Data Source'
    if ($dataSource -imatch '([^\\]+)\\(.+)') {
        $computerName = $Matches[1]
        $instanceName = $Matches[2]
        $sqlServiceName = 'MSSQL${0}' -f $instanceName
    } 
    else {
        $computerName = $dataSource
        $instanceName = 'MSSQLSERVER'
        $sqlServiceName = $instanceName
    }

    if (!$ConnectionParams) {
        $ConnectionParams = New-ConnectionParameters -Nodes $computerName
    }

    $cimParams = $ConnectionParams.CimSessionParams
    try { 
        $cimSession = New-CimSession @cimParams

        $sqlServerNamespaces = Get-CimInstance -CimSession $cimSession -Namespace 'ROOT\Microsoft\SqlServer' -class '__Namespace' -ErrorAction Continue | `
            Where-Object { $_.Name.StartsWith('ComputerManagement') } | Select-Object -ExpandProperty Name
        if (!$sqlServerNamespaces) {
            if ($Error.Count -gt 0) { 
                $errMsg = $Error[0].ToString()
            } 
            else {
                $errMsg = ''
            }
            throw "Cannot get SQL Server WMI namespace from '$computerName': $errMsg."
        }

        $cimObjects = @()
        foreach ($namespace in $sqlServerNamespaces) { 
            $cimObjects += Get-CimInstance -CimSession $cimSession -Namespace "ROOT\Microsoft\SqlServer\$namespace" `
            -Class 'FilestreamSettings' | Where-Object { $_.InstanceName -eq $instanceName }
        }

        if (!$cimObjects) {
            throw "Cannot find any SQL Server WMI object for instance '$instanceName' at '$($wmiParams.ComputerName)' from namespace ROOT\Microsoft\SqlServer - check your instance name is correct: '$instanceName'"
        }

        $changed = $false
        $numWmiInstancesCorrect = 0
        foreach ($cimObject in $cimObjects) { 
            $cimNamespace = $cimObject.CimClass.CimSystemProperties.Namespace
            if ($cimObject.AccessLevel -ne $FilestreamLevel) {
                Write-Log -Info "WMI $cimNamespace - setting filestream from $($cimObject.AccessLevel) to $FilestreamLevel."
                $result = Invoke-CimMethod -InputObject $cimObject -MethodName EnableFilestream -Arguments @{ 
                    AccessLevel = $FilestreamLevel
                    ShareName = $instanceName
                }
                if ($result.ReturnValue -eq 0) {
                    $changed = $true
                    $numWmiInstancesCorrect++
                } 
                else {
                    Write-Log -Warn "Failed to set filestream at $cimNamespace - return value from wmi.EnableFilestream: $($result.ReturnValue)"
                }
            } 
            else {
                Write-Log -Info "WMI $cimNamespace - filestream already at level $($cimObject.AccessLevel)."
                $numWmiInstancesCorrect++
            }
        }

        if ($numWmiInstancesCorrect -eq 0) {
            throw "Failed to set filestream on any WMI objects."
        }
    } finally {
        if ($cimSession) {
            [void](Remove-CimSession -CimSession $cimSession)
        }
    }

    if ($changed) {
        Write-Log -Info "Restarting service $sqlServiceName at '$($ConnectionParams.Nodes)'"
        $psSessionParams = $ConnectionParams.PSSessionParams
        Invoke-Command @psSessionParams -ScriptBlock { 
            Restart-Service -Name $using:sqlServiceName -Force # TODO: what about SQL Server Agent?
        }
    }

    $currentFilestreamLevel = Invoke-Sql -ConnectionString $ConnectionString -Query "select serverproperty('FilestreamEffectiveLevel')" -SqlCommandMode Scalar -DatabaseName ''
    if ($currentFileStreamLevel -ne $FilestreamLevel) { 
        Write-Log -Info "Setting filestream to level $FilestreamLevel - SQL"
        Invoke-Sql -ConnectionString $ConnectionString -Query "EXEC sp_configure filestream_access_level, ${FilestreamLevel}; RECONFIGURE" -SqlCommandMode NonQuery -DatabaseName ''
        $changed = $true
    }

    if ($changed) {
        Write-Log -Info "Filestream successfully changed to level $FilestreamLevel."
    } 
    else {
        Write-Log -Info "Filestream already at level $FilestreamLevel."
    }
}
