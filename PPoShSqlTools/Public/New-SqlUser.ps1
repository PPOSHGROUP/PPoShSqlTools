function New-SqlUser {
    <# 
    .SYNOPSIS 
    Creates or updates user on given database. It also remaps user to the login.

    .EXAMPLE
    New-SqlUser -ConnectionString $connectionString -DatabaseName "database" -Username "username" -DbRole "db_owner|db_datareader"
    #> 
    
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ConnectionString,
    
        [Parameter(Mandatory=$true)]
        [string]
        $Username,

        #  Database name - if not specified, Initial Catalog from ConnectionString will be used.
        [Parameter(Mandatory=$false)]
        [string]
        $DatabaseName,
    
        # Database roles to assign to the user.
        [Parameter(Mandatory=$false)]
        [string[]]
        $DbRoles
    )
    $sqlScript = Join-Path -Path $PSScriptRoot -ChildPath 'New-SqlUser.sql'

    if (!$DatabaseName) { 
        $csb = New-Object -TypeName System.Data.SqlClient.SqlConnectionStringBuilder -ArgumentList $ConnectionString
        $DatabaseName = $csb.InitialCatalog
    }
    if (!$DatabaseName) {
        throw "No database name - please specify -DatabaseName or add Initial Catalog to ConnectionString."
    }

    $parameters =  @{ 
        Username = $Username 
        DatabaseName = $DatabaseName
    }
    [void](Invoke-Sql -ConnectionString $ConnectionString -InputFile $sqlScript -SqlCmdVariables $parameters -DatabaseName '')

    $sqlScript = Join-Path -Path $PSScriptRoot -ChildPath 'New-SqlUserRole.sql'
    foreach ($role in $DbRoles) {
        [void](Invoke-Sql -ConnectionString $connectionString -InputFile $sqlScript -SqlCmdVariables @{ Username = $Username; DatabaseName = $DatabaseName; Role = $role } -DatabaseName '')
    }
}