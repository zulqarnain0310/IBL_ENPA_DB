SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
create PROCEDURE  [dbo].[SecurityErosion_BKP_22122023] 
(
@TimeKey int
)
AS
BEGIN
SET NOCOUNT ON

DECLARE @EXT_Date DATE=(SELECT DATE FROM SysDataMatrix WHERE TimeKey=@TimeKey)
DECLARE @STD_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='STD')
DECLARE @SUB_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='SUB')
DECLARE @LOSS_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='LOS')
DECLARE @DB1_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='DB1')
DECLARE @WRITEOFF_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='WO')

--select @EXT_Date,@STD_Alt_Key,@SUB_Alt_Key,@LOSS_Alt_Key,@DB1_Alt_Key,@WRITEOFF_Alt_Key

BEGIN TRY
DELETE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] 
WHERE [SP_Name]='SecurityErosion' AND [EXT_DATE]=@EXT_Date AND ISNULL([Audit_Flg],0)=0

INSERT INTO IBL_ENPA_STGDB.[dbo].[Procedure_Audit]
           ([EXT_DATE] ,[Timekey] ,[SP_Name],Start_Date_Time )
SELECT @EXT_Date,@TimeKey,'SecurityErosion',GETDATE()

BEGIN TRAN

IF OBJECT_ID('TEMPDB..#Erosion') IS NOT NULL
DROP TABLE #Erosion

IF OBJECT_ID('TEMPDB..#Security') IS NOT NULL
DROP TABLE #Security

IF OBJECT_ID('TEMPDB..#NCIF') IS NOT NULL
DROP TABLE #NCIF

Select NCIF_Id into #NCIF from NPA_IntegrationDetails With (nolock) where EffectiveFromTimeKey=@TimeKey and EffectiveToTimeKey=@TimeKey
ANd isnull(NCIF_AssetClassAlt_Key,0) not in (1,7) ANd SecuredFlag='Y' And IsFunded='Y'  
--AND NCIF_Id=10000759 
Group By NCIF_Id




SELECT A.NCIF_Id,SUM(PrincipleOutstanding) PrincipleOutstanding,SUM(SecurityValue) SecurityValue
INTO #Security
FROM NPA_IntegrationDetails A With (nolock)
Inner Join #NCIF B ON A.NCIF_Id=B.NCIF_Id
WHERE EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey
GROUP BY A.NCIF_Id



SELECT DISTINCT B.NCIF_Id as RefCustomer_CIF, PrincipleOutstanding,Prev_Value,CurrentValue,
((CurrentValue/Case When Isnull(PrincipleOutstanding,0)=0 then 1 else PrincipleOutstanding end )*100) SecurityCoverPercentage,
(100-(CurrentValue/Case when ISNULL(Prev_Value,0)=0 then 1 else Prev_Value end )*100) SecurityErosionPercentage,

  (CASE WHEN (
             ((CASE WHEN isnull(CurrentValue,0)=0 THEN 0 ELSE (CurrentValue/PrincipleOutstanding) END)*100<10) and LossDT IS null) 
             THEN @LOSS_Alt_Key  /* If already lossdt is marked , then Erosion_Flag ,ErosionDT , DbtDT should not be re-calculated added by satish as on date 09052023 */
             WHEN  

  (CASE WHEN ISNULL(CurrentValue,0)<ISNULL(PrincipleOutstanding,0) And
   ISNULL(CurrentValue,0)=0
THEN 0  ELSE CurrentValue/ (CASE WHEN ISNULL(Prev_Value,0)=0
THEN 1 ELSE Prev_Value END) END)*100<=50
AND (CASE WHEN ISNULL(CurrentValue,0)<ISNULL(PrincipleOutstanding,0) And ISNULL(CurrentValue,0)=0
THEN 0  ELSE CurrentValue/ (CASE WHEN ISNULL(Prev_Value,0)=0
THEN 1 ELSE Prev_Value END) END)*100<50
And ((CurrentValue/Case When Isnull(PrincipleOutstanding,0)=0 then 1 else PrincipleOutstanding end )*100)<50

  And NCIF_AssetClassAlt_Key=@SUB_Alt_Key and LossDT IS null and DbtDT IS null /* If already DBTdt is marked , then Erosion_Flag ,ErosionDT , DbtDT should not be re-calculated added by satish as on date 09052023 */
      THEN @DB1_Alt_Key
    ELSE NCIF_AssetClassAlt_Key
    END) NCIF_AssetClassAlt_Key,
   (CASE WHEN ((CASE WHEN ISNULL(CurrentValue,0)=0 THEN 0  ELSE (CurrentValue/PrincipleOutstanding)END)*100<10
    and LossDT IS null)
      OR
 
((CASE WHEN ISNULL(CurrentValue,0)<ISNULL(PrincipleOutstanding,0) And ISNULL(CurrentValue,0)=0
THEN 0  ELSE CurrentValue/ (CASE WHEN ISNULL(Prev_Value,0)=0
THEN 1 ELSE Prev_Value END) END)*100<=50
AND (CASE WHEN ISNULL(CurrentValue,0)<ISNULL(PrincipleOutstanding,0) And ISNULL(CurrentValue,0)=0
THEN 0  ELSE CurrentValue/ (CASE WHEN ISNULL(Prev_Value,0)=0
THEN 1 ELSE Prev_Value END) END)*100<50
And ((CurrentValue/Case When Isnull(PrincipleOutstanding,0)=0 then 1 else PrincipleOutstanding end )*100)<50
  And NCIF_AssetClassAlt_Key=@SUB_Alt_Key) and (LossDT IS  null and DbtDT IS null)
               THEN 'Y'
         END) Erosion_Flag
