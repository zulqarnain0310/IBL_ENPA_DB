SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO




create PROC [dbo].[Merg_Stg_PTSmart_Data_BKP_22122023]
WITH RECOMPILE
AS
DECLARE @TimeKey Smallint=(SELECT TimeKey FROM SysDatamatrix WHERE CurrentStatus='C')
DECLARE @Exec_Date DATE=(SELECT DATE FROM SysDataMatrix WHERE CurrentStatus='C' )
DECLARE @MAX_AccountEntityID INT=(SELECT ISNULL(MAX(AccountEntityID),0) FROM NPA_IntegrationDetails)
DECLARE @SrcSysAlt_Key Smallint=(SELECT SourceAlt_Key FROM [dbo].[DimSourceSystem] WHERE SourceName='PT Smart' AND  EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
DECLARE @MonthEndDate DATE=(SELECT EOMONTH(DATEADD(MONTH,-1,@Exec_Date)))
DECLARE @MonthEndTimekey Smallint=(SELECT TimeKey FROM SysDataMatrix WHERE CAST(DATE AS DATE)=@MonthEndDate)
DECLARE @PrevMonthEndDate DATE=(SELECT EOMONTH(DATEADD(MONTH,-1,@Exec_Date)))--ADDED ON UAT 20230612 DEPLOYED ON 20230707 FOR STD PROVISION
DECLARE @PrevMonthEndTimekey Smallint=(SELECT TimeKey FROM SysDataMatrix WHERE CAST(DATE AS DATE)=@PrevMonthEndDate)--ADDED ON UAT 20230612 DEPLOYED ON 20230707 FOR STD PROVISION
DECLARE @PrevMoc_Freeze varchar(5)=(SELECT MOC_Freeze FROM SysDataMatrix WHERE TimeKey=@PrevMonthEndTimekey)--ADDED ON UAT 20230612 DEPLOYED ON 20230707 FOR STD PROVISION


DECLARE @Daily_COUNT INT=(SELECT COUNT(1) FROM IBL_ENPA_STGDB.dbo.PTSmart_Stg_Daily_Error)
DECLARE @Incremental_COUNT INT=(SELECT COUNT(1) FROM IBL_ENPA_STGDB.dbo.PTSmart_Stg_Incremental_Error)
DECLARE @Security_COUNT INT=(SELECT COUNT(1) FROM IBL_ENPA_STGDB.dbo.PTSmart_Stg_Security_Error)
DECLARE @Restructure_COUNT INT=(SELECT COUNT(1) FROM IBL_ENPA_STGDB.dbo.PTSmart_Stg_Restructure_Error)
DECLARE @Error_Str VARCHAR(100)= 'Data is not Available for '+CAST(@Exec_Date AS VARCHAR(10))
DECLARE @DataProcessingFlg VARCHAR(1)


SELECT @DataProcessingFlg=(CASE WHEN @Incremental_COUNT>0 OR @Daily_COUNT>0 OR @Security_COUNT>0  OR @Restructure_COUNT>0
                                   OR  (SELECT ISNULL(COUNT(1),0) FROM IBL_ENPA_STGDB.DBO.PTSmart_Stg_Daily WHERE AsOnDate=@Exec_Date)=0
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
SELECT @Exec_Date,'PTSmart',@DATEDATAUSE
END

--Audit 
DELETE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] 
WHERE [SP_Name]='Merg_Stg_PTSmart_Data' AND [EXT_DATE]=GETDATE() AND ISNULL([Audit_Flg],0)=0

INSERT INTO IBL_ENPA_STGDB.[dbo].[Procedure_Audit]
           ([EXT_DATE] ,[Timekey] ,[SP_Name],Start_Date_Time )
SELECT @Exec_Date,@TimeKey,'Merg_Stg_PTSmart_Data',GETDATE()


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
   ,ProvisionAlt_Key=NULL
   ,DegReason=NULL
   ,FlgErosion=NULL
   ,UpgDate=NULL
   ,ErosionDT=NULL
WHERE EffectiveFromTimeKey<=@TimeKey
AND   EffectiveToTimeKey>=@TimeKey
AND   SrcSysAlt_Key=@SrcSysAlt_Key*/

IF(@DataProcessingFlg=1)
BEGIN

UPDATE A SET CustomerId=B.RefCustomerID
FROM NPA_IntegrationDetails A
INNER JOIN IBL_ENPA_STGDB.dbo.PTSmart_Stg_Incremental B ON A.EffectiveFromTimeKey<=@TimeKey
                                                 AND A.EffectiveToTimeKey>=@TimeKey
												 AND B.AsONDATE=@Exec_Date
												 --AND A.NCIF_Id=B.UCIF_ID --- commented on 12/09/2021
												 AND A.CustomerACID=B.CustomerAcID
WHERE ISNULL(B.SRC_CIF_UPDATED,'N')='Y'
AND SrcSysAlt_Key=@SrcSysAlt_Key

UPDATE A SET NCIF_Id=B.UCIF_ID
FROM NPA_IntegrationDetails A
INNER JOIN IBL_ENPA_STGDB.dbo.PTSmart_Stg_Daily B ON A.EffectiveFromTimeKey<=@TimeKey
                                                 AND A.EffectiveToTimeKey>=@TimeKey
												 AND B.AsONDATE=@Exec_Date
												 AND A.CustomerID=B.RefCustomerID
												 AND A.CustomerACID=B.CustomerAcID
WHERE ISNULL(A.NCIF_Id,'')<>ISNULL(B.UCIF_ID,'')
AND SrcSysAlt_Key=@SrcSysAlt_Key


UPDATE C SET RefCustomer_CIF=B.UCIF_ID
FROM NPA_IntegrationDetails A
INNER JOIN IBL_ENPA_STGDB.dbo.PTSmart_Stg_Daily B ON A.EffectiveFromTimeKey<=@TimeKey
                                                 AND A.EffectiveToTimeKey>=@TimeKey
												 AND B.AsONDATE=@Exec_Date
												 AND A.CustomerID=B.RefCustomerID
												 AND A.CustomerACID=B.CustomerAcID
INNER JOIN  CURDAT.AdvSecurityDetail C ON C.EffectiveFromTimeKey<=@TimeKey-1
                                      AND C.EffectiveToTimeKey>=@TimeKey-1
							          AND A.CustomerID=C.RefCustomerID
									  AND A.CustomerACID=C.RefSystemAcId 
									  AND A.SrcSysAlt_Key=C.SrcSystemAlt_Key
WHERE ISNULL(A.NCIF_Id,'')<>ISNULL(B.UCIF_ID,'')
AND SrcSysAlt_Key=@SrcSysAlt_Key

UPDATE C SET RefCustomer_CIF=B.UCIF_ID
FROM NPA_IntegrationDetails A
INNER JOIN IBL_ENPA_STGDB.dbo.PTSmart_Stg_Daily B ON A.EffectiveFromTimeKey<=@TimeKey
                                                 AND A.EffectiveToTimeKey>=@TimeKey
												 AND B.AsONDATE=@Exec_Date
												 AND A.CustomerID=B.RefCustomerID
												 AND A.CustomerACID=B.CustomerAcID
INNER JOIN  CURDAT.AdvAcRestructureDetail C ON C.EffectiveFromTimeKey<=@TimeKey-1
                                           AND C.EffectiveToTimeKey>=@TimeKey-1
							               AND A.CustomerID=C.RefCustomerID
									       AND A.CustomerACID=C.RefSystemAcId 
										   AND A.SrcSysAlt_Key=C.SrcSysAlt_Key
WHERE ISNULL(A.NCIF_Id,'')<>ISNULL(B.UCIF_ID,'')
AND A.SrcSysAlt_Key=@SrcSysAlt_Key

UPDATE A SET CustomerId=B.RefCustomerID
FROM NPA_IntegrationDetails A
INNER JOIN IBL_ENPA_STGDB.dbo.PTSmart_Stg_Incremental B ON A.EffectiveFromTimeKey<=@TimeKey
                                                 AND A.EffectiveToTimeKey>=@TimeKey
												 AND B.AsONDATE=@Exec_Date
												 AND A.NCIF_Id=B.UCIF_ID
												 AND A.CustomerACID=B.CustomerAcID
WHERE ISNULL(B.SRC_CIF_UPDATED,'N')='Y'
AND SrcSysAlt_Key=@SrcSysAlt_Key

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
ModifiedBy='SSIS USER',
DateModified=GETDATE()
FROM NPA_IntegrationDetails NPA
INNER JOIN IBL_ENPA_STGDB.dbo.PTSmart_Stg_Daily PSD ON NPA.SrcSysAlt_Key=@SrcSysAlt_Key
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
FROM  IBL_ENPA_STGDB.dbo.PTSmart_Stg_Daily PSD 
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
INNER JOIN IBL_ENPA_STGDB.dbo.PTSmart_Stg_Incremental PSD ON NPA.SrcSysAlt_Key=@SrcSysAlt_Key
                                                        AND EffectiveFromTimeKey<=@TimeKey
                                                        AND EffectiveToTimeKey>=@TimeKey
                                                        AND ISNULL(NPA.NCIF_Id,'')=ISNULL(PSD.UCIF_ID,'')
												        AND NPA.CustomerId=PSD.RefCustomerID
												        AND NPA.CustomerACID=PSD.CustomerAcID
WHERE PSD.CLOSED_DATE IS NOT NULL
AND PSD.AsOnDate=@Exec_Date

DELETE NPA
FROM NPA_IntegrationDetails NPA
INNER JOIN IBL_ENPA_STGDB.dbo.PTSmart_Stg_Incremental PSD ON NPA.SrcSysAlt_Key=@SrcSysAlt_Key
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
    NCIF_Id=COALESCE(FI.UCIF_ID,FI.PAN,'PS_'+FI.RefCustomerID),
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
	Zone =FI.Zone,
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
      --WriteOffFlag=CASE WHEN FI.TWO_Date IS NOT NULL THEN 'Y' ELSE 'N' END,   -------commeneted by sunil 16-06-2021
	 WriteOffFlag=ISNULL(FI.IsTWO,'N'),
	 AC_Closed_Date=[FI].CLOSED_DATE,
	--Processing Columns
	[NCIF_Changed]=NULL,
	[MaxDPD_Type]=NULL,
	[PNPA_Status]=NULL,	
	[PNPA_ReasonAlt_Key]=NULL,
	[PNPA_Date]=NULL,
	[NF_PNPA_Date]=NULL,
	IsFunded=isnull(FI.Funded_NonFunded_Flag,'Y'),
	ModifiedBy='SSIS USER',
	DateModified=GETDATE(),
	DCCO_Date=FI.DCCO_Date,
	PROJ_COMPLETION_DATE=FI.PROJ_COMPLETION_DATE,
	OPEN_DATE=FI.OPEN_DATE
FROM NPA_IntegrationDetails NI
INNER JOIN IBL_ENPA_STGDB.dbo.PTSmart_Stg_Incremental  FI ON EffectiveFromTimeKey<=@TimeKey
													    AND EffectiveToTimeKey>=@TimeKey
                                                        AND ISNULL(NI.NCIF_Id,'')=ISNULL(FI.UCIF_ID,'')
												        AND NI.CustomerId=FI.RefCustomerID
												        AND NI.CustomerACID=FI.CustomerAcID
                                                        AND NI.SrcSysAlt_Key=@SrcSysAlt_Key
													    AND FI.AsOnDate=@Exec_Date
LEFT JOIN DimAssetClass DAC ON FI.SrcAssetClass=DAC.PTSmartAssetClassCode
                           AND DAC.EffectiveFromTimeKey<=@TimeKey
						   AND DAC.EffectiveToTimeKey>=@TimeKey


UPDATE NPA_IntegrationDetails 
SET PrincipleOutstanding=0,UNSERVED_INTEREST=0 ,Balance=0,IntOverdue=0    ------ Added on 16-06-2021 for Balance,IntOverdue by sunil
WHERE EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey
AND SrcSysAlt_Key=@SrcSysAlt_Key
AND IsTWO='Y'


Update NPA_IntegrationDetails set DPD_Renewals=NULL 
where DPD_Renewals<0  
AND  EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey 
AND SrcSysAlt_Key=@SrcSysAlt_Key-----Added on 16-06-2021


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


--AdvSecurityValueDetail AND AdvSecurityDetail Merging Start
--DECLARE @TimeKey int=(SELECT Timekey FROM SysDataMatrix WHERE ProcessingStatus='C')
DECLARE @EXT_DT DATE=(SELECT DATE FROM SysDataMatrix WHERE CurrentStatus='C')
--DECLARE @SrcSysAlt_Key Smallint=(SELECT SourceAlt_Key FROM [dbo].[DimSourceSystem] WHERE SourceName='PTSmart' AND  EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
DECLARE @MaxSecID int=ISNULL((SELECT MAX(SecurityEntityID) FROM IBL_ENPA_DB_LOCAL_DEV.[CURDAT].AdvSecurityDetail),0) 
DECLARE @SECURITY int=(SELECT isnull(COUNT(1),0) FROM CURDAT.AdvSecurityValueDetail)

/*
UPDATE IBL_ENPA_DB_LOCAL_DEV.[CURDAT].AdvSecurityDetail
SET EffectiveFromTimeKey=@TimeKey,
    EffectiveToTimeKey=@TimeKey
WHERE EffectiveFromTimeKey<=@TimeKey-1
  AND EffectiveToTimeKey>=@TimeKey-1
  AND SrcSystemAlt_Key=@SrcSysAlt_Key

UPDATE IBL_ENPA_DB_LOCAL_DEV.[CURDAT].AdvSecurityValueDetail
SET EffectiveFromTimeKey=@TimeKey,
    EffectiveToTimeKey=@TimeKey
FROM IBL_ENPA_DB_LOCAL_DEV.[CURDAT].AdvSecurityValueDetail  A
INNER JOIN IBL_ENPA_DB_LOCAL_DEV.[CURDAT].AdvSecurityDetail B ON   
    A.EffectiveFromTimeKey<=@TimeKey-1
AND A.EffectiveToTimeKey>=@TimeKey-1
AND B.EffectiveFromTimeKey<=@TimeKey
AND B.EffectiveToTimeKey>=@TimeKey
AND B.SrcSystemAlt_Key=@SrcSysAlt_Key*/
/*
--DELETE RECORDS FROM SECURITY TABLES WHICH ARE NOT IN STG TABLES
IF OBJECT_ID('TEMPDB..#ENTITYID') IS NOT NULL
DROP TABLE #ENTITYID 

SELECT ASD.SecurityEntityID
INTO #ENTITYID 
FROM IBL_ENPA_DB_LOCAL_DEV.dbo.AdvSecurityDetail ASD 
LEFT JOIN IBL_ENPA_STGDB.dbo.PTSmart_Stg_Security SEC  ON  SEC.COLL_ID=ASD.CollateralID
                                                      AND SEC.ACC_NO=ASD.RefSystemAcId
WHERE ASD.EffectiveFromTimeKey<=@TimeKey
AND ASD.EffectiveToTimeKey>=@TimeKey
AND SEC.AS_ON_DATE=@EXT_DT
AND ASD.SrcSystemAlt_Key=@SrcSysAlt_Key
AND SEC.COLL_ID IS NULL
GROUP BY ASD.SecurityEntityID

DELETE IBL_ENPA_DB_LOCAL_DEV.dbo.AdvSecurityValueDetail 
WHERE EXISTS(SELECT 1 FROM #ENTITYID B WHERE AdvSecurityValueDetail.SecurityEntityID=B.SecurityEntityID)

DELETE IBL_ENPA_DB_LOCAL_DEV.dbo.AdvSecurityDetail 
WHERE EXISTS(SELECT 1 FROM #ENTITYID B WHERE AdvSecurityDetail.SecurityEntityID=B.SecurityEntityID)*/

--INSERT NEW RECORDS IN AdvSecurityDetail TABLE
--How to remove coll which has been relesed (Account Closed)
--Waring IF Same coll id having multiple entity id 
IF(@DataProcessingFlg=1)
BEGIN
INSERT INTO IBL_ENPA_DB_LOCAL_DEV.[CURDAT].AdvSecurityDetail
(SecurityEntityID,CollateralType,SrcSystemAlt_Key,RefCustomer_CIF,RefCustomerId,RefSystemAcId,
 CollateralID,EffectiveFromTimeKey,EffectiveToTimeKey,CreatedBy,DateCreated,COLL_DELINK_DATE)
SELECT 0,COLL_TYPE,@SrcSysAlt_Key,ENT_CIF,SRC_CIF,ACC_NO,COLL_ID,@TimeKey,@TimeKey,'SSIS USER',GETDATE(),SEC.COLL_DELINK_DATE
FROM IBL_ENPA_STGDB.dbo.PTSmart_Stg_Security SEC
LEFT JOIN IBL_ENPA_DB_LOCAL_DEV.[CURDAT].AdvSecurityDetail ASD ON  ASD.EffectiveFromTimeKey<=@TimeKey
                                                      AND ASD.EffectiveToTimeKey>=@TimeKey
													  AND SEC.AS_ON_DATE=@EXT_DT
													  AND ASD.SrcSystemAlt_Key=@SrcSysAlt_Key
                                                      AND SEC.COLL_ID=ASD.CollateralID
                                                      AND ISNULL(SEC.ENT_CIF,'')=ISNULL(ASD.RefCustomer_CIF,'')
													  AND SEC.SRC_CIF=ASD.RefCustomerId
													  AND  SEC.ACC_NO=ASD.RefSystemAcId
WHERE ASD.CollateralID IS NULL
GROUP BY COLL_TYPE,ENT_CIF,SRC_CIF,ACC_NO,COLL_ID,SEC.COLL_DELINK_DATE

UPDATE  ASD SET COLL_DELINK_DATE=SEC.COLL_DELINK_DATE
FROM IBL_ENPA_STGDB.dbo.PTSmart_Stg_Security SEC
INNER JOIN IBL_ENPA_DB_LOCAL_DEV.[CURDAT].AdvSecurityDetail ASD ON  ASD.EffectiveFromTimeKey<=@TimeKey
                                                      AND ASD.EffectiveToTimeKey>=@TimeKey
													  AND SEC.AS_ON_DATE=@EXT_DT
													  AND ASD.SrcSystemAlt_Key=@SrcSysAlt_Key
                                                      AND SEC.COLL_ID=ASD.CollateralID
                                                      AND ISNULL(SEC.ENT_CIF,'')=ISNULL(ASD.RefCustomer_CIF,'')
													  AND SEC.SRC_CIF=ASD.RefCustomerId
													  AND  SEC.ACC_NO=ASD.RefSystemAcId
---WHERE ASD.COLL_DELINK_DATE<>SEC.COLL_DELINK_DATE
where  ISNULL(ASD.COLL_DELINK_DATE,'1900-01-01')<>ISNULL(SEC.COLL_DELINK_DATE,'1900-01-01') --05/09/2021


--UPDATE SecurityEntityID 
UPDATE ASD SET SecurityEntityID=B.SecurityEntityID
FROM 
(SELECT CollateralID,ROW_NUMBER() OVER (ORDER BY CollateralID)+@MaxSecID SecurityEntityID
FROM 
(SELECT CollateralID 
FROM  IBL_ENPA_DB_LOCAL_DEV.[CURDAT].AdvSecurityDetail
WHERE EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey
AND SrcSystemAlt_Key=@SrcSysAlt_Key
AND SecurityEntityID=0
GROUP BY CollateralID) A) B
INNER JOIN IBL_ENPA_DB_LOCAL_DEV.[CURDAT].AdvSecurityDetail ASD ON B.CollateralID=ASD.CollateralID

--Updating change recards AdvSecurityValueDetail
UPDATE ASVD SET ValuationDate=SEC.COLL_VAL_DATE
              ,CurrentValue=ISNULL(COLL_AMT,0)
			  ,ValuationExpiryDate=COLL_EXPRY_DATE
			  ,Prev_Value=(CASE WHEN ISNULL(CurrentValue,0)<>ISNULL(COLL_AMT,0) THEN ISNULL(CurrentValue,0) ELSE Prev_Value END)
			  ,Prev_ValuationDate=(CASE WHEN ISNULL(CurrentValue,0)<>ISNULL(COLL_AMT,0) THEN ISNULL(ValuationDate,0) ELSE Prev_ValuationDate END)
			  ,ModifiedBy='SSIS USER'
			  ,DateModified=GETDATE()
FROM IBL_ENPA_STGDB.dbo.PTSmart_Stg_Security SEC
INNER JOIN  IBL_ENPA_DB_LOCAL_DEV.[CURDAT].AdvSecurityDetail ASD ON ASD.EffectiveFromTimeKey<=@TimeKey
                                                       AND ASD.EffectiveToTimeKey>=@TimeKey
                                                       AND SEC.AS_ON_DATE=@EXT_DT
                                                       AND SEC.COLL_ID=ASD.CollateralID
                                                       AND ISNULL(SEC.ENT_CIF,'')=ISNULL(ASD.RefCustomer_CIF,'')
													   AND SEC.SRC_CIF=ASD.RefCustomerId
													   AND SEC.ACC_NO=ASD.RefSystemAcId 
													   AND ASD.SrcSystemAlt_Key=@SrcSysAlt_Key
INNER JOIN  IBL_ENPA_DB_LOCAL_DEV.[CURDAT].AdvSecurityValueDetail ASVD  ON ASVD.EffectiveFromTimeKey<=@TimeKey
                                                               AND ASVD.EffectiveToTimeKey>=@TimeKey
                                                               AND ASVD.SecurityEntityID=ASD.SecurityEntityID
WHERE ISNULL(ValuationDate,'1900-01-01')<>ISNULL(COLL_VAL_DATE,'1900-01-01')
   OR ISNULL(CurrentValue,0)<>ISNULL(COLL_AMT,0)
   OR ISNULL(ValuationExpiryDate,'1900-01-01')<>ISNULL(COLL_EXPRY_DATE,'1900-01-01')

--INSERT NEW RECORDS IN AdvSecurityValueDetail(Populating Min coll value if same coll_id appering more than one)
INSERT INTO IBL_ENPA_DB_LOCAL_DEV.[CURDAT].AdvSecurityValueDetail(
SecurityEntityID,Prev_ValuationDate,Prev_Value,ValuationDate,CurrentValue,ValuationExpiryDate,EffectiveFromTimeKey,EffectiveToTimeKey,CreatedBy,DateCreated)
SELECT A.SecurityEntityID,NULL,NULL,SEC.COLL_VAL_DATE,SEC.COLL_AMT,SEC.COLL_EXPRY_DATE,@TimeKey,@TimeKey,'SSIS USER',GETDATE()
FROM 
(SELECT SEC.COLL_ID,SEC.COLL_AMT,STG.COLL_VAL_DATE,STG.COLL_EXPRY_DATE
 FROM 
(SELECT COLL_ID,MIN(COLL_AMT) COLL_AMT
 FROM IBL_ENPA_STGDB.dbo.PTSmart_Stg_Security
 WHERE AS_ON_DATE=@EXT_DT
 GROUP BY AS_ON_DATE/*,ACC_NO*/,COLL_ID) SEC
 INNER JOIN IBL_ENPA_STGDB.dbo.PTSmart_Stg_Security STG ON SEC.COLL_ID=STG.COLL_ID
													  AND ISNULL(SEC.COLL_AMT,0)=ISNULL(STG.COLL_AMT,0)
													  AND STG.AS_ON_DATE=@EXT_DT
GROUP BY SEC.COLL_ID,SEC.COLL_AMT,STG.COLL_VAL_DATE,STG.COLL_EXPRY_DATE) SEC
INNER JOIN 
(SELECT ASD.SecurityEntityID,ASD.CollateralID
FROM IBL_ENPA_DB_LOCAL_DEV.[CURDAT].AdvSecurityDetail ASD 
LEFT JOIN  IBL_ENPA_DB_LOCAL_DEV.[CURDAT].AdvSecurityValueDetail ASVD  ON  ASVD.EffectiveFromTimeKey<=@TimeKey
                                                               AND ASVD.EffectiveToTimeKey>=@TimeKey
													          /* AND ASD.EffectiveFromTimeKey<=@TimeKey
                                                               AND ASD.EffectiveToTimeKey>=@TimeKey
															   AND ASD.SrcSystemAlt_Key=@SrcSysAlt_Key*/
                                                               AND ASVD.SecurityEntityID=ASD.SecurityEntityID
WHERE ASVD.SecurityEntityID IS NULL
--added on 06082021
AND ASD.EffectiveFromTimeKey<=@TimeKey
AND ASD.EffectiveToTimeKey>=@TimeKey
AND ASD.SrcSystemAlt_Key=@SrcSysAlt_Key
GROUP BY ASD.SecurityEntityID,ASD.CollateralID) A ON SEC.COLL_ID=A.CollateralID
GROUP BY A.SecurityEntityID,SEC.COLL_VAL_DATE,SEC.COLL_AMT,SEC.COLL_EXPRY_DATE

/*Update stock Statement Date*/
UPDATE C 
SET StkStmtDate=A.ValuationDate
   ,DPD_StockStmt=ISNULL(DATEDIFF(DAY,ValuationDate,@EXT_DT)+1,0)
FROM 
(SELECT A.RefCustomer_CIF,A.RefSystemAcId,A.RefCustomerId,MIN(B.ValuationDate)  ValuationDate
FROM [CURDAT].AdvSecurityDetail A
INNER JOIN [CURDAT].AdvSecurityValueDetail B ON A.EffectiveFromTimeKey<=@TimeKey
                                   AND A.EffectiveToTimeKey>=@TimeKey
								   AND B.EffectiveFromTimeKey<=@TimeKey
                                   AND B.EffectiveToTimeKey>=@TimeKey
								   AND A.SrcSystemAlt_Key=@SrcSysAlt_Key
								   AND A.SecurityEntityID=B.SecurityEntityID
WHERE CollateralType IN ('COLHBD','COLHST')
AND A.COLL_DELINK_DATE IS NULL--ADDED ON 31-07-2021
GROUP BY A.RefCustomer_CIF,A.RefSystemAcId,A.RefCustomerId) A
INNER JOIN NPA_IntegrationDetails C ON C.EffectiveFromTimeKey<=@TimeKey
                                   AND C.EffectiveToTimeKey>=@TimeKey
								   AND A.RefCustomer_CIF=C.NCIF_Id
								   AND A.RefCustomerId=C.CustomerId
								   AND A.RefSystemAcId=C.CustomerACID
								   AND SrcSysAlt_Key=@SrcSysAlt_Key

UPDATE NPA_IntegrationDetails SET MaxDPD=(SELECT Max(v) FROM (VALUES ([DPD_Interest_Not_Serviced]),
                                    ([DPD_Overdrawn]), 
                                    (CASE WHEN [DPD_Renewals]-90<0 THEN 0 ELSE [DPD_Renewals]-90 END ),
									(CASE WHEN DPD_StockStmt-90<0 THEN 0 ELSE DPD_StockStmt-90 END ),
									([DPD_Overdue_Loans])) AS value(v))
WHERE EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey
AND SrcSysAlt_Key=@SrcSysAlt_Key

IF(@SECURITY=0)
BEGIN
UPDATE CURDAT.AdvSecurityValueDetail SET Prev_Value=CurrentValue, Prev_ValuationDate=ValuationDate
END

END
/*--------------------------------------------------01042022 pt smart delay SToopep

IF((SELECT COUNT(DISTINCT AsOnDate) FROM IBL_ENPA_STGDB.dbo.PTSmart_Stg_Daily)=2
AND EXISTS(SELECT 1 FROM IBL_ENPA_STGDB.dbo.PTSmart_Stg_Daily WHERE ASonDate=@MonthEndDate)
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
ModifiedBy='SSIS USER',
DateModified=GETDATE()
FROM NPA_IntegrationDetails NPA
INNER JOIN IBL_ENPA_STGDB.dbo.PTSmart_Stg_Daily PSD ON NPA.SrcSysAlt_Key=@SrcSysAlt_Key
                                                  AND NPA.EffectiveFromTimeKey<=@MonthEndTimekey
                                                  AND NPA.EffectiveToTimeKey>=@MonthEndTimekey
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
AND PSD.AsOnDate=@MonthEndDate

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
	   @MonthEndTimekey,
	   @MonthEndTimekey,
	   'SSIS USER',
	   GETDATE()
FROM  IBL_ENPA_STGDB.dbo.PTSmart_Stg_Daily PSD 
LEFT JOIN NPA_IntegrationDetails NPA ON ISNULL(PSD.UCIF_ID,'')= ISNULL(NPA.NCIF_Id,'')
                                    AND NPA.EffectiveFromTimeKey<=@MonthEndTimekey
                                    AND NPA.EffectiveToTimeKey>=@MonthEndTimekey
							        AND PSD.RefCustomerID=NPA.CustomerId
								    AND PSD.CustomerAcID=NPA.CustomerACID
									AND NPA.SrcSysAlt_Key=@SrcSysAlt_Key
WHERE PSD.AsOnDate=@MonthEndDate
AND NPA.CustomerACID IS NULL

DELETE NPA
FROM NPA_IntegrationDetails NPA
INNER JOIN IBL_ENPA_STGDB.dbo.PTSmart_Stg_Incremental PSD ON NPA.SrcSysAlt_Key=@SrcSysAlt_Key
                                                        AND EffectiveFromTimeKey<=@MonthEndTimekey
                                                        AND EffectiveToTimeKey>=@MonthEndTimekey
                                                        AND ISNULL(NPA.NCIF_Id,'')=ISNULL(PSD.UCIF_ID,'')
												        AND NPA.CustomerId=PSD.RefCustomerID
												        AND NPA.CustomerACID=PSD.CustomerAcID
WHERE PSD.CLOSED_DATE IS NOT NULL
AND PSD.AsOnDate=@MonthEndDate

UPDATE NI
SET [CustomerName]=FI.CustName,
    NCIF_Id=COALESCE(FI.UCIF_ID,FI.PAN,'PS_'+FI.RefCustomerID),
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
	Zone =FI.Zone,
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
	[DPD_Interest_Not_Serviced]=CASE WHEN FI.IntNotServicedDt IS NOT NULL THEN DATEDIFF(DAY,FI.IntNotServicedDt,@MonthEndDate) END,
	[DPD_Overdrawn]=CASE WHEN FI.ContiExcessDt IS NOT NULL THEN DATEDIFF(DAY,FI.ContiExcessDt,@MonthEndDate) END,
	[DPD_Renewals] =CASE WHEN FI.ReviewDueDt IS NOT NULL AND FI.ReviewDueDt<=@MonthEndDate THEN DATEDIFF(DAY,FI.ReviewDueDt,@MonthEndDate) END,
	[DPD_Overdue_Loans]=CASE WHEN FI.PrincOverdueSinceDt=NULL AND FI.OtherOverdueSinceDt=NULL AND FI.IntOverdueSinceDt=NULL THEN NULL
                        ELSE DATEDIFF(DAY,(CASE WHEN ISNULL(FI.PrincOverdueSinceDt,'2099-01-01') < ISNULL(FI.OtherOverdueSinceDt,'2099-01-01') And ISNULL(FI.PrincOverdueSinceDt,'2099-01-01') < ISNULL(FI.IntOverdueSinceDt,'2099-01-01') Then FI.PrincOverdueSinceDt
                                                WHEN  ISNULL(FI.OtherOverdueSinceDt,'2099-01-01')< ISNULL(FI.PrincOverdueSinceDt,'2099-01-01') And  ISNULL(FI.OtherOverdueSinceDt,'2099-01-01') < ISNULL(FI.IntOverdueSinceDt,'2099-01-01') Then  FI.OtherOverdueSinceDt
                                                ELSE FI.IntOverdueSinceDt END),@MonthEndDate) END,
      --WriteOffFlag=CASE WHEN FI.TWO_Date IS NOT NULL THEN 'Y' ELSE 'N' END,   -------commeneted by sunil 16-06-2021
	 WriteOffFlag=ISNULL(FI.IsTWO,'N'),
	 AC_Closed_Date=[FI].CLOSED_DATE,
	--Processing Columns
	[NCIF_Changed]=NULL,
	[MaxDPD_Type]=NULL,
	[PNPA_Status]=NULL,	
	[PNPA_ReasonAlt_Key]=NULL,
	[PNPA_Date]=NULL,
	[NF_PNPA_Date]=NULL,
	IsFunded=isnull(FI.Funded_NonFunded_Flag,'Y'),
	ModifiedBy='SSIS USER',
	DateModified=GETDATE()
FROM NPA_IntegrationDetails NI
INNER JOIN IBL_ENPA_STGDB.dbo.PTSmart_Stg_Incremental  FI ON EffectiveFromTimeKey<=@MonthEndTimekey
													    AND EffectiveToTimeKey>=@MonthEndTimekey
                                                        AND ISNULL(NI.NCIF_Id,'')=ISNULL(FI.UCIF_ID,'')
												        AND NI.CustomerId=FI.RefCustomerID
												        AND NI.CustomerACID=FI.CustomerAcID
                                                        AND NI.SrcSysAlt_Key=@SrcSysAlt_Key
													    AND FI.AsOnDate=@MonthEndDate
LEFT JOIN DimAssetClass DAC ON FI.SrcAssetClass=DAC.PTSmartAssetClassCode
                           AND DAC.EffectiveFromTimeKey<=@MonthEndTimekey
						   AND DAC.EffectiveToTimeKey>=@MonthEndTimekey

UPDATE NPA_IntegrationDetails 
SET PrincipleOutstanding=0,UNSERVED_INTEREST=0 ,Balance=0,IntOverdue=0    ------ Added on 16-06-2021 for Balance,IntOverdue by sunil
WHERE EffectiveFromTimeKey<=@MonthEndTimekey
AND EffectiveToTimeKey>=@MonthEndTimekey
AND SrcSysAlt_Key=@SrcSysAlt_Key
AND IsTWO='Y'


Update NPA_IntegrationDetails set DPD_Renewals=NULL
where DPD_Renewals<0  
AND  EffectiveFromTimeKey<=@MonthEndTimekey
AND EffectiveToTimeKey>=@MonthEndTimekey 
AND SrcSysAlt_Key=@SrcSysAlt_Key-----Added on 16-06-2021


END
													 
--Update previous date timekey as processing date timekey
/*UPDATE [CURDAT].AdvAcRestructureDetail SET EffectiveFromTimeKey=@TimeKey,
                                  EffectiveToTimeKey=@TimeKey
WHERE EffectiveFromTimeKey<=@TimeKey-1
  AND EffectiveToTimeKey>=@TimeKey-1
  AND SrcSysAlt_Key=@SrcSysAlt_Key   */                                                     

IF(@DataProcessingFlg=1)
BEGIN

UPDATE B SET 
RestructureDt=A.RESTR_DATE,
RestructureTypeAlt_Key=DP.ParameterAlt_Key,
RestructureAmt=A.RESTR_AMT,
DiminutionAmount=A.DFV_AMT,
RepaymentStartDate=A.LATEST_REPAY_DATE,
ModifiedBy='SSIS USER',
DateModified=GETDATE(),
TEN_PC_DATE=A.TEN_PC_DATE
FROM IBL_ENPA_STGDB.dbo.PTSmart_Stg_Restructure A
INNER JOIN [CURDAT].AdvAcRestructureDetail B ON A.AS_ON_DATE=@EXT_DT
                                   AND B.EffectiveFromTimeKey<=@TimeKey
                                   AND B.EffectiveToTimeKey>=@TimeKey
								   AND B.SrcSysAlt_Key=@SrcSysAlt_Key
								   AND ISNULL(A.ENT_CIF,'')=ISNULL(B.RefCustomer_CIF,'')
								   AND A.SRC_CIF=B.RefCustomerId
								   AND A.ACC_NO=B.RefSystemAcId
LEFT JOIN DimParameter DP ON DP.EffectiveFromTimeKey<=@TimeKey
                         AND DP.EffectiveToTimeKey>=@TimeKey
						 AND DP.DimParameterName='TypeofRestructuring'
						 AND A.RESTR_TYPE=DP.ParameterName 
						 
INSERT INTO [CURDAT].AdvAcRestructureDetail
(EffectiveFromTimeKey,
EffectiveToTimeKey,
RefCustomer_CIF,
RefCustomerId,
RefSystemAcId,
RestructureDt,
RestructureTypeAlt_Key,
RestructureAmt,
DiminutionAmount,
RepaymentStartDate,
SrcSysAlt_Key,
CreatedBy,
DateCreated,TEN_PC_DATE)
SELECT @TimeKey,
       @TimeKey,
	   A.ENT_CIF,
	   A.SRC_CIF,
	   A.ACC_NO,
	   A.RESTR_DATE,
	   DP.ParameterAlt_Key,
	   A.RESTR_AMT,
	   A.DFV_AMT,
	   A.LATEST_REPAY_DATE,
	   @SrcSysAlt_Key,
	   'SSIS USER',
	   GETDATE(),A.TEN_PC_DATE
FROM IBL_ENPA_STGDB.dbo.PTSmart_Stg_Restructure A
LEFT JOIN [CURDAT].AdvAcRestructureDetail B ON  A.AS_ON_DATE=@EXT_DT
                                   AND B.EffectiveFromTimeKey<=@TimeKey
                                   AND B.EffectiveToTimeKey>=@TimeKey
								   AND B.SrcSysAlt_Key=@SrcSysAlt_Key
								   AND ISNULL(A.ENT_CIF,'')=ISNULL(B.RefCustomer_CIF,'')
								   AND A.SRC_CIF=B.RefCustomerId
								   AND A.ACC_NO=B.RefSystemAcId
LEFT JOIN DimParameter DP ON DP.EffectiveFromTimeKey<=@TimeKey
                         AND DP.EffectiveToTimeKey>=@TimeKey
						 AND DP.DimParameterName='TypeofRestructuring'
						 AND A.RESTR_TYPE=DP.ParameterName  
WHERE B.RefSystemAcId IS NULL
--added on 06082021 
/* AND EXISTS(SELECT 1 FROM NPA_IntegrationDetails NPA
           WHERE NPA.EffectiveFromTimeKey<=@TimeKey 
             and NPA.EffectiveToTimeKey>=@TimeKey 
			 AND ISNULL(NPA.NCIF_Id,'')=ISNULL(A.ENT_CIF,'')
			 AND NPA.CustomerId=A.SRC_CIF
			 AND NPA.CustomerACID=A.ACC_NO
			 AND NPA.IsRestructured='Y') */
*/
--ADDED ON UAT 20230612 DEPLOYED ON 20230707 FOR STD PROVISION

IF(@DataProcessingFlg=1)
BEGIN
--Audit Hist Table
--INSERTING INTO HIST TABLE FOR CHANGED ASSET CAT 20230622


--ADDED ON 20230612 BY ZAIN 
INSERT into HIST_STD_ASSET_CAT(Date_of_Change,	DateCreated,	NCIF_Id,	CustomerId,	CustomerACID,	Balance,	PrevSTD_ASSET_CAT_Alt_key,	CurSTD_ASSET_CAT_Alt_key,	MOC_status,	SOURCENAME)
SELECT @Exec_Date as Date_of_Change,getdate() as DateCreated,A.NCIF_Id,A.CustomerId,A.CustomerACID,A.Balance,A.STD_ASSET_CAT_Alt_key,B.STD_ASSET_CATAlt_key,@PrevMoc_Freeze  MOC_status,'PT Smart'
FROM NPA_IntegrationDetails A
INNER JOIN IBL_ENPA_STGDB.dbo.PTSMART_Provision_Stg_Daily P ON  A.NCIF_Id=P.ENT_CIF
												 AND A.CustomerID=P.SRC_CIF
												 AND A.CustomerACID=P.ACC_NO	
												 AND A.EffectiveFromTimeKey<=@TIMEKEY
												 AND A.EffectiveToTimeKey>=@TIMEKEY
												 AND CAST( P.AS_ON_DATE AS date) = @Exec_Date
INNER JOIN IBL_ENPA_DB_LOCAL_DEV.dbo.DIM_STD_ASSET_CAT B ON  B.EffectiveFromTimeKey<=@TIMEKEY
                                                 AND B.EffectiveToTimeKey>=@TIMEKEY
												 AND P.STD_ASSET_CAT=B.STD_ASSET_CATShortNameEnum
												WHERE SrcSysAlt_Key=@SrcSysAlt_Key
												and A.STD_ASSET_CAT_Alt_key<>B.STD_ASSET_CATAlt_key



--Update STD ASSET CAT as per logic for Current date
UPDATE A SET A.STD_ASSET_CAT_Alt_key=B.STD_ASSET_CATAlt_key
 FROM NPA_IntegrationDetails A
INNER JOIN IBL_ENPA_STGDB.dbo.PTSMART_Provision_Stg_Daily P ON  A.NCIF_Id=P.ENT_CIF
												 AND A.CustomerID=P.SRC_CIF
												 AND A.CustomerACID=P.ACC_NO	
												 AND A.EffectiveFromTimeKey<=@TIMEKEY
												 AND A.EffectiveToTimeKey>=@TIMEKEY
												 AND CAST( P.AS_ON_DATE AS date) = @Exec_Date
INNER JOIN IBL_ENPA_DB_LOCAL_DEV.dbo.DIM_STD_ASSET_CAT B ON  B.EffectiveFromTimeKey<=@TIMEKEY
                                                 AND B.EffectiveToTimeKey>=@TIMEKEY
												 AND P.STD_ASSET_CAT=B.STD_ASSET_CATShortNameEnum
												WHERE SrcSysAlt_Key=@SrcSysAlt_Key

--UPDATING STD_ASSET_CAT_Alt_key IN NPA INTEGRATION TABLE FOR NULL STD_ASSET_CAT_Alt_key AS PER OBSERVATION 20230619 ADDED BY ZAIN
UPDATE IBL_ENPA_DB_LOCAL_DEV.DBO.NPA_IntegrationDetails SET STD_ASSET_CAT_Alt_key=900 
WHERE EffectiveFromTimeKey=@TIMEKEY AND SrcSysAlt_Key=@SrcSysAlt_Key
AND STD_ASSET_CAT_Alt_key IS NULL

---for Previous Month End Timekey timekey to update if Previous Month Moc is not frozen

UPDATE A SET A.STD_ASSET_CAT_Alt_key=B.STD_ASSET_CATAlt_key
 FROM NPA_IntegrationDetails A
INNER JOIN IBL_ENPA_STGDB.dbo.PTSMART_Provision_Stg_Daily P ON  A.NCIF_Id=P.ENT_CIF
												 AND A.CustomerID=P.SRC_CIF
												 AND A.CustomerACID=P.ACC_NO	
												 AND A.EffectiveFromTimeKey<=@PrevMonthEndTimekey
												 AND A.EffectiveToTimeKey>=@PrevMonthEndTimekey
												 AND CAST( P.AS_ON_DATE AS date) = @Exec_Date
INNER JOIN IBL_ENPA_DB_LOCAL_DEV.dbo.DIM_STD_ASSET_CAT B ON  B.EffectiveFromTimeKey<=@PrevMonthEndTimekey
                                                 AND B.EffectiveToTimeKey>=@PrevMonthEndTimekey
												 AND P.STD_ASSET_CAT=B.STD_ASSET_CATShortNameEnum
												WHERE SrcSysAlt_Key=@SrcSysAlt_Key
												and isnull(@PrevMoc_Freeze,'') in ('','N')
---for Previous Month End Timekey timekey to update if Previous Month Moc is not frozen

UPDATE A SET A.STD_ASSET_CAT_Alt_key=B.STD_ASSET_CATAlt_key
 FROM NPA_IntegrationDetails A
INNER JOIN IBL_ENPA_STGDB.dbo.PTSMART_Provision_Stg_Daily P ON  A.NCIF_Id=P.ENT_CIF
												 AND A.CustomerID=P.SRC_CIF
												 AND A.CustomerACID=P.ACC_NO	
												 AND A.EffectiveFromTimeKey<=@PrevMonthEndTimekey
												 AND A.EffectiveToTimeKey>=@PrevMonthEndTimekey
												 AND CAST( P.AS_ON_DATE AS date) = @Exec_Date
INNER JOIN IBL_ENPA_DB_LOCAL_DEV.dbo.DIM_STD_ASSET_CAT B ON  B.EffectiveFromTimeKey<=@PrevMonthEndTimekey
                                                 AND B.EffectiveToTimeKey>=@PrevMonthEndTimekey
												 AND P.STD_ASSET_CAT=B.STD_ASSET_CATShortNameEnum
												WHERE SrcSysAlt_Key=@SrcSysAlt_Key
												and isnull(@PrevMoc_Freeze,'') in ('','N')


END

--UPDATE Audit Flag
UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET End_Date_Time=GETDATE(),[Audit_Flg]=1 
WHERE [SP_Name]='Merg_Stg_PTSmart_Data' AND [EXT_DATE]=@EXT_DT AND ISNULL([Audit_Flg],0)=0
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
WHERE [SP_Name]='Merg_Stg_PTSmart_Data' AND [EXT_DATE]=@EXT_DT AND ISNULL([Audit_Flg],0)=0
 
 RAISERROR (@ErMessage,
             @ErSeverity,
             @ErState )
ROLLBACK TRAN
END CATCH
GO