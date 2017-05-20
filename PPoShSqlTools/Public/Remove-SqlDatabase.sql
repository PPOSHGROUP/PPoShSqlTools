IF  EXISTS (SELECT name FROM sys.databases WHERE name = N'$(DatabaseName)')
BEGIN
    PRINT 'Deleting database $(DatabaseName)'
    ALTER DATABASE [$(DatabaseName)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
    DROP DATABASE [$(DatabaseName)]
END
ELSE
BEGIN
    PRINT 'Unable to delete. $(DatabaseName) does not exist.'
END
    

