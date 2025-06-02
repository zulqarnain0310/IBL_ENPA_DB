SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[GetMOCUploadAuthPendingData]
 @UserID varchar(20)=NULL
,@OperationFlag int=1
,@TimeKey int=24868
AS
BEGIN
SELECT isnull(PreProcessingFreeze,'N') AS IsPreProcessingFreeze,ISNULL(MOC_Freeze,'N') AS IsPostProcessingFreeze,'TblProcessing' AS TableName 
FROM SysDataMatrix where CurrentStatus='c'
SELECT 
								-- A.NCIF_Id				AS ENTCIF
								--,A.NCIF_EntityID		AS ENTCIF
							    ROW_NUMBER() OVER (ORDER BY G.CustomerId) AS SrNo
								,MAX(A.CustomerName)	AS CustomerName
								,MAX(A.PAN)				AS PAN
								,SUM(G.Balance)			AS Balance
								,MAX(G.MaxDPD)			AS MaxDPD 
								,D.AssetClassShortName  AS AssetClass
								,0                      AS ApprovedAll
								,0					    AS RejectAll
								,A.MOC_AssetClassAlt_Key AS AssetClassAlt_Key
								,CONVERT(VARCHAR(10),A.MOC_NPA_Date,103) AS NPADate
								,G.SrcSysAlt_Key as SourceSystem
								,A.NCIF_EntityID
								,A.NCIF_Id AS ENTCIF
								--,F.SourceName as SourceSystem
								,G.CustomerId as CustomerID
								,max(a.MOC_ReasonAlt_Key) as Reason
								,max(a.MOC_Remark) as Remark
								,'Data' AS TableName 
							FROM MOC_NPA_IntegrationDetails_MOD  A

							INNER JOIN (SELECT MAX(EntityKey)EntityKey FROM MOC_NPA_IntegrationDetails_MOD A
												WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
												--AND A.NCIF_Id=CASE WHEN @ENTCIF<>'' THEN @ENTCIF ELSE A.NCIF_Id END
												AND A.AuthorisationStatus IN ('NP','MP','DP','RM')
												GROUP BY NCIF_EntityID	
										)B  ON B.EntityKey=A.EntityKey

							LEFT JOIN DimAssetClass      D   ON (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey)
																    AND D.AssetClassAlt_Key=A.MOC_AssetClassAlt_Key

							LEFT JOIN NPA_IntegrationDetails	G   ON (G.EffectiveFromTimeKey<=@TimeKey AND G.EffectiveToTimeKey>=@TimeKey)
																		AND G.NCIF_EntityID=A.NCIF_EntityID

							
							LEFT JOIN DimSourceSystem	F   ON (F.EffectiveFromTimeKey<=@TimeKey AND F.EffectiveToTimeKey>=@TimeKey)
																			AND G.SrcSysAlt_Key=F.SourceAlt_Key												
																		 													
							WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey) 
									and A.ModifiedBy <> @UserID 
									 AND ISNULL(A.UploadFlag,'')='U'
									 AND A.AuthorisationStatus IN ('NP','MP','DP','RM')

							GROUP BY 
									 A.NCIF_Id,
									 A.NCIF_EntityID,
									 D.AssetClassShortName,
									 A.MOC_AssetClassAlt_Key,
									 A.MOC_NPA_Date,
									 G.SrcSysAlt_Key 
								    ,A.NCIF_EntityID
								    ,A.NCIF_Id 
								    ,F.SourceName
								    ,G.CustomerId

		
END
GO