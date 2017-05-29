USE MASTER

SET NOCOUNT ON

DECLARE @DatabaseName NVARCHAR(255) = N'$(DatabaseName)'
DECLARE @BackupLocation NVARCHAR(255) = N'$(Path)'

DECLARE @DatabaseFilesFolder NVARCHAR(255) = NULL
DECLARE @DatabaseLogsFolder NVARCHAR(255) = NULL
DECLARE @Sql NVARCHAR(max)
DECLARE @Msg NVARCHAR(max)
DECLARE @OldDatabaseName NVARCHAR(128)
DECLARE @version NVARCHAR(128)
DECLARE @versionInt INT

DECLARE @BackupFileList2014_2016 table(LogicalName NVARCHAR(128) NOT NULL, PhysicalName NVARCHAR(260) NOT NULL, [Type] CHAR(1) NOT NULL, FileGroupName NVARCHAR(120) NULL, Size NUMERIC(20, 0) NOT NULL, MaxSize NUMERIC(20, 0) NOT NULL, FileID BIGINT NULL, CreateLSN NUMERIC(25,0) NULL, DropLSN NUMERIC(25,0) NULL, UniqueID UNIQUEIDENTIFIER NULL, ReadOnlyLSN NUMERIC(25,0) NULL , ReadWriteLSN NUMERIC(25,0) NULL, BackupSizeInBytes BIGINT NULL, SourceBlockSize INT NULL, FileGroupID INT NULL, LogGroupGUID UNIQUEIDENTIFIER NULL, DfferentialBaseLSN NUMERIC(25,0)NULL, DifferentialBaseGUID UNIQUEIDENTIFIER NULL, IsReadOnly BIT NULL, IsPresent BIT NULL, TDEThumbprint VARBINARY(32) NULL, SnapshotUrl VARCHAR(MAX)) 
DECLARE @BackupFileList2008_2012 table(LogicalName NVARCHAR(128) NOT NULL, PhysicalName NVARCHAR(260) NOT NULL, [Type] CHAR(1) NOT NULL, FileGroupName NVARCHAR(120) NULL, Size NUMERIC(20, 0) NOT NULL, MaxSize NUMERIC(20, 0) NOT NULL, FileID BIGINT NULL, CreateLSN NUMERIC(25,0) NULL, DropLSN NUMERIC(25,0) NULL, UniqueID UNIQUEIDENTIFIER NULL, ReadOnlyLSN NUMERIC(25,0) NULL , ReadWriteLSN NUMERIC(25,0) NULL, BackupSizeInBytes BIGINT NULL, SourceBlockSize INT NULL, FileGroupID INT NULL, LogGroupGUID UNIQUEIDENTIFIER NULL, DfferentialBaseLSN NUMERIC(25,0)NULL, DifferentialBaseGUID UNIQUEIDENTIFIER NULL, IsReadOnly BIT NULL, IsPresent BIT NULL, TDEThumbprint VARBINARY(32) NULL) 
DECLARE @BackupFileList2005 table(LogicalName NVARCHAR(128) NOT NULL, PhysicalName NVARCHAR(260) NOT NULL, [Type] CHAR(1) NOT NULL, FileGroupName NVARCHAR(120) NULL, Size NUMERIC(20, 0) NOT NULL, MaxSize NUMERIC(20, 0) NOT NULL, FileID BIGINT NULL, CreateLSN NUMERIC(25,0) NULL, DropLSN NUMERIC(25,0) NULL, UniqueID UNIQUEIDENTIFIER NULL, ReadOnlyLSN NUMERIC(25,0) NULL , ReadWriteLSN NUMERIC(25,0) NULL, BackupSizeInBytes BIGINT NULL, SourceBlockSize INT NULL, FileGroupID INT NULL, LogGroupGUID UNIQUEIDENTIFIER NULL, DfferentialBaseLSN NUMERIC(25,0)NULL, DifferentialBaseGUID UNIQUEIDENTIFIER NULL, IsReadOnly BIT NULL, IsPresent BIT NULL) 
DECLARE @BackupHeader2014_2016 table(BackupName nvarchar(128), BackupDescription nvarchar(255), BackupType smallint, ExpirationDate datetime, Compressed bit, Position smallint, DeviceType tinyint, UserName nvarchar(128), ServerName nvarchar(128), DatabaseName nvarchar(128), DatabaseVersion int, DatabaseCreationDate datetime, BackupSize numeric(20,0), FirstLSN numeric(25,0), LastLSN numeric(25,0), CheckpointLSN numeric(25,0), DatabaseBackupLSN numeric(25,0), BackupStartDate datetime, BackupFinishDate datetime, SortOrder smallint, [CodePage] smallint, UnicodeLocaleId int, UnicodeComparisonStyle int, CompatibilityLevel tinyint, SoftwareVendorId int, SoftwareVersionMajor int, SoftwareVersionMinor int, SoftwareVersionBuild int, MachineName nvarchar(128), Flags int, BindingID uniqueidentifier, RecoveryForkID uniqueidentifier, Collation nvarchar(128), FamilyGUID uniqueidentifier, HasBulkLoggedData bit, IsSnapshot bit, IsReadOnly bit, IsSingleUser bit, HasBackupChecksums bit, IsDamaged bit, BeginsLogChain bit, HasIncompleteMetaData bit, IsForceOffline bit, IsCopyOnly bit, FirstRecoveryForkID uniqueidentifier, ForkPointLSN numeric(25,0) NULL, RecoveryModel nvarchar(60), DifferentialBaseLSN numeric(25,0) NULL, DifferentialBaseGUID uniqueidentifier, BackupTypeDescription nvarchar(60), BackupSetGUID uniqueidentifier NULL, CompressedBackupSize bigint NULL, Containment varchar(256), KeyAlgorithm nvarchar(32) NULL, EncryptorThumbprint varbinary(20) NULL, EncryptorType nvarchar(32) NULL)
DECLARE @BackupHeader2012 table(BackupName nvarchar(128), BackupDescription nvarchar(255), BackupType smallint, ExpirationDate datetime, Compressed bit, Position smallint, DeviceType tinyint, UserName nvarchar(128), ServerName nvarchar(128), DatabaseName nvarchar(128), DatabaseVersion int, DatabaseCreationDate datetime, BackupSize numeric(20,0), FirstLSN numeric(25,0), LastLSN numeric(25,0), CheckpointLSN numeric(25,0), DatabaseBackupLSN numeric(25,0), BackupStartDate datetime, BackupFinishDate datetime, SortOrder smallint, [CodePage] smallint, UnicodeLocaleId int, UnicodeComparisonStyle int, CompatibilityLevel tinyint, SoftwareVendorId int, SoftwareVersionMajor int, SoftwareVersionMinor int, SoftwareVersionBuild int, MachineName nvarchar(128), Flags int, BindingID uniqueidentifier, RecoveryForkID uniqueidentifier, Collation nvarchar(128), FamilyGUID uniqueidentifier, HasBulkLoggedData bit, IsSnapshot bit, IsReadOnly bit, IsSingleUser bit, HasBackupChecksums bit, IsDamaged bit, BeginsLogChain bit, HasIncompleteMetaData bit, IsForceOffline bit, IsCopyOnly bit, FirstRecoveryForkID uniqueidentifier, ForkPointLSN numeric(25,0) NULL, RecoveryModel nvarchar(60), DifferentialBaseLSN numeric(25,0) NULL, DifferentialBaseGUID uniqueidentifier, BackupTypeDescription nvarchar(60), BackupSetGUID uniqueidentifier NULL, CompressedBackupSize bigint NULL, Containment varchar(256))
DECLARE @BackupHeader2008 table(BackupName nvarchar(128), BackupDescription nvarchar(255), BackupType smallint, ExpirationDate datetime, Compressed bit, Position smallint, DeviceType tinyint, UserName nvarchar(128), ServerName nvarchar(128), DatabaseName nvarchar(128), DatabaseVersion int, DatabaseCreationDate datetime, BackupSize numeric(20,0), FirstLSN numeric(25,0), LastLSN numeric(25,0), CheckpointLSN numeric(25,0), DatabaseBackupLSN numeric(25,0), BackupStartDate datetime, BackupFinishDate datetime, SortOrder smallint, [CodePage] smallint, UnicodeLocaleId int, UnicodeComparisonStyle int, CompatibilityLevel tinyint, SoftwareVendorId int, SoftwareVersionMajor int, SoftwareVersionMinor int, SoftwareVersionBuild int, MachineName nvarchar(128), Flags int, BindingID uniqueidentifier, RecoveryForkID uniqueidentifier, Collation nvarchar(128), FamilyGUID uniqueidentifier, HasBulkLoggedData bit, IsSnapshot bit, IsReadOnly bit, IsSingleUser bit, HasBackupChecksums bit, IsDamaged bit, BeginsLogChain bit, HasIncompleteMetaData bit, IsForceOffline bit, IsCopyOnly bit, FirstRecoveryForkID uniqueidentifier, ForkPointLSN numeric(25,0) NULL, RecoveryModel nvarchar(60), DifferentialBaseLSN numeric(25,0) NULL, DifferentialBaseGUID uniqueidentifier, BackupTypeDescription nvarchar(60), BackupSetGUID uniqueidentifier NULL, CompressedBackupSize bigint NULL)
DECLARE @BackupHeader2005 table(BackupName nvarchar(128), BackupDescription nvarchar(255), BackupType smallint, ExpirationDate datetime, Compressed bit, Position smallint, DeviceType tinyint, UserName nvarchar(128), ServerName nvarchar(128), DatabaseName nvarchar(128), DatabaseVersion int, DatabaseCreationDate datetime, BackupSize numeric(20,0), FirstLSN numeric(25,0), LastLSN numeric(25,0), CheckpointLSN numeric(25,0), DatabaseBackupLSN numeric(25,0), BackupStartDate datetime, BackupFinishDate datetime, SortOrder smallint, [CodePage] smallint, UnicodeLocaleId int, UnicodeComparisonStyle int, CompatibilityLevel tinyint, SoftwareVendorId int, SoftwareVersionMajor int, SoftwareVersionMinor int, SoftwareVersionBuild int, MachineName nvarchar(128), Flags int, BindingID uniqueidentifier, RecoveryForkID uniqueidentifier, Collation nvarchar(128), FamilyGUID uniqueidentifier, HasBulkLoggedData bit, IsSnapshot bit, IsReadOnly bit, IsSingleUser bit, HasBackupChecksums bit, IsDamaged bit, BeginsLogChain bit, HasIncompleteMetaData bit, IsForceOffline bit, IsCopyOnly bit, FirstRecoveryForkID uniqueidentifier, ForkPointLSN numeric(25,0) NULL, RecoveryModel nvarchar(60), DifferentialBaseLSN numeric(25,0) NULL, DifferentialBaseGUID uniqueidentifier, BackupTypeDescription nvarchar(60), BackupSetGUID uniqueidentifier NULL)

