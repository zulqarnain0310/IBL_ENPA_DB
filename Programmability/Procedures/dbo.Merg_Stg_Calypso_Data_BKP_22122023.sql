SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO



create PROC [dbo].[Merg_Stg_Calypso_Data_BKP_22122023]
WITH RECOMPILE
AS
DECLARE @TimeKey Smallint=(SELECT TimeKey FROM SysDatamatrix WHERE CurrentStatus='C')
DECLARE @Exec_Date DATE=(SELECT DATE FROM SysDataMatrix WHERE CurrentStatus='C' )
DECLARE @MAX_AccountEntityID INT=(SELECT ISNULL(MAX(AccountEntityID),0) FROM NPA_IntegrationDetails)
DECLARE @SrcSysAlt_Key Smallint=(SELECT SourceAlt_Key FROM [dbo].[DimSourceSystem] WHERE SourceName='Calypso' AND  EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
DECLARE @MonthEndDate DATE=(SELECT EOMONTH(DATEADD(MONTH,-1,@Exec_Date)))
DECLARE @MonthEndTimekey Smallint=(SELECT TimeKey FROM SysDataMatrix WHERE CAST(DATE AS DATE)=@MonthEndDate)

DECLARE @Daily_COUNT INT=(SELECT COUNT(1) FROM IBL_ENPA_STGDB.dbo.Calypso_Stg_Daily_Error)
DECLARE @Incremental_COUNT INT=(SELECT COUNT(1) FROM IBL_ENPA_STGDB.dbo.Calypso_Stg_Incremental_Error)
DECLARE @Error_Str VARCHAR(100)= 'Data is not Available for '+CAST(@Exec_Date AS VARCHAR(10))
DECLARE @DataProcessingFlg VARCHAR(1)

SELECT @DataProcessingFlg=(CASE WHEN @Incremental_COUNT>0 OR @Daily_COUNT>0 
                                   OR  (SELECT ISNULL(COUNT(1),0) FROM IBL_ENPA_STGDB.DBO.Calypso_Stg_Daily WHERE AsOnDate=@Exec_Date)=0
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
SELECT @Exec_Date,'Calypso',@DATEDATAUSE
END

--Audit 
DELETE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] 
WHERE [SP_Name]='Merg_Stg_Calypso_Data' AND [EXT_DATE]=GETDATE() AND ISNULL([Audit_Flg],0)=0

INSERT INTO IBL_ENPA_STGDB.[dbo].[Procedure_Audit]
           ([EXT_DATE] ,[Timekey] ,[SP_Name],Start_Date_Time )
SELECT @Exec_Date,@TimeKey,'Merg_Stg_Calypso_Data',GETDATE()

BEGIN TRY

BEGIN TRAN
--Update previous date timekey as processing date timekey
/*UPDATE NPA_IntegrationDetails SET EffectiveFromTimeKey=@TimeKey,
                                  EffectiveToTimeKey=@TimeKey
WHERE EffectiveFromTimeKey<=@TimeKey-1
  AND EffectiveToTimeKey>=@TimeKey-1
  AND SrcSysAlt_Key=@SrcSysAlt_Key

--Update DPD according to day increment
UPDATE NPA_IntegrationDetails 
SET [DPD_Interest_Not_Serviced]=CASE WHEN [DPD_Interest_Not_Serviced]>0 THEN [DPD_Interest_Not_Serviced]+1 ELSE NULL END
   ,[DPD_Overdrawn]=CASE WHEN [DPD_Overdrawn]>0 THEN [DPD_Overdrawn]+1 ELSE NULL END
   ,[DPD_Renewals]=CASE WHEN ReviewDueDt IS NOT NULL AND ReviewDueDt<=@Exec_Date  THEN DATEDIFF(DAY,ReviewDueDt,@Exec_Date)+1 ELSE NULL END
   ,[DPD_Overdue_Loans]=CASE WHEN [DPD_Overdue_Loans]>0 THEN [DPD_Overdue_Loans]+1 ELSE NULL END
--Processing Columns
   ,[NCIF_Changed]=NULL
   ,[MaxDPD_Type]=NULL
   ,[PNPA_Status]=NULL
   ,[PNPA_ReasonAlt_Key]=NULL
   ,[PNPA_Date]=NULL
   ,[NF_PNPA_Date]=NULL
   ,NCIF_AssetClassAlt_Key=NULL
   ,NCIF_NPA_Date=NULL
   ,SecuredAmt=NULL
   ,UnSecuredAmt=NULL
   ,TotalProvision=NULL
   ,Provsecured=NULL
   ,ProvUnsecured=NULL
   ,AddlProvision=NULL
   ,AddlProvisionPer=NULL
   ,FlgDeg=NULL
   ,FlgUpg=NULL
   ,LossDT=NULL
   ,DbtDT=NULL
   ,ErosionDT=NULL
   ,ProvisionAlt_Key=NULL
   ,DegReason=NULL
   ,FlgErosion=NULL
   ,UpgDate=NULL
WHERE EffectiveFromTimeKey<=@TimeKey
AND   EffectiveToTimeKey>=@TimeKey
AND   SrcSysAlt_Key=@SrcSysAlt_Key*/



IF(@DataProcessingFlg=1)
BEGIN

---------------------Added on 14082021 for CustomerId Update

UPDATE A SET CustomerId=B.RefCustomerID
FROM NPA_IntegrationDetails A
INNER JOIN IBL_ENPA_STGDB.dbo.Calypso_Stg_Incremental B ON A.EffectiveFromTimeKey<=@TimeKey
                                                 AND A.EffectiveToTimeKey>=@TimeKey
												 AND B.AsONDATE=@Exec_Date
												 --AND A.NCIF_Id=B.UCIF_ID --- commented on 12/09/2021
												 AND A.CustomerACID=B.CustomerAcID
WHERE ISNULL(B.SRC_CIF_UPDATED,'N')='Y'
AND SrcSysAlt_Key=@SrcSysAlt_Key
--------------------

UPDATE A SET NCIF_Id=B.UCIF_ID
FROM NPA_IntegrationDetails A
INNER JOIN IBL_ENPA_STGDB.dbo.Calypso_Stg_Daily B ON A.EffectiveFromTimeKey<=@TimeKey
                                                 AND A.EffectiveToTimeKey>=@TimeKey
												 AND B.AsONDATE=@Exec_Date
												 AND A.CustomerID=B.RefCustomerID
												 AND A.CustomerACID=B.CustomerAcID
WHERE ISNULL(A.NCIF_Id,'')<>ISNULL(B.UCIF_ID,'')
AND SrcSysAlt_Key=@SrcSysAlt_Key




-----------------------


--Updating Existing Records
UPDATE NPA SET 
NPA.Balance= ISNULL(PSD.BALANCE,0) ,
NPA.PrincipleOutstanding= ISNULL(PSD.PrincOutStd,0),
NPA.Overdue=(ISNULL(PSD.IntOverdue,0)+ISNULL(PSD.OtherOverdue,0)+ISNULL(PSD.PrincOverdue,0)),
NPA.IntAccrued=ISNULL(PSD.IntAccrued,0),
NPA.IntOverdue=ISNULL(PSD.IntOverdue,0),
NPA.OtherOverdue=ISNULL(PSD.OtherOverdue ,0),
NPA.PrincOverdue=ISNULL(PSD.PrincOverdue,0),
NPA.NCIF_Id=ISNULL(PSD.UCIF_ID,''),
NPA.ModifiedBy='SSIS USER',
NPA.DateModified=GETDATE()

FROM NPA_IntegrationDetails NPA
INNER JOIN IBL_ENPA_STGDB.dbo.Calypso_Stg_Daily PSD ON NPA.SrcSysAlt_Key=@SrcSysAlt_Key
                                                  AND NPA.EffectiveFromTimeKey<=@TimeKey
                                                  AND NPA.EffectiveToTimeKey>=@TimeKey
												  AND ISNULL(NPA.NCIF_Id,'')=ISNULL(PSD.UCIF_ID,'')
												  AND NPA.CustomerId=PSD.RefCustomerID
												  AND NPA.CustomerACID=PSD.CustomerAcID
WHERE (ISNULL(NPA.Balance,0) <> ISNULL(PSD.BALANCE,0) 
   OR ISNULL(NPA.PrincipleOutstanding,0) <> ISNULL(PSD.PrincOutStd,0)
   OR ISNULL(NPA.Overdue,0)<>(ISNULL(PSD.IntOverdue,0)+ISNULL(PSD.OtherOverdue,0)+ISNULL(PSD.PrincOverdue,0))
   OR ISNULL(NPA.IntAccrued,0)<>ISNULL(PSD.IntAccrued,0)
   OR ISNULL(NPA.IntOverdue,0)<>ISNULL(PSD.IntOverdue,0)
   OR ISNULL(NPA.OtherOverdue ,0)<>ISNULL(PSD.OtherOverdue ,0)
   OR ISNULL(NPA.PrincOverdue,0)<>ISNULL(PSD.PrincOverdue,0)
   OR ISNULL(NPA.NCIF_Id,'')<>ISNULL(PSD.UCIF_ID,''))
AND PSD.AsOnDate=@Exec_Date

--Inserting New Records
INSERT INTO  NPA_IntegrationDetails (NCIF_Id,
                                     CustomerId,
                                     CustomerACID,
			                         NCIF_EntityID,
			                         AccountEntityID,
			                         Balance, 
			                         PrincipleOutstanding,
			                         Overdue,
			                         IntAccrued,
			                         IntOverdue,
			                         OtherOverdue,
			                         PrincOverdue,
			                         SrcSysAlt_Key,
			                         EffectiveFromTimeKey,
			                         EffectiveToTimeKey,
									 CreatedBy,
									 DateCreated) 
SELECT PSD.UCIF_ID, 
	   PSD.RefCustomerID, 
	   PSD.CustomerAcID,
	   1,
	   ROW_NUMBER() OVER(ORDER BY PSD.CustomerACID)+@MAX_AccountEntityID,
	   ISNULL(PSD.BALANCE,0),
	   ISNULL(PSD.PrincOutStd,0),
	   (ISNULL(PSD.IntOverdue,0)+ISNULL(PSD.OtherOverdue,0)+ISNULL(PSD.PrincOverdue,0)),
	   ISNULL(PSD.IntAccrued,0),
	   ISNULL(PSD.IntOverdue,0),
	   ISNULL(PSD.OtherOverdue,0),
	   ISNULL(PSD.PrincOverdue,0),
	   @SrcSysAlt_Key,
	   @TimeKey,
	   @TimeKey,
	   'SSIS USER',
	   GETDATE()
FROM  IBL_ENPA_STGDB.dbo.Calypso_Stg_Daily PSD 
LEFT JOIN NPA_IntegrationDetails NPA ON ISNULL(PSD.UCIF_ID,'')= ISNULL(NPA.NCIF_Id,'')
                                    AND NPA.EffectiveFromTimeKey<=@TimeKey
                                    AND NPA.EffectiveToTimeKey>=@TimeKey
							        AND PSD.RefCustomerID=NPA.CustomerId
								    AND PSD.CustomerAcID=NPA.CustomerACID
									AND NPA.SrcSysAlt_Key=@SrcSysAlt_Key
WHERE PSD.AsOnDate=@Exec_Date
AND NPA.CustomerACID IS NULL

INSERT INTO Closed_Account_Details(ASONDATE,SrcSysAlt_Key,NCIF_ID,CustomerId,CustomerACID,CustomerName,AC_Closed_Date)
SELECT PSD.AsOnDate,@SrcSysAlt_Key,NPA.NCIF_Id,NPA.CustomerId,NPA.CustomerACID,NPA.CustomerName,PSD.CLOSED_DATE
FROM NPA_IntegrationDetails NPA
INNER JOIN IBL_ENPA_STGDB.dbo.Calypso_Stg_Incremental PSD ON NPA.SrcSysAlt_Key=@SrcSysAlt_Key
                                                        AND EffectiveFromTimeKey<=@TimeKey
                                                        AND EffectiveToTimeKey>=@TimeKey
                                                        AND ISNULL(NPA.NCIF_Id,'')=ISNULL(PSD.UCIF_ID,'')
												        AND NPA.CustomerId=PSD.RefCustomerID
												        AND NPA.CustomerACID=PSD.CustomerAcID
WHERE PSD.CLOSED_DATE IS NOT NULL
AND PSD.AsOnDate=@Exec_Date

DELETE NPA
FROM NPA_IntegrationDetails NPA
INNER JOIN IBL_ENPA_STGDB.dbo.Calypso_Stg_Incremental PSD ON NPA.SrcSysAlt_Key=@SrcSysAlt_Key
                                                        AND EffectiveFromTimeKey<=@TimeKey
                                                        AND EffectiveToTimeKey>=@TimeKey
                                                        AND ISNULL(NPA.NCIF_Id,'')=ISNULL(PSD.UCIF_ID,'')
												        AND NPA.CustomerId=PSD.RefCustomerID
												        AND NPA.CustomerACID=PSD.CustomerAcID
WHERE PSD.CLOSED_DATE IS NOT NULL
AND PSD.AsOnDate=@Exec_Date

--Updating data From incremental table
UPDATE NI
SET [CustomerName]=FI.CustName,
    NCIF_Id=COALESCE(FI.UCIF_ID,FI.PAN,'CLYPS_'+FI.RefCustomerID),
    [PAN]=FI.PAN,
    [SanctionedLimit] =FI.SancLimit,
    [Segment] =FI.ActSegmentCode,
	[ProductCode]=FI.ProductCode,
	[ProductDesc] =FI.ProductName,
	[AC_AssetClassAlt_Key] =DAC.AssetClassAlt_Key,
	[AC_NPA_Date]=SrcNpaDt,
	[WriteOffDate]=FI.TWO_Date,
	[IsRestructured] =ISNULL(FI.IsRestructured,'N'),
	IsOTS=ISNULL(FI.IsOTS,'N'),
	IsTWO =ISNULL(FI.IsTWO,'N'),
	IsARC_Sale=ISNULL(FI.IsARC_Sale,'N'),
	IsFraud =ISNULL(FI.IsFraud,'N'),
	IsWiful =ISNULL(FI.IsWiful,'N'),
	IsNonCooperative =ISNULL(FI.IsNonCooperative,'N'),
	IsSuitFiled=ISNULL(FI.IsSuitFiled,'N'),
	IsRFA=ISNULL(FI.IsRFA,'N'),
	IsFITL=ISNULL(FI.IsFITL,'N'),
	IsCentral_GovGty=ISNULL(FI.IsCentral_GovGty,'N'),
	Is_Oth_GovGty=ISNULL(FI.Is_Oth_GovGty,'N'),
	[BranchCode]=FI.BranchCode,
	[FacilityType] =FI.FacilityType,
	SancDate=FI.SancDate,
	Region =FI.Region,
	State =FI.State,
	Zone =SUBSTRING(FI.Zone,1,20),
	NPA_TagDate=FI.NPA_TagDate,
	[PS_NPS]=FI.PS_NPS,
	Retail_Corpo=FI.Retail_Corpo,
	Area=FI.Area,
	FraudAmt=FI.FraudAmt,
	FraudDate=FI.FraudDate,
	[GovtGtyAmt] =FI.GovGtyAmt,
	GtyRepudiated =FI.GtyRepudiated,
	RepudiationDate=FI.RepudiationDate,
	OTS_Amt=FI.OTS_Amt,
	[WriteOffAmount] =FI.TWO_Amt,
	ARC_SaleDate=FI.ARC_SaleDate,
	ARC_SaleAmt=FI.ARC_SaleAmt,
	PrincOverdueSinceDt=FI.PrincOverdueSinceDt,
	IntNotServicedDt=FI.IntNotServicedDt,
	ContiExcessDt=FI.ContiExcessDt,
	ReviewDueDt=FI.ReviewDueDt,
	OtherOverdueSinceDt=FI.OtherOverdueSinceDt,
	IntOverdueSinceDt=FI.IntOverdueSinceDt,
	SecuredFlag =fi.SecuredFlag,	
	[DPD_Interest_Not_Serviced]=CASE WHEN FI.IntNotServicedDt IS NOT NULL THEN DATEDIFF(DAY,FI.IntNotServicedDt,@Exec_Date)+1 END,
	[DPD_Overdrawn]=CASE WHEN FI.ContiExcessDt IS NOT NULL THEN DATEDIFF(DAY,FI.ContiExcessDt,@Exec_Date)+1 END,
	[DPD_Renewals] =CASE WHEN FI.ReviewDueDt IS NOT NULL AND FI.ReviewDueDt<=@Exec_Date THEN DATEDIFF(DAY,FI.ReviewDueDt,@Exec_Date)+1 END,
	[DPD_Overdue_Loans]=CASE WHEN FI.PrincOverdueSinceDt=NULL AND FI.OtherOverdueSinceDt=NULL AND FI.IntOverdueSinceDt=NULL THEN NULL
                        ELSE DATEDIFF(DAY,(CASE WHEN ISNULL(FI.PrincOverdueSinceDt,'2099-01-01') < ISNULL(FI.OtherOverdueSinceDt,'2099-01-01') And ISNULL(FI.PrincOverdueSinceDt,'2099-01-01') < ISNULL(FI.IntOverdueSinceDt,'2099-01-01') Then FI.PrincOverdueSinceDt
                                                WHEN  ISNULL(FI.OtherOverdueSinceDt,'2099-01-01')< ISNULL(FI.PrincOverdueSinceDt,'2099-01-01') And  ISNULL(FI.OtherOverdueSinceDt,'2099-01-01') < ISNULL(FI.IntOverdueSinceDt,'2099-01-01') Then  FI.OtherOverdueSinceDt
                                                ELSE FI.IntOverdueSinceDt END),@Exec_Date)+1 END,
     --WriteOffFlag=CASE WHEN FI.TWO_Date IS NOT NULL THEN 'Y' ELSE 'N' END,
	 WriteOffFlag=ISNULL(FI.IsTWO,'N'),
	 AC_Closed_Date=[FI].CLOSED_DATE,
	--Processing Columns
	[NCIF_Changed]=NULL,
	[MaxDPD_Type]=NULL,
	[PNPA_Status]=NULL,	
	[PNPA_ReasonAlt_Key]=NULL,
	[PNPA_Date]=NULL,
	[NF_PNPA_Date]=NULL,
	IsFunded=ISNULL(FI.Funded_NonFunded_Flag,'Y'),
	ModifiedBy='SSIS USER',
	DateModified=GETDATE(),
	DCCO_Date=FI.DCCO_Date,
	PROJ_COMPLETION_DATE=FI.PROJ_COMPLETION_DATE,
	OPEN_DATE=FI.OPEN_DATE
FROM NPA_IntegrationDetails NI
INNER JOIN IBL_ENPA_STGDB.dbo.Calypso_Stg_Incremental  FI ON EffectiveFromTimeKey<=@TimeKey
													    AND EffectiveToTimeKey>=@TimeKey
                                                        AND ISNULL(NI.NCIF_Id,'')=ISNULL(FI.UCIF_ID,'')
												        AND NI.CustomerId=FI.RefCustomerID
												        AND NI.CustomerACID=FI.CustomerAcID
                                                        AND NI.SrcSysAlt_Key=@SrcSysAlt_Key
													    AND FI.AsOnDate=@Exec_Date
LEFT JOIN DimAssetClass DAC ON FI.SrcAssetClass=DAC.CalypsoAssetClassCode
                           AND DAC.EffectiveFromTimeKey<=@TimeKey
						   AND DAC.EffectiveToTimeKey>=@TimeKey


UPDATE NPA_IntegrationDetails 
SET PrincipleOutstanding=0,UNSERVED_INTEREST=0 ,Balance=0,IntOverdue=0 ------ Added on 16-06-2021 for Balance,IntOverdue by sunil
WHERE EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey
AND SrcSysAlt_Key=@SrcSysAlt_Key
AND IsTWO='Y'

Update NPA_IntegrationDetails set DPD_Renewals=NULL
where DPD_Renewals<0 
AND  EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey
AND SrcSysAlt_Key=@SrcSysAlt_Key



UPDATE WO
SET EffectiveToTimeKey=@TimeKey-1,
	ModifiedBy='SSIS USER',
	DateModified=GETDATE()
FROM [CURDAT].[AdvAcWODetail] WO
INNER JOIN NPA_IntegrationDetails NI ON WO.EffectiveFromTimeKey<=@TimeKey
						            AND WO.EffectiveToTimeKey>=@TimeKey
									AND NI.EffectiveFromTimeKey<=@TimeKey
									AND NI.EffectiveToTimeKey>=@TimeKey
									AND Wo.CustomerID=NI.CustomerId
									AND WO.CustomerACID=NI.CustomerACID
WHERE NI.IsTWO='Y'
AND NI.SrcSysAlt_Key=@SrcSysAlt_Key     ------Added on 19-07-2021
AND ([WriteOffDt]<>NI.WriteOffDate
 OR [WriteOffAmt] <>NI.WriteOffAmount)

INSERT INTO [CURDAT].[AdvAcWODetail](
[EffectiveFromTimeKey],
[EffectiveToTimeKey],
Customer_CIF,
[CustomerID],
[CustomerACID],
[WriteOffDt],
[WO_PWO],
[WriteOffAmt],
CreatedBy,
DateCreated)
SELECT @TimeKey,
       99999,
	   NI.NCIF_Id,
	   NI.CustomerId,
	   NI.CustomerACID,
	   NI.WriteOffDate,
	   'TWO',
	   NI.WriteOffAmount,
	   'SSIS USER',
	   GETDATE()
FROM NPA_IntegrationDetails NI
LEFT JOIN [CURDAT].[AdvAcWODetail] WO  ON WO.EffectiveFromTimeKey<=@TimeKey
						             AND WO.EffectiveToTimeKey>=@TimeKey
									 AND Wo.CustomerID=NI.CustomerId
									 AND WO.CustomerACID=NI.CustomerACID
WHERE NI.IsTWO='Y'
AND (WO.CustomerACID IS NULL
 OR ([WriteOffDt]<>NI.WriteOffDate
 OR [WriteOffAmt] <>NI.WriteOffAmount))
AND NI.EffectiveFromTimeKey<=@TimeKey
AND NI.EffectiveToTimeKey>=@TimeKey
AND NI.SrcSysAlt_Key=@SrcSysAlt_Key 

END

UPDATE NPA_IntegrationDetails SET MaxDPD=(SELECT Max(v) FROM (VALUES ([DPD_Interest_Not_Serviced]),
                                    ([DPD_Overdrawn]), 
                                    (CASE WHEN [DPD_Renewals]-90<0 THEN 0 ELSE [DPD_Renewals]-90 END ),
									([DPD_Overdue_Loans])) AS value(v))
WHERE EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey


IF((SELECT COUNT(DISTINCT AsOnDate) FROM IBL_ENPA_STGDB.dbo.Calypso_Stg_Daily)=2
AND EXISTS(SELECT 1 FROM IBL_ENPA_STGDB.dbo.Calypso_Stg_Daily WHERE ASonDate=@MonthEndDate)
AND (SELECT ISNULL(MOC_Initialised,'N') FROM SysDataMatrix WHERE Date=@MonthEndDate)='N')
BEGIN

UPDATE NPA SET 
NPA.Balance= ISNULL(PSD.BALANCE,0) ,
NPA.PrincipleOutstanding= ISNULL(PSD.PrincOutStd,0),
NPA.Overdue=(ISNULL(PSD.IntOverdue,0)+ISNULL(PSD.OtherOverdue,0)+ISNULL(PSD.PrincOverdue,0)),
NPA.IntAccrued=ISNULL(PSD.IntAccrued,0),
NPA.IntOverdue=ISNULL(PSD.IntOverdue,0),
NPA.OtherOverdue=ISNULL(PSD.OtherOverdue ,0),
NPA.PrincOverdue=ISNULL(PSD.PrincOverdue,0),
NPA.NCIF_Id=ISNULL(PSD.UCIF_ID,''),
NPA.ModifiedBy='SSIS USER',
NPA.DateModified=GETDATE()
FROM NPA_IntegrationDetails NPA
INNER JOIN IBL_ENPA_STGDB.dbo.Calypso_Stg_Daily PSD ON NPA.SrcSysAlt_Key=@SrcSysAlt_Key
                                                  AND NPA.EffectiveFromTimeKey<=@MonthEndTimekey
                                                  AND NPA.EffectiveToTimeKey>=@MonthEndTimekey
												  AND NPA.NCIF_Id=PSD.UCIF_ID
												  AND NPA.CustomerId=PSD.RefCustomerID
												  AND NPA.CustomerACID=PSD.CustomerAcID
WHERE (ISNULL(NPA.Balance,0) <> ISNULL(PSD.BALANCE,0) 
   OR ISNULL(NPA.PrincipleOutstanding,0) <> ISNULL(PSD.PrincOutStd,0)
   OR ISNULL(NPA.Overdue,0)<>(ISNULL(PSD.IntOverdue,0)+ISNULL(PSD.OtherOverdue,0)+ISNULL(PSD.PrincOverdue,0))
   OR ISNULL(NPA.IntAccrued,0)<>ISNULL(PSD.IntAccrued,0)
   OR ISNULL(NPA.IntOverdue,0)<>ISNULL(PSD.IntOverdue,0)
   OR ISNULL(NPA.OtherOverdue ,0)<>ISNULL(PSD.OtherOverdue ,0)
   OR ISNULL(NPA.PrincOverdue,0)<>ISNULL(PSD.PrincOverdue,0)
   OR ISNULL(NPA.NCIF_Id,'')<>ISNULL(PSD.UCIF_ID,''))
AND PSD.AsOnDate=@MonthEndDate

END
													 
--UPDATE Audit Flag
UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET End_Date_Time=GETDATE(),[Audit_Flg]=1 
WHERE [SP_Name]='Merg_Stg_Calypso_Data' AND [EXT_DATE]=@Exec_Date AND ISNULL([Audit_Flg],0)=0

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
WHERE [SP_Name]='Merg_Stg_Calypso_Data' AND [EXT_DATE]=@Exec_Date AND ISNULL([Audit_Flg],0)=0
 
 RAISERROR (@ErMessage,
             @ErSeverity,
             @ErState )
ROLLBACK TRAN
END CATCH

GO