SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ProvisionPolicy_DownloadData_Live]
@Timekey INT

AS

BEGIN
		SET NOCOUNT ON;
		SET @Timekey =(Select TimeKey from SysDataMatrix where CurrentStatus='C') 

	PRINT 'Live Data from main table'
		SELECT 'Details' as TableName				 
				,Source_System
			--	,Source_Alt_Key
				,CASE WHEN Scheme_Code IS NULL THEN 'NULL' ELSE Scheme_Code END AS Scheme_Code
				,CAST(upto_3_months as decimal(18,4))*100 as upto_3_months
				,CAST(From_4_months_upto_6_months as decimal(18,4))*100 as From_4_months_upto_6_months
				,CAST(From_7_months_upto_9_months as decimal(18,4))*100 as From_7_months_upto_9_months
				,CAST(From_10_months_upto_12_months as decimal(18,4))*100 as From_10_months_upto_12_months
				,CAST(Doubtful_1 as decimal(18,4))*100 as Doubtful_1
				,CAST(Doubtful_2 as decimal(18,4))*100 as Doubtful_2
				,CAST(Doubtful_3 as decimal(18,4))*100 as Doubtful_3
				,CAST(Loss as decimal(18,4))*100 as Loss	 					
				,CAST(ProvisionUnSecured as decimal(18,4))*100 as ProvisionUnSecured			
		--		,Effective_date
				,CASE WHEN  AuthorisationStatus='A' THEN 'Authorized'
					 WHEN  AuthorisationStatus='R' THEN 'Rejected'
					 WHEN  AuthorisationStatus='1A' THEN '1Authorized'
					 WHEN  AuthorisationStatus='NP' THEN 'Pending' ELSE NULL END AS AuthorisationStatus		
		--		,EffectiveFromTimeKey
		--		,EffectiveToTimeKey
				,CASE WHEN CreatedBy IS NULL THEN 'NULL' ELSE CreatedBy END AS CreatedBy
				, DateCreated   AS DateCreated
				,CASE WHEN ModifiedBy IS NULL THEN 'NULL' ELSE ModifiedBy END AS ModifiedBy
				, DateModified  AS DateModified
				,CASE WHEN ApprovedBy IS NULL THEN 'NULL' ELSE ApprovedBy END AS ApprovedBy
				,  DateApproved as DateApproved
		--		,CASE WHEN IS NULL THEN 'NULL' ELSE END AS D2Ktimestamp
				,CASE WHEN ApprovedByFirstLevel IS NULL THEN 'NULL' ELSE ApprovedByFirstLevel END AS ApprovedByFirstLevel
				, DateApprovedFirstLevel AS DateApprovedFirstLevel
		--		,ProvisionAlt_key
				
			--	,UploadID
			FROM DIMPROVISIONPOLICY
			WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey >= @Timekey
			

			--Count of Existing Scheme Codes			
			 SELECT 
					'Summary' as TableName								 
					,COUNT(1)	[Live SchemeCode Count]
			 FROM DIMPROVISIONPOLICY			
			 WHERE	EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey



END

GO