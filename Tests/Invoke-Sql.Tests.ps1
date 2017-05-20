<#
The MIT License (MIT)

Copyright (c) 2015 Objectivity Bespoke Software Specialists

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

Import-Module -Name "$PSScriptRoot\..\PPoShSqlTools" -Force

Describe -Tag "PPoShSqlTools" "Invoke-Sql" {
    InModuleScope PPoShSqlTools {
        Mock Write-Log { 
             Write-Information $Message
        }

        Mock Start-ExternalProcess -MockWith { $Output.Value = "command_executed" }
        
            
        Context "When Invoke-Sql Is called with mode sqlcmd" {
            Mock Test-Path -MockWith { if ($LiteralPath -match 'sqlcmd|Binn') { return $true } }
            $connectionString = "data source=localhost;integrated security=True"
            $sql = "SELECT * FROM Categories"
            $param = @{"dummy"="param"; "anotherdummy"="parameter"}

            It "should return command_executed result when all parameters are given" {
                Invoke-Sql -ConnectionString $connectionString -Query $sql -QueryTimeoutInSeconds 65030 -SqlCmdVariables $param -Mode sqlcmd | Should Be "command_executed"
            }

            It "should return command_executed result when all mandatory parameters are given" {
                Invoke-Sql -ConnectionString $connectionString -Query $sql -Mode sqlcmd | Should Be "command_executed"
            }
        }
    }
}

 