SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE  [dbo].[ProvisionPolicyStageDataInUp_11112024] 
	@Timekey INT,
	@UserLoginID VARCHAR(100),
	@OperationFlag INT,
	@MenuId INT,
	@AuthMode	CHAR(1),
	@filepath VARCHAR(MAX),
	@EffectiveFromTimeKey INT,
	@EffectiveToTimeKey	INT,
    @Result		INT=0 OUTPUT,
	@UniqueUploadID INT
	--@Authlevel varchar(5)

AS


BEGIN
SET DATEFORMAT DMY
	SET NOCOUNT ON;
 
	SET @Timekey =(SELECT TimeKey FROM SysDataMatrix WHERE CurrentStatus='C' )
	PRINT @TIMEKEY

	SET @EffectiveFromTimeKey=@TimeKey
	SET @EffectiveToTimeKey=@TimeKey


	DECLARE @FilePathUpload	VARCHAR(100)
				   SET @FilePathUpload=@UserLoginId+'_'+@filepath
					PRINT '@FilePathUpload'
					PRINT @FilePathUpload

BEGIN TRY
		
IF (@MenuId=2026)
BEGIN

	IF(@OperationFlag=1)
	BEGIN

	IF NOT (EXISTS (SELECT 1 FROM ProvisionPolicy_stg  WHERE filname=@FilePathUpload))
					BEGIN
							 --Rollback tran
							SET @Result=-8
							RETURN @Result
						Print 'Roll Back'
					END		
				    
	
			-----use of sequence-----
			DECLARE @ExcelUploadId int
			SELECT @ExcelUploadId=next value for [dbo].[Seq_UploadId]  
			SELECT @ExcelUploadId
	
			SET DATEFORMAT DMY
	
	IF EXISTS(SELECT 1 FROM ProvisionPolicy_stg WHERE filname=@FilePathUpload)
		BEGIN
print '0'			
		    SET DATEFORMAT DMY
	
		/*FOR NEW SCHEME CODE ADDITION*/
		
				  
								INSERT INTO  DIMPROVISIONPOLICY_mod (
								 Source_System
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
							--	,ProvisionAlt_key
								,ProvisionUnSecured
								,UploadID
								,IsUpload
								)
								
								SELECT
								 S.SourceName
								,S.SourceAlt_Key
								,P.SchemeCode
								,CAST(P.upto3months as decimal(18,2))/100 as upto_3_months
								,CAST(P.From4monthsupto6months as decimal(18,2))/100 as From_4_months_upto_6_months
								,CAST(P.From7monthsupto9months as decimal(18,2))/100 as From_7_months_upto_9_months
								,CAST(P.From10monthsupto12months as decimal(18,2))/100 as From_10_months_upto_12_months
								,CAST(P.Doubtful1 as decimal(18,2))/100 as Doubtful_1
								,CAST(P.Doubtful2 as decimal(18,2))/100 as Doubtful_2
								,CAST(P.Doubtful3 as decimal(18,2))/100 as Doubtful_3
								,CAST(P.Loss as decimal(18,2))/100 as Loss	 					
								,'YYYY'
								,'NP'
								,@Timekey
								,49999
								,@UserLoginID
								,GETDATE()
						--		,@ProvisionAlt_key
								,CAST(P.ProvisionUnSecured as decimal(18,2))/100 as ProvisionUnSecured
								,@ExcelUploadId
								,'Y'
								
								FROM ProvisionPolicy_stg P
								LEFT JOIN DimSourceSystem S ON P.SourceSystem = S.SourceName	
								WHERE P.filname=@FilePathUpload
								AND P.Action IN('A')
