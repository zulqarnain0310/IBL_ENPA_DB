SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[DocumentDetailSelect]
--DECLARE 
	@EntityId  varchar(10)=NULL,    --PAN
    @MenuId      INT=NULL,
	@TimeKey            INT=NULL,
	@Mode				INT=NULL
	--@EvententityId		INT=NULL,
	--@DocumentTypeAlt_Key INT=NULL,
	--@LenderentityId		 INT=NULL



AS
	BEGIN
	
	IF @Mode = 16
	  BEGIN
			print '2'
			SELECT	 
				 ADM.EntityId     --Pan   
				,ADM.NCIF_Id AS ENTCIF
				,ADM.NCIF_EntityID
				,ADM.MenuId
				,ADM.DocumentAlt_key
				,ADM.DocumentTypeAlt_Key
				--,DP.ParameterName DocumentType
				,ADM.DocLocation
				,ADM.DocTitle		
				,ADM.Remark
				,CONVERT(VARCHAR(10),ADM.DocDate,103) AS DocumentUploadDate
				,ADM.DocExtn
				,ADM.DocLocation
				,ADM.AuthorisationStatus	
				,'N' AS IsMainTable
				, CASE WHEN ISNULL(ADM.ModifiedBy,'')='' THEN ADM.CreatedBy ELSE ADM.ModifiedBy END  AS CreatedModifiedBy
				,'N' as InUpDeNo
				,'Y' as DBCheck
				--,ADM.EventEntityId as EventSequenceId
				,CONVERT(VARCHAR(10),ADM.DocumentTypeDt,103)DocumentTypeDt
				--,LenderEntityId
		FROM	DocumentUploadDetails ADM
		WHERE   	
				 (ADM.EffectiveFromTimeKey <=@TimeKey AND ADM.EffectiveToTimeKey >=@TimeKey)				       
				AND ADM.NCIF_Id=@EntityId									
		
	  END	  
	  ELSE IF @Mode = 2
	  BEGIN
	  print '3'
			SELECT	 
				 ADM.EntityId
				,ADM.NCIF_Id AS ENTCIF
				,ADM.NCIF_EntityID
				,ADM.MenuId
				,ADM.DocumentAlt_key
				,ADM.DocumentTypeAlt_Key
				--,DP.ParameterName DocumentType
				,ADM.DocLocation
				,ADM.DocTitle		
				,ADM.Remark
				,CONVERT(VARCHAR(10),ADM.DocDate,103) AS DocumentUploadDate
				,ADM.DocExtn
				,ADM.DocLocation
				,ADM.AuthorisationStatus	
				,'Y' AS IsMainTable
				, CASE WHEN ISNULL(ADM.ModifiedBy,'')='' THEN ADM.CreatedBy ELSE ADM.ModifiedBy END  AS CreatedModifiedBy
				,'N' as InUpDeNo
				,'Y' as DBCheck
				--,ADM.EventEntityId	as EventSequenceId
				,CONVERT(VARCHAR(10),ADM.DocumentTypeDt,103)DocumentTypeDt
				--,LenderEntityId
		FROM DocumentUploadDetails ADM
		
		--LEFT JOIN DimParameter DP ON (DP.EffectiveFromTimeKey<=@TimeKey AND DP.EffectiveToTimeKey>=@TimeKey)
		--							  AND DP.DimParameterName ='DimDocumenttype'
		--							  AND DP.ParameterAlt_Key=ADM.DocumentTypeAlt_Key

		WHERE   
		---ADM.EntityId = @EntityId 
				 (ADM.EffectiveFromTimeKey <=@TimeKey AND ADM.EffectiveToTimeKey >=@TimeKey)		
		       AND ISNULL(ADM.AuthorisationStatus,'A')='A' 
				--AND ADM.DocumentTypeAlt_Key=@DocumentTypeAlt_Key
				AND ADM.NCIF_Id=@EntityId
				--AND ADM.EvententityId=@EvententityId
				--AND ISNULL(ADM.LenderEntityId,0)=ISNULL(@LenderentityId,0)	order by	ADM.DocumentTypeDt
										
						


	  END
	  
END
	  
   
 
GO