SET @version = CAST(SERVERPROPERTY('ProductVersion') AS nvarchar)
SET @versionInt = CAST(SUBSTRING(@version, 1, CHARINDEX('.', @version) - 1) AS INT)

IF @DatabaseFilesFolder IS NULL
BEGIN
                -- Get DatabaseFilesFolder from master file location
                SELECT 
                               @DatabaseFilesFolder = SUBSTRING(physical_name, 1, CHARINDEX(N'master.mdf', LOWER(physical_name)) - 2) 
                FROM 
                               master.sys.master_files
                WHERE 
                               name = 'master' AND type_desc = 'ROWS'
END
IF @DatabaseLogsFolder IS NULL
BEGIN
                -- Get DatabaseFilesFolder from master file location
                SELECT 
                               @DatabaseLogsFolder = SUBSTRING(physical_name, 1, CHARINDEX(N'templog.ldf', LOWER(physical_name)) - 2) 
                FROM 
                               master.sys.master_files
                WHERE 
                               name = 'templog' AND type_desc = 'LOG'           
END

IF EXISTS (SELECT * FROM sys.databases WHERE name = @DatabaseName)
BEGIN
                SET @Msg = CONVERT(VARCHAR, GETDATE(), 120) + ' [' + @DatabaseName + '] Setting SINGLE_USER'
                RAISERROR(@Msg, 0, 1) WITH NOWAIT
                SET @Sql = 'ALTER DATABASE ' + @DatabaseName + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE'
                EXEC(@sql)
