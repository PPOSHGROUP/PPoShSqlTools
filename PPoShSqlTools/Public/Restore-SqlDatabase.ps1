function Restore-SqlDatabase {
    <# 
    .SYNOPSIS 
        Restores database on MSSQL Server.

    .DESCRIPTION 
    Uses Restore-SqlDatabase.sql sql script to restore database.    

    .EXAMPLE
        Restore-SqlDatabase -DatabaseName "DbName" -ConnectionString "data source=localhost;integrated security=True" -Path "C:\database.bak"
    #> 

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ConnectionString,

        # Database name - if not specified, Initial Catalog from ConnectionString will be used.
        [Parameter(Mandatory=$false)]
        [string]
        $DatabaseName, 
        
        # Backup file path.
        [Parameter(Mandatory=$true)]
        [string]
        $Path,

        # Remote share credential to use if $Path is an UNC path. Note the file will be copied to localhost if this set, and this will work only if 
        # you're connecting to local database.
        [Parameter(Mandatory=$false)]
        [PSCredential] 
        $RemoteShareCredential,

        # Timeout for executing sql restore command.
        [Parameter(Mandatory=$false)] 
        [int]
        $QueryTimeoutInSeconds = 3600
    )

    try { 
        if (!$DatabaseName) { 
            $csb = New-Object -TypeName System.Data.SqlClient.SqlConnectionStringBuilder -ArgumentList $ConnectionString
            $DatabaseName = $csb.InitialCatalog
        }
        if (!$DatabaseName) {
            throw "No database name - please specify -DatabaseName or add Initial Catalog to ConnectionString."
        }

        if ($RemoteShareCredential) {
            $shareDir = Split-Path -Path $Path -Parent
            #TODO: disconnect-share by prefix
            Connect-Share -Path $shareDir -Credential $RemoteShareCredential
            $tempDir = New-TempDirectory
            Write-Log -Info "Copying '$Path' to '$tempDir'"
            Copy-Item -Path $Path -Destination $tempDir -Force
            #TODO: unhardcode this user
            Set-SimpleAcl -Path $tempDir -User 'NT Service\MSSQLSERVER' -Permission 'Read' -Type 'Allow'
            $Path = Join-Path -Path $tempDir -ChildPath (Split-Path -Path $Path -Leaf)
        }

        $sqlScript = Join-Path -Path $PSScriptRoot -ChildPath "Restore-SqlDatabase.sql"
        $parameters =  @{ "DatabaseName" = $DatabaseName }
        $parameters += @{ "Path" = $Path }
        [void](Invoke-Sql -ConnectionString $ConnectionString -InputFile $sqlScript -SqlCmdVariables $parameters -QueryTimeoutInSeconds $QueryTimeoutInSeconds -DatabaseName '')
    } finally {
        if ($RemoteShareCredential) {
            Disconnect-Share -Path $shareDir
            Remove-TempDirectory
        }
    }
}