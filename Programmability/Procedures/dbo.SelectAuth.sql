SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[SelectAuth]
 @AccountNo			VARCHAR(20)=''
,@TimeKey			INT=0
,@OperationFlag	    TINYINT=0
,@ENTCIF			VARCHAR(20)=''
,@ASS_MOC			CHAR(1)='A'
,@UserID			VARCHAR(20)
AS

--DECLARE
-- @AccountNo	VARCHAR(20)=''
--,@TimeKey	INT=0
--,@OperationFlag TINYINT=0

IF @OperationFlag=16
	BEGIN
			IF @ASS_MOC='A' -- FOR ASSET CLASS
				BEGIN
				
					SELECT 
						D.SourceShortName  AS SourceSystem
						,A.NCIF_Id				AS ENTCIF
						,A.CustomerACID		AS AccountNo
						,A.CustomerId       AS ClientID
						,A.CustomerName		AS CustomerName
						,0                  AS ApprovedAll
						,0					AS RejectAll
						,''					AS RejectionRemark
						,A.AccountEntityID  AS AccountEntityID
						,A.SrcSysAlt_Key    AS SrcSysAlt_Key	
						,A.ModifiedBy 
						,'TblAuthPending' AS TableName 
					FROM NPA_IntegrationDetails_MOD A
					INNER JOIN (SELECT MAX(EntityKey)EntityKey FROM NPA_IntegrationDetails_MOD  A
								WHERE    (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey) 
											AND A.CustomerACID=CASE WHEN @AccountNo<>'' THEN @AccountNo ELSE A.CustomerACID END 
											AND A.AuthorisationStatus IN ('NP','MP','DP','RM')	
											GROUP BY AccountEntityID
								)B  ON (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey) AND
										B.EntityKey=A.EntityKey

					LEFT JOIN DimSourceSystem				D    ON (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey)
																			AND A.SrcSysAlt_Key=D.SourceAlt_Key

				WHERE  (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
					 AND A.AuthorisationStatus IN ('NP','MP','DP','RM')
					 AND A.ModifiedBy <> @UserID 														

				END	
				  
			ELSE IF @ASS_MOC='M' -- FOR MOC
					BEGIN

							
							SELECT 
								 A.NCIF_Id				AS ENTCIF_ID
								,A.NCIF_EntityID		AS ENTCIF
								,MAX(A.CustomerName)	AS CustomerName
								,MAX(A.PAN)				AS PAN
								,SUM(G.Balance)			AS Balance
								,MAX(G.MaxDPD)			AS MaxDPD 
								,D.AssetClassShortName  AS AssetClass
								,0                      AS ApprovedAll
								,0					    AS RejectAll
								,A.MOC_AssetClassAlt_Key AS AssetClassAlt_Key
								,CONVERT(VARCHAR(10),A.MOC_NPA_Date,103) AS NPA_Date
								,G.SrcSysAlt_Key 
								,A.NCIF_EntityID
								,A.NCIF_Id AS ENTCIF
								,F.SourceName
								,G.CustomerId as ClientID
								,'TblAuthPending' AS TableName 
							FROM MOC_NPA_IntegrationDetails_MOD  A

							INNER JOIN (SELECT MAX(EntityKey)EntityKey FROM MOC_NPA_IntegrationDetails_MOD A
												WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
												AND A.NCIF_Id=CASE WHEN @ENTCIF<>'' THEN @ENTCIF ELSE A.NCIF_Id END
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
									AND A.AuthorisationStatus IN ('NP','MP','DP','RM') 
									AND  A.ModifiedBy <> @UserID 
									

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
	END
GO