,(CASE WHEN (CASE WHEN isnull(CurrentValue,0)=0 THEN 0 ELSE (isnull(CurrentValue,0)/isnull(PrincipleOutstanding,0)) END)*100<10
                 and LossDT IS null
                THEN @EXT_Date
       END) LOSS_DATE
          ,

(CASE WHEN (CASE WHEN ISNULL(CurrentValue,0)<ISNULL(PrincipleOutstanding,0) And ISNULL(CurrentValue,0)=0
THEN 0  ELSE CurrentValue/ (CASE WHEN ISNULL(Prev_Value,0)=0
THEN 1 ELSE Prev_Value END) END)*100<=50
 AND (CASE WHEN ISNULL(CurrentValue,0)<ISNULL(PrincipleOutstanding,0) And ISNULL(CurrentValue,0)=0
THEN 0  ELSE CurrentValue/ (CASE WHEN ISNULL(Prev_Value,0)=0
THEN 1 ELSE Prev_Value END) END)*100>10
And ((CurrentValue/Case When Isnull(PrincipleOutstanding,0)=0 then 1 else PrincipleOutstanding end )*100)<50
  And NCIF_AssetClassAlt_Key=@SUB_Alt_Key
  and (LossDT IS  null and DbtDT IS null)  /* If already DBTdt is marked , then Erosion_Flag ,ErosionDT , DbtDT should not be re-calculated added by satish as on date 09052023 */
         THEN @EXT_Date
          ELSE DbtDT  ---- EXTRA CODE ADDED BY SATISH TO HANDLE DBTDT 23022023 CR OF FINCALE 
END) DBt_Date
INTO #Erosion
FROM
(SELECT RefCustomer_CIF,SUM(Case When ValuationExpiryDate IS NULL OR ValuationExpiryDate='' OR ValuationExpiryDate<@EXT_Date  then  0 Else CurrentValue End) CurrentValue,
SUM(Case When ValuationExpiryDate IS NULL OR ValuationExpiryDate='' OR     DATEADD(DAY,1,ValuationExpiryDate)<@EXT_Date  then  0 Else Prev_Value End) Prev_Value
--SUM(Case When ValuationExpiryDate IS NULL OR ValuationExpiryDate='' OR    ValuationExpiryDate<@EXT_Date  then  0 Else Prev_Value End) Prev_Value
FROM
(SELECT A.RefCustomer_CIF,A.CollateralID,ValuationExpiryDate,MIN(isnull(B.CurrentValue,0)) CurrentValue,MIN(Isnull(B.Prev_Value,0)) Prev_Value
FROM [CurDat].AdvSecurityDetail A With (nolock)
INNER JOIN [CurDat].AdvSecurityValueDetail B With (nolock)  ON A.EffectiveFromTimeKey<=@TimeKey
                                   AND A.EffectiveToTimeKey>=@TimeKey
  AND B.EffectiveFromTimeKey<=@Timekey
                                   AND B.EffectiveToTimeKey>=@TimeKey
                                   AND A.SecurityEntityID=B.SecurityEntityID


GROUP BY RefCustomer_CIF,A.CollateralID,ValuationExpiryDate) A
GROUP BY RefCustomer_CIF) A

Right JOIN

(SELECT A.NCIF_Id,MIN(LossDT) LossDT,MIN(DbtDT) DbtDT,MAX(NCIF_AssetClassAlt_Key) NCIF_AssetClassAlt_Key,SUM(isnull(Balance,0)) Balance,
SUM(isnull(PrincipleOutstanding,0))PrincipleOutstanding ---- EXTRA CODE ADDED BY SATISH TO HANDLE DBTDT CR OF FINCALE  
FROM NPA_IntegrationDetails A With (nolock)
WHERE EffectiveFromTimeKey<=@Timekey
AND EffectiveToTimeKey>=@Timekey
AND SecuredFlag='Y'
AND IsFunded='Y'
AND isnull(NCIF_AssetClassAlt_Key,0) NOT IN(@LOSS_Alt_Key)
GROUP BY A.NCIF_Id) B ON A.RefCustomer_CIF=B.NCIF_Id
INNER JOIN #NCIF C on B.NCIF_Id=C.NCIF_Id
WHERE (ISNULL(A.CurrentValue,0)>=0 OR ISNULL(Prev_Value,0)>=0 )
AND ISNULL(B.PrincipleOutstanding,0)>0
AND ISNULL(B.PrincipleOutstanding,0)> ISNULL(A.CurrentValue,0)


