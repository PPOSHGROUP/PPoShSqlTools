IF (NOT EXISTS (select name from sys.databases where name = '$(DatabaseName)'))
BEGIN
  PRINT 'Creating database $(DatabaseName)'
	CREATE DATABASE [$(DatabaseName)]
	ALTER DATABASE [$(DatabaseName)] SET RECOVERY SIMPLE 
	ALTER DATABASE [$(DatabaseName)] SET MULTI_USER 
END
ELSE
BEGIN
  PRINT 'Database $(DatabaseName) already exists'
END