END

SET @Msg = CONVERT(VARCHAR, GETDATE(), 120) + ' [' + @DatabaseName + '] Reading backup file ' + @BackupLocation
RAISERROR(@Msg, 0, 1) WITH NOWAIT

SET @Sql = 'RESTORE FILELISTONLY FROM DISK = ''' + @BackupLocation + ''''
IF @versionInt IN (12, 13)
BEGIN
			 INSERT INTO @BackupFileList2014_2016
			 EXEC (@Sql)
END
ELSE IF @versionInt IN (10, 11)
BEGIN
                INSERT INTO @BackupFileList2008_2012
                EXEC(@Sql)
END
ELSE IF @versionInt = 9
BEGIN
                INSERT INTO @BackupFileList2005
                EXEC(@Sql)
END
ELSE
	RAISERROR ('Failed to read file list from backup. This version of SQL server is not supported', -- Message text.
            16, -- Severity.
            1 -- State.
            );

SET @Sql = 'RESTORE HEADERONLY FROM DISK = ''' + @BackupLocation + ''''
IF @versionInt IN (12, 13)
BEGIN
	            INSERT INTO @BackupHeader2014_2016
                EXEC(@Sql)
END
ELSE IF @versionInt = 11
BEGIN
                INSERT INTO @BackupHeader2012
                EXEC(@Sql)
END
ELSE IF @versionInt = 10
BEGIN
                INSERT INTO @BackupHeader2008
                EXEC(@Sql)
END
ELSE  IF @versionInt = 9
BEGIN
                INSERT INTO @BackupHeader2005
                EXEC(@Sql)
END
ELSE
	RAISERROR ('Failed to read backup header. This version of SQL server is not supported', -- Message text.
            16, -- Severity.
            1 -- State.
            );

SELECT @OldDatabaseName = DatabaseName FROM 
( 
	SELECT DatabaseName FROM @BackupHeader2014_2016 UNION ALL
	SELECT DatabaseName FROM @BackupHeader2012 UNION ALL
	SELECT DatabaseName FROM @BackupHeader2008 UNION ALL
	SELECT DatabaseName FROM @BackupHeader2005
) x

SET @Sql = 'RESTORE DATABASE ' + @DatabaseName + ' FROM DISK = N''' + @BackupLocation + ''' WITH FILE = 1, '

SELECT
                @Sql = @Sql + 'MOVE N''' + LogicalName + ''' TO N''' + CASE WHEN [Type] = 'L' THEN @DatabaseLogsFolder ELSE @DatabaseFilesFolder END + '\' + @DatabaseName + 
                '_' + REPLACE(LogicalName, @OldDatabaseName + '_', '') + SUBSTRING(PhysicalName, LEN(PhysicalName) - 3, 4) + ''', '
FROM
( 
	SELECT [Type], LogicalName, PhysicalName FROM @BackupFileList2014_2016 UNION ALL
	SELECT [Type], LogicalName, PhysicalName FROM @BackupFileList2008_2012 UNION ALL	
	SELECT [Type], LogicalName, PhysicalName FROM @BackupFileList2005
) x

SET @Sql = @Sql + 'NOUNLOAD, REPLACE, STATS = 10'

SET @Msg = CONVERT(VARCHAR, GETDATE(), 120) + ' [' + @DatabaseName + '] Restoring database'
RAISERROR(@Msg, 0, 1) WITH NOWAIT
EXEC(@Sql)

SET @Msg = CONVERT(VARCHAR, GETDATE(), 120) + ' [' + @DatabaseName + '] Setting recovery to SIMPLE'
RAISERROR(@Msg, 0, 1) WITH NOWAIT
SET @sql = 'ALTER DATABASE ' + @DatabaseName + ' SET RECOVERY SIMPLE'
EXEC(@Sql)

SET @Msg = CONVERT(VARCHAR, GETDATE(), 120) + ' [' + @DatabaseName + '] Setting MULTI_USER'
RAISERROR(@Msg, 0, 1) WITH NOWAIT
SET @Sql = 'ALTER DATABASE ' + @DatabaseName + ' SET MULTI_USER'
EXEC(@sql)

GO