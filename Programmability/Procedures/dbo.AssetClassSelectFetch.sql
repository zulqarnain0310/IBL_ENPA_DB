SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[AssetClassSelectFetch]
 @ClientID  VARCHAR(20)
,@AccountNo  INT
,@SourceSystem TINYINT
,@Mode		 TINYINT=0
,@TimeKey	 INT=0
,@UserID varchar(10)
AS
--DECLARE
--@ClientID  VARCHAR(20)
--,@AccountNo  VARCHAR(20)
--,@ACC		 TINYINT=0
--,@TimeKey	 INT=0

CREATE TABLE #NCIF
(
	NCIF_Id VARCHAR(20)
)
INSERT INTO #NCIF
EXEC User_NCIF @UserID, @TimeKey, @ClientID

IF @Mode=2
	BEGIN


----FIND THE ORIGINAL ASSET CLASS
DECLARE
 @Org_AssetClass SMALLINT
,@Org_NPA_Date	  DATE

SELECT @Org_AssetClass=A.AC_AssetClassAlt_Key,@Org_NPA_Date=A.AC_NPA_Date FROM NPA_IntegrationDetails A
INNER JOIN #NCIF N ON N.NCIF_Id = A.NCIF_Id
WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
	 AND A.AccountEntityID=@AccountNo
	 AND A.CustomerId=@ClientID 
	 AND ISNULL(A.AuthorisationStatus,'A') in('MP','A')

	-- select * from #NCIF
SELECT 
ClientID
,CustomerName
,AccountNo
,AccountEntityID
,PAN
,Segment
,SchemeCode
,Limit
,O_S
,DPD
,@Org_AssetClass         AssetClass												 -----Original	
,CONVERT(VARCHAR(10),@Org_NPA_Date,103)					AS NPA_Date					
,AssetClassShortName									AS ToolTipAssetClass		---ToolTip
,NPA_Date												AS ToolTipNPA_Date          ---ToolTip NPA_Date
,OverdueAmount
,AstClsChngRemark
,DrawingPower
,SourceName
,ENTCIF
,Facility
,TableName
,CrModBy
,CrModDate
,IsMainTable
 FROM
