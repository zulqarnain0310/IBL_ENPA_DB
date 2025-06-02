SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[SecurityErosion_09102021](@TimeKey int)
AS
DECLARE @EXT_Date DATE=(SELECT DATE FROM SysDataMatrix WHERE TimeKey=@TimeKey)
DECLARE @STD_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='STD')
DECLARE @SUB_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='SUB')
DECLARE @LOSS_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='LOS')
DECLARE @DB1_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='DB1')
DECLARE @WRITEOFF_Alt_Key SMALLINT=(SELECT AssetClassAlt_Key FROM DimAssetClass WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey AND AssetClassShortName='WO')

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

SELECT NCIF_Id,SUM(PrincipleOutstanding) PrincipleOutstanding,SUM(SecurityValue) SecurityValue
INTO #Security
FROM NPA_IntegrationDetails
WHERE EffectiveFromTimeKey<=@TimeKey
AND EffectiveToTimeKey>=@TimeKey
GROUP BY NCIF_Id


SELECT DISTINCT RefCustomerId, 
	   (CASE WHEN (CASE WHEN CurrentValue=0 THEN 0 ELSE (CurrentValue/PrincipleOutstanding) END)*100<10 
	              THEN @LOSS_Alt_Key
             WHEN  (ISNULL(CurrentValue,0)/(CASE WHEN ISNULL(PrincipleOutstanding,0)<=0 
					THEN ISNULL(CurrentValue,0) ELSE ISNULL(PrincipleOutstanding,0) END))*100<50 
			   AND (CASE WHEN (CASE WHEN Prev_Value IS NULL THEN CurrentValue  ELSE Prev_Value END)=0 
						THEN 0  ELSE CurrentValue/ (CASE WHEN Prev_Value IS NULL  
						THEN CurrentValue ELSE Prev_Value END) END)*100<=50 
			   And NCIF_AssetClassAlt_Key=@SUB_Alt_Key
			       THEN @DB1_Alt_Key
		     ELSE NCIF_AssetClassAlt_Key
	     END) NCIF_AssetClassAlt_Key,
	    (CASE WHEN (CASE WHEN ISNULL(CurrentValue,0)=0 THEN 0  ELSE (CurrentValue/PrincipleOutstanding)END)*100<10 
		       OR ((ISNULL(CurrentValue,0)/(CASE WHEN ISNULL(PrincipleOutstanding,0)<=0 THEN ISNULL(CurrentValue,0) ELSE ISNULL(PrincipleOutstanding,0) END))*100<50 
			   AND (CASE WHEN (CASE WHEN Prev_Value IS NULL THEN CurrentValue ELSE Prev_Value END)=0 THEN 0 ELSE CurrentValue/ (CASE WHEN Prev_Value IS NULL THEN CurrentValue ELSE Prev_Value END) END) *100<50 
		       And NCIF_AssetClassAlt_Key=@SUB_Alt_Key)  
	                THEN 'Y'
         END) Erosion_Flag 
		 ,(CASE WHEN (CASE WHEN CurrentValue=0 THEN 0 ELSE (CurrentValue/PrincipleOutstanding) END)*100<10 
	                 THEN @EXT_Date
	        END) LOSS_DATE
          ,(CASE WHEN (ISNULL(CurrentValue,0)/(CASE WHEN ISNULL(PrincipleOutstanding,0)<=0 THEN ISNULL(CurrentValue,0) ELSE ISNULL(PrincipleOutstanding,0) END))*100<50
		          AND (CASE WHEN (CASE WHEN Prev_Value IS NULL THEN CurrentValue ELSE Prev_Value END)=0 THEN 0 ELSE CurrentValue/ (CASE WHEN Prev_Value IS NULL THEN CurrentValue ELSE Prev_Value END) END) *100<=50 
		          And NCIF_AssetClassAlt_Key=@SUB_Alt_Key
				  AND (CASE WHEN ISNULL(CurrentValue,0)=0 THEN 0  ELSE (CurrentValue/PrincipleOutstanding)END)*100>=10
			          THEN @EXT_Date
			END) DBt_Date 	
INTO #Erosion
FROM 
(SELECT RefCustomerId,SUM(Case When ISNULL(ValuationExpiryDate,'1900-01-01')>=@EXT_Date then  CurrentValue Else 0 End) CurrentValue,SUM(Prev_Value) Prev_Value
FROM
(SELECT A.RefCustomerId,A.CollateralID,ValuationExpiryDate,MIN(B.CurrentValue) CurrentValue,MIN(B.Prev_Value) Prev_Value
FROM [CurDat].AdvSecurityDetail A
INNER JOIN [CurDat].AdvSecurityValueDetail B ON A.EffectiveFromTimeKey<=@Timekey 
                                   AND A.EffectiveToTimeKey>=@Timekey 
								   AND B.EffectiveFromTimeKey<=@Timekey 
                                   AND B.EffectiveToTimeKey>=@Timekey
                                   AND A.SecurityEntityID=B.SecurityEntityID
--WHERE ValuationExpiryDate>=@EXT_Date       -----------------Changed by Sunil for Expired Collateral where excluding ncif for erosion shifted to sum function. 
GROUP BY RefCustomerId,A.CollateralID,ValuationExpiryDate) A
GROUP BY RefCustomerId) A
INNER JOIN
(SELECT A.CustomerId,MAX(AC_AssetClassAlt_Key) NCIF_AssetClassAlt_Key,SUM(Balance) Balance,SUM(PrincipleOutstanding)PrincipleOutstanding
FROM NPA_IntegrationDetails A
WHERE EffectiveFromTimeKey<=@Timekey 
AND EffectiveToTimeKey>=@Timekey 
AND SecuredFlag='Y'
AND AC_AssetClassAlt_Key NOT IN(@STD_Alt_Key,@WRITEOFF_Alt_Key,@LOSS_Alt_Key)
GROUP BY A.CustomerId) B ON A.RefCustomerId=B.CustomerId
WHERE (ISNULL(A.CurrentValue,0)>0 OR ISNULL(Prev_Value,0)>0 )
AND ISNULL(B.PrincipleOutstanding,0)>0
AND ISNULL(B.PrincipleOutstanding,0)> ISNULL(A.CurrentValue,0)


UPDATE  NID SET 
				--NCIF_AssetClassAlt_Key=A.NCIF_AssetClassAlt_Key,
                FlgErosion=A.Erosion_Flag--,
				--DbtDT=A.DBt_Date,
				--LossDT=A.LOSS_DATE,
				--ErosionDT=@EXT_Date
FROm #Erosion A
INNER JOIN NPA_IntegrationDetails NID ON NID.EffectiveFromTimeKey<=@Timekey 
                                     AND NID.EffectiveToTimeKey>=@Timekey          
                                     AND NID.CustomerId=A.RefCustomerId
WHERE NID.NCIF_AssetClassAlt_Key <>@WRITEOFF_Alt_Key




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
GO