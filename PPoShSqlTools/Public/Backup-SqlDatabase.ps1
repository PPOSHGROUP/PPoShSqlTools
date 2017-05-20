function Backup-SqlDatabase {
    <#
    .SYNOPSIS
        Creates SQL database backup.

    .DESCRIPTION
        Uses Invoke-Sql cmdlet to run Backup-SqlDatabase SQL script to backup database.   

    .EXAMPLE
        Backup-SqlDatabase -DatabaseName "DbName" -ConnectionString "Data Source=localhost;Integrated Security=True" -BackupPath "C:\db_backups\" -BackupName "DbName{0}.bak"
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ConnectionString,

        # The name of the database to be backed up - if not specified, Initial Catalog from ConnectionString will be used.
        [Parameter(Mandatory=$false)]
        [string]
        $DatabaseName, 

        # The folder path where backup will be stored.
        [Parameter(Mandatory=$true)]
        [string]
        $BackupPath,

        # The name of the backup. If you add placehodler {0} to BackupName, current date will be inserted.
        [Parameter(Mandatory=$true)]
        [string]
        $BackupName
    )

    $BackupName = if ($BackupName.Contains('{0}')) { $BackupName -f $(Get-Date -Format yyyy-MM-dd_HH-mm-ss) } else { $BackupName }
    $BackupFullPath = Join-Path -Path $BackupPath -ChildPath $BackupName

    $sqlScript = Join-Path -Path $PSScriptRoot -ChildPath "Backup-SqlDatabase.sql"
    if (!$DatabaseName) { 
        $csb = New-Object -TypeName System.Data.SqlClient.SqlConnectionStringBuilder -ArgumentList $ConnectionString
        $DatabaseName = $csb.InitialCatalog
    }
    if (!$DatabaseName) {
        throw "No database name - please specify -DatabaseName or add Initial Catalog to ConnectionString."
    }
    $parameters = @{ 
        DatabaseName = $DatabaseName
        BackupPath = $BackupFullPath
    }

    Write-Log -Info "Start creating database $DatabaseName backup to location $BackupFullPath"
    [void](Invoke-Sql -ConnectionString $ConnectionString -InputFile $sqlScript -SqlCmdVariables $parameters -DatabaseName '')
}