(				

				SELECT 
					 CustomerId																								AS ClientID
					,CustomerName																							AS CustomerName
					,CustomerACID																							AS AccountNo
					,AccountEntityID																						AS AccountEntityID
					,PAN																									AS PAN
					,Segment																								AS Segment
					,ProductCode																							AS SchemeCode
					,CAST(SanctionedLimit AS DECIMAL(18,2))																	AS Limit
					,CAST(Balance AS DECIMAL(18,2))																			AS O_S
					--,PrincipleOutstanding
					--,Overdue
					--,DPD 
					,ISNULL(MAXDPD,0)																						AS DPD
					,AC_AssetClassAlt_Key																					AS AssetClass					
					,B.AssetClassShortName																					AS AssetClassShortName
					,CONVERT(VARCHAR(10),AC_NPA_Date,103)																	AS NPA_Date
					,CAST(A.Overdue AS DECIMAL(18,2))																		AS OverdueAmount
					,A.AstClsChngRemark																						AS AstClsChngRemark
					,A.DrawingPower																							AS DrawingPower
					,C.SourceName																							AS SourceName
					,A.NCIF_Id																								AS ENTCIF
					,A.NCIF_EntityID																						
					,A.ProductType																							AS Facility
					,'TblSelect'																							AS TableName 
					--,ISNULL(A.ModifiedBy,A.CreatedBy)																		AS CrModBy
					,A.ModifiedBy																		AS CrModBy
					,ISNULL(CONVERT(VARCHAR(10),A.DateModified,103),CONVERT(VARCHAR(10),A.DateCreated,103))					AS CrModDate
					,'Y' as IsMainTable
				 
				FROM NPA_IntegrationDetails A
				INNER JOIN #NCIF			N	 ON N.NCIF_Id = A.NCIF_Id
				LEFT JOIN DimAssetClass    B	 ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
													AND A.AC_AssetClassAlt_Key=B.AssetClassAlt_Key
				LEFT JOIN DimSourceSystem    C   ON (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
													AND A.SrcSysAlt_Key = C.SourceAlt_Key
				WHERE   (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
							 AND A.AccountEntityID=@AccountNo 
							 AND A.CustomerId=@ClientID 
							 AND ISNULL(A.AuthorisationStatus,'A')='A'	

				UNION

				SELECT 
					 A.CustomerId							AS ClientID
					,A.CustomerName						AS CustomerName
					,A.CustomerACID						AS AccountNo
					,A.AccountEntityID					AS AccountEntityID
					,PAN								AS PAN
					,Segment							AS Segment
					,ProductCode						AS SchemeCode
					,CAST(SanctionedLimit AS DECIMAL(18,2))  AS Limit
					,CAST(Balance AS DECIMAL(18,2))     AS O_S
					--,PrincipleOutstanding
					--,Overdue
					--,DPD 
					,isnull(MAXDPD,0)						AS DPD
					,A.AC_AssetClassAlt_Key					AS AssetClass
					,B.AssetClassShortName					AS AssetClassShortName
					,CONVERT(VARCHAR(10),A.AC_NPA_Date,103)	AS NPA_Date
					,CAST(C.Overdue AS DECIMAL(18,2))		AS OverdueAmount
					--,A.AstClsChngRemark                     AS AstClsChngRemark
					,''                     AS AstClsChngRemark
					,C.DrawingPower							AS DrawingPower
					,D.SourceName							AS SourceName
					,A.NCIF_Id								AS ENTCIF
					,A.NCIF_EntityID					    
					,C.ProductType						    AS Facility
				    ,'TblSelect' AS TableName 
					--,ISNULL(A.ModifiedBy,A.CreatedBy)																		AS CrModBy
					,A.ModifiedBy	AS CrModBy
					,ISNULL(CONVERT(VARCHAR(10),A.DateModified,103),CONVERT(VARCHAR(10),A.DateCreated,103))					AS CrModDate
					,'N' as IsMainTable
				FROM NPA_IntegrationDetails_mod A
				INNER JOIN #NCIF N ON N.NCIF_Id = A.NCIF_Id
				LEFT JOIN DimAssetClass    B   ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
													AND A.AC_AssetClassAlt_Key=B.AssetClassAlt_Key

				LEFT JOIN NPA_IntegrationDetails	C  ON (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)	
															AND C.AccountEntityID=A.AccountEntityID	
				LEFT JOIN DimSourceSystem    D   ON (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey)
													AND A.SrcSysAlt_Key = D.SourceAlt_Key								
				
				WHERE   (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
							 AND A.AccountEntityID=@AccountNo 
							 AND A.CustomerId=@ClientID 
							 AND A.AuthorisationStatus IN ('NP','MP','DP','RM')

)A
								

	END
	
ELSE 
	 BEGIN
	       
		   PRINT '16'
			SELECT 
				A.CustomerId											AS ClientID
			   ,G.Segment												AS Segment
			   ,G.ProductCode											AS SchemeCode
			   ,A.CustomerACID											AS AccountNo
			   ,A.AccountEntityID										AS AccountEntityID
			  -- ,G.DPD													AS DPD
			   --,G.DPD_Interest_Not_Serviced
			   --,G.DPD_Overdrawn
			  -- ,G.DPD_Overdue_Loans
			  -- ,G.DPD_Renewals
			   ,G.MaxDPD												AS DPD
			   ,A.AC_AssetClassAlt_Key									AS MOD_AssetClass 
			   ,CONVERT(VARCHAR(10),A.AC_NPA_Date,103)					AS MOD_NPA_Date 
			   ,B.AC_AssetClassAlt_Key									AS AssetClass
			   ,CONVERT(VARCHAR(10),B.AC_NPA_Date,103)					AS NPA_Date
			   ,A.AstClsChngRemark										AS AstClsChngRemark
			   ,A.ModifiedBy											AS MOD_By
			   ,FORMAT(A.DateModified,'dd/MM/yyyy HH:mm:ss'	)			AS Date_MOD
			   ,G.DrawingPower											AS DrawingPower
			   ,D.SourceName											AS SourceName
			   ,PAN														AS PAN
			   ,E.AssetClassShortNameEnum								AS AssetClassName
			   ,C.AssetClassShortNameEnum								AS MOD_AssetClassName
			   ,G.ProductType											AS Facility
			   ,CAST(SanctionedLimit AS DECIMAL(18,2))					AS Limit
			   ,'TblSelect' AS TableName 
			
			FROM NPA_IntegrationDetails_MOD A
			INNER JOIN #NCIF N ON N.NCIF_Id = A.NCIF_Id

			LEFT JOIN NPA_IntegrationDetails_MOD	B  ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
															AND A.CustomerACID=B.CustomerACID
															AND A.CustomerId=B.CustomerId
															AND A.SrcSysAlt_Key=B.SrcSysAlt_Key
															AND B.AuthorisationStatus='O'

			LEFT JOIN NPA_IntegrationDetails        G   ON (G.EffectiveFromTimeKey<=@TimeKey AND G.EffectiveToTimeKey>=@TimeKey)
														    AND G.CustomerACID=A.CustomerACID
															AND G.CustomerId=A.CustomerId	
															AND G.SrcSysAlt_Key=A.SrcSysAlt_Key
																										

			LEFT  JOIN DimAssetClass			    C   ON (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
															AND A.AC_AssetClassAlt_Key=C.AssetClassAlt_Key
															
															
			LEFT JOIN DimSourceSystem				D    ON (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey)
															AND B.SrcSysAlt_Key=D.SourceAlt_Key	

															
			LEFT  JOIN DimAssetClass			    E   ON (E.EffectiveFromTimeKey<=@TimeKey AND E.EffectiveToTimeKey>=@TimeKey)
				   												AND B.AC_AssetClassAlt_Key=E.AssetClassAlt_Key
			

			WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
					  AND A.AccountEntityID=@AccountNo
					  AND A.CustomerId=@ClientID
					  AND A.SrcSysAlt_Key=@SourceSystem
				  AND A.AuthorisationStatus IN ('NP','MP','DP','RM')													
																					
				 
	 END	
					
			
GO