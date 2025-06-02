SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[SearchGrid]
 @SourceSystem  SMALLINT
,@ClientID	   VARCHAR(20)
,@ENTCIF       VARCHAR(20)
,@TimeKey	   INT
,@AstMOC	   CHAR(1)='A'	   
,@UserID varchar(10)
AS

--DECLARE
-- @SourceSystem  SMALLINT
--,@ClientID	   VARCHAR(20)
--,@TimeKey	   INT


CREATE TABLE #NCIF
(
	NCIF_Id VARCHAR(20)
)
INSERT INTO #NCIF
EXEC User_NCIF @UserID, @TimeKey, @ClientID

IF @AstMOC='A'
	BEGIN
			PRINT 'A'
			/*A/C ASSET GRID*/
			
			SELECT 
			 CustomerId		AS ClientID
			,CustomerACID	
			,AccountEntityID AS AccountEntityID	
			,'TblSearchGrid' AS TableName 
			FROM NPA_IntegrationDetails NPA
			--INNER JOIN #NCIF N ON N.NCIF_Id = NPA.NCIF_Id
			WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
				  AND CustomerId=@ClientID
				  AND SrcSysAlt_Key=@SourceSystem
				  and NCIF_AssetClassAlt_Key <> 7
				  ---AND ISNULL(AuthorisationStatus,'A')='A'	

			/*A/C ASSET GRID*/		

	END
	
