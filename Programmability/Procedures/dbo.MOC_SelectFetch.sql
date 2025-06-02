SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[MOC_SelectFetch]
 @ENTCIF	   VARCHAR(20)
,@ClientID	   VARCHAR(20)
,@AccountNo	   VARCHAR(20)
,@TimeKey		INT
,@MODE           TINYINT=2
,@UserID varchar(20)
,@AuthMode char(1)
AS




IF @MODE=2
	BEGIN

			CREATE TABLE #NCIF
			(
				NCIF_Id VARCHAR(20)
			)
			INSERT INTO #NCIF
			EXEC User_NCIF @UserID, @TimeKey, @ClientID

			SELECT 
					CustomerId									AS ClientID
					,CustomerName								AS CustomerName
					,PAN										AS PAN
					,D.SourceName								AS SourceSystem
					,CustomerACID								AS AccountNo
					,AccountEntityID							AS AccountEntityID
					,Segment									AS Segment
					,Balance									AS O_S
					,SanctionedLimit							AS Limit
					,Overdue									AS Overdue
					,MaxDPD										AS DPD
					,B.AssetClassShortName						AS AssetClass
					,CONVERT(VARCHAR(10),AC_NPA_Date,103)		AS NPA_Date
					---,CONVERT(VARCHAR(10),A.NCIF_NPA_Date,103)	AS NCIF_NPA_Date
					,ProductType AS Facility
					,DrawingPower AS DrawingPower
					,'TblSelect' AS TableName 	
					FROM NPA_IntegrationDetails A
					INNER JOIN #NCIF		   N	ON N.NCIF_Id = A.NCIF_Id

					LEFT JOIN DimAssetClass    B   ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
														AND A.AC_AssetClassAlt_Key=B.AssetClassAlt_Key

					LEFT JOIN DimSourceSystem	D   ON (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey)
														AND D.SourceAlt_Key=A.SrcSysAlt_Key	
														
				
							
					WHERE   (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey) 
								AND A.CustomerACID=@AccountNo 
								AND A.CustomerId=@ClientID 
								AND A.NCIF_Id=@ENTCIF
								---AND ISNULL(A.AuthorisationStatus,'A')='A'		
		END	
	ELSE 
		BEGIN

					


					SELECT 
					 A.NCIF_Id											AS ENTCIF
				    ,D.Segment											AS Segment
					,B.AssetClassShortName								AS AssetClass
					,CONVERT(VARCHAR(10),A.NCIF_NPA_Date,103)			AS NPA_Date


					,E.AssetClassShortName								AS MOD_AssetClassName
					,CONVERT(VARCHAR(10),F.MOC_NPA_Date,103)			AS MOD_NPA_Date
					,M.MocReasonName									AS AstClsChngRemark
					,F.ModifiedBy										AS MOD_By
					,FORMAT(F.DateModified,'dd/MM/yyyy HH:mm:ss')		AS Date_MOD	
					,'TblSelect' AS TableName 
					,F.MOC_Remark										AS MakerRemark
					FROM MOC_NPA_IntegrationDetails_MOD A

					LEFT JOIN (SELECT NCIF_EntityID,MAX(Segment)Segment  FROM NPA_IntegrationDetails 
								WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
									   AND NCIF_Id=@ENTCIF
							    GROUP BY NCIF_EntityID												
						      )D   ON (A.NCIF_EntityID=D.NCIF_EntityID)

					LEFT JOIN (	SELECT NCIF_EntityID,MOC_AssetClassAlt_Key,MOC_NPA_Date,MOC_ReasonAlt_Key,ModifiedBy,DateModified ,MOC_Remark
								FROM MOC_NPA_IntegrationDetails_MOD 
							    WHERE  (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
											AND NCIF_Id=@ENTCIF
											AND AuthorisationStatus IN ('MP') 	
							   )F   ON (A.NCIF_EntityID=F.NCIF_EntityID)			

					LEFT JOIN DimAssetClass				B  ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
																AND A.NCIF_AssetClassAlt_Key=B.AssetClassAlt_Key


					LEFT JOIN DimAssetClass				E  ON (E.EffectiveFromTimeKey<=@TimeKey AND E.EffectiveToTimeKey>=@TimeKey)
																AND F.MOC_AssetClassAlt_Key=E.AssetClassAlt_Key

				    LEFT JOIN DimMocReason				M  ON (M.EffectiveFromTimeKey<=@TimeKey AND M.EffectiveToTimeKey>=@TimeKey)
															   AND M.MocReasonAlt_Key=F.MOC_ReasonAlt_Key													
																	

					WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
						  AND A.NCIF_Id=@ENTCIF
						  AND A.AuthorisationStatus='O'

				SELECT 
				 ND.NCIF_Id       AS ENTCIF
				,CustomerId    AS ClientID
				,CustomerACID  
				,AccountEntityID AS AccountNo	
				,Balance
				,'TblAccountList' AS TableName 	
				,DS.SourceName as SourceName
				FROM NPA_IntegrationDetails ND
				 --INNER JOIN #NCIF N ON N.NCIF_Id = ND.NCIF_Id
				 INNER JOIN DimSourceSystem DS on  ND.SrcSysAlt_Key=DS.SourceAlt_Key
				WHERE (ND.EffectiveFromTimeKey<=@TimeKey AND ND.EffectiveToTimeKey>=@TimeKey)
						AND ND.NCIF_Id=@ENTCIF
						
		END										
GO