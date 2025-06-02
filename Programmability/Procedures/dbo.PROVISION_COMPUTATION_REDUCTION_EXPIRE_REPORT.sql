SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[PROVISION_COMPUTATION_REDUCTION_EXPIRE_REPORT] 

AS

BEGIN

SELECT 

EntityKey	
,NCIF_Id	
,CustomerId
,AccountEntityID	
,CustomerACID
,SECURED_PERCENTAGE
,UNSECURED_PERCENTAGE
,AuthorisationStatus
,EffectiveFromTimeKey	
,EffectiveToTimeKey	
,CreatedBy	
,convert(varchar,DateCreated,120)	As DateCreated
,ModifiedBy	
,convert(varchar,DateModified,120)   AS DateModified
,ApprovedBy
,convert(varchar,DateApproved,120)   AS DateApproved
,UploadId	
,NCIF_AssetClassAlt_Key

 FROM PROVISION_REDUCTION_HIST


END
GO