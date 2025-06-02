SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
Create PROCEDURE [dbo].[AccMOCGridData_04052023]
	 @Timekey INT
	,@UserLoginId VARCHAR(100)
	,@Menuid INT
	,@OperationFlag int
	,@UniqueUploadID INT

AS
--DECLARE @Timekey INT=24927
--	,@UserLoginId VARCHAR(100)='superadmin'
--	,@Menuid INT=101
--	,@OperationFlag int=16
--	,@UniqueUploadID INT=0

BEGIN
		SET NOCOUNT ON;

		SET @Timekey =(Select TimeKey from SysDataMatrix where CurrentStatus_MOC='C' and MOC_Initialised='Y') 
--  Set @Timekey=(select CAST(B.timekey as int)from SysDataMatrix A
--Inner Join SysDayMatrix B ON A.TimeKey=B.TimeKey
-- where A.CurrentStatus='C')
  --SET @Timekey =(Select LastMonthDateKey from SysDayMatrix where Timekey=@Timekey) 


    PRINT @Timekey 

	IF (@OperationFlag=20) 

	BEGIN
		 IF OBJECT_ID('TEMPDB..#INT1')IS NOT NULL
			DROP TABLE #INT1

			--SELECT * INTO #INT1 FROM(
		SELECT  UniqueUploadID,UploadedBy
		,CONVERT(VARCHAR(10),DateofUpload,103) AS DateofUpload,
		--,DateofUpload,
		CASE WHEN  AuthorisationStatus='A' THEN 'Authorized'
				WHEN  AuthorisationStatus='R' THEN 'Rejected'
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
			
		INTO #INT1
		
		FROM ExcelUploadHistory
		   WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) AND UploadType='Account MOC Upload'
		   AND AuthorisationStatus='1A'
		--FROM ExcelUploadHistory
		--WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
		--and UploadType =CASE WHEN @Menuid=99 THEN'Buyout Upload'
		--						ELSE  NULL END 
		--)   A
		ORDER BY DateofUpload  DESC
		--,CASE WHEN AuthorisationStatus='NP' THEN CAST(1 AS VARCHAR(50))
  --                              WHEN AuthorisationStatus='A' THEN CAST(2 AS VARCHAR(50))
  --                              WHEN AuthorisationStatus='R' THEN CAST(3 AS VARCHAR(50))
		--						WHEN AuthorisationStatus='1A' THEN CAST (4 AS VARCHAR(50))
  --                              ELSE (ROW_NUMBER () OVER(ORDER BY(AuthorisationStatus)+CAST(4 AS VARCHAR(50)))) 
  --                              END ASC
				
	
	
	                     

                                SELECT UniqueUploadID ,UploadedBy,CONVERT(VARCHAR(10),DateofUpload,103) AS DateofUpload,AuthorisationStatus,UploadType,
								CrModBy,CrModDate,CrAppBy,CrAppDate,ModAppBy,ModAppDate
                                FROM #INT1 Where AuthorisationStatus Not In ('Authorized','Rejected','Pending')
                                 ORDER BY UniqueUploadID Desc 
								 
								-- CASE WHEN AuthorisationStatus='Pending' THEN CAST(1 AS VARCHAR(50))
        --                        WHEN AuthorisationStatus='Authorized' THEN CAST(2 AS VARCHAR(50))
        --                        WHEN AuthorisationStatus='Rejected' THEN CAST(3 AS VARCHAR(50))
								--WHEN AuthorisationStatus='1Authorized' THEN CAST(4 AS VARCHAR(50))
        --                        ELSE (ROW_NUMBER () OVER(ORDER BY(AuthorisationStatus)+CAST(4 AS VARCHAR(50)))) 
        --                        END ASC,DateofUpload  DESC,UniqueUploadID Desc
			
		END
  
		ELSE

		IF (@OperationFlag in (16))

		BEGIN
		print'1'
		PRINT 'OPERATIONFLAG 16'
		
			IF OBJECT_ID('TEMPDB..#INT3')IS NOT NULL
				DROP TABLE #INT3

		--SELECT * INTO #INT FROM(
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
		   WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) AND UploadType='Account MOC Upload'
		   AND AuthorisationStatus IN('NP','MP','DP','R','RM')
		 --FROM ExcelUploadHistory
		 --WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
		 --and UploadType =CASE WHEN @Menuid=99 THEN'Buyout Upload'
			--					ELSE  NULL END 
		 --)   A
		 ORDER BY DateofUpload  DESC
		 --,CASE WHEN AuthorisationStatus='NP' THEN CAST(1 AS VARCHAR(50))
   --                             WHEN AuthorisationStatus='A' THEN CAST(2 AS VARCHAR(50))
   --                             WHEN AuthorisationStatus='R' THEN CAST(3 AS VARCHAR(50))
			--					WHEN  AuthorisationStatus='1A' THEN CAST(4 AS varchar(50))
   --                             ELSE (ROW_NUMBER () OVER(ORDER BY(AuthorisationStatus)+CAST(4 AS VARCHAR(50)))) 
   --                             END ASC


                                SELECT UniqueUploadID ,UploadedBy,CONVERT(VARCHAR(10),DateofUpload,103) AS DateofUpload,AuthorisationStatus,UploadType,
								CrModBy,CrModDate,CrAppBy,CrAppDate,ModAppBy,ModAppDate
                                FROM #INT3 Where AuthorisationStatus Not In ('Authorized','Rejected','1Authorized')
                                 ORDER BY UniqueUploadID Desc
								 
								-- CASE WHEN AuthorisationStatus='Pending' THEN CAST(1 AS VARCHAR(50))
        --                        WHEN AuthorisationStatus='Authorized' THEN CAST(2 AS VARCHAR(50))
        --                        WHEN AuthorisationStatus='Rejected' THEN CAST(3 AS VARCHAR(50))
								--WHEN  AuthorisationStatus='1Authorized' THEN CAST(4 AS VARCHAR(50))
        --                        ELSE (ROW_NUMBER () OVER(ORDER BY(AuthorisationStatus)+CAST(4 AS VARCHAR(50)))) 
        --                        END ASC,DateofUpload  DESC,UniqueUploadID Desc
			
		END  

		ELSE 
		BEGIN
				

				select 
			COUNT(*) as Count
			,Sum(isnull(cast(Balance as float),0))Balance
			,Sum(isnull(cast(ApprRV as decimal(22,2)),0))SecurityValue		
		 from NPA_IntegrationDetails_mod A
			
		 where A.UploadId=@UniqueUploadID
			AND  (A.EffectiveFromTimeKey<=@TIMEKEY AND A.EffectiveToTimeKey>=@TIMEKEY)

		END 