print '1'					
	/*TO UPDATE THE PERCENTAGES OF EXITSTING SCHEME CODE FROM MAIN TABLE--SHUBHAM KAMBLE*/
			SET IDENTITY_INSERT DIMPROVISIONPOLICY_mod ON;
						INSERT INTO  DIMPROVISIONPOLICY_mod (
										 Source_System
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
										,ProvisionAlt_key
										,ProvisionUnSecured
										,UploadID
										,IsUpload
										)
										
										SELECT 
										 s.SourceName
										,S.SourceAlt_Key
										,DP.Scheme_Code
										,Case When ISNULL(P.upto3months,'')='' Then CAST(DP.upto_3_months AS DECIMAL(18,2)) Else CAST(P.upto3months as decimal(18,2))/100  END upto_3_months
										,Case When ISNULL(P.From4monthsupto6months,'')='' Then CAST(DP.From_4_months_upto_6_months AS DECIMAL(18,2)) Else CAST(P.From4monthsupto6months as decimal(18,2))/100  END From_4_months_upto_6_months
										,Case When ISNULL(P.From7monthsupto9months,'')='' Then CAST(DP.From_7_months_upto_9_months AS DECIMAL(18,2)) Else CAST(P.From7monthsupto9months as decimal(18,2))/100  END From_7_months_upto_9_months
										,Case When ISNULL(P.From10monthsupto12months,'')='' Then CAST(DP.From_10_months_upto_12_months AS DECIMAL(18,2)) Else CAST(P.From10monthsupto12months as decimal(18,2))/100 END From_10_months_upto_12_months
										,Case When ISNULL(P.Doubtful1,'')='' Then CAST(DP.Doubtful_1 AS DECIMAL(18,2)) Else CAST(P.Doubtful1 as decimal(18,2))/100  END Doubtful_1
										,Case When ISNULL(P.Doubtful2,'')='' Then CAST(DP.Doubtful_2 AS DECIMAL(18,2)) Else CAST(P.Doubtful2 as decimal(18,2))/100 END Doubtful_2
										,Case When ISNULL(P.Doubtful3,'')='' Then CAST(DP.Doubtful_3 AS DECIMAL(18,2)) Else CAST(P.Doubtful3 as decimal(18,2))/100  END Doubtful_3
										,Case When ISNULL(P.Loss,'')='' Then CAST(DP.Loss AS DECIMAL(18,2)) Else CAST(P.Loss as decimal(18,2))/100 END Loss		
										,'YYYY'
										,'MP'
										,@Timekey
										,49999
										,ISNULL(DP.CreatedBy,'D2K') AS CreatedBy
										,CONVERT(DATETIME,(ISNULL(DP.DateCreated,'2023-07-05'))) AS DateCreated
										,@UserLoginID
										,GETDATE()
										,DP.ProvisionAlt_key
										,Case When ISNULL(P.ProvisionUnSecured,'')='' Then CAST(DP.ProvisionUnSecured AS DECIMAL(18,2)) Else CAST(P.ProvisionUnSecured as decimal(18,2))/100  END ProvisionUnSecured			
										,@ExcelUploadId
										,'Y'
										
									FROM ProvisionPolicy_stg P
										INNER JOIN DimSourceSystem S ON P.SourceSystem = S.SourceName
										INNER JOIN DIMPROVISIONPOLICY DP ON P.SchemeCode=DP.Scheme_Code 																			
										WHERE p.filname=@FilePathUpload
										AND DP.Scheme_Code IS NOT NULL
										AND P.Action IN('U')
										AND DP.EffectiveFromTimeKey<=@Timekey AND DP.EffectiveToTimeKey>=@Timekey

