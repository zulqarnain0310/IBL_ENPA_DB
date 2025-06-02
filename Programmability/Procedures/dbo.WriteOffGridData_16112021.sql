SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[WriteOffGridData_16112021]
	 @Timekey INT
	,@UserLoginId VARCHAR(100)
	,@Menuid INT
	,@OperationFlag int
	,@UniqueUploadID int
	
AS

--DECLARE  @Timekey INT=24927
--	,@UserLoginId VARCHAR(100)='npachecker'
--	,@Menuid INT=96
--	,@OperationFlag int=20
--	,@UniqueUploadID int=NULL

BEGIN
		SET NOCOUNT ON;


		Set @Timekey=(select CAST(B.timekey as int)
		from SysDataMatrix A
		Inner Join SysDayMatrix B 
		ON A.TimeKey=B.TimeKey
		where A.CurrentStatus='C')

    PRINT @Timekey 

	IF (@OperationFlag=20) 

	BEGIN

	

		   IF OBJECT_ID('TEMPDB..#INT1')IS NOT NULL
			DROP TABLE #INT1

		--SELECT * INTO #INT1 FROM
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
		   WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) AND UploadType='Write Off Data Upload'
		   AND AuthorisationStatus='1A'
	   --FROM ExcelUploadHistory
	   --WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
	   --and UploadType =case when @Menuid='96' then 'Write Off Upload'
				--			ELSE  NULL END 
	   --)   A

		 ORDER BY DateofUpload  DESC

		  SELECT UniqueUploadID ,UploadedBy,CONVERT(VARCHAR(10),DateofUpload,103) AS DateofUpload,AuthorisationStatus,UploadType,
								CrModBy,CrModDate,CrAppBy,CrAppDate,ModAppBy,ModAppDate
                                FROM #INT1 Where AuthorisationStatus Not In ('Authorized','Rejected','Pending')
                                 ORDER BY UniqueUploadID Desc 

		 --,CASE WHEN AuthorisationStatus='NP' THEN CAST(1 AS VARCHAR(50))
		 --                               WHEN AuthorisationStatus='A' THEN CAST(2 AS VARCHAR(50))
		 --                               WHEN AuthorisationStatus='R' THEN CAST(3 AS VARCHAR(50))
			--							WHEN  AuthorisationStatus='1A' THEN CAST(4 AS varchar(50))
		 --                               ELSE (ROW_NUMBER () OVER(ORDER BY(AuthorisationStatus)+CAST(4 AS VARCHAR(50)))) 
		 --                               END ASC
		
		
			

		        --                        SELECT UniqueUploadID ,UploadedBy,CONVERT(VARCHAR(10),DateofUpload,103) AS DateofUpload,AuthorisationStatus,UploadType,
										--CrModBy,CrModDate,CrAppBy,CrAppDate,ModAppBy,ModAppDate
		        --                        FROM #INT1 
		        --                         ORDER BY CASE WHEN AuthorisationStatus='Pending' THEN CAST(1 AS VARCHAR(50))
		        --                        WHEN AuthorisationStatus='Authorized' THEN CAST(2 AS VARCHAR(50))
		        --                        WHEN AuthorisationStatus='Rejected' THEN CAST(3 AS VARCHAR(50))
										--WHEN  AuthorisationStatus='1Authorized' THEN CAST(4 AS VARCHAR(50))
		        --                        ELSE (ROW_NUMBER () OVER(ORDER BY(AuthorisationStatus)+CAST(4 AS VARCHAR(50)))) 
		        --                        END ASC,DateofUpload  DESC,UniqueUploadID Desc

	   --ORDER BY DateofUpload  DESC,CASE WHEN AuthorisationStatus='NP' THEN CAST(1 AS VARCHAR(50))
	   --                             WHEN AuthorisationStatus='A' THEN CAST(2 AS VARCHAR(50))
	   --                             WHEN AuthorisationStatus='R' THEN CAST(3 AS VARCHAR(50))
				--					WHEN AuthorisationStatus='1A' THEN CAST (4 AS VARCHAR(50))
	   --                             ELSE (ROW_NUMBER () OVER(ORDER BY(AuthorisationStatus)+CAST(4 AS VARCHAR(50)))) 
	   --                             END ASC
					
		
		
		                     
	
	   --                             SELECT UniqueUploadID ,UploadedBy,CONVERT(VARCHAR(10),DateofUpload,103) AS DateofUpload,AuthorisationStatus,UploadType,
				--					CrModBy,CrModDate,CrAppBy,CrAppDate,ModAppBy,ModAppDate
	   --                             FROM #INT1 Where AuthorisationStatus Not In ('Authorized','Rejected','Pending')
	   --                              ORDER BY CASE WHEN AuthorisationStatus='Pending' THEN CAST(1 AS VARCHAR(50))
	   --                             WHEN AuthorisationStatus='Authorized' THEN CAST(2 AS VARCHAR(50))
	   --                             WHEN AuthorisationStatus='Rejected' THEN CAST(3 AS VARCHAR(50))
				--					WHEN AuthorisationStatus='1Authorized' THEN CAST(4 AS VARCHAR(50))
	   --                             ELSE (ROW_NUMBER () OVER(ORDER BY(AuthorisationStatus)+CAST(4 AS VARCHAR(50)))) 
	   --                             END ASC,DateofUpload  DESC,UniqueUploadID Desc
				
	END
	  
	ELSE IF (@OperationFlag in (16))

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
		   WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey) AND UploadType='Write Off Data Upload'
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
								 

		 --,CASE WHEN AuthorisationStatus='NP' THEN CAST(1 AS VARCHAR(50))
		 --                               WHEN AuthorisationStatus='A' THEN CAST(2 AS VARCHAR(50))
		 --                               WHEN AuthorisationStatus='R' THEN CAST(3 AS VARCHAR(50))
			--							WHEN  AuthorisationStatus='1A' THEN CAST(4 AS varchar(50))
		 --                               ELSE (ROW_NUMBER () OVER(ORDER BY(AuthorisationStatus)+CAST(4 AS VARCHAR(50)))) 
		 --                               END ASC
		
		
		 --                               SELECT UniqueUploadID ,UploadedBy,CONVERT(VARCHAR(10),DateofUpload,103) AS DateofUpload,AuthorisationStatus,UploadType,
			--							CrModBy,CrModDate,CrAppBy,CrAppDate,ModAppBy,ModAppDate
		 --                               FROM #INT3 Where AuthorisationStatus Not In ('Authorized','Rejected','1Authorized')
		 --                                ORDER BY CASE WHEN AuthorisationStatus='Pending' THEN CAST(1 AS VARCHAR(50))
		 --                               WHEN AuthorisationStatus='Authorized' THEN CAST(2 AS VARCHAR(50))
		 --                               WHEN AuthorisationStatus='Rejected' THEN CAST(3 AS VARCHAR(50))
			--							WHEN  AuthorisationStatus='1Authorized' THEN CAST(4 AS VARCHAR(50))
		 --                               ELSE (ROW_NUMBER () OVER(ORDER BY(AuthorisationStatus)+CAST(4 AS VARCHAR(50)))) 
		 --                               END ASC,DateofUpload  DESC,UniqueUploadID Desc
		   --ORDER BY DateofUpload  DESC,CASE WHEN AuthorisationStatus='NP' THEN CAST(1 AS VARCHAR(50))
		   --                             WHEN AuthorisationStatus='A' THEN CAST(2 AS VARCHAR(50))
		   --                             WHEN AuthorisationStatus='R' THEN CAST(3 AS VARCHAR(50))
					--					WHEN  AuthorisationStatus='1A' THEN CAST(4 AS varchar(50))
		   --                             ELSE (ROW_NUMBER () OVER(ORDER BY(AuthorisationStatus)+CAST(4 AS VARCHAR(50)))) 
		   --                             END ASC
		
		
		   --                             SELECT UniqueUploadID ,UploadedBy,CONVERT(VARCHAR(10),DateofUpload,103) AS DateofUpload,AuthorisationStatus,UploadType,
					--					CrModBy,CrModDate,CrAppBy,CrAppDate,ModAppBy,ModAppDate
		   --                             FROM #INT Where AuthorisationStatus Not In ('Authorized','Rejected','1Authorized')
		   --                              ORDER BY CASE WHEN AuthorisationStatus='Pending' THEN CAST(1 AS VARCHAR(50))
		   --                             WHEN AuthorisationStatus='Authorized' THEN CAST(2 AS VARCHAR(50))
		   --                             WHEN AuthorisationStatus='Rejected' THEN CAST(3 AS VARCHAR(50))
					--					WHEN  AuthorisationStatus='1Authorized' THEN CAST(4 AS VARCHAR(50))
		   --                             ELSE (ROW_NUMBER () OVER(ORDER BY(AuthorisationStatus)+CAST(4 AS VARCHAR(50)))) 
		   --                             END ASC,DateofUpload  DESC,UniqueUploadID Desc
					
		END  
	

	ELSE 
	BEGIN
		select 
			COUNT(*) as Count
			,sum(IntSacrifice) WriteOffAmtPrincipal
			,sum(WriteOffAmt) AS WriteOffAmtInterest
		--ROW_NUMBER()OVER(ORDER BY CUSTOMERID) SrNo
		--,UploadID
		--,DS.SourceName
		--,CONVERT(VARCHAR(10),SDM.DATE,103) AsOnDate
		--,DS.SourceName
		--,NCIF_Id
		--,CustomerID
		--,CustomerAcID
		--,CONVERT(VARCHAR(10),WriteOffDt,103) AS WriteOffDate
		--,WO_PWO AS  WriteOffType
		--,IntSacrifice AS WriteOffAmtPrincipal
		--,WriteOffAmt AS WriteOffAmtInterest
		--,Action		
		 from AdvAcWoDetail_Mod A
			--INNER JOIN DIMSOURCESYSTEM DS
			--	ON DS.SourceAlt_Key=A.SrcSysAlt_Key
			--	AND  (DS.EffectiveFromTimeKey<=@TIMEKEY AND DS.EffectiveToTimeKey>=@TIMEKEY)
			--INNER JOIN SYSDAYMATRIX SDM	
			--	ON SDM.TIMEKEY=A.EffectiveFromTimeKey
		 where A.UploadId=@UniqueUploadID
			AND  (A.EffectiveFromTimeKey<=@TIMEKEY AND A.EffectiveToTimeKey>=@TIMEKEY)

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
   and UploadType =case when @Menuid='1462' then 'Sale to ARC Upload'
   ELSE NULL END
						 
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
END
GO