SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE proc [dbo].[CASA_NPA_IntegrationDetailstemp]
as
begin

DECLARE @TimeKey int = (SELECT TimeKey FROM SysDatamatrix  WHERE CurrentStatus='C')

INSERT INTO  CASA_NPA_IntegrationDetails_temp ( 
 NCIF_Id
 ,NCIF_EntityID
,NCIF_Changed
,SrcSysAlt_Key
,CustomerId
,CustomerName
,PAN
,AddharNo
,GroupId
,GroupCode
,GroupDesc
,NCIF_AssetClassAlt_Key
,NCIF_NPA_Date
,AccountEntityID
,CustomerACID
,SanctionedLimit
,DrawingPower
,PrincipleOutstanding
,Balance
,Overdue
,DPD_Overdue_Loans
,DPD_Interest_Not_Serviced
,DPD_Overdrawn
,DPD_Renewals
,DPD
,WriteOffFlag
,Segment
,SubSegment
,ProductCode
,ProductDesc
,Settlement_Status
,AC_AssetClassAlt_Key
,AC_NPA_Date
,EffectiveFromTimeKey
,EffectiveToTimeKey
,CreatedBy
,DateCreated
,ProductType
,ActualOutStanding
,ProductAlt_Key
,UNSERVED_INTEREST
,CUSTOMER_IDENTIFIER
,ACCOUNT_LEVEL_CODE

)

select 

ENTERPRISE_CIF as NCIF_Id,
0 AS NCIF_EntityID,
'N' AS NCIF_Changed,
10  AS SrcSysAlt_Key ----fincale sourcename
,CLIENT_ID,
LEFT(CUSTOMER_NAME,80) as CUSTOMER_NAME
,left(PAN,10) as PAN
,LEFT(AADHAR_UID,12) as AADHAR_UID
,nullif(GROUP_ID,'')as GROUP_ID, 
nullif(GROUP_CODE,'') as GROUP_CODE,
nullif(GROUP_DESC,'') as GROUP_DESC,
0 AS NCIF_AssetClassAlt_Key,
null AS NCIF_NPA_Dt
,0 AS AccountEntityID
,ACCOUNT_NUMBER as CustomerACID,
(CAST(ISNULL(LIMIT,0) AS decimal)) AS SanctionedLimit,
ISNULL(DRAWING_POWER,0) AS DrawingPower,
ISNULL(PRINCIPAL_OUTSTANDING,0) AS PrincipleOutstanding
,isnull(TOTAL_OUTSTANDING,0)
--,isnull(case when cast(TOTAL_OUTSTANDING as decimal(28,2))<=0 then (cast(TOTAL_OUTSTANDING as decimal(28,2))*-1) 
--               when cast(TOTAL_OUTSTANDING as decimal(28))>0 then 0 end,0) BALANCE
,ISNULL(OVERDUE_AMOUNT,0) AS Overdue,
ISNULL(DPD_OVERDUE_LOANS,0) AS DPD_Overdue_Loans,
ISNULL(DPD_INTEREST_NOT_SERVICED,0) AS DPD_interest_Not_Serviced,
ISNULL(DPD_OVERDRAWN,0) AS DPD_Overdrawn,
ISNULL(DPD_RENEWALS,0)  AS DPD_Renewals,
ISNULL(DPD,'')  AS DPD,
----finalDPD,
ISNULL(WRITE_OFF_FLAG,'') ASWriteOffFlag,
ISNULL(SEGMENT,'') AS Segment,
ISNULL(SUB_SEGMENT,'') AS SubSegment,
SCHEME_CODE AS ProductCodu,
ISNULL(SCHEME_DESCRIPTION,'') AS productDesc,
ISNULL(SETTLEMENT_STATUS,'') AS Settlement_Status,
ISNULL(DimAssetClass.AssetClassAlt_Key,'') AS AC_AssetClassAlt_Key,
nullif(NPA_DATE,'') AS AC_NPA_Dt
,@TimeKey    AS EffectiveFromTimeKey,
 @TimeKey   AS EffectiveToTimeKey
,'SSISUSER'  AS CreatedBy,
 GETDATE()  AS DateCreated,
 SCHEME_TYPE AS ProductType,
 nullif(TOTAL_OUTSTANDING,'') AS ActualOutStanding
 ,ProductAlt_Key AS ProductAlt_Key
 ,nullif(UNSERVED_INTEREST,'') as UNSERVED_INTEREST
,nullif(CUSTOMER_IDENTIFIER,'') as CUSTOMER_IDENTIFIER
,nullif(ACCOUNT_LEVEL_CODE,'') as ACCOUNT_LEVEL_CODE
 from Induslnd_stg.dbo.Finacle_Stg 
 LEFT  JOIN  DimAssetClass ON Finacle_Stg.CLASSIFICATION=DimAssetClass.FinacleAssetClassCode
             AND DimAssetClass.EffectiveFromTimeKey<=@TimeKey AND DimAssetClass.EffectiveToTimeKey>=@TimeKey
 INNER JOIN    DIMPRODUCT  ON DIMPRODUCT.ProductCode=Finacle_Stg.SCHEME_CODE	
                  AND DIMPRODUCT.EffectiveFromTimeKey<=@TimeKey AND DIMPRODUCT.EffectiveToTimeKey>=@TimeKey
				  AND  (cast(Finacle_Stg.TOTAL_OUTSTANDING as decimal(28,2))>=0 and Finacle_Stg.SCHEME_TYPE in('SBA','CAA','TDA'))

end
GO