END
  
 
 /*Select @Timekey=Max(Timekey) from dbo.SysDayMatrix  
  where  Date=cast(getdate() as Date)

    PRINT @Timekey  


  SELECT * INTO #INT FROM(
   SELECT  UniqueUploadID,UploadedBy
   ,CONVERT(VARCHAR(10),DateofUpload,103) AS DateofUpload,
   --,DateofUpload,
   CASE WHEN  AuthorisationStatus='A' THEN 'Authorized'
		WHEN   AuthorisationStatus='R' THEN 'Rejected'
		WHEN  AuthorisationStatus='NP' THEN 'Pending' ELSE NULL END AS AuthorisationStatus
	---,Action
	,UploadType
	
   FROM ExcelUploadHistory
   WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
   and UploadType =CASE WHEN @Menuid=1466 THEN'Buyout Upload'
						ELSE  NULL END 
   )   A
   ORDER BY DateofUpload  DESC,CASE WHEN AuthorisationStatus='NP' THEN CAST(1 AS VARCHAR(50))
                                WHEN AuthorisationStatus='A' THEN CAST(2 AS VARCHAR(50))
                                WHEN AuthorisationStatus='R' THEN CAST(3 AS VARCHAR(50))
                                ELSE (ROW_NUMBER () OVER(ORDER BY(AuthorisationStatus)+CAST(3 AS VARCHAR(50)))) 
                                END ASC
				
	
	
	                     

                                SELECT UniqueUploadID ,UploadedBy,CONVERT(VARCHAR(10),DateofUpload,103) AS DateofUpload,AuthorisationStatus,UploadType
                                FROM #INT Where AuthorisationStatus Not In ('Authorized','Rejected')
                                 ORDER BY CASE WHEN AuthorisationStatus='Pending' THEN CAST(1 AS VARCHAR(50))
                                WHEN AuthorisationStatus='Authorized' THEN CAST(2 AS VARCHAR(50))
                                WHEN AuthorisationStatus='Rejected' THEN CAST(3 AS VARCHAR(50))
                                ELSE (ROW_NUMBER () OVER(ORDER BY(AuthorisationStatus)+CAST(3 AS VARCHAR(50)))) 
                                END ASC,DateofUpload  DESC,UniqueUploadID Desc
			
  

END */
GO