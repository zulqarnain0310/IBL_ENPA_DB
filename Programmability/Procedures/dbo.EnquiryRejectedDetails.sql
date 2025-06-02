SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROC [dbo].[EnquiryRejectedDetails]

@DateOfData  VARCHAR(10)
,@SelectLevel VARCHAR(10)
,@EnterValue	 VARCHAR(20)
,@AccountEntityID	INT
,@Result	INT =0   OUTPUT
,@TimeKey	INT=0


AS 



IF @SelectLevel='ACR' --Changed name Asset Class Rejected
	BEGIN
				
			SELECT 
			 A.NCIF_Id										 AS ENTCIF
			,A.CustomerId									 AS ClientID
			,A.CustomerACID									 AS AccountNumber
			,A.CustomerName									 AS CustomerName
			,B.PAN											 AS  PAN
			,B.Segment										 AS Segment
		    ,B.ProductCode								     AS Schemecode
			,B.SanctionedLimit								 AS Limit
			,B.DrawingPower									 AS DrawingPower
			,B.Balance										 AS OS_Balance
			,B.Overdue										 AS OverdueAmount
			,B.MaxDPD										 AS DPD
			,C.AssetClassName							     AS AssetClass
			,CONVERT(VARCHAR(10),A.AC_NPA_Date,103)          AS NPA_Date
			,A.ModifiedBy									 AS ModifiedBy
			,CONVERT(VARCHAR(10),A.DateModified	,103)		 AS DateModified
			,A.AstClsChngRemark								 AS AssetClassChangeRemark
			,A.Remark										 AS RejectRemark
			,A.ApprovedBy									 AS RejectedBy
			,CONVERT(VARCHAR(10),A.DateApproved,103)		 AS DateOfRejection		
			,'TblSearchGrid'							     AS TableName
			FROM 

			NPA_IntegrationDetails_MOD  A

			LEFT JOIN NPA_IntegrationDetails   B  ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
													  AND A.AccountEntityID=B.AccountEntityID
													  AND ISNULL(B.AuthorisationStatus,'A')='A'	

			LEFT JOIN DimAssetClass   C  ON (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
													  AND C.AssetClassAlt_Key = A.AC_AssetClassAlt_Key

			WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
					AND (A.CustomerId=@EnterValue)
					AND (A.AccountEntityID=@AccountEntityID)
				    AND (A.AuthorisationStatus='R')
	END
ELSE
		BEGIN

					SELECT 
					 A.NCIF_Id										 AS ENTCIF
					,A.CustomerName									 AS CustomerName
					,B.PAN											 AS PAN
					,B.Segment										 AS Segment
					,Balance										 AS OS_Balance
					,Overdue										 AS OverdueAmount
					,B.MaxDPD										 AS DPD
					,C.AssetClassName							     AS AssetClass
					,CONVERT(VARCHAR(10),A.MOC_NPA_Date,103)        AS NPA_Date
					,A.ModifiedBy									 AS ModifiedBy
					,CONVERT(VARCHAR(10),A.DateModified	,103)		 AS DateModified
					,D.MocReasonName								 AS AssetClassChangeRemark
					,A.MocAppRemark									 AS RejectRemark
					,A.ApprovedBy									 AS RejectedBy
					,CONVERT(VARCHAR(10),A.DateApproved,103)		 AS DateOfRejection	
					,A.MOC_Remark                                    AS MOC_Remark
					,'TblSearchGrid'							     AS TableName
					FROM MOC_NPA_IntegrationDetails_MOD A
						
					LEFT JOIN 
					(
					
						SELECT NCIF_EntityID,MAX(PAN)PAN,MAX(Segment)Segment,MAX(MaxDPD)MaxDPD	
						,SUM(Balance)Balance,SUM(Overdue)Overdue
						FROM NPA_IntegrationDetails  
						WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
								AND  NCIF_Id=@EnterValue
								AND ISNULL(AuthorisationStatus,'A')='A'
						GROUP BY NCIF_EntityID
					
					)B ON   A.NCIF_EntityID=B.NCIF_EntityID
															   
					LEFT JOIN DimAssetClass   C  ON (C.EffectiveFromTimeKey<=@TimeKey AND C.EffectiveToTimeKey>=@TimeKey)
													 AND C.AssetClassAlt_Key = A.MOC_AssetClassAlt_Key

				    LEFT JOIN DimMocReason	  D  ON (D.EffectiveFromTimeKey<=@TimeKey AND D.EffectiveToTimeKey>=@TimeKey)
													 AND A.MOC_ReasonAlt_Key=D.MocReasonAlt_Key							

					WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey>=@TimeKey)
						AND (A.NCIF_Id=@EnterValue)
						AND (A.AuthorisationStatus='R')
				

		END
GO