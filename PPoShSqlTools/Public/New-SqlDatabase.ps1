function New-SqlDatabase {
    <# 
    .SYNOPSIS 
        Creates a new SQL Server database with default settings and simple recovery mode.

    .DESCRIPTION 
        Creates database using New-SqlDatabase.sql script with default settings.

    .EXAMPLE
        New-SqlDatabase -DatabaseName "MyDb" -ConnectionString "Data Source=localhost;Integrated Security=True"
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

        [Parameter(Mandatory=$false)] 
        [int]
        $QueryTimeoutInSeconds

    )

    $sqlScript = Join-Path -Path $PSScriptRoot -ChildPath "New-SqlDatabase.sql"

    if (!$DatabaseName) { 
        $csb = New-Object -TypeName System.Data.SqlClient.SqlConnectionStringBuilder -ArgumentList $ConnectionString
        $DatabaseName = $csb.InitialCatalog
    }
    if (!$DatabaseName) {
        throw "No database name - please specify -DatabaseName or add Initial Catalog to ConnectionString."
    }

    $parameters = @{ "DatabaseName" = $databaseName }
    [void](Invoke-Sql -ConnectionString $ConnectionString -InputFile $sqlScript -SqlCmdVariables $parameters -QueryTimeoutInSeconds $QueryTimeoutInSeconds -DatabaseName '')
}