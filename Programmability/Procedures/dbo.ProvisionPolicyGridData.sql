SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

Create PROCEDURE [dbo].[ProvisionPolicyGridData] --27030,'dm338',2026,20,2972
	 @Timekey INT
	,@UserLoginId VARCHAR(100)
	,@Menuid INT
	,@OperationFlag int
	,@UniqueUploadID INT

AS

BEGIN
		SET NOCOUNT ON;

		SET @Timekey =(Select TimeKey from SysDataMatrix where CurrentStatus='C') 
	    PRINT @Timekey 
IF (@Menuid=2026)
BEGIN
	IF (@OperationFlag=20) 
	BEGIN
			IF OBJECT_ID('TEMPDB..#INT1')IS NOT NULL
			DROP TABLE #INT1
				
			SELECT  
				 UniqueUploadID
				,UploadedBy
				,CONVERT(VARCHAR(10),DateofUpload,103) AS DateofUpload		
				,CASE WHEN  AuthorisationStatus='A' THEN 'Authorized'
					 WHEN  AuthorisationStatus='R' THEN 'Rejected'
					 WHEN  AuthorisationStatus='1A' THEN '1Authorized'
					 WHEN  AuthorisationStatus='NP' THEN 'Pending' ELSE NULL END AS AuthorisationStatus				
				,UploadType
				,IsNull(ModifyBy,CreatedBy)as CrModBy
				,IsNull(DateModified,DateCreated)as CrModDate
				,ISNULL(ApprovedBy,CreatedBy) as CrAppBy
				,ISNULL(DateApproved,DateCreated) as CrAppDate
				,ISNULL(ApprovedBy,ModifyBy) as ModAppBy
				,ISNULL(DateApproved,DateModified) as ModAppDate				
			INTO #INT1			
			FROM ExcelUploadHistory
			WHERE   EffectiveFromTimeKey<=@Timekey
			    AND EffectiveToTimeKey>=@Timekey 
				AND UploadType='Provision Policy Upload'
				AND AuthorisationStatus='1A'			
			ORDER BY DateofUpload  DESC
		              

            SELECT 
		        UniqueUploadID 
				,UploadedBy
				,CONVERT(VARCHAR(10),DateofUpload,103) AS DateofUpload
				,AuthorisationStatus
				,UploadType
				,CrModBy
				,CrModDate
				,CrAppBy
				,CrAppDate
				,ModAppBy
				,ModAppDate
            FROM #INT1
		    Where AuthorisationStatus Not In ('Authorized','Rejected','Pending')
            ORDER BY UniqueUploadID Desc 
								 
	END
  

	
	ELSE
	IF (@OperationFlag =16)
	BEGIN
			print'1'
			PRINT 'OPERATIONFLAG 16'
			
					IF OBJECT_ID('TEMPDB..#INT3')IS NOT NULL
					DROP TABLE #INT3

			
			 SELECT  
					UniqueUploadID
				   ,UploadedBy
				   ,CONVERT(VARCHAR(10),DateofUpload,103) AS DateofUpload,			 
					CASE WHEN  AuthorisationStatus='A' THEN 'Authorized'
						 WHEN   AuthorisationStatus='R' THEN 'Rejected'
						 WHEN  AuthorisationStatus='1A' THEN '1Authorized'
						 WHEN  AuthorisationStatus='NP' THEN 'Pending'
						 WHEN  AuthorisationStatus='NP' THEN 'Pending'
						 WHEN  AuthorisationStatus='MP' THEN 'Pending' ELSE NULL END AS AuthorisationStatus
				
				   ,UploadType
			 	   ,IsNull(ModifyBy,CreatedBy)as CrModBy
				   ,IsNull(DateModified,DateCreated)as CrModDate
				   ,ISNULL(ApprovedBy,CreatedBy) as CrAppBy
				   ,ISNULL(DateApproved,DateCreated) as CrAppDate
				   ,ISNULL(ApprovedBy,ModifyBy) as ModAppBy
				   ,ISNULL(DateApproved,DateModified) as ModAppDate
				
			 INTO #INT3				
			 FROM ExcelUploadHistory
			 WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) AND UploadType='Provision Policy Upload'
			 AND AuthorisationStatus IN('NP','MP','DP','R','RM')
			 ORDER BY DateofUpload  DESC


			 SELECT 
					 UniqueUploadID 
					,UploadedBy
					,CONVERT(VARCHAR(10)
					,DateofUpload,103) AS DateofUpload
					,AuthorisationStatus
					,UploadType
		            ,CrModBy
					,CrModDate
					,CrAppBy
					,CrAppDate
					,ModAppBy
					,ModAppDate
             FROM #INT3 
			 Where AuthorisationStatus Not In ('Authorized','Rejected','1Authorized')
             ORDER BY UniqueUploadID Desc
									 
	END  

	ELSE
	IF(@OperationFlag=2)
	BEGIN
					
			 SELECT 					
					 COUNT(*) as Count
				--	,COUNT(Source_Alt_Key)	[Count of Records]
			 FROM DIMPROVISIONPOLICY_MOD A			
			 WHERE A.UploadId=@UniqueUploadID
			   AND A.EffectiveFromTimeKey<=@Timekey 
			   AND A.EffectiveToTimeKey>=@Timekey

	END 

END
END
  
GO