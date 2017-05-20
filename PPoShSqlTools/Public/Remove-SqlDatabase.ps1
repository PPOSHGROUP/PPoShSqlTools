function Remove-SqlDatabase {
    <# 
    .SYNOPSIS 
        Remove database from MSSQL Server.

    .DESCRIPTION 
        Drops database using Remove-SqlDatabase.sql script. Does nothing when database does not exists.

    .EXAMPLE
        Remove-SqlDatabase -DatabaseName "MyDb" -ConnectionString "data source=localhost;integrated security=True"
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

    $sqlScript = Join-Path -Path $PSScriptRoot -ChildPath "Remove-SqlDatabase.sql"
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