print '2'
	/*TO UPDATE THE PERCENTAGES OF EXITSTING SCHEME CODE WHICH ARE NULL FROM MAIN TABLE --SHUBHAM KAMBLE*/										
						INSERT INTO  DIMPROVISIONPOLICY_mod (
										 Source_System
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
										,ProvisionAlt_key
										,ProvisionUnSecured
										,UploadID
										,IsUpload
										)
										
										SELECT 
										 s.SourceName
										,S.SourceAlt_Key
										,DP.Scheme_Code
										,Case When ISNULL(P.upto3months,'')='' Then CAST(DP.upto_3_months AS DECIMAL(18,2)) Else CAST(P.upto3months as decimal(18,2))/100  END upto_3_months
										,Case When ISNULL(P.From4monthsupto6months,'')='' Then CAST(DP.From_4_months_upto_6_months AS DECIMAL(18,2)) Else CAST(P.From4monthsupto6months as decimal(18,2))/100  END From_4_months_upto_6_months
										,Case When ISNULL(P.From7monthsupto9months,'')='' Then CAST(DP.From_7_months_upto_9_months AS DECIMAL(18,2)) Else CAST(P.From7monthsupto9months as decimal(18,2))/100  END From_7_months_upto_9_months
										,Case When ISNULL(P.From10monthsupto12months,'')='' Then CAST(DP.From_10_months_upto_12_months AS DECIMAL(18,2)) Else CAST(P.From10monthsupto12months as decimal(18,2))/100 END From_10_months_upto_12_months
										,Case When ISNULL(P.Doubtful1,'')='' Then CAST(DP.Doubtful_1 AS DECIMAL(18,2)) Else CAST(P.Doubtful1 as decimal(18,2))/100  END Doubtful_1
										,Case When ISNULL(P.Doubtful2,'')='' Then CAST(DP.Doubtful_2 AS DECIMAL(18,2)) Else CAST(P.Doubtful2 as decimal(18,2))/100 END Doubtful_2
										,Case When ISNULL(P.Doubtful3,'')='' Then CAST(DP.Doubtful_3 AS DECIMAL(18,2)) Else CAST(P.Doubtful3 as decimal(18,2))/100  END Doubtful_3
										,Case When ISNULL(P.Loss,'')='' Then CAST(DP.Loss AS DECIMAL(18,2)) Else CAST(P.Loss as decimal(18,2))/100 END Loss		
										,'YYYY'
										,'MP'
										,@Timekey
										,49999
										,ISNULL(DP.CreatedBy,'D2K') AS CreatedBy
										,CONVERT(DATETIME,(ISNULL(DP.DateCreated,'2023-07-05'))) AS DateCreated
										,@UserLoginID
										,GETDATE()
										,DP.ProvisionAlt_key
										,Case When ISNULL(P.ProvisionUnSecured,'')='' Then CAST(DP.ProvisionUnSecured AS DECIMAL(18,2)) Else CAST(P.ProvisionUnSecured as decimal(18,2))/100  END ProvisionUnSecured			
										,@ExcelUploadId
										,'Y'
										
									FROM ProvisionPolicy_stg P
										INNER JOIN DimSourceSystem S ON P.SourceSystem = S.SourceName
										INNER JOIN DIMPROVISIONPOLICY DP ON P.SourceSystem=DP.Source_System	AND isnull(DP.Scheme_Code,'')=isnull(P.SchemeCode,'')																		
										WHERE p.filname=@FilePathUpload										
										AND DP.Scheme_Code IS NULL
										AND P.Action IN('U')
										AND DP.EffectiveFromTimeKey<=@Timekey AND DP.EffectiveToTimeKey>=@Timekey

					
