function New-SqlLogin {
    <# 
    .SYNOPSIS 
        Creates or updates database login on MSSQL Server.

    .EXAMPLE
        New-SqlLogin -ConnectionString "data source=localhost;integrated security=True" -Credentials (Get-Credential)
    #> 

    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ConnectionString,
        
        # Credentials of the login to add (username + optional password).
        [Parameter(Mandatory=$true)]
        [PSCredential]
        $Credentials,
               
        # Whether the login uses Windows Authentication (if not set, it will be SQL Server Authentication).
        [Parameter(Mandatory=$false)]
        [switch]
        $WindowsAuthentication,

        # List of server roles to assign to the user. Note roles are only added, not removed.
        [Parameter(Mandatory=$false)]
        [string[]]
        $ServerRoles
    )
    $sqlScript = Join-Path -Path $PSScriptRoot -ChildPath 'New-SqlLogin.sql'

    if ([string]::IsNullOrEmpty($Credentials.GetNetworkCredential().Password) -and !$WindowsAuthentication) {
        throw "Empty password when WindowsAuthentication is set to false"
    }
    
    if ($WindowsAuthentication) {
        $WinAuth = "1"
    }
    else {
        $WinAuth = "0"
    }
    
    $parameters =  @{ 
        Username = $Credentials.UserName
        Password = $Credentials.GetNetworkCredential().Password 
        WindowsAuthentication = $WinAuth
    }

   [void](Invoke-Sql -ConnectionString $connectionString -InputFile $sqlScript -SqlCmdVariables $parameters -DatabaseName '')

   $sqlScript = Join-Path -Path $PSScriptRoot -ChildPath 'New-SqlLoginRole.sql'
   foreach ($role in $ServerRoles) {
     [void](Invoke-Sql -ConnectionString $connectionString -InputFile $sqlScript -SqlCmdVariables @{ Username = $Username; Role = $role } -DatabaseName '')
   }
}