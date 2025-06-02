SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

create PROCEDURE  [dbo].[ACNPAMOCStageDataInUp_10042024]
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

--@TimeKey=26084,@UserLoginID=N'iblfm2',@OperationFlag=N'1',@MenuId=N'101',@AuthMode=N'Y',@filepath=N'Account_MOC_Upload.xlsx',@EffectiveFromTimeKey=26084
--,@EffectiveToTimeKey=49999,@UniqueUploadID=NULL,@Result=@p10 output
--DECLARE @Timekey INT=26084,
--	@UserLoginID VARCHAR(100)='iblfm2',
--	@OperationFlag INT=1,
--	@MenuId INT=101,
--	@AuthMode	CHAR(1)='Y',
--	@filepath VARCHAR(MAX)='Account_MOC_Upload.xlsx',
--	@EffectiveFromTimeKey INT=26084,
--	@EffectiveToTimeKey	INT=26084,
--    @Result		INT=0 ,
--	@UniqueUploadID INT=NULL
BEGIN
SET DATEFORMAT DMY
	SET NOCOUNT ON;

   DECLARE @AsOnDate VARCHAR(10)
   
  SET @Timekey =(Select TimeKey from SysDataMatrix where CurrentStatus_MOC='C' and MOC_Initialised='Y') 

  --SET @Timekey =(Select LastMonthDateKey from SysDayMatrix where Timekey=@Timekey) 
   	PRINT @TIMEKEY

	SET @EffectiveFromTimeKey=@TimeKey
	SET @EffectiveToTimeKey=@TimeKey


	DECLARE @FilePathUpload	VARCHAR(100)
				   SET @FilePathUpload=@UserLoginId+'_'+@filepath
					PRINT '@FilePathUpload'
					PRINT @FilePathUpload

		BEGIN TRY

		--BEGIN TRAN
		
IF (@MenuId=101)
BEGIN
	IF (@OperationFlag=1)

	BEGIN
		IF NOT (EXISTS (SELECT 1 FROM AccountLvlMOCDetails_stg  where filname=@FilePathUpload))

							BEGIN
									 --Rollback tran
									SET @Result=-8

								RETURN @Result
							END
			
                   Print 'Sachin'

		---------- Implement Logic of AsOnDate for Enquiry Screen Grid Data Fetching --------------
		IF EXISTS(SELECT 1 FROM AccountLvlMOCDetails_stg WHERE filname=@FilePathUpload)
		BEGIN
				------ Fetch the Value of AsOndate From Stage Table Brfore Inserting into ExcelUploadHistory Table
				SET @AsOnDate = (SELECT TOP 1 AsOnDate FROM AccountLvlMOCDetails_stg WHERE filname=@FilePathUpload)
		END

		---use of sequence
		DECLARE @ExcelUploadId int
		select @ExcelUploadId=next value for [dbo].[Seq_UploadId]  
		select @ExcelUploadId

		SET DATEFORMAT DMY
		IF EXISTS(SELECT 1 FROM AccountLvlMOCDetails_stg WHERE filname=@FilePathUpload)
		BEGIN
		
					   
		SET DATEFORMAT DMY
				
		 DECLARE @Entity_Key Int   IF (@Entity_Key IS NULL)

                        BEGIN 
						  SET    @Entity_Key=isnull(@Entity_Key,0)+1
						 END 


				DROP TABLE IF EXISTS #tmp
					Select distinct CustomerACID,EffectiveFromTimeKey,EffectiveToTimeKey,Accountentityid into #tmp 
					from NPA_IntegrationDetails where CustomerACID in(Select AccountID from AccountLvlMOCDetails_stg)
					AND EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey    -- ADDED ON 08032024 BY SHUBHAM KAMBLE
				
		INSERT INTO NPA_IntegrationDetails_mod
		( NCIF_ID
		,NCIF_EntityID
		,AccountEntityID
		,CustomerID
		,SrcSysAlt_Key
		,CustomerName
		,CustomerACID	       
    	,Balance
		,PrincipleOutstanding
		,SecurityValue		------- Replaced from ApprRV to SecurityValue BY SATWAJI as on 21/04/2022 as per Bank's Requirement Change(implemented at 04052023 at prod)
		--,ApprRV
		--,UNSERVED_INTEREST
		,IntOverdue			------- Replaced from UNSERVED_INTEREST to IntOverdue BY SATWAJI as on 03/09/2021 as per Bank's Requirement Change
		,AddlProvisionPer
		,AddlProvision
		,ACMOC_ReasonAlt_Key
		,AuthorisationStatus
        ,EffectiveFromTimeKey
        ,EffectiveToTimeKey
        ,CreatedBy
        ,DateCreated
		,UploadID
		,MOC_Remark
		
)
		 
		SELECT distinct
			 --SrNo
             --AsOnDate
             AccountLvlMOCDetails_stg.NCIF_Id
			 ,@Entity_Key
			 ,N.Accountentityid
             ,AccountLvlMOCDetails_stg.CustomerId
             ,S.SourceAlt_Key  SourceSystem
             ,AccountLvlMOCDetails_stg.CustomerName
			 --,NULL
             ,AccountID
             ,Case When GrossBalance='' Then CAST(NULL AS DECIMAL(18,2)) Else CAST(GrossBalance AS DECIMAL(18,2)) END GrossBalance
             ,Case When PrincipalOutstanding='' Then CAST(NULL AS DECIMAL(18,2)) Else CAST(PrincipalOutstanding AS DECIMAL(18,2)) END PrincipalOutstanding
			 ,Case When AccountLvlMOCDetails_stg.SecurityValue='' Then CAST(NULL AS DECIMAL(22,2)) Else CAST(AccountLvlMOCDetails_stg.SecurityValue AS DECIMAL(22,2)) END SecurityValue                -----new added as mail 03072021
             ,Case When UnservicedInterestAmount='' Then CAST(NULL AS DECIMAL(18,2)) Else CAST(UnservicedInterestAmount AS DECIMAL(18,2)) END UnservicedInterestAmount
             ,Case When Additionalprovisionpercentage='' Then CAST(NULL AS DECIMAL(18,2)) Else CAST(Additionalprovisionpercentage AS DECIMAL(18,2)) END Additionalprovisionpercentage
             ,Case When AdditionalprovisionAmount='' Then CAST(NULL AS DECIMAL(18,2)) Else CAST(AdditionalprovisionAmount AS DECIMAL(18,2)) END AdditionalprovisionAmount
             --,Acceleratedprovisionamount    ---value insert into AcceleratedProv table
             ,R.MocReasonAlt_Key  MOCReason
			 ,'NP'	
			,@Timekey
			,@TimeKey	
			,@UserLoginID	
			,GETDATE()	
			
            ,@ExcelUploadId
			,AccountLvlMOCDetails_stg.Remark

		
		FROM AccountLvlMOCDetails_stg
		left JOIN #tmp N on N.CustomerACID=AccountLvlMOCDetails_stg.AccountID
		            --  and EffectiveFromTimeKey<=@Timekey and EffectiveToTimeKey>=@Timekey
		LEFT JOIN dimsourcesystem S ON S.SourceName=AccountLvlMOCDetails_stg.SourceSystem
		LEFT JOIN DimMocReason  R ON (case when R.MocReasonName='Other reason of Account MOC' then 'Other' 
										  else R.MocReasonName END)= AccountLvlMOCDetails_stg.MOCReason 
								  and R.EffectiveToTimeKey=49999		
		where filname=@FilePathUpload

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
		,AsOnDate					-------- New Column Added By Satwaji as on 02/09/2021
		
	)
	---select * from ExcelUploadHistory
	SELECT 
			@ExcelUploadId
	        ,@UserLoginID
		   ,GETDATE()
		   ,'NP'
		   --,'NP'
		   ,'Account MOC Upload'
		   ,@EffectiveFromTimeKey
		   ,@EffectiveToTimeKey
		   ,@UserLoginID
		   ,GETDATE()
		   ,CONVERT(Date,@AsOnDate,103)

			   PRINT @@ROWCOUNT

	----	   DECLARE @ExcelUploadId INT
	----SET 	@ExcelUploadId=(SELECT MAX(UniqueUploadID) FROM  ExcelUploadHistory)
		
			Insert into UploadStatus (FileNames,UploadedBy,UploadDateTime,UploadType)
		           Values(@filepath,@UserLoginID ,GETDATE(),'Account MOC Upload')