print '3'
		/*TO DELETE EXISTING SCEHEME CODE - on local 608042024 -SHUBHAM KAMBLE*/
						INSERT INTO  DIMPROVISIONPOLICY_mod (
										 Source_System
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
										,ProvisionAlt_key
										,ProvisionUnSecured
										,UploadID
										,IsUpload
										)
										
										SELECT 
										 s.SourceName
										,S.SourceAlt_Key
										,DP.Scheme_Code
										,Case When ISNULL(P.upto3months,'')='' Then CAST(DP.upto_3_months AS DECIMAL(18,2)) Else CAST(P.upto3months as decimal(18,2))/100  END upto_3_months
										,Case When ISNULL(P.From4monthsupto6months,'')='' Then CAST(DP.From_4_months_upto_6_months AS DECIMAL(18,2)) Else CAST(P.From4monthsupto6months as decimal(18,2))/100  END From_4_months_upto_6_months
										,Case When ISNULL(P.From7monthsupto9months,'')='' Then CAST(DP.From_7_months_upto_9_months AS DECIMAL(18,2)) Else CAST(P.From7monthsupto9months as decimal(18,2))/100  END From_7_months_upto_9_months
										,Case When ISNULL(P.From10monthsupto12months,'')='' Then CAST(DP.From_10_months_upto_12_months AS DECIMAL(18,2)) Else CAST(P.From10monthsupto12months as decimal(18,2))/100 END From_10_months_upto_12_months
										,Case When ISNULL(P.Doubtful1,'')='' Then CAST(DP.Doubtful_1 AS DECIMAL(18,2)) Else CAST(P.Doubtful1 as decimal(18,2))/100  END Doubtful_1
										,Case When ISNULL(P.Doubtful2,'')='' Then CAST(DP.Doubtful_2 AS DECIMAL(18,2)) Else CAST(P.Doubtful2 as decimal(18,2))/100 END Doubtful_2
										,Case When ISNULL(P.Doubtful3,'')='' Then CAST(DP.Doubtful_3 AS DECIMAL(18,2)) Else CAST(P.Doubtful3 as decimal(18,2))/100  END Doubtful_3
										,Case When ISNULL(P.Loss,'')='' Then CAST(DP.Loss AS DECIMAL(18,2)) Else CAST(P.Loss as decimal(18,2))/100 END Loss		
										,'YYYY'
										,'DP'
										,@Timekey
										,49999
										,ISNULL(DP.CreatedBy,'D2K') AS CreatedBy
										,CONVERT(datetime,(ISNULL(DP.DateCreated,'2023-07-05'))) AS DateCreated
										,@UserLoginID
										,GETDATE()
										,DP.ProvisionAlt_key
										,Case When ISNULL(P.ProvisionUnSecured,'')='' Then CAST(DP.ProvisionUnSecured AS DECIMAL(18,2)) Else CAST(P.ProvisionUnSecured as decimal(18,2))/100  END ProvisionUnSecured			
										,@ExcelUploadId
										,'Y'
										
									FROM ProvisionPolicy_stg P
										INNER JOIN DimSourceSystem S ON P.SourceSystem = S.SourceName
										INNER JOIN DIMPROVISIONPOLICY DP ON P.SchemeCode=DP.Scheme_Code																			
										WHERE p.filname=@FilePathUpload
										AND DP.Scheme_Code IS NOT NULL
										AND P.Action IN('D')
										AND DP.EffectiveFromTimeKey<=@Timekey AND DP.EffectiveToTimeKey>=@Timekey

