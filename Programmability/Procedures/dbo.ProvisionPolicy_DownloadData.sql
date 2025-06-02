SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

Create PROCEDURE [dbo].[ProvisionPolicy_DownloadData]	--27030,'SHUBHAM',262,'Provision Policy Upload'
	@Timekey INT
	,@UserLoginId VARCHAR(100)
	,@ExcelUploadId INT
	,@UploadType VARCHAR(50)

AS

BEGIN
		SET NOCOUNT ON;

		SET @Timekey =(Select TimeKey from SysDataMatrix where CurrentStatus='C') 


IF (@UploadType='Provision Policy Upload')

BEGIN
		PRINT 'REV'
		--SELECT * FROM(
		SELECT 'Details' as TableName				 
				,Source_System
				,Source_Alt_Key
				,Scheme_Code
				,upto_3_months
				,From_4_months_upto_6_months
				,From_7_months_upto_9_months
				,From_10_months_upto_12_months
				,Doubtful_1
				,Doubtful_2
				,Doubtful_3
				,Loss
				,Effective_date
				,AuthorisationStatus
				,EffectiveFromTimeKey
				,EffectiveToTimeKey
				,CreatedBy
				,DateCreated
				,ModifiedBy
				,DateModified
				,ApprovedBy
				,DateApproved
		--		,D2Ktimestamp
				,ApprovedByFirstLevel
				,DateApprovedFirstLevel
				,ProvisionAlt_key
				,ProvisionUnSecured
				,UploadID
				FROM DIMPROVISIONPOLICY_mod
				WHERE UploadId=@ExcelUploadId
				AND EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >= @Timekey
			

						
			 SELECT 
					'Summary' as TableName			
					 ,COUNT(*) as Count
					,COUNT(Scheme_Code)	[SchemeCode Count]
			 FROM DIMPROVISIONPOLICY_MOD A			
			 WHERE A.UploadId=@ExcelUploadId
			   AND A.EffectiveFromTimeKey<=@TIMEKEY 
			   AND A.EffectiveToTimeKey>=@TIMEKEY



END



END
GO