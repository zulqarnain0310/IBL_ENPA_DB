SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

create PROC [dbo].[MainTablesDataBackup_BKP_22122023]

AS

DECLARE @TIMEKEY INT ,@Exec_Date DATE

BEGIN TRY
BEGIN TRAN
SELECT @TIMEKEY=TimeKey,@Exec_Date=Date
FROM IBL_ENPA_DB_LOCAL_DEV.dbo.SysDataMatrix
WHERE CurrentStatus='C'
--Audit 
DELETE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] 
WHERE [SP_Name]='MainTablesDataBackup' AND [EXT_DATE]=GETDATE() AND ISNULL([Audit_Flg],0)=0

INSERT INTO IBL_ENPA_STGDB.[dbo].[Procedure_Audit]
           ([EXT_DATE] ,[Timekey] ,[SP_Name],Start_Date_Time )
SELECT @Exec_Date,@TimeKey,'MainTablesDataBackup',GETDATE()

TRUNCATE TABLE [dbo].[NPA_IntegrationDetails_Temp_EOM_Process]
INSERT INTO [dbo].[NPA_IntegrationDetails_Temp_EOM_Process]
SELECT * FROM [dbo].[NPA_IntegrationDetails]
WHERE EffectiveFromTimeKey<=@TIMEKEY
AND   EffectiveToTimeKey>=@TIMEKEY


TRUNCATE TABLE [CurDat].[AdvSecurityDetail_Temp_EOM_Process]
INSERT INTO [CurDat].[AdvSecurityDetail_Temp_EOM_Process]
SELECT * FROM [CurDat].[AdvSecurityDetail]
WHERE EffectiveFromTimeKey<=@TIMEKEY
AND   EffectiveToTimeKey>=@TIMEKEY

TRUNCATE TABLE [CurDat].[AdvSecurityValueDetail_Temp_EOM_Process]
INSERT INTO [CurDat].[AdvSecurityValueDetail_Temp_EOM_Process]
SELECT * FROM [CurDat].[AdvSecurityValueDetail]
WHERE EffectiveFromTimeKey<=@TIMEKEY
AND   EffectiveToTimeKey>=@TIMEKEY

TRUNCATE TABLE [CurDat].[AdvAcRestructureDetail_Temp_EOM_Process]
INSERT INTO [CurDat].[AdvAcRestructureDetail_Temp_EOM_Process]
SELECT * FROM [CurDat].[AdvAcRestructureDetail]
WHERE EffectiveFromTimeKey<=@TIMEKEY
AND   EffectiveToTimeKey>=@TIMEKEY

--UPDATE Audit Flag
UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET End_Date_Time=GETDATE(),[Audit_Flg]=1 
WHERE [SP_Name]='MainTablesDataBackup' AND [EXT_DATE]=@Exec_Date AND ISNULL([Audit_Flg],0)=0

COMMIT TRAN
END TRY
BEGIN CATCH
 DECLARE
   @ErMessage NVARCHAR(2048),
   @ErSeverity INT,
   @ErState INT
 
 SELECT  @ErMessage = ERROR_MESSAGE(),
   @ErSeverity = ERROR_SEVERITY(),
   @ErState = ERROR_STATE()
 
--UPDATE Audit Flag
UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET  ERROR_MESSAGE=@ErMessage 
WHERE [SP_Name]='MainTablesDataBackup' AND [EXT_DATE]=@Exec_Date AND ISNULL([Audit_Flg],0)=0

 RAISERROR (@ErMessage,
             @ErSeverity,
             @ErState )

ROLLBACK TRAN
END CATCH
GO