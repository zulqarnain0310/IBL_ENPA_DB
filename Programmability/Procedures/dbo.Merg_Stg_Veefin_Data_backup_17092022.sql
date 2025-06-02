SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO




CReate PROC [dbo].[Merg_Stg_Veefin_Data_backup_17092022]
WITH RECOMPILE
AS
DECLARE @TimeKey Smallint=(SELECT TimeKey FROM SysDatamatrix WHERE CurrentStatus='C')
DECLARE @Exec_Date DATE=(SELECT DATE FROM SysDataMatrix WHERE CurrentStatus='C' )
DECLARE @MAX_AccountEntityID INT=(SELECT ISNULL(MAX(AccountEntityID),0) FROM NPA_IntegrationDetails)
DECLARE @SrcSysAlt_Key Smallint=(SELECT SourceAlt_Key FROM [dbo].[DimSourceSystem] WHERE SourceName='Veefin' AND  EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
DECLARE @MonthEndDate DATE=(SELECT EOMONTH(DATEADD(MONTH,-1,@Exec_Date)))
DECLARE @MonthEndTimekey Smallint=(SELECT TimeKey FROM SysDataMatrix WHERE CAST(DATE AS DATE)=@MonthEndDate)

DECLARE @Daily_COUNT INT=(SELECT COUNT(1) FROM IBL_ENPA_STGDB.dbo.Veefin_Stg_Daily_Error)
DECLARE @Incremental_COUNT INT=(SELECT COUNT(1) FROM IBL_ENPA_STGDB.dbo.Veefin_Stg_Incremental_Error)
DECLARE @Error_Str VARCHAR(100)= 'Data is not Available for '+CAST(@Exec_Date AS VARCHAR(10))
DECLARE @DataProcessingFlg VARCHAR(1)

SELECT @DataProcessingFlg=(CASE WHEN @Incremental_COUNT>0 OR @Daily_COUNT>0 
                                   OR  (SELECT ISNULL(COUNT(1),0) FROM IBL_ENPA_STGDB.DBO.Veefin_Stg_Daily WHERE AsOnDate=@Exec_Date)=0
                                    THEN 0
                               ELSE 1
                           END)  

IF(@DataProcessingFlg=0) 
BEGIN 

DECLARE @DATEDATAUSE DATE=(SELECT DATE FROM SysDataMatrix WHERE TimeKey=(SELECT MAX(EffectiveToTimeKey) FROM NPA_IntegrationDetails))

INSERT INTO [dbo].[LagDateDataDetails]
           ([DateOfData]
           ,[SourceSystem]
           ,[DataDateUsed])
SELECT @Exec_Date,'Veefin',@DATEDATAUSE
END 

--Audit 
DELETE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] 
WHERE [SP_Name]='Merg_Stg_Veefin_Data' AND [EXT_DATE]=GETDATE() AND ISNULL([Audit_Flg],0)=0

INSERT INTO IBL_ENPA_STGDB.[dbo].[Procedure_Audit]
           ([EXT_DATE] ,[Timekey] ,[SP_Name],Start_Date_Time )
SELECT @Exec_Date,@TimeKey,'Merg_Stg_Veefin_Data',GETDATE()

BEGIN TRY

BEGIN TRAN

--IF(@DataProcessingFlg=1)
--BEGIN


DECLARE @EXT_DT DATE=(SELECT DATE FROM SysDataMatrix WHERE CurrentStatus='C')

--Updating Existing Records
UPDATE NPA SET 
NPA.Balance= ISNULL(PSD.BALANCE,0) ,
NPA.PrincipleOutstanding= ISNULL(PSD.PrincOutStd,0),
NPA.IntOverdue=ISNULL(PSD.IntOverdue,0),
NPA.IntAccrued=ISNULL(PSD.IntAccrued ,0),
NPA.PrincOverdue=ISNULL(PSD.PrincOverdue,0)