/*   
  ------------Below Code comment For adding  AcceleratedProv mod table logic 14022022(implemented at 04052023 at prod)

		---------- INTO INTO AcceleratedProv TABLE 


		--IF EXISTS(SELECT 1 FROM CURDAT.AcceleratedProv A
		--			INNER JOIN AccountLvlMOCDetails_stg S ON A.CustomerACID=S.AccountID
		--			WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
					--AND ISNULL(S.Additionalprovisionpercentage,'')<>'')
                  BEGIN 
				  UPDATE A 
				   SET EffectiveToTimeKey=EffectiveFromTimeKey-1

				  FROM [CURDAT].[AcceleratedProv] A 
		                            INNER JOIN AccountLvlMOCDetails_stg S ON A.CustomerACID=S.AccountID
		                                                WHERE A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey
														AND ISNULL(S.Acceleratedprovisionpercentage,'')<>''
														---AND EffectiveFromTimeKey=EffectiveToTimeKey
				   
				 
				   END 
		
								INSERT INTO [CURDAT].[AcceleratedProv]
                        (
								
                              NCIF_Id
                              
                              ,CustomerId
							  ,SrcSysAlt_Key
                              ,AccountEntityID
                              ,CustomerACID
                              ,AccProvPer			--TotalProvision Column Name Changed As AccProvPer As Per Requirement Changed as on 07/07/2021 By SATWAJI
                              ,AuthorisationStatus
                              ,EffectiveFromTimeKey
                              ,EffectiveToTimeKey
                              ,CreatedBy
                              ,DateCreated
                              ,ModifiedBy
                              ,DateModified
                              ,ApprovedBy
                              ,DateApproved
							  )

							   
							  SELECT
			 
                                         ST.NCIF_Id
                                         ,ST.CustomerId
                                         ,S.SourceAlt_Key  SourceSystem
                                        -- ,CustomerName
			                             --,NULL
                                         ,A.AccountEntityID 
										 ,AccountID
                                         --,GrossBalance
                                         --,PrincipalOutstanding
                                         --,UnservicedInterestAmount
                                         --,Additionalprovisionpercentage
                                         --,AdditionalprovisionAmount
										 ,CAST(ST.Acceleratedprovisionpercentage AS DECIMAL(18,2)) AS AcceleratedProvisionPercentage
           --                              ,Case When (ST.Acceleratedprovisionpercentage='' OR ST.Acceleratedprovisionpercentage='0') 
										 --THEN CAST(P.AccProvPer AS DECIMAL(16,2)) Else CAST(ST.Acceleratedprovisionpercentage AS DECIMAL(18,2)) END AcceleratedProvisionPercentage		--Acceleratedprovisionamount    ---value insert into AcceleratedProv table
                                         --,MOCReason
			                             ,'NP'	
			                            ,@Timekey
			                            ,49999	
			                            ,@UserLoginID	
			                            ,GETDATE()
										,@UserLoginID
										,Getdate()
										,@UserLoginID
										,Getdate()
      
		FROM AccountLvlMOCDetails_stg ST
		left JOIN dbo.NPA_IntegrationDetails A on A.CustomerACID=ST.AccountID
		                      and EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
		LEFT JOIN dimsourcesystem S ON S.SourceName=ST.SourceSystem
		LEFT JOIN DimMocReason  R ON R.MocReasonName= ST.MOCReason
		--LEFT JOIN CURDAT.AcceleratedProv P
		--ON ST.AccountID=P.CustomerACID
		--AND P.EffectiveFromTimeKey<=@Timekey AND P.EffectiveToTimeKey>=@Timekey
		where ISNULL(ST.Acceleratedprovisionpercentage,'')<>'' AND filname=@FilePathUpload
*/

----Add   14022022(implemented at 04052023 at prod)

	INSERT INTO [AcceleratedProv_Mod]
                        (							
                              NCIF_Id
                              ,CustomerId
							  ,SrcSysAlt_Key
                              ,AccountEntityID
                              ,CustomerACID
                              ,AccProvPer			
                              ,AuthorisationStatus
                              ,EffectiveFromTimeKey
                              ,EffectiveToTimeKey
                              ,CreatedBy
                              ,DateCreated
                              --,ModifiedBy
                              --,DateModified
                              --,ApprovedBy
                              --,DateApproved
							  ,UploadID
							  )

							   
							  SELECT distinct
			 
                                         ST.NCIF_Id
                                         ,ST.CustomerId
                                         ,S.SourceAlt_Key  SourceSystem
                                        ,A.AccountEntityID 
										 ,AccountID
                                          ,CAST(ST.Acceleratedprovisionpercentage AS DECIMAL(18,2)) AS AcceleratedProvisionPercentage
                                        ,'NP'	
			                            ,@Timekey
			                            ,49999	
			                            ,@UserLoginID	
			                            ,GETDATE()
										--,@UserLoginID
										--,Getdate()
										--,@UserLoginID
										--,Getdate()
										,@ExcelUploadId
      
		FROM AccountLvlMOCDetails_stg ST
		left JOIN dbo.NPA_IntegrationDetails A on A.CustomerACID=ST.AccountID
		                      and EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
		LEFT JOIN dimsourcesystem S ON S.SourceName=ST.SourceSystem
--		LEFT JOIN DimMocReason  R ON R.MocReasonName= ST.MOCReason
		where ISNULL(ST.Acceleratedprovisionpercentage,'')<>'' AND filname=@FilePathUpload



		PRINT @@ROWCOUNT
		
		---DELETE FROM STAGING DATA

		 DELETE FROM AccountLvlMOCDetails_stg
		 WHERE filname=@FilePathUpload

		 ----RETURN @ExcelUploadId

