IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'$(Username)')
BEGIN
    IF ($(WindowsAuthentication) = 0)
    BEGIN
        PRINT 'CREATING USER $(Username) WITH PASSWORD'
        CREATE LOGIN [$(Username)] WITH PASSWORD=N'$(Password)', DEFAULT_DATABASE=[master], CHECK_POLICY=OFF, CHECK_EXPIRATION=OFF
    END
    ELSE
    BEGIN
        PRINT 'CREATING USER $(Username) WITHOUT PASSWORD'
        CREATE LOGIN [$(Username)] FROM WINDOWS
    END
END
ELSE
BEGIN
    IF ($(WindowsAuthentication) = 0)
     BEGIN
        PRINT 'ALTERING USER $(Username). Setting new password'
        ALTER LOGIN [$(Username)] WITH PASSWORD=N'$(Password)', CHECK_POLICY=OFF, CHECK_EXPIRATION=OFF
    END
END