FROM NPA_IntegrationDetails NPA
INNER JOIN IBL_ENPA_STGDB.dbo.Veefin_Stg_Daily PSD ON --NPA.SrcSysAlt_Key=@SrcSysAlt_Key
                                                   NPA.EffectiveFromTimeKey<=@TimeKey
                                                  AND NPA.EffectiveToTimeKey>=@TimeKey
												  AND PSD.AsOnDate=@EXT_DT
												  AND NPA.NCIF_Id=PSD.UCIF_ID
												  AND NPA.CustomerId=PSD.RefCustomerID
												  AND NPA.CustomerACID=PSD.CustomerAcID
WHERE (ISNULL(NPA.Balance,0) <> ISNULL(PSD.BALANCE,0) 
   OR ISNULL(NPA.PrincipleOutstanding,0) <> ISNULL(PSD.PrincOutStd,0)
   OR ISNULL(NPA.IntAccrued,0)<>ISNULL(PSD.IntAccrued,0)
   OR ISNULL(NPA.IntOverdue,0)<>ISNULL(PSD.IntOverdue,0)
   OR ISNULL(NPA.PrincOverdue,0)<>ISNULL(PSD.PrincOverdue,0))
AND PSD.AsOnDate=@Exec_Date



--Updating data From incremental table
UPDATE NI
SET 
	
	
	PrincOverdueSinceDt=FI.PrincOverdueSinceDt,
	
	IntOverdueSinceDt=FI.IntOverdueSinceDt,

	[DPD_Overdue_Loans]=CASE WHEN FI.PrincOverdueSinceDt=NULL AND FI.IntOverdueSinceDt=NULL THEN NULL
                        ELSE DATEDIFF(DAY,(CASE WHEN  ISNULL(FI.PrincOverdueSinceDt,'2099-01-01') < ISNULL(FI.IntOverdueSinceDt,'2099-01-01') Then FI.PrincOverdueSinceDt
                                                
                                                ELSE FI.IntOverdueSinceDt END),@Exec_Date)+1 END
	
FROM NPA_IntegrationDetails NI
INNER JOIN IBL_ENPA_STGDB.dbo.Veefin_Stg_Incremental  FI ON EffectiveFromTimeKey<=@TimeKey
													    AND EffectiveToTimeKey>=@TimeKey
														AND FI.AsOnDate=@EXT_DT
                                                        AND NI.NCIF_Id=FI.UCIF_ID
												        AND NI.CustomerId=FI.RefCustomerID
												        AND NI.CustomerACID=FI.CustomerAcID
                                                        --AND NI.SrcSysAlt_Key=@SrcSysAlt_Key
													    AND FI.AsOnDate=@Exec_Date


UPDATE NPA_IntegrationDetails 
SET PrincipleOutstanding=0,UNSERVED_INTEREST=0 ,Balance=0,IntOverdue=0    ------ Added on 16-06-2021 for Balance,IntOverdue by sunil
WHERE EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey
AND IsTWO='Y'

-----------------Added on 12082021

UPDATE NPA_IntegrationDetails SET MaxDPD=(SELECT Max(v) FROM (VALUES ([DPD_Interest_Not_Serviced]),
                                    ([DPD_Overdrawn]), 
                                    (CASE WHEN [DPD_Renewals]-90<0 THEN 0 ELSE [DPD_Renewals]-90 END ),
									(CASE WHEN DPD_StockStmt-90<0 THEN 0 ELSE DPD_StockStmt-90 END ),
									([DPD_Overdue_Loans])) AS value(v))
WHERE EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey
AND SrcSysAlt_Key=(SELECT SourceAlt_Key FROM DimSourceSystem WHERE SourceName='Finacle' and EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)





--UPDATE Audit Flag
UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET End_Date_Time=GETDATE(),[Audit_Flg]=1 
WHERE [SP_Name]='Merg_Stg_Veefin_Data' AND [EXT_DATE]=@EXT_DT AND ISNULL([Audit_Flg],0)=0






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
 
 UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET ERROR_MESSAGE=@ErMessage   
WHERE [SP_Name]='Merg_Stg_Veefin_Data' AND [EXT_DATE]=@EXT_DT AND ISNULL([Audit_Flg],0)=0

 RAISERROR (@ErMessage,
             @ErSeverity,
             @ErState )
ROLLBACK TRAN
END CATCH
GO