END
		   ----DECLARE @UniqueUploadID INT
	--SET 	@UniqueUploadID=(SELECT MAX(UniqueUploadID) FROM  ExcelUploadHistory)
	END



IF (@OperationFlag=16)	---- FIRST LEVEL AUTHORIZE
	BEGIN	
		UPDATE NPA_IntegrationDetails_mod 
		SET 
			AuthorisationStatus	='1A'
			,ApprovedByFirstLevel	= @UserLoginID
			,DateApprovedFirstLevel	= GETDATE()
		WHERE UploadId=@UniqueUploadID
			
		UPDATE ExcelUploadHistory
		SET 
			AuthorisationStatus='1A'
			,ApprovedByFirstLevel	= @UserLoginID
			,DateApprovedFirstLevel	= GETDATE()
		where UniqueUploadID=@UniqueUploadID
		AND UploadType='Account MOC Upload'
		-----------New Add 14022022 (implemented at 04052023 at prod)
		UPDATE AcceleratedProv_Mod 
		SET 
			AuthorisationStatus	='1A'
			,ApprovedByFirstLevel	= @UserLoginID
			,DateApprovedFirstLevel	= GETDATE()
		WHERE UploadId=@UniqueUploadID

	END

--------------------------------------------

	IF (@OperationFlag=20)----AUTHORIZE

	BEGIN
		
		UPDATE 
			NPA_IntegrationDetails_mod 
			SET AuthorisationStatus	='A'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			WHERE UploadId=@UniqueUploadID		
			AND (CreatedBy<>@UserLoginID
			OR ApprovedByFirstLevel<>@UserLoginID)

			
		------------------------New add 14022022  Start ---------------  (implemented at 04052023 at prod)
		UPDATE 
			AcceleratedProv_mod 
			SET AuthorisationStatus	='A'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			WHERE UploadId=@UniqueUploadID		
			AND (CreatedBy<>@UserLoginID
			OR ApprovedByFirstLevel<>@UserLoginID)

				PRINT 'SAME TIMEKEY'
				UPDATE A SET
					A.AccProvPer=B.AccProvPer,
					A.ModifiedBy=@UserLoginID,
					A.DateModified=GETDATE()
				FROM CURDAT.AcceleratedProv A
				INNER JOIN AcceleratedProv_MOD B 
				ON A.CustomerACID=B.CustomerACID 
				AND (B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey>=@Timekey) 
				AND A.EffectiveFromTimeKey=B.EffectiveFromTimeKey
				WHERE (A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey) 
				AND B.UploadId=@UniqueUploadID
			
				PRINT 'DIFFERENT TIMEKEY'
				UPDATE A SET
					A.EffectiveToTimeKey=@EffectiveFromTimeKey-1
				FROM CURDAT.AcceleratedProv A
				INNER JOIN AcceleratedProv_MOD B 
				ON A.CustomerACID=B.CustomerACID 
				AND (B.EffectiveFromTimeKey<=@Timekey AND B.EffectiveToTimeKey>=@Timekey) 
				AND A.EffectiveFromTimeKey<>B.EffectiveFromTimeKey
				WHERE (A.EffectiveFromTimeKey<=@Timekey AND A.EffectiveToTimeKey>=@Timekey) 
				AND B.UploadId=@UniqueUploadID

				INSERT INTO Curdat.[AcceleratedProv]
                (   
					 NCIF_Id
                    ,CustomerId
					,SrcSysAlt_Key
                    ,AccountEntityID
                    ,CustomerACID
                    ,AccProvPer			
                    ,AuthorisationStatus
                    ,EffectiveFromTimeKey
                    ,EffectiveToTimeKey
                    ,CreatedBy
                    ,DateCreated
                    ,ModifiedBy
                    ,DateModified
                    ,ApprovedBy
                    ,DateApproved
					,UploadID /* (implemented at 04052023 at prod) */
				)
							  					   
				SELECT	DISTINCT		 
					 NCIF_Id
					,CustomerId
					,SrcSysAlt_Key 
					,AccountEntityID 
					,CustomerACID
                    ,CAST(ST.AccProvPer AS DECIMAL(18,2)) AS AcceleratedProvisionPercentage
					,'A'	
			        ,@Timekey
			        ,49999	
			        ,ST.CreatedBy
					,ST.DateCreated
					,ST.ModifiedBy
					,ST.DateModified
					,@UserLoginID
					,Getdate()
					,UploadID  /* (implemented at 04052023 at prod) */
										
				FROm dbo.[AcceleratedProv_Mod] ST
				where  ST.UploadID=@UniqueUploadID
				AND ST.AuthorisationStatus='A'
				--AND  ST.EffectiveFromTimeKey<>@EffectiveFromTimeKey 
				And Not exists(Select 1 from CURDAT.AcceleratedProv A Where A.CustomerACID=ST.CustomerACID And A.EffectiveToTimeKey=49999)

			--INSERT INTO Curdat.[AcceleratedProv]
			--(   
			--	 NCIF_Id
		 --       ,CustomerId
			--	,SrcSysAlt_Key
		 --       ,AccountEntityID
		 --       ,CustomerACID
		 --       ,AccProvPer			
		 --       ,AuthorisationStatus
		 --       ,EffectiveFromTimeKey
		 --       ,EffectiveToTimeKey
		 --       ,CreatedBy
		 --       ,DateCreated
		 --       ,ModifiedBy
		 --       ,DateModified
		 --       ,ApprovedBy
		 --       ,DateApproved
			--)
							  					   
			--SELECT			 
			--	 NCIF_Id
			--	,CustomerId
			--	,SrcSysAlt_Key 
		 --       ,AccountEntityID 
			--	,CustomerACID
		 --       ,CAST(ST.AccProvPer AS DECIMAL(18,2)) AS AcceleratedProvisionPercentage
			--    ,'A'	
			--    ,@Timekey
			--    ,49999	
			--    ,ST.CreatedBy
			--	,ST.DateCreated
			--	,ST.ModifiedBy
			--	,ST.DateModified
			--	,@UserLoginID
			--	,Getdate()
										
   --   		--select *
			--FROm dbo.[AcceleratedProv_Mod] ST
			--where  ST.UploadID=@UniqueUploadID
			--AND ST.AuthorisationStatus='A'
			--AND  ST.EffectiveToTimeKey>=@Timekey 

---------------------------------End 
	

			DROP TABLE IF EXISTS #ACCOUNT_CAL
		
						SELECT A.* INTO #ACCOUNT_CAL FROM NPA_IntegrationDetails A
						INNER JOIN NPA_IntegrationDetails_Mod B ON A.CustomerAcID=B.CustomerAcID
						WHERE (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey> =@TimeKey)
						and (b.EffectiveFromTimeKey<=@TimeKey AND b.EffectiveToTimeKey> =@TimeKey)
						AND B.UploadID=@UniqueUploadID
						AND B.AuthorisationStatus='A'
				--Select '#ACCOUNT_CAL',* from #ACCOUNT_CAL
					
						UPDATE A
							SET A.EffectiveToTimeKey =@TimeKey -1
							,A.AuthorisationStatus='A'
						FROM NPA_IntegrationDetails A
						INNER JOIN NPA_IntegrationDetails_Mod B ON A.CustomerAcID=B.CustomerAcID
						where (A.EffectiveFromTimeKey=@TimeKey AND A.EffectiveToTimeKey =@TimeKey)
						AND B.UploadID=@UniqueUploadID
						AND B.AuthorisationStatus='A'

							--AND A.EffectiveFromTimeKey<@TImeKey
							--where (A.EffectiveFromTimeKey<=@TimeKey AND A.EffectiveToTimeKey >=@TimeKey)
							--AND A.EffectiveFromTimeKey<@TImeKey