print '4'
		/*TO DELETE EXISTING SCEHEME CODES WHICH ARE NULL - 08042024 -SHUBHAM KAMBLE*/
						INSERT INTO  DIMPROVISIONPOLICY_mod (
										 Source_System
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
										,ProvisionAlt_key
										,ProvisionUnSecured
										,UploadID
										,IsUpload
										)
										
										SELECT 
										 s.SourceName
										,S.SourceAlt_Key
										,DP.Scheme_Code
										,Case When ISNULL(P.upto3months,'')='' Then CAST(DP.upto_3_months AS DECIMAL(18,2)) Else CAST(P.upto3months as decimal(18,2))/100  END upto_3_months
										,Case When ISNULL(P.From4monthsupto6months,'')='' Then CAST(DP.From_4_months_upto_6_months AS DECIMAL(18,2)) Else CAST(P.From4monthsupto6months as decimal(18,2))/100  END From_4_months_upto_6_months
										,Case When ISNULL(P.From7monthsupto9months,'')='' Then CAST(DP.From_7_months_upto_9_months AS DECIMAL(18,2)) Else CAST(P.From7monthsupto9months as decimal(18,2))/100  END From_7_months_upto_9_months
										,Case When ISNULL(P.From10monthsupto12months,'')='' Then CAST(DP.From_10_months_upto_12_months AS DECIMAL(18,2)) Else CAST(P.From10monthsupto12months as decimal(18,2))/100 END From_10_months_upto_12_months
										,Case When ISNULL(P.Doubtful1,'')='' Then CAST(DP.Doubtful_1 AS DECIMAL(18,2)) Else CAST(P.Doubtful1 as decimal(18,2))/100  END Doubtful_1
										,Case When ISNULL(P.Doubtful2,'')='' Then CAST(DP.Doubtful_2 AS DECIMAL(18,2)) Else CAST(P.Doubtful2 as decimal(18,2))/100 END Doubtful_2
										,Case When ISNULL(P.Doubtful3,'')='' Then CAST(DP.Doubtful_3 AS DECIMAL(18,2)) Else CAST(P.Doubtful3 as decimal(18,2))/100  END Doubtful_3
										,Case When ISNULL(P.Loss,'')='' Then CAST(DP.Loss AS DECIMAL(18,2)) Else CAST(P.Loss as decimal(18,2))/100 END Loss		
										,'YYYY'
										,'DP'
										,@Timekey
										,49999
										,ISNULL(DP.CreatedBy,'D2K') AS CreatedBy
										,CONVERT(datetime,(ISNULL(DP.DateCreated,'2023-07-05'))) AS DateCreated
										,@UserLoginID
										,GETDATE()
										,DP.ProvisionAlt_key
										,Case When ISNULL(P.ProvisionUnSecured,'')='' Then CAST(DP.ProvisionUnSecured AS DECIMAL(18,2)) Else CAST(P.ProvisionUnSecured as decimal(18,2))/100  END ProvisionUnSecured			
										,@ExcelUploadId
										,'Y'
										
									FROM ProvisionPolicy_stg P
										INNER JOIN DimSourceSystem S ON P.SourceSystem = S.SourceName
										INNER JOIN DIMPROVISIONPOLICY DP ON P.SourceSystem=DP.Source_System		 
										AND ISNULL(P.SchemeCode,'NULL')=ISNULL(DP.Scheme_Code,'NULL')																			
										WHERE p.filname=@FilePathUpload
										AND DP.Scheme_Code IS NULL
										AND P.Action IN('D')
										AND DP.EffectiveFromTimeKey<=@Timekey AND DP.EffectiveToTimeKey>=@Timekey
					----------------


print '5'

								INSERT INTO ExcelUploadHistory
							(  
								UniqueUploadID
								,UploadedBy	
								,DateofUpload	
								,AuthorisationStatus	
								--,Action	
								,UploadType
								,EffectiveFromTimeKey	
								,EffectiveToTimeKey	
								,CreatedBy	
								,DateCreated
							--	,ModifyBy
							--	,DateModified
							)
							
							SELECT 
									@ExcelUploadId
							        ,@UserLoginID
								   ,GETDATE()
								  -- ,'MP'
								   ,'NP'
								   ,'Provision Policy Upload'
								   ,@EffectiveFromTimeKey
								   ,49999
								   ,@UserLoginID
								   ,GETDATE()
								--   ,@UserLoginID
								--   ,GETDATE()
							
							PRINT @@ROWCOUNT

							--	END
			
			SET IDENTITY_INSERT DIMPROVISIONPOLICY_mod OFF;
		  -----------------------------------------------------------

	
	
					Insert into UploadStatus (FileNames,UploadedBy,UploadDateTime,UploadType)
					Values(@filepath,@UserLoginID ,GETDATE(),'Provision Policy Upload')

						
					--	DELETE FROM STAGING DATA
					   DELETE FROM ProvisionPolicy_stg
					   WHERE filname=@FilePathUpload
	END
	END
	
print '6'

