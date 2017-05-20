IF (IS_SRVROLEMEMBER('$(Role)', '$(Username)') = 0)
BEGIN
    PRINT 'Adding user $(Username) to server role $(Role).'
    EXEC sp_addsrvrolemember @rolename = '$(Role)', @loginame = '$(Username)'
    
    --This is not ok for SQL Server 2008
    --ALTER SERVER ROLE [$(Role)] ADD MEMBER [$(Username)]
END
ELSE
BEGIN
    PRINT 'User $(Username) already has server role $(Role).'
END