--	UPDATE A set
							

--A.Balance=CASE WHEN B.Balance IS NULL THEN A.Balance ELSE  B.Balance  END								
--,A.PrincipleOutstanding =CASE WHEN B.PrincipleOutstanding IS NULL THEN A.PrincipleOutstanding ELSE B.PrincipleOutstanding END				
--,A.UNSERVED_INTEREST =CASE WHEN B.UNSERVED_INTEREST IS NULL THEN A.UNSERVED_INTEREST ELSE  B.UNSERVED_INTEREST END			
--,A.AddlProvisionPer	=CASE WHEN B.AddlProvisionPer IS NULL THEN	A.AddlProvisionPer	ELSE      B.AddlProvisionPer END	
--,A.AddlProvision=CASE WHEN B.AddlProvision IS NULL THEN A.AddlProvision ELSE	 B.AddlProvision END			
----,A.DFVAmt=CASE WHEN B.Acceleratedprovisionamount	 IS NULL THEN	DFVAmt	ELSE B.Acceleratedprovisionamount	END			
--			,A.MOC_Date= getdate()
--								--,A.=@ScreenFlag						
--								--,A.=@MOCSource							
--								,A.moc_status ='Y'
--								--,A.ScreenFlag='U'
--								--,A.ChangeField=B.ChangeField
--							FROM NPA_IntegrationDetails a
--							INNER JOIN NPA_IntegrationDetails_Mod B ON A.CustomerAcID=B.CustomerAcID
--								where A.EffectiveFromTimeKey=@TimeKey and A.EffectiveToTimeKey=@TimeKey
						
						INSERT INTO dbo.NPA_IntegrationDetails
								(
                                                               NCIF_Id
                                                               ,NCIF_Changed
                                                               ,SrcSysAlt_Key
                                                               ,NCIF_EntityID
                                                               ,CustomerId
                                                               ,CustomerName
                                                               ,PAN
                                                               ,NCIF_AssetClassAlt_Key
                                                               ,NCIF_NPA_Date
                                                               ,AccountEntityID
                                                               ,CustomerACID
                                                               ,SanctionedLimit
                                                               ,DrawingPower
                                                               ,PrincipleOutstanding
                                                               ,Balance
                                                               ,Overdue
                                                               ,DPD_Overdue_Loans
                                                               ,DPD_Interest_Not_Serviced
                                                               ,DPD_Overdrawn
                                                               ,DPD_Renewals
                                                               ,MaxDPD
                                                               ,WriteOffFlag
                                                               ,Segment
                                                               ,SubSegment
                                                               ,ProductCode
                                                               ,ProductDesc
                                                               ,Settlement_Status
                                                               ,AC_AssetClassAlt_Key
                                                               ,AC_NPA_Date
                                                               ,AstClsChngByUser
                                                               ,AstClsChngDate
                                                               ,AstClsChngRemark
                                                               ,MOC_Status
                                                               ,MOC_Date
                                                               ,ACMOC_ReasonAlt_Key
                                                               ,MOC_AssetClassAlt_Key
                                                               ,MOC_NPA_Date
																,AuthorisationStatus
                                                               ,EffectiveFromTimeKey
                                                               ,EffectiveToTimeKey
                                                               ,CreatedBy
                                                               ,DateCreated
                                                               ,ModifiedBy
                                                               ,DateModified
                                                               ,ApprovedBy
                                                               ,DateApproved
                                                               ,MOC_Remark
                                                               --,D2Ktimestamp
                                                               ,ProductType
                                                               ,ActualOutStanding
                                                               ,MaxDPD_Type
                                                               ,ProductAlt_Key
                                                               ,AstClsAppRemark
                                                               ,MocAppRemark
                                                               ,PNPA_Status
                                                               ,PNPA_ReasonAlt_Key
                                                               ,PNPA_Date
                                                               ,ActualPrincipleOutstanding
                                                               ,UNSERVED_INTEREST
                                                               ,CUSTOMER_IDENTIFIER
                                                               ,ACCOUNT_LEVEL_CODE
                                                               ,NF_PNPA_Date
                                                               ,Remark
                                                               ,WriteOffDate
                                                               ,DbtDT
                                                               ,ErosionDT
                                                               ,FlgErosion
                                                               ,IntOverdue
                                                               ,IntAccrued
                                                               ,OtherOverdue
                                                               ,PrincOverdue
                                                               ,IsRestructured
                                                               ,IsOTS
                                                               ,IsTWO
                                                               ,IsARC_Sale
                                                               ,IsFraud
                                                               ,IsWiful
                                                               ,IsNonCooperative
                                                               ,IsSuitFiled
                                                               ,IsRFA
                                                               ,IsFITL
                                                               ,IsCentral_GovGty
                                                               ,Is_Oth_GovGty
                                                               ,BranchCode
                                                               ,FacilityType
                                                               ,SancDate
                                                               ,Region
                                                               ,State
                                                               ,Zone
                                        ,NPA_TagDate
                                                               ,PS_NPS
                                                               ,Retail_Corpo
                                                               ,Area
                                                               ,FraudAmt
                                                               ,FraudDate
                                                               ,GovtGtyAmt
                                                               ,GtyRepudiated
                                                               ,RepudiationDate
                                                               ,OTS_Amt
                                                               ,WriteOffAmount
                                                               ,ARC_SaleDate
                                                               ,ARC_SaleAmt
                                                               ,PrincOverdueSinceDt
                                                               ,IntNotServicedDt
                                                               ,ContiExcessDt
                                                               ,ReviewDueDt
                                                               ,OtherOverdueSinceDt
                                                               ,IntOverdueSinceDt
                                                               ,SecuredFlag
                                                               ,StkStmtDate
                                                               ,SecurityValue
                                                               ,DFVAmt
                                                               ,CoverGovGur
                                                               ,CreditsinceDt
                                                               ,DegReason
                                                               ,NetBalance
                                                               ,ApprRV
                                                               ,SecuredAmt
                                                               ,UnSecuredAmt
                                                               ,ProvDFV
                                                               ,Provsecured
                                                               ,ProvUnsecured
                                                               ,ProvCoverGovGur
                                                               ,AddlProvision
                                                               ,TotalProvision
                                                               ,BankProvsecured
                                                               ,BankProvUnsecured
                                                               ,BankTotalProvision
                                                               ,RBIProvsecured
                                                               ,RBIProvUnsecured
                                                               ,RBITotalProvision
                                                               ,SMA_Dt
                                                               ,UpgDate
                                                               ,ProvisionAlt_Key
                                                               ,PNPA_Reason
                                                               ,SMA_Class
                                                               ,SMA_Reason
                                                               ,CommonMocTypeAlt_Key
                                                               ,FlgDeg
                                                               ,FlgSMA
      ,FlgPNPA
                                                               ,FlgUpg
                                                               ,FlgFITL
                                                               ,FlgAbinitio
                                                               ,NPA_Days
                                                               ,AppGovGur
                                                               ,UsedRV
                                                               ,ComputedClaim
                                                               ,NPA_Reason
                                                               ,PnpaAssetClassAlt_key
                                                               ,SecApp
                                                               ,ProvPerSecured
                                                               ,ProvPerUnSecured
                                                               ,AddlProvisionPer
                                                               ,FlgINFRA
                                                               ,MOCTYPE
                                                               ,DPD_IntService
                                                               ,DPD_StockStmt
                                                               ,DPD_FinMaxType
                                                               ,DPD_PrincOverdue
                                                               ,DPD_OtherOverdueSince
                                                               ,IsPUI
                                                               ,AC_Closed_Date
                                                               ,SECTOR
															   ,FlgMOC
															   ,FlgProcessing

															   ,IsFunded
															   ,UploadID -- Added by SSK 0n 14032023 to store MOC Upload ID
                                                 
												  )
					               	SELECT	DISTINCT

								                               
                                                               A.NCIF_Id
                                                               ,A.NCIF_Changed
                                                               ,A.SrcSysAlt_Key
                                                               ,A.NCIF_EntityID
                                                               ,A.CustomerId
                                                               ,A.CustomerName
                                                               ,A.PAN
                                                               --,A.NCIF_AssetClassAlt_Key
															   ,CASE WHEN B.AC_AssetClassAlt_Key<>7 then b.AC_AssetClassAlt_Key ELSE A.NCIF_AssetClassAlt_Key end AS NCIF_AssetClassAlt_Key
                                                               --,A.NCIF_NPA_Date
															   ,CASE WHEN B.AC_AssetClassAlt_Key<>7 then b.AC_NPA_Date ELSE A.NCIF_NPA_Date end AS NCIF_NPA_Date
                                                               ,A.AccountEntityID
                                                               ,A.CustomerACID
                                                               ,A.SanctionedLimit
                                                               ,A.DrawingPower
                                                               ,CASE WHEN (B.PrincipleOutstanding IS NULL) THEN A.PrincipleOutstanding ELSE B.PrincipleOutstanding END as PrincipleOutstanding
                                                               ,CASE WHEN (B.Balance IS NULL) THEN A.Balance ELSE  B.Balance  END as Balance
                                                               ,A.Overdue
                                                               ,A.DPD_Overdue_Loans
                                                               ,A.DPD_Interest_Not_Serviced
                                                               ,A.DPD_Overdrawn
                                                               ,A.DPD_Renewals
                                                               ,A.MaxDPD
                                                               ,A.WriteOffFlag
                                                               ,A.Segment
                                                               ,A.SubSegment
                                                               ,A.ProductCode
                                                               ,A.ProductDesc
                                                               ,A.Settlement_Status
                                                               ,A.AC_AssetClassAlt_Key
                                                               ,A.AC_NPA_Date
                                                               ,A.AstClsChngByUser
                                                               ,A.AstClsChngDate
                                                               ,A.AstClsChngRemark
                                                               ,'Y' AS MOC_Status
                                                               ,GETDATE() AS MOC_Date
                                                               ,B.ACMOC_ReasonAlt_Key
                                                               ,A.MOC_AssetClassAlt_Key
                                                               ,A.MOC_NPA_Date
                                                               ,B.AuthorisationStatus
                                                               ,@TimeKey
                                                               ,@TimeKey
                                                               ,B.CreatedBy
                                                               ,B.DateCreated
                                                               ,B.ModifiedBy
                                                               ,B.DateModified
                                                               ,B.ApprovedBy
                                                               ,B.DateApproved
                                                               ,B.MOC_Remark
                                                               --,A.D2Ktimestamp
                                                               ,A.ProductType
                                                               ,A.ActualOutStanding
                                                               ,A.MaxDPD_Type
                                                               ,A.ProductAlt_Key
                                                               ,A.AstClsAppRemark
                                                               ,A.MocAppRemark
                                                               ,A.PNPA_Status
                                                               ,A.PNPA_ReasonAlt_Key
                                                               ,A.PNPA_Date
                                                               ,A.ActualPrincipleOutstanding
                                                               ,A.UNSERVED_INTEREST	
                                                               ,A.CUSTOMER_IDENTIFIER
                                                               ,A.ACCOUNT_LEVEL_CODE
                                                               ,A.NF_PNPA_Date
                                                               ,A.Remark
                                                               ,A.WriteOffDate
                                                               ,A.DbtDT
                                                               ,A.ErosionDT
                                                               ,A.FlgErosion
                                                               ,CASE WHEN (B.IntOverdue IS NULL) THEN A.IntOverdue ELSE  B.IntOverdue END as IntOverdue
                                                               ,A.IntAccrued
                                                               ,A.OtherOverdue
                                                               ,A.PrincOverdue
                                                               ,A.IsRestructured
                                                               ,A.IsOTS
                                                               ,A.IsTWO
                                                               ,A.IsARC_Sale
                                                               ,A.IsFraud
                                                               ,A.IsWiful
                                                               ,A.IsNonCooperative
                                                               ,A.IsSuitFiled
                                                               ,A.IsRFA
                                                               ,A.IsFITL
                                                               ,A.IsCentral_GovGty
                                                               ,A.Is_Oth_GovGty
                                                               ,A.BranchCode
                                                               ,A.FacilityType
                                                               ,A.SancDate
                                                               ,A.Region
                                                               ,A.State
                                                               ,A.Zone
                                                               ,A.NPA_TagDate
                                                               ,A.PS_NPS
                                                               ,A.Retail_Corpo
                                                               ,A.Area
                                                               ,A.FraudAmt
                                                               ,A.FraudDate
                                                               ,A.GovtGtyAmt
                                                               ,A.GtyRepudiated
                                                               ,A.RepudiationDate
                                                               ,A.OTS_Amt
                                                               ,A.WriteOffAmount
                                                               ,A.ARC_SaleDate
                                                               ,A.ARC_SaleAmt
                                                               ,A.PrincOverdueSinceDt
                                                               ,A.IntNotServicedDt
                                                               ,A.ContiExcessDt
                                                               ,A.ReviewDueDt
                                                               ,A.OtherOverdueSinceDt
                                                               ,A.IntOverdueSinceDt
                                                               ,A.SecuredFlag
                                                               ,A.StkStmtDate
                                                               --,A.SecurityValue   /* (commented implemented at 04052023 at prod) */
															   ,CASE WHEN (B.SecurityValue IS NULL) THEN A.SecurityValue ELSE B.SecurityValue END as SecurityValue /* (implemented at 04052023 at prod) */
                                                               ,A.DFVAmt
                                                               ,A.CoverGovGur
                                                               ,A.CreditsinceDt
                                                               ,CAST(A.DegReason AS varchar(500))
                                                               ,A.NetBalance
                                                               ,A.ApprRV        /* (uncommented implemented at 04052023 at prod) */
															  -- ,CASE WHEN (B.ApprRV IS NULL) THEN A.ApprRV ELSE	 B.ApprRV END as ApprRV /* (implemented at 04052023 at prod) */

                                                               ,A.SecuredAmt
                                                               ,A.UnSecuredAmt
                                                               ,A.ProvDFV
                                                               ,A.Provsecured
                                                               ,A.ProvUnsecured
                                                              ,A.ProvCoverGovGur
                                                               ,CASE WHEN (B.AddlProvision IS NULL) THEN A.AddlProvision ELSE	 B.AddlProvision END as AddlProvision
                                                               ,A.TotalProvision
                                                               ,A.BankProvsecured
                                                               ,A.BankProvUnsecured
                                                               ,A.BankTotalProvision
                                                               ,A.RBIProvsecured
                                                               ,A.RBIProvUnsecured
                                                               ,A.RBITotalProvision
                                                               ,A.SMA_Dt
                                                               ,A.UpgDate
                                                               ,A.ProvisionAlt_Key
                                                               ,CAST(A.PNPA_Reason AS VARCHAR(16))
                                                               ,A.SMA_Class
                                                               ,CAST(A.SMA_Reason AS VARCHAR(16))
                                                               ,A.CommonMocTypeAlt_Key
                                                               ,A.FlgDeg
                                                               ,A.FlgSMA
                                                               ,A.FlgPNPA
                                                               ,A.FlgUpg
                                                               ,A.FlgFITL
                                                               ,A.FlgAbinitio
                                                               ,A.NPA_Days
                                                               ,A.AppGovGur
                                                               ,A.UsedRV
                                                               ,A.ComputedClaim
                                                               ,CAST(A.NPA_Reason AS VARCHAR(16))
                                                               ,A.PnpaAssetClassAlt_key
                                                               ,A.SecApp
                                                               ,A.ProvPerSecured
                                                               ,A.ProvPerUnSecured
                                                               ,CASE WHEN (B.AddlProvisionPer IS NULL) THEN	A.AddlProvisionPer	ELSE      B.AddlProvisionPer END as AddlProvisionPer
                                                               ,A.FlgINFRA
                                                               ,A.MOCTYPE
                                                               ,A.DPD_IntService
                                                               ,A.DPD_StockStmt
                                                               ,A.DPD_FinMaxType
                                                               ,A.DPD_PrincOverdue
                                                               ,A.DPD_OtherOverdueSince
                                                               ,A.IsPUI
                                                               ,A.AC_Closed_Date
                                                               ,A.SECTOR
															   ,'Y' as  FlgMOC
															   ,'Y'

															   ,A.IsFunded
															   ,B.UploadID -- Added by SSK on 14032023 to store MOC Upload ID /* (implemented at 04052023 at prod) */
                                                   			from #ACCOUNT_CAL A
						                                INNER JOIN dbo.NPA_IntegrationDetails_mod B ON A.CustomerAcID=B.CustomerAcID
														                 -- And B.AuthorisationStatus='A'
								                                   where (b.EffectiveFromTimeKey=@TimeKey and b.EffectiveToTimeKey =@TimeKey)
																AND B.UploadID=@UniqueUploadID
																AND B.AuthorisationStatus='A'
																	  

							---pre moc
							

						INSERT INTO PreMoc.NPA_IntegrationDetails
								(
										 NCIF_Id
                                                               ,NCIF_Changed
                                                               ,SrcSysAlt_Key
                                                               ,NCIF_EntityID
                                                               ,CustomerId
                                                               ,CustomerName
                                                               ,PAN
                                                               ,NCIF_AssetClassAlt_Key
                                                               ,NCIF_NPA_Date
                                                               ,AccountEntityID
                                                               ,CustomerACID
                                                               ,SanctionedLimit
                                                               ,DrawingPower
                                                               ,PrincipleOutstanding
                                                               ,Balance
                                                               ,Overdue
                                                               ,DPD_Overdue_Loans
                                                               ,DPD_Interest_Not_Serviced
                                                               ,DPD_Overdrawn
                                                               ,DPD_Renewals
															   ,MaxDPD
                                                               ,WriteOffFlag
                                                               ,Segment
                                                               ,SubSegment
                                                               ,ProductCode
                                                               ,ProductDesc
                                                               ,Settlement_Status
                                                               ,AC_AssetClassAlt_Key
                                                               ,AC_NPA_Date
                                                               ,AstClsChngByUser
                                                               ,AstClsChngDate
                                                               ,AstClsChngRemark
                                                               ,MOC_Status
                                                               ,MOC_Date
                                                               ,MOC_ReasonAlt_Key
                                                               ,MOC_AssetClassAlt_Key
                                                               ,MOC_NPA_Date
                                                               ,AuthorisationStatus
                                                               ,EffectiveFromTimeKey
                                                               ,EffectiveToTimeKey
                                                               ,CreatedBy
                                                               ,DateCreated
                                                               ,ModifiedBy
                                                               ,DateModified
                                                               ,ApprovedBy
                                                               ,DateApproved
                                                               ,MOC_Remark
                                                               --,D2Ktimestamp
                                                               ,ProductType
                                                               ,ActualOutStanding
                                                               ,MaxDPD_Type
                                                               ,ProductAlt_Key
                                                               ,AstClsAppRemark
                                                               ,MocAppRemark
                                                               ,PNPA_Status
                                                               ,PNPA_ReasonAlt_Key
                                                               ,PNPA_Date
                                                               ,ActualPrincipleOutstanding
                                                               ,UNSERVED_INTEREST
                                                               ,CUSTOMER_IDENTIFIER
                                                               ,ACCOUNT_LEVEL_CODE
                                                               ,NF_PNPA_Date
                                                               ,Remark
                                                               ,WriteOffDate
                                                               ,DbtDT
                                                               ,ErosionDT
                                                               ,FlgErosion
                                                               ,IntOverdue
                                                               ,IntAccrued
                                                               ,OtherOverdue
                                                               ,PrincOverdue
															   ,IsRestructured
                                                               ,IsOTS
                                                               ,IsTWO
                                                               ,IsARC_Sale
                                                               ,IsFraud
                                                               ,IsWiful
                                                               ,IsNonCooperative
                                                               ,IsSuitFiled
                                                               ,IsRFA
                                                               ,IsFITL
                                                               ,IsCentral_GovGty
                                                               ,Is_Oth_GovGty
                                                               ,BranchCode
                                                               ,FacilityType
                                                               ,SancDate
                                                               ,Region
                                                               ,State
                                                               ,Zone
                                                               ,NPA_TagDate
                                                               ,PS_NPS
                                                               ,Retail_Corpo
                                                               ,Area
                                                               ,FraudAmt
                                                               ,FraudDate
                                                               ,GovtGtyAmt
                                                               ,GtyRepudiated
                                                               ,RepudiationDate
                                                               ,OTS_Amt
                                                               ,WriteOffAmount
                                                               ,ARC_SaleDate
                                                               ,ARC_SaleAmt
                                                               ,PrincOverdueSinceDt
                                                               ,IntNotServicedDt
                                                               ,ContiExcessDt
                                                               ,ReviewDueDt
                                                               ,OtherOverdueSinceDt
                                                               ,IntOverdueSinceDt
                                                               ,SecuredFlag
                                                               ,StkStmtDate
                                                               ,SecurityValue
                                                               ,DFVAmt
                                                               ,CoverGovGur
                                                               ,CreditsinceDt
                                                               ,DegReason
                                                               ,NetBalance
                                                               ,ApprRV
                                                               ,SecuredAmt
                                                               ,UnSecuredAmt
                                                               ,ProvDFV
                                                               ,Provsecured
                                                               ,ProvUnsecured
                                                               ,ProvCoverGovGur
															   ,AddlProvision
                                                               ,TotalProvision
                                                               ,BankProvsecured
                                                               ,BankProvUnsecured
                                                               ,BankTotalProvision
                                                               ,RBIProvsecured
                                                               ,RBIProvUnsecured
                                                               ,RBITotalProvision
                                                               ,SMA_Dt
                                                               ,UpgDate
                                                               ,ProvisionAlt_Key
                                                               ,PNPA_Reason
                                                               ,SMA_Class
                                                               ,SMA_Reason
                                                               ,CommonMocTypeAlt_Key
                                                               ,FlgDeg
                                                               ,FlgSMA
                                                               ,FlgPNPA
                                                               ,FlgUpg
                                                               ,FlgFITL
                                                               ,FlgAbinitio
                                                               ,NPA_Days
                                                               ,AppGovGur
                                                               ,UsedRV
                                                               ,ComputedClaim
                                                               ,NPA_Reason
                                                               ,PnpaAssetClassAlt_key
                                                               ,SecApp
                                                               ,ProvPerSecured
                                                               ,ProvPerUnSecured
                                                               ,AddlProvisionPer
                                                               ,FlgINFRA
                                                               ,MOCTYPE
                                                               ,DPD_IntService
                                                               ,DPD_StockStmt
                                                               ,DPD_FinMaxType
                                                               ,DPD_PrincOverdue
                                                               ,DPD_OtherOverdueSince
                                                               ,IsPUI
                                                               ,AC_Closed_Date
                                                               ,SECTOR
															   ,FlgMoc

															   ,IsFunded
															   , UploadID -- Added by SSK on 14032023
                                                 
												  )
					               SELECT

								                               
                                                               A.NCIF_Id
                                                               ,A.NCIF_Changed
                                                               ,A.SrcSysAlt_Key
                                                               ,A.NCIF_EntityID
                                                               ,A.CustomerId
                                                               ,A.CustomerName
                                                               ,A.PAN
                                                               ,A.NCIF_AssetClassAlt_Key
																,A.NCIF_NPA_Date
                                                               ,A.AccountEntityID
                                                               ,A.CustomerACID
                                                               ,A.SanctionedLimit
                                                               ,A.DrawingPower
                                                               ,A.PrincipleOutstanding
                                                               ,A.Balance
                                                               ,A.Overdue
                                                               ,A.DPD_Overdue_Loans
                                                               ,A.DPD_Interest_Not_Serviced
                                                               ,A.DPD_Overdrawn
                                                               ,A.DPD_Renewals
                                                               ,A.MaxDPD
                                                               ,A.WriteOffFlag
                                                               ,A.Segment
                                                               ,A.SubSegment
                                                               ,A.ProductCode
                                                               ,A.ProductDesc
                                                               ,A.Settlement_Status
                                                               ,A.AC_AssetClassAlt_Key
                                                               ,A.AC_NPA_Date
                                                               ,A.AstClsChngByUser
                                                               ,A.AstClsChngDate
                                                               ,A.AstClsChngRemark
                                                               ,A.MOC_Status
                                                               ,A.MOC_Date
                                                               ,A.MOC_ReasonAlt_Key
                                                               ,A.MOC_AssetClassAlt_Key
                                                               ,A.MOC_NPA_Date
                                                               ,A.AuthorisationStatus
                                                               ,@TimeKey
                                                               ,@TimeKey
                                                               ,A.CreatedBy
                                                               ,A.DateCreated
                                                               ,A.ModifiedBy
                                                               ,A.DateModified
                                                               ,A.ApprovedBy
                                                               ,A.DateApproved
                                                               ,A.MOC_Remark
                                                               --,A.D2Ktimestamp
                                                               ,A.ProductType
                                                               ,A.ActualOutStanding
                                                               ,A.MaxDPD_Type
                                                               ,A.ProductAlt_Key
                                                               ,A.AstClsAppRemark
                                                               ,A.MocAppRemark
                                                               ,A.PNPA_Status
                                                               ,A.PNPA_ReasonAlt_Key
                                                               ,A.PNPA_Date
                                                               ,A.ActualPrincipleOutstanding
                                                              ,A.UNSERVED_INTEREST	
                                                               ,A.CUSTOMER_IDENTIFIER
                                                               ,A.ACCOUNT_LEVEL_CODE
                                                               ,A.NF_PNPA_Date
                                                               ,A.Remark
                                                               ,A.WriteOffDate
                                                               ,A.DbtDT
                                                               ,A.ErosionDT
                                                               ,A.FlgErosion
                                                               ,A.IntOverdue
                                                               ,A.IntAccrued
                                                               ,A.OtherOverdue
                                                               ,A.PrincOverdue
                                                               ,A.IsRestructured
                                                               ,A.IsOTS
                                                               ,A.IsTWO
                                                               ,A.IsARC_Sale
                                                               ,A.IsFraud
                                                               ,A.IsWiful
                                                               ,A.IsNonCooperative
                                                               ,A.IsSuitFiled
                                                               ,A.IsRFA
                                                               ,A.IsFITL
                                                               ,A.IsCentral_GovGty
                                                               ,A.Is_Oth_GovGty
                                                               ,A.BranchCode
                                                               ,A.FacilityType
                                                               ,A.SancDate
                                                               ,A.Region
                                                               ,A.State
                                                               ,A.Zone
                                                               ,A.NPA_TagDate
                                                               ,A.PS_NPS
                                                               ,A.Retail_Corpo
                                                               ,A.Area
                                                               ,A.FraudAmt
                                                               ,A.FraudDate
                                                               ,A.GovtGtyAmt
                                                               ,A.GtyRepudiated
                                                               ,A.RepudiationDate
                                                               ,A.OTS_Amt
                                                               ,A.WriteOffAmount
                                                               ,A.ARC_SaleDate
                                                               ,A.ARC_SaleAmt
                                                               ,A.PrincOverdueSinceDt
                                                               ,A.IntNotServicedDt
                                                               ,A.ContiExcessDt
                                                               ,A.ReviewDueDt
                                                               ,A.OtherOverdueSinceDt
                                                               ,A.IntOverdueSinceDt
																,A.SecuredFlag
                                                               ,A.StkStmtDate
                                                               ,A.SecurityValue
                                                               ,A.DFVAmt
                                                               ,A.CoverGovGur
                                                               ,A.CreditsinceDt
                                                               ,A.DegReason
                                                               ,A.NetBalance
                                                               ,A.ApprRV
                                                               ,A.SecuredAmt
                                                               ,A.UnSecuredAmt
                                                               ,A.ProvDFV
                                                               ,A.Provsecured
                                                               ,A.ProvUnsecured
                                                               ,A.ProvCoverGovGur
                                                               ,A.AddlProvision
                                                               ,A.TotalProvision
                                                               ,A.BankProvsecured
                                                               ,A.BankProvUnsecured
                                                               ,A.BankTotalProvision
                                                               ,A.RBIProvsecured
                                                               ,A.RBIProvUnsecured
                                                               ,A.RBITotalProvision
                                                               ,A.SMA_Dt
                                                               ,A.UpgDate
                                                               ,A.ProvisionAlt_Key
                                                               ,A.PNPA_Reason
                                                               ,A.SMA_Class
                                                               ,A.SMA_Reason
                                                               ,A.CommonMocTypeAlt_Key
                                                               ,A.FlgDeg
                                                               ,A.FlgSMA
                                                               ,A.FlgPNPA
                                                               ,A.FlgUpg
                                                               ,A.FlgFITL
                                                               ,A.FlgAbinitio
                                                               ,A.NPA_Days
                                                               ,A.AppGovGur
                                                               ,A.UsedRV
                                                               ,A.ComputedClaim
                                                               ,A.NPA_Reason
                                                               ,A.PnpaAssetClassAlt_key
                                                               ,A.SecApp
                                                               ,A.ProvPerSecured
                                                               ,A.ProvPerUnSecured
                                                               ,A.AddlProvisionPer
                                                               ,A.FlgINFRA
                                                               ,A.MOCTYPE
                                                               ,A.DPD_IntService
                                                               ,A.DPD_StockStmt
                                                               ,A.DPD_FinMaxType
                                                               ,A.DPD_PrincOverdue
                                                               ,A.DPD_OtherOverdueSince
                                                               ,A.IsPUI
                                                               ,A.AC_Closed_Date
                                                               ,A.SECTOR
                                                               ,'Y' as FlgMoc

															   ,A.IsFunded
															   ,C.UploadID -- Added by SSK on 14032023
							from #ACCOUNT_CAL A
							INNER JOIN NPA_IntegrationDetails_mod C ON A.CustomerAcID=C.CustomerAcID
								LEFT JOIN premoc.NPA_IntegrationDetails B
									ON (B.EffectiveFromTimeKey=@TimeKey AND B.EffectiveToTimeKey=@TimeKey) 
									AND A.CustomerACID=B.CustomerACID
								WHERE  (c.EffectiveFromTimeKey<=@TimeKey AND c.EffectiveToTimeKey> =@TimeKey)
								AND C.UploadID=@UniqueUploadID
								AND C.AuthorisationStatus='A'
								and B.CustomerAcID is null




		Update  A
			Set A.EffectiveToTimeKey=A.EffectiveFromTimeKey-1
			from  NPA_IntegrationDetails_Mod A
			WHERE UploadId=@UniqueUploadID

				UPDATE
				ExcelUploadHistory
				SET AuthorisationStatus='A',ApprovedBy=@UserLoginID,DateApproved=GETDATE()
				WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
				AND UniqueUploadID=@UniqueUploadID
				AND UploadType='Account MOC Upload'

				


	END


	IF (@OperationFlag=17)	---- FIRST LEVEL REJECT
	BEGIN
		UPDATE NPA_IntegrationDetails_mod 
		SET 
			AuthorisationStatus	='R'
			,ApprovedByFirstLevel	=@UserLoginID
			,DateApprovedFirstLevel	=GETDATE()
		WHERE UploadId=@UniqueUploadID
		AND AuthorisationStatus='NP'
		AND CreatedBy<> @UserLoginID
		
		UPDATE ExcelUploadHistory
		SET 
			AuthorisationStatus='R'
			,ApprovedByFirstLevel=@UserLoginID
			,DateApprovedFirstLevel=GETDATE()
		WHERE (EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey)
		AND UniqueUploadID=@UniqueUploadID
		AND UploadType='Account MOC Upload'

		-- Added by SATWAJI as on 18/04/2022 /* (implemented at 04052023 at prod) */
		UPDATE AcceleratedProv_MOD 
		SET 
			AuthorisationStatus	='R'
			,ApprovedByFirstLevel	=@UserLoginID
			,DateApprovedFirstLevel	=GETDATE()
		WHERE UploadId=@UniqueUploadID
		AND AuthorisationStatus='NP'
	END