/*FIRST LEVEL AUTHORIZE*/
IF (@OperationFlag=16)	 
		BEGIN	
			UPDATE DIMPROVISIONPOLICY_mod 
			SET 
				AuthorisationStatus	='1A'
				,ApprovedByFirstLevel	= @UserLoginID
				,DateApprovedFirstLevel	= GETDATE()
			WHERE UploadId=@UniqueUploadID
			AND AuthorisationStatus IN ('NP','MP')
			AND CreatedBy<>@UserLoginID

			UPDATE DIMPROVISIONPOLICY_mod 
			SET 
				AuthorisationStatus	='1D'
				,ApprovedByFirstLevel	= @UserLoginID
				,DateApprovedFirstLevel	= GETDATE()
			WHERE UploadId=@UniqueUploadID
			AND AuthorisationStatus IN ('DP')
			AND CreatedBy<>@UserLoginID
				
			UPDATE ExcelUploadHistory
			SET 
				AuthorisationStatus='1A'
				,ApprovedByFirstLevel	= @UserLoginID
				,DateApprovedFirstLevel	= GETDATE()
			WHERE UniqueUploadID=@UniqueUploadID
			AND AuthorisationStatus IN ('NP','MP','DP')
			AND UploadType='Provision Policy Upload'
		--	AND CreatedBy<>@UserLoginID
		
		END

