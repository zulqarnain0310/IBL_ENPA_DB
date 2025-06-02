SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[BranchMasterUploadGridData]
	 @Timekey INT
	,@UserLoginId VARCHAR(100)
	,@Menuid INT
	,@OperationFlag int
	,@UniqueUploadID int
	
AS


BEGIN
		SET NOCOUNT ON;


		Set @Timekey=(select CAST(B.timekey as int)
		from SysDataMatrix A
		Inner Join SysDayMatrix B 
		ON A.TimeKey=B.TimeKey
		where A.CurrentStatus='C')

    PRINT @Timekey 

		  
	 IF (@OperationFlag in (16))

		BEGIN
		print'1'
		PRINT 'OPERATIONFLAG 16'
		
			IF OBJECT_ID('TEMPDB..#INT3')IS NOT NULL
				DROP TABLE #INT3
		 -- SELECT * 
		  --INTO #INT FROM
		   SELECT  UniqueUploadID,UploadedBy
		   ,CONVERT(VARCHAR(10),DateofUpload,103) AS DateofUpload,
		   --,DateofUpload,
		   CASE WHEN  AuthorisationStatus='A' THEN 'Authorized'
				WHEN   AuthorisationStatus='R' THEN 'Rejected'
				WHEN  AuthorisationStatus='1A' THEN '1Authorized'
				WHEN  AuthorisationStatus='NP' THEN 'Pending' ELSE NULL END AS AuthorisationStatus
			---,Action
			,UploadType
			,IsNull(ModifyBy,CreatedBy)as CrModBy
			,IsNull(DateModified,DateCreated)as CrModDate
			,ISNULL(ApprovedBy,CreatedBy) as CrAppBy
			,ISNULL(DateApproved,DateCreated) as CrAppDate
			,ISNULL(ApprovedBy,ModifyBy) as ModAppBy
			,ISNULL(DateApproved,DateModified) as ModAppDate

			INTO #INT3
			
		   FROM ExcelUploadHistory
		   WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) AND UploadType='Branch_Master_Upload'
		   AND AuthorisationStatus IN('NP','MP','DP','R','RM')
		   --and UploadType =case when @Menuid='96' then 'Write Off Upload'
								--ELSE  NULL END 
		   --)   A
		 --  FROM ExcelUploadHistory
		 --WHERE --UniqueUploadID=@UniqueUploadID		    
		 --  AND (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey)

		 ORDER BY DateofUpload  DESC

		 SELECT UniqueUploadID ,UploadedBy,CONVERT(VARCHAR(10),DateofUpload,103) AS DateofUpload,AuthorisationStatus,UploadType,
								CrModBy,CrModDate,CrAppBy,CrAppDate,ModAppBy,ModAppDate
                                FROM #INT3 Where AuthorisationStatus Not In ('Authorized','Rejected','1Authorized')
                                 ORDER BY UniqueUploadID Desc
								 

	
		END  
	

	ELSE 
	BEGIN
		select 
			COUNT(*) as Count
			--,'BranchCodecount' as Tablename		
		 from DimBranch_Mod A
		 where A.UploadId=@UniqueUploadID
			AND  (A.EffectiveFromTimeKey<=@TIMEKEY AND A.EffectiveToTimeKey>=@TIMEKEY)

	END 


END
GO