IF (@OperationFlag=21)----REJECT

	BEGIN
		
		UPDATE 
			NPA_IntegrationDetails_mod 
			SET 
			AuthorisationStatus	='R'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			WHERE UploadId=@UniqueUploadID
			AND AuthorisationStatus in('NP','1A')
			AND (CreatedBy<>@UserLoginID
			OR ApprovedByFirstLevel<>@UserLoginID)
			

			UPDATE
				ExcelUploadHistory
				SET AuthorisationStatus='R',ApprovedBy=@UserLoginID,DateApproved=GETDATE()
				WHERE EffectiveFromTimeKey<=@Timekey AND EffectiveToTimeKey>=@Timekey
				AND UniqueUploadID=@UniqueUploadID
				AND UploadType='Account MOC Upload'

			-- Added by SATWAJI as on 18/04/2022 /* (implemented at 04052023 at prod) */
			UPDATE 
			AcceleratedProv_MOD 
			SET 
			AuthorisationStatus	='R'
			,ApprovedBy	=@UserLoginID
			,DateApproved	=GETDATE()
			WHERE UploadId=@UniqueUploadID
			AND AuthorisationStatus in('NP','1A')
	END


END


	--COMMIT TRAN
		---SET @Result=CASE WHEN  @OperationFlag=1 THEN @UniqueUploadID ELSE 1 END
		SET @Result=CASE WHEN  @OperationFlag=1 AND @MenuId=101 THEN @ExcelUploadId 
					ELSE 1 END

		
		 Update UploadStatus Set InsertionOfData='Y',InsertionCompletedOn=GETDATE() where FileNames=@filepath

		 ---- IF EXISTS(SELECT 1 FROM IBPCPoolDetail_stg WHERE filEname=@FilePathUpload)
		 ----BEGIN
			----	 DELETE FROM IBPCPoolDetail_stg
			----	 WHERE filEname=@FilePathUpload

			----	 PRINT 'ROWS DELETED FROM IBPCPoolDetail_stg'+CAST(@@ROWCOUNT AS VARCHAR(100))
		 ----END
		 

		RETURN @Result
		------RETURN @UniqueUploadID
	END TRY
	BEGIN CATCH 
	   --ROLLBACK TRAN
	SELECT ERROR_MESSAGE(),ERROR_LINE()
	SET @Result=-1
	 Update UploadStatus Set InsertionOfData='Y',InsertionCompletedOn=GETDATE() where FileNames=@filepath
	--RETURN -1
	END CATCH

END
GO