/*SECOND LEVEL AUTHORIZATION*/
IF (@OperationFlag=20)

	
	BEGIN
		UPDATE 	DIMPROVISIONPOLICY_mod 
				SET AuthorisationStatus	='A'
				,ApprovedBy	= @UserLoginID
				,DateApproved	=GETDATE()
				WHERE UploadId=@UniqueUploadID
				AND AuthorisationStatus IN ('1A')
				AND (CreatedBy<>@UserLoginID
				OR ApprovedByFirstLevel<>@UserLoginID)

		UPDATE	DIMPROVISIONPOLICY_mod 
				SET AuthorisationStatus	='D'
				,ApprovedBy	= @UserLoginID
				,DateApproved	=GETDATE()
				WHERE UploadId=@UniqueUploadID
				AND AuthorisationStatus IN ('1D')
				AND (CreatedBy<>@UserLoginID
				OR ApprovedByFirstLevel<>@UserLoginID)
	
		
		/*EXPIRING OLD RECORD FROM MAIN TABLE*/

		UPDATE A
						SET A.EffectiveToTimeKey =@Timekey -1
						,A.ModifiedBy=@UserLoginID
						,A.DateModified=GETDATE()
						,A.AuthorisationStatus='A'
					FROM DIMPROVISIONPOLICY A
					INNER JOIN DIMPROVISIONPOLICY_MOD B ON A.ProvisionAlt_key=B.ProvisionAlt_key
					WHERE (A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey >=@Timekey)
					AND B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey >=@Timekey
					AND B.UploadID=@UniqueUploadID
					AND B.AuthorisationStatus IN ('A')
		
		UPDATE A
						SET A.EffectiveToTimeKey =@Timekey -1
						,A.ModifiedBy=@UserLoginID
						,A.DateModified=GETDATE()
						,A.AuthorisationStatus='D'
					FROM DIMPROVISIONPOLICY A
					INNER JOIN DIMPROVISIONPOLICY_MOD B ON A.ProvisionAlt_key=B.ProvisionAlt_key
					WHERE (A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey >=@Timekey)
					AND B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey >=@Timekey
					AND B.UploadID=@UniqueUploadID
					AND B.AuthorisationStatus IN ('D')
		
		
		UPDATE B
						SET B.EffectiveToTimeKey =@Timekey -1
						,B.ModifiedBy=@UserLoginID
						,B.DateModified=GETDATE()
						,B.AuthorisationStatus='D'
					FROM DIMPROVISIONPOLICY_MOD A
					INNER JOIN DIMPROVISIONPOLICY B ON A.ProvisionAlt_key=B.ProvisionAlt_key
					WHERE (A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey >=@Timekey)
					AND B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey >=@Timekey
					AND A.UploadID<>B.UploadID
					AND A.AuthorisationStatus IN ('D')
		

				UPDATE B
					SET B.EffectiveToTimeKey = @Timekey -1
						,B.ModifiedBy=@UserLoginID
						,B.DateModified=GETDATE()
					--	,B.AuthorisationStatus='D'
				FROM DIMPROVISIONPOLICY_MOD B
					WHERE B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey >=@Timekey
					AND B.UploadID=@UniqueUploadID
					AND B.AuthorisationStatus IN ('D')

	-----bellow Change  on 20062024 by liyaqat -----
	UPDATE A
						SET A.EffectiveToTimeKey =@Timekey -1
						,A.ModifiedBy=@UserLoginID
						,A.DateModified=GETDATE() 
					FROM DIMPROVISIONPOLICY_MOD A
					INNER JOIN DIMPROVISIONPOLICY B ON A.ProvisionAlt_key=B.ProvisionAlt_key and A.Scheme_Code=B.Scheme_Code ----MOHIT
					WHERE B.EffectiveFromTimeKey<=(@Timekey-1) AND B.EffectiveToTimeKey >=(@Timekey-1)
					AND A.UploadID<>@UniqueUploadID
					AND A.AuthorisationStatus IN ('A') AND B.AuthorisationStatus IN ('D')

	-----bellow Change  on 20243110 by Mohit -----
	UPDATE A
						SET A.EffectiveToTimeKey =@Timekey -1
						,A.ModifiedBy=@UserLoginID
						,A.DateModified=GETDATE() 
					FROM DIMPROVISIONPOLICY_MOD A
					INNER JOIN DIMPROVISIONPOLICY B ON A.ProvisionAlt_key=B.ProvisionAlt_key and A.Scheme_Code=B.Scheme_Code ---MOHIT
					WHERE B.EffectiveFromTimeKey<=(@Timekey-1) AND B.EffectiveToTimeKey >=(@Timekey-1)
					AND A.UploadID<>@UniqueUploadID
					AND A.AuthorisationStatus IN ('A') AND B.AuthorisationStatus IN ('A')

		/*INSERT DATA INTO MAIN FROM MOD IF SCHEME CODE IS NEW*/
		BEGIN
		PRINT 'MAIN BEGIN'
				INSERT INTO DIMPROVISIONPOLICY
				(Source_System
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
				,UploadId
				)
	
				SELECT 
				Source_System
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
				, DateCreated 
				,ModifiedBy
				, DateModified  
				,ApprovedBy
				,DateApproved 
		--		,D2Ktimestamp
				,ApprovedByFirstLevel
				,DateApprovedFirstLevel 
				,ProvisionAlt_key
				,ProvisionUnSecured
				,UploadID

				FROM DIMPROVISIONPOLICY_mod
				WHERE UploadId=@UniqueUploadID
				AND AuthorisationStatus	IN ('A')
	--			AND Scheme_Code IN (SELECT Scheme_Code FROM DIMPROVISIONPOLICY WHERE Scheme_Code IS NOT NULL)
				AND (CreatedBy<>@UserLoginID
				OR ApprovedByFirstLevel<>@UserLoginID)

		END
		PRINT 'MAIN COMPLETE'

		


		/*Expiring record in mod table*/

		update B
		SET B.EffectiveToTimeKey=@Timekey-1
			,B.ModifiedBy=@UserLoginID
			,B.DateModified=GETDATE()
		FROM DIMPROVISIONPOLICY A
		INNER JOIN DIMPROVISIONPOLICY_MOD B ON A.ProvisionAlt_key = B.ProvisionAlt_key 
		WHERE A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey
		AND B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey>=@Timekey
		AND A.UploadID <> B.UploadID		

	-----bellow Change  on 19062024 by liyaqat and Mohit-----	
	--	;With CTE_DIMPROVISIONPOLICY_MOD As 
	--	( select * from DIMPROVISIONPOLICY_MOD where EffectiveToTimeKey=49999 )
	--			update C
	--			SET C.EffectiveToTimeKey=@Timekey-1
	--				,C.ModifiedBy=@UserLoginID
	--				,C.DateModified=GETDATE()
	--			FROM DIMPROVISIONPOLICY A
	--			INNER JOIN DIMPROVISIONPOLICY_MOD B ON A.ProvisionAlt_key = B.ProvisionAlt_key
	--			INNER JOIN DIMPROVISIONPOLICY_MOD C ON C.ProvisionAlt_key = B.ProvisionAlt_key
	--			WHERE A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey
	--			AND B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey>=@Timekey
	--			AND A.UploadID <> B.UploadID	
	--			AND C.AuthorisationStatus='A' 



		UPDATE	ExcelUploadHistory
			SET AuthorisationStatus='A'
				,ApprovedBy=@UserLoginID
				,DateApproved=GETDATE()
			WHERE EffectiveFromTimeKey<=@Timekey 
				AND EffectiveToTimeKey>=@Timekey
				AND UniqueUploadID=@UniqueUploadID
				AND UploadType='Provision Policy Upload'	
				AND (CreatedBy<>@UserLoginID
				OR ApprovedByFirstLevel<>@UserLoginID)
	
 end