ELSE 
		BEGIN

			DECLARE  @NCIF_Id VARCHAR(20)
			
			PRINT 'ClientID'
			SET @NCIF_Id= (SELECT NCIF_Id  FROM NPA_IntegrationDetails
			WHERE EffectiveFromTimeKey <= @TimeKey AND EffectiveToTimeKey >= @TimeKey
			AND CustomerId = @ClientID
			GROUP BY NCIF_Id)
		 
			PRINT 'ELSE PART'
			SELECT A.NCIF_Id																												 AS ENTCIF 
				  ,MAX(A.CustomerName)																										 AS CustomerName
				  ,MAX(A.PAN)																												 AS PAN						---AS PER DISCUSS WITH SHISHIR SIR TAKE ANY ONE PAN BETWEEN DIFFERENT CLIENT ID
				  ,SUM(A.Balance)																											 AS TotalOS
				  ,SUM(ISNULL(A.MaxDPD,0))																									 AS DPD
				  ,CASE WHEN A.MOC_Status='Y' THEN A.MOC_AssetClassAlt_Key ELSE  A.NCIF_AssetClassAlt_Key	 END							 AS NCIF_AssetClassAlt_Key
				  ,D.AssetClassShortName																									 AS AssetClass
				  ,CASE WHEN A.MOC_Status='Y' THEN CONVERT(VARCHAR(10),A.MOC_NPA_Date,103) ELSE CONVERT(VARCHAR(10),A.NCIF_NPA_Date,103) END AS NPA_Date
				  ,'TblENTCIFData' AS TableName 
				  ,A.NCIF_EntityID		
				  ,A.MOC_ReasonAlt_Key																										  AS RemarkAltKey
				  ,DS.SourceName AS SourceName																								  
				  ,A.MOC_Remark																												  AS MOC_Remark     -----New MOC Remark added 17112017
				  ,@ClientID
				  ,a.SrcSysAlt_Key
				  --,a.NCIF_EntityID																												  AS ClientID
				   ,@ClientID																												  AS ClientID
			 FROM  NPA_IntegrationDetails A
			  INNER JOIN #NCIF N ON N.NCIF_Id = A.NCIF_Id
			  INNER JOIN DimSourceSystem DS ON	(DS.EffectiveFromTimeKey<=@TimeKey AND DS.EffectiveToTimeKey>=@TimeKey)
												AND A.SrcSysAlt_Key=DS.SourceAlt_Key


			 LEFT JOIN DimAssetClass    D  ON  (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey)
											    AND D.AssetClassAlt_Key=CASE WHEN A.MOC_Status='Y' THEN A.MOC_AssetClassAlt_Key ELSE  A.NCIF_AssetClassAlt_Key	END

			 LEFT JOIN (
						 SELECT A.NCIF_EntityID,A.NCIF_Id,A.NCIF_AssetClassAlt_Key,A.NCIF_NPA_Date,A.MOC_ReasonAlt_Key,A.MOC_Remark,A.MocAppRemark FROM MOC_NPA_IntegrationDetails_MOD A
						 INNER JOIN (
										SELECT MAX(E.EntityKey)EntityKey FROM MOC_NPA_IntegrationDetails_MOD E   
										WHERE  (E.EffectiveFromTimeKey<=@TimeKey AND E.EffectiveToTimeKey>=@TimeKey)
												AND E.NCIF_Id=@NCIF_Id
												AND E.AuthorisationStatus IN ('NP','MP','DP','RM')
										GROUP BY E.NCIF_Id	
									 ) B  ON (A.EntityKey=B.EntityKey)				
						
						)E   ON (E.NCIF_EntityID=A.NCIF_EntityID)
															     										

			WHERE	 (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
						AND  A.NCIF_Id=@NCIF_Id--@ENTCIF
					---AND ISNULL(A.AuthorisationStatus,'A')='A'    
					    
			GROUP BY A.NCIF_Id,A.NCIF_AssetClassAlt_Key,D.AssetClassShortName,A.NCIF_NPA_Date,A.NCIF_EntityID,A.MOC_ReasonAlt_Key,MOC_Status,MOC_AssetClassAlt_Key,MOC_NPA_Date	,DS.SourceName,A.MOC_Remark	,a.SrcSysAlt_Key,a.NCIF_EntityID				

			--UNION
						
			--SELECT 
			-- A.NCIF_Id						AS  ENTCIF
			--,MAX(A.CustomerName)			AS  CustomerName
			--,MAX(A.PAN)						AS  PAN
			--,SUM(C.Balance)					AS  TotalOS
			--,SUM(ISNULL(C.MaxDPD,0))		AS  MaxDPD
			--,CASE WHEN A.MOC_Status='Y' THEN A.MOC_AssetClassAlt_Key ELSE  A.NCIF_AssetClassAlt_Key	 END NCIF_AssetClassAlt_Key	
			--,D.AssetClassShortName			AS  AssetClass
		 --   ,CASE WHEN A.MOC_Status='Y' THEN CONVERT(VARCHAR(10),A.MOC_NPA_Date,103) ELSE CONVERT(VARCHAR(10),A.NCIF_NPA_Date,103) END AS NPA_Date
			--,'TblENTCIFData' AS TableName
			--,A.NCIF_EntityID				
		 --   ,A.MOC_ReasonAlt_Key  AS RemarkAltKey
			---,A.Remark			AS MOC_Remark     -----New MOC Remark added 17112017
			--FROM MOC_NPA_IntegrationDetails_MOD  A

			--LEFT JOIN 	DimAssetClass     D          ON (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey)
			--									          AND D.AssetClassAlt_Key=A.NCIF_AssetClassAlt_Key

			--LEFT JOIN	NPA_IntegrationDetails  C 	ON (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
			--											AND A.NCIF_Id=C.NCIF_Id
													

			--WHERE		(A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
			--		AND A.AuthorisationStatus IN ('NP','MP','DP','RM')
			--		AND A.NCIF_Id=@ENTCIF	
					
			--GROUP BY A.NCIF_Id,A.NCIF_AssetClassAlt_Key,D.AssetClassShortName,A.NCIF_NPA_Date,A.NCIF_EntityID,A.MOC_ReasonAlt_Key,A.MOC_Status,A.MOC_AssetClassAlt_Key,A.MOC_NPA_Date,A.Remark						
			
			/*Least Account information*/								

			/*ENTCIF GRID*/					

				SELECT 
				 ND.NCIF_Id       AS ENTCIF
				,CustomerId    AS ClientID
				,CustomerACID  
				,AccountEntityID AS AccountNo	
				,Balance
				,'TblSearchGrid' AS TableName 	
				,DS.SourceName as SourceName
				FROM NPA_IntegrationDetails ND
				 INNER JOIN #NCIF N ON N.NCIF_Id = ND.NCIF_Id
				 INNER JOIN DimSourceSystem DS on  ND.SrcSysAlt_Key=DS.SourceAlt_Key
				WHERE (ND.EffectiveFromTimeKey<=@TimeKey AND ND.EffectiveToTimeKey>=@TimeKey)
						AND ND.NCIF_Id=@NCIF_Id--@ENTCIF
						---AND ISNULL(AuthorisationStatus,'A')='A'	
			/*ENTCIF GRID*/					
					
			--END
		END			
		



				 
						 

GO