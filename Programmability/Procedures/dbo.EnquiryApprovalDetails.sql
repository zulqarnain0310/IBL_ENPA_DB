SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC	[dbo].[EnquiryApprovalDetails]
 @DateOfData VARCHAR(10)
,@SelectLevel VARCHAR(10)
,@EnterValue  VARCHAR(20)
,@AccountEntityId  INT
,@TimeKey  INT
,@UserID varchar(10)
,@Result int=0 output

	
AS

DECLARE @SearchLevel VARCHAR(10)
	                   IF OBJECT_ID('Tempdb..#temp') IS NOT NULL
				       DROP TABLE   #temp

		             SELECT 
		             		Split.a.value('.', 'VARCHAR(100)') AS String  ,ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS SNO 
		             		INTO #temp
		             FROM  
		             (
		                 SELECT 
		                     CAST ('<M>' + REPLACE(@SelectLevel, ',', '</M><M>') + '</M>' AS XML) AS Data  
		                
		             ) AS A CROSS APPLY Data.nodes ('/M') AS Split(a); 

		          SET @SearchLevel=(SELECT String from #temp WHERE SNO=2)
				  SET @SelectLevel=(SELECT String from #temp WHERE SNO=1)
				  
				  PRINT @SearchLevel
				  PRINT @SelectLevel

IF @SelectLevel='M'
	BEGIN              

				  	  --SELECT * FROM #temp
				  

																		
							
							SELECT 
							 A.NCIF_Id											AS ENTCIF
							,MAX(A.Segment)										AS Segment
							,A.ModifiedBy										AS ModifiedBy
							,CONVERT(VARCHAR(10),A.DateModified	,103)			AS DateModified
							,A.ApprovedBy										AS ApprovedBy
							,CONVERT(VARCHAR(10),A.DateApproved,103)			AS DateApproved
							,M.MocReasonName									AS AssetClassChangeRemark
							,B.AssetClassName									AS AssetClass
							,CONVERT(VARCHAR(10),A.MOC_NPA_Date,103)   AS NPA_Date
							,D.AssetClassName									AS MOD_AssetClass
							,CONVERT(VARCHAR(10),A.NCIF_NPA_Date,103)			AS MOD_NPA_Date
						    ,'TblSearchGrid' AS TableName 
							,SUM(A.Balance)										As OS_Balance
							,SUM(A.Overdue)										AS OverdueAmount
							,MAX(A.MaxDPD)										AS DPD	
							,A.MocAppRemark										AS ApprRemark		
							,A.MOC_Remark											AS MOC_Remark									
																
							FROM NPA_IntegrationDetails  A

							LEFT JOIN DimAssetClass     B				ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
																			AND B.AssetClassAlt_Key=A.MOC_AssetClassAlt_Key
							
							--LEFT JOIN MOC_NPA_IntegrationDetails_MOD C  ON (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
							--												AND C.NCIF_Id=A.NCIF_Id
							--												AND C.AuthorisationStatus='O'
							
							LEFT JOIN DimAssetClass     D				ON (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey)
																			AND D.AssetClassAlt_Key=A.NCIF_AssetClassAlt_Key

							LEFT JOIN DimMocReason		M				ON (M.EffectiveFromTimeKey<=@TimeKey AND M.EffectiveToTimeKey>=@TimeKey)
																			AND M.MocReasonAlt_Key=A.MOC_ReasonAlt_Key													

																				

							WHERE  (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey) 
									AND ISNULL(A.AuthorisationStatus,'A')='A'
									--AND A.NCIF_Id=@EnterValue
									AND (CASE WHEN @SearchLevel = 'E' AND A.NCIF_Id = @EnterValue THEN 1 
                                        WHEN @SearchLevel = 'P' AND A.PAN=@EnterValue THEN 1 END )= 1
									AND A.ApprovedBy IS NOT NULL
									AND A.DateApproved IS NOT NULL

							GROUP BY 	
							 A.NCIF_Id		
							,A.ModifiedBy
							,A.DateModified	
							,A.ApprovedBy				
							,A.DateApproved				
							,M.MocReasonName		
							,A.NCIF_NPA_Date			
							,A.MOC_NPA_Date
							,A.MocAppRemark		
							,B.AssetClassName
							,D.AssetClassName	
							,A.MOC_Remark			
							
							
										
					
								
	END	
ELSE
	BEGIN
			
				SELECT 
				 A.NCIF_Id												AS ENTCIF
				,A.CustomerId                                           AS ClientID
				,A.CustomerACID											AS AccountNumber
				,A.CustomerName                                         AS CustomerName
				,A.PAN													AS PAN
				,A.Segment												AS Segment
				,A.ProductType										    AS Schemecode
				,A.SanctionedLimit									    AS Limit
				,A.DrawingPower											AS DrawingPower
				,A.Balance											    AS OS_Balance
				,A.Overdue												AS OverdueAmount
			    ,A.MaxDPD												AS DPD
				,E.ModifiedBy											AS ModifiedBy
				,CONVERT(VARCHAR(10),E.DateModified,103)				AS DateModified
				,A.ApprovedBy											AS ApprovedBy
				,A.AstClsChngRemark										AS AssetClassChangeRemark
				,B.AssetClassName									    AS AssetClass
				,CONVERT(VARCHAR(10),A.AC_NPA_Date,103)				    AS NPA_Date
				,D.AssetClassName									    AS MOD_AssetClass
				,CONVERT(VARCHAR(10),C.AC_NPA_Date,103)					AS MOD_NPA_Date
				,E.ApprovedBy										    AS ApprovedBy
				,CONVERT(VARCHAR(10),E.DateApproved,103)			    AS DateApproved
				,A.AstClsAppRemark										AS ApprRemark
				,'TblSearchGrid' AS TableName 

				FROM NPA_IntegrationDetails  A

				LEFT JOIN DimAssetClass     B				ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
																AND B.AssetClassAlt_Key=A.AC_AssetClassAlt_Key
			
				LEFT JOIN NPA_IntegrationDetails_MOD C      ON (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
																AND C.AccountEntityID=A.AccountEntityID
																AND C.AuthorisationStatus='O'

				LEFT JOIN NPA_IntegrationDetails_MOD  E     ON (E.EffectiveFromTimeKey<=@TimeKey AND E.EffectiveToTimeKey>=@TimeKey)
																AND (E.AccountEntityID=A.AccountEntityID)
																AND (E.AuthorisationStatus)='A'													
			
				LEFT JOIN DimAssetClass     D				ON (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey)
																AND D.AssetClassAlt_Key=C.AC_AssetClassAlt_Key

				WHERE  (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey) 
						AND A.AccountEntityID = @AccountEntityId
						AND A.AuthorisationStatus='A'
						AND A.ApprovedBy IS NOT NULL
						AND A.DateApproved IS NOT NULL
						

		
		
			END		

SET @Result=1
RETURN @Result
	
	
GO