/* FIRST LEVEL REJECT*/

	IF (@OperationFlag=17)	
	BEGIN
		UPDATE DIMPROVISIONPOLICY_mod 
		SET 
			 AuthorisationStatus	='R'
			 ,EffectiveToTimeKey	= EffectiveFromTimeKey -1
			,ApprovedByFirstLevel	=@UserLoginID
			,DateApprovedFirstLevel	=GETDATE()
		WHERE UploadId=@UniqueUploadID
		AND AuthorisationStatus IN ('NP','MP','DP')
		AND CreatedBy<> @UserLoginID
		

		UPDATE ExcelUploadHistory
		SET 
			AuthorisationStatus='R'
			,EffectiveToTimeKey	= EffectiveFromTimeKey -1
			,ApprovedByFirstLevel=@UserLoginID
			,DateApprovedFirstLevel=GETDATE()
		WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey)
		AND AuthorisationStatus IN ('NP','MP','DP')
		AND UniqueUploadID=@UniqueUploadID
		AND UploadType='Provision Policy Upload'

	END

/* SECOND LEVEL REJECT*/
IF (@OperationFlag=21)

	BEGIN
		
		UPDATE 
			DIMPROVISIONPOLICY_mod 
			SET 
			AuthorisationStatus	='R'
			,EffectiveToTimeKey	= EffectiveFromTimeKey -1
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			WHERE UploadId=@UniqueUploadID
			AND AuthorisationStatus in('1A','1R','1D')
			AND (CreatedBy<>@UserLoginID
			OR ApprovedByFirstLevel<>@UserLoginID)
			

			UPDATE	ExcelUploadHistory
			SET 
				AuthorisationStatus='R',
				EffectiveToTimeKey	= EffectiveFromTimeKey -1,
				ApprovedBy= @UserLoginID,
				DateApproved=GETDATE()
				WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
				AND AuthorisationStatus in('1A','1R')
				AND UniqueUploadID=@UniqueUploadID
				AND UploadType='Provision Policy Upload'

	END
END


	--COMMIT TRAN		
		SET @Result=CASE WHEN  @OperationFlag=1 AND @MenuId=2026 THEN @ExcelUploadId 
					ELSE 1 END
		
		Update UploadStatus Set InsertionOfData='Y',InsertionCompletedOn=GETDATE() WHERE FileNames=@filepath
		 
		RETURN @Result		--RETURN @UniqueUploadID



		
END TRY
	BEGIN CATCH 

	   --ROLLBACK TRAN
	SELECT ERROR_MESSAGE(),ERROR_LINE()
	SET @Result=-1
	 Update UploadStatus Set InsertionOfData='Y',InsertionCompletedOn=GETDATE() WHERE FileNames=@filepath
	--RETURN -1
	END CATCH

END


GO