--select * from #erosion

UPDATE  NID SET NCIF_AssetClassAlt_Key=A.NCIF_AssetClassAlt_Key,
                FlgErosion=A.Erosion_Flag,
				DbtDT=A.DBt_Date,
				LossDT=A.LOSS_DATE,
				ErosionDT=(case when A.Erosion_Flag='Y' then @EXT_Date else Null End)
FROm #Erosion A
INNER JOIN NPA_IntegrationDetails NID ON NID.EffectiveFromTimeKey<=@Timekey 
                                     AND NID.EffectiveToTimeKey>=@Timekey          
                                     AND NID.NCIF_Id =A.RefCustomer_CIF
/*18042023 amar changes for */
/*WHERE NID.NCIF_AssetClassAlt_Key <>@WRITEOFF_Alt_Key */
WHERE NID.NCIF_AssetClassAlt_Key NOT IN(@WRITEOFF_Alt_Key)





--Select  distinct RefCustomer_CIF as NCIF_ID,
--B.CustomerName,
--a.PrincipleOutstanding,
--Case When c.AssetClassShortName='LOS' and Erosion_Flag='Y' and Isnull(Prev_Value,0)=0 Then 0 else  Prev_Value end Prev_Value,
--Case When c.AssetClassShortName='LOS' and Erosion_Flag='Y' and Isnull(CurrentValue,0)=0 Then 0 else  CurrentValue end CurrentValue,
--Case When c.AssetClassShortName='LOS' and Erosion_Flag='Y' and Isnull(SecurityCoverPercentage,0)=0 Then 0 else  SecurityCoverPercentage end SecurityCoverPercentage,
--Case When c.AssetClassShortName='LOS' and Erosion_Flag='Y' and Isnull(SecurityErosionPercentage,0)=0 Then 100 else  SecurityErosionPercentage end SecurityErosionPercentage,
--c.AssetClassShortName ErosionAssetClass,
--Erosion_Flag,
--Case When c.AssetClassShortName='LOS' and Erosion_Flag='Y' and Isnull(LOSS_DATE,'')='' Then @EXT_Date else  LOSS_DATE end LOSS_DATE
--,DBt_Date,
--d.AssetClassShortName ActualAssetClass,
--z.CustomerACID
-- from  #Erosion A
--Inner Join (Select NCIF_Id,CustomerName,NCIF_AssetClassAlt_Key from NPA_IntegrationDetails b with (nolock) where b.EffectiveFromTimeKey=@TimeKey and b.EffectiveToTimeKey=@TimeKey
--Group by NCIF_Id,CustomerName,NCIF_AssetClassAlt_Key) B ON A.RefCustomer_CIF=B.NCIF_Id 
--inner join NPA_IntegrationDetails Z with (nolock)  on Z.ncif_id = a.RefCustomer_CIF and z.EffectiveFromTimeKey=@TimeKey and z.EffectiveToTimeKey=@TimeKey
--inner join DimAssetClass c on c.AssetClassAlt_Key=a.NCIF_AssetClassAlt_Key
--inner join DimAssetClass d on d.AssetClassAlt_Key=b.NCIF_AssetClassAlt_Key
--where Erosion_Flag='Y'  order by a.PrincipleOutstanding desc


--Select RefCustomer_CIF,RefCustomerId,ValuationExpiryDate,Prev_Value,CurrentValue,a.CollateralID,RefSystemAcId from CURDAT.AdvSecurityDetail A with (nolock)
--Inner Join CURDAT.AdvSecurityValueDetail B with (nolock) On A.SecurityEntityID=B.SecurityEntityID
--And B.EffectiveFromTimeKey=@TimeKey And B.EffectiveToTimeKey=@TimeKey
--Where A.EffectiveFromTimeKey=@TimeKey And A.EffectiveToTimeKey=@TimeKey
--And A.RefCustomer_CIF in (Select distinct RefCustomer_CIF from #Erosion where Erosion_Flag='Y')



COMMIT TRAN
--UPDATE Audit Flag
UPDATE IBL_ENPA_STGDB.[dbo].[Procedure_Audit] SET End_Date_Time=GETDATE(),[Audit_Flg]=1 
WHERE [SP_Name]='SecurityErosion' AND [EXT_DATE]=@EXT_Date AND ISNULL([Audit_Flg],0)=0
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
WHERE [SP_Name]='SecurityErosion' AND [EXT_DATE]=@EXT_Date AND ISNULL([Audit_Flg],0)=0
 
 RAISERROR (@ErMessage,
             @ErSeverity,
             @ErState )
ROLLBACK TRAN
END CATCH
END
GO