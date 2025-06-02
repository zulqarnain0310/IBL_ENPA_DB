SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
--EXEC dbo.AuditAPISelectCommon '','Cust1','','','2P'
CREATE PROCEDURE [dbo].[AuditAPISelectCommon]
(
       @PANNo       VARCHAR(10) 	= N'',
       @NCIF_Id     VARCHAR(10) 	= N'',
       @Aadhar		VARCHAR(2000)	= N'',
	   @VoterId		VARCHAR(20)		= N'',  
	   @Request		VARCHAR(10)		='2P'		 
)
AS

BEGIN 

	SET NOCOUNT OFF;
	SET STATISTICS TIME OFF;

	SET DATEFORMAT DMY;

	IF @Request ='4P'
	BEGIN 
		IF OBJECT_ID('Tempdb..#TempAuditPAN_4P') IS NOT NULL
    	DROP TABLE #TempAuditPAN_4P

		CREATE TABLE dbo.#TempAuditPAN_4P
				(
					CountPAN				BIGINT		   NULL,
					NCIF_Id					VARCHAR(100)   NULL,
					SourceName				VARCHAR(50)    NULL,
					CustomerId				VARCHAR(20)    NULL,
					CustomerACID			VARCHAR(20)    NULL,
					CustomerName			VARCHAR(500)   NULL,
					ARCFLAG					VARCHAR(1)	   NULL,
					IsRestructured			VARCHAR(1)	   NULL,
					OTS						VARCHAR(1)	   NULL,
					fraud					VARCHAR(1)	   NULL,
					WriteOffFlag			VARCHAR(1)	   NULL,
					ARC_SaleDate			VARCHAR(10)	   NULL,
					Writeoffdate			VARCHAR(10)    NULL,
					RestructureDt			VARCHAR(10)    NULL,
					PrincipleOutstanding	DECIMAL(16, 2) NOT NULL,
					Balance					DECIMAL(16, 2) NOT NULL,
					Segment					VARCHAR(100)   NULL,
					ProductCode				VARCHAR(50)    NULL,
					FacilityType			VARCHAR(10)    NULL,
					AC_NPA_Date				VARCHAR(10)    NULL,
					NCIF_AssetClassAlt_Key  SMALLINT	   NULL,
					NCIF_NPA_Date			VARCHAR(10)    NULL,
					Status					VARCHAR(3)     NOT NULL,
					MaxDPD					INT			   NULL,
					IsSuitFiled				VARCHAR(1)	   NULL,	
					PAN						VARCHAR(20)	   NULL,
					Voter_ID				VARCHAR(2000)  NULL,
					AADHAR_ID				VARCHAR(2000)  NULL,
					Matched_Criteria		VARCHAR(1000)  NULL
			 ) ON [PRIMARY]
	END

	IF @Request = '2P'
	BEGIN 
 		IF OBJECT_ID('Tempdb..#TempAuditPAN_2P') IS NOT NULL  
        DROP TABLE #TempAuditPAN_2P  
		
		CREATE TABLE dbo.#TempAuditPAN_2P
			(  
				 CountPAN				BIGINT			NULL,  
				 PAN					VARCHAR(100)	NULL, 
				 NCIF_Id				VARCHAR(100)	NULL,  
				 SourceName				VARCHAR(50)		NULL,  
				 CustomerId				VARCHAR(20)		NULL,  
				 CustomerACID			VARCHAR(20)		NULL,  
				 CustomerName			VARCHAR(500)	NULL,  
				 ARCFLAG				VARCHAR(1)		NULL,  
				 IsRestructured			VARCHAR(1)		NULL,  
				 OTS					VARCHAR(1)		NULL,  
				 fraud					VARCHAR(1)		NULL,  
				 WriteOffFlag			VARCHAR(1)		NULL,  
				 Writeoffdate			VARCHAR(10)		NULL,  
				 ARC_SaleDate			VARCHAR(10)		NULL,  
				 RestructureDt			VARCHAR(10)		NULL,  
				 PrincipleOutstanding	DECIMAL(16, 2)	NOT NULL,  
				 Balance				DECIMAL(16, 2)	NOT NULL,  
				 Segment				VARCHAR(100)	NULL,  
				 ProductCode			VARCHAR(50)		NULL,  
				 FacilityType			VARCHAR(10)		NULL,  
				 AC_NPA_Date			VARCHAR(10)		NULL,  
				 NCIF_AssetClassAlt_Key SMALLINT		NULL,  
				 NCIF_NPA_Date			VARCHAR(10)		NULL,  
				 Status					VARCHAR(3)		NOT NULL,  
				 MaxDPD					INT				NULL,  
				 IsSuitFiled			VARCHAR(1)		NULL 
			) ON [PRIMARY]  
  
	END
	--=========================================================================================================-------
	--			Basic Validations																					--
	--=========================================================================================================-------
	--1) If Pan & Voter Id Both Parameter having blank Values 

	IF LEN(ISNULL(@PANNo,''))= 0 AND LEN(ISNULL(@NCIF_Id,''))=0 AND (LEN(@Aadhar)<>0 AND LEN(@NCIF_Id)<>0) AND @Request ='2P'
    BEGIN
		SELECT 'Please Provide Atleast One Value...Either PanNo Or NCIF_Id' As Remark
		INSERT INTO Log_APIAudit (PAN,NCIF_Id,RecordCount,AADHAR,VOTERID,Date,Time,Remark)
		SELECT @PANNO					AS PANNO,
               @NCIF_Id					AS NCIF_Id,
               0						AS RecordCount,
               NULL						AS AADHAR,
			   NULL						AS VOTERID,
               CAST(GETDATE() AS DATE)  AS DATECUR,
               CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,
               'Please Provide Atleast One Value...Either PanNo or NCIF_Id or Aadhar or VoterId' AS Remark 
		RETURN 
	END

	--2) If Both Parameter value provided by User 
	IF LEN(ISNULL(@PANNo,''))>0 AND LEN(ISNULL(@NCIF_Id,''))>0 AND @Request ='2P'
	BEGIN 
		SELECT 'Please Provide Only One Value...Either PanNo or NCIF_Id' As Remark
		INSERT INTO Log_APIAudit (PAN,NCIF_Id,RecordCount,AADHAR,VOTERID,Date,Time,Remark)
		SELECT @PANNO					AS PANNO,
               @NCIF_Id					AS NCIF_Id,
               0						AS RecordCount,
               NULL						AS AADHAR,
			   NULL						AS VOTERID,
               CAST(GETDATE() AS DATE)  AS DATECUR,
               CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,
               'Wrong Value Entered' AS Remark 
	END

	--3) If PAN Parameter value provided by User but it invalid as per format 
	IF LEN(ISNULL(@PANNo,''))>0 AND @PANNo NOT LIKE '[A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]'   
	BEGIN 
		SELECT 'Invalid Pan Details' As Remark
		INSERT INTO Log_APIAudit (PAN,NCIF_Id,RecordCount,AADHAR,VOTERID,Date,Time,Remark)
		SELECT @PANNO					AS PANNO,
               @NCIF_Id					AS NCIF_Id,
               0						AS RecordCount,
               NULL						AS AADHAR,
			   NULL						AS VOTERID,
               CAST(GETDATE() AS DATE)  AS DATECUR,
               CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,
               'Invalid Pan Details' AS Remark 
	END

	--4) If CIF ID Parameter value provided by User but it invalid as per format 
	IF LEN(ISNULL(@NCIF_Id,''))>0 AND LEN(ISNULL(@NCIF_Id,''))>9 AND ISNUMERIC (@NCIF_Id) = 0  
	BEGIN 
		SELECT 'Invalid NCif ID Details' As Remark
		INSERT INTO Log_APIAudit (PAN,NCIF_Id,RecordCount,AADHAR,VOTERID,Date,Time,Remark)
		SELECT @PANNO					AS PANNO,
               @NCIF_Id					AS NCIF_Id,
               0						AS RecordCount,
               NULL						AS AADHAR,
			   NULL						AS VOTERID,
               CAST(GETDATE() AS DATE)  AS DATECUR,
               CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,
               'Invalid NCif ID Details' AS Remark 
	END

	--5) IF Request Is 4P and All Parameter value are Blank
	IF LEN(ISNULL(@PANNo,''))= 0 AND LEN(ISNULL(@NCIF_Id,''))=0 AND LEN(ISNULL(@Aadhar,''))=0 AND LEN(ISNULL(@VoterId,''))=0 AND (@Request ='4P' OR @Request ='2P')
    BEGIN 
	SELECT 'Please Provide Atleast One Value...Either PanNo or NCIF_Id or Aadhar or VoterId' As Remark
		INSERT INTO Log_APIAudit (PAN,NCIF_Id,RecordCount,AADHAR,VOTERID,Date,Time,Remark)
		SELECT @PANNO					AS PANNO,
               @NCIF_Id					AS NCIF_Id,
               0						AS RecordCount,
               NULL						AS AADHAR,
			   NULL						AS VOTERID,
               CAST(GETDATE() AS DATE)  AS DATECUR,
               CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,
               'Please Provide Atleast One Value...Either PanNo or NCIF_Id or Aadhar or VoterId' AS Remark 
	END

	IF (LEN(ISNULL(@Aadhar,''))>0 OR LEN(ISNULL(@VoterId,''))>0) AND @Request <>'4P'
    BEGIN 
	SELECT 'Kindly Provide Me Request As 4P' As Remark
		INSERT INTO Log_APIAudit (PAN,NCIF_Id,RecordCount,AADHAR,VOTERID,Date,Time,Remark)
		SELECT @PANNO					AS PANNO,
               @NCIF_Id					AS NCIF_Id,
               0						AS RecordCount,
               NULL						AS AADHAR,
			   NULL						AS VOTERID,
               CAST(GETDATE() AS DATE)  AS DATECUR,
               CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,
               'Kindly Provide Me Request As 4P' AS Remark 
	END
	--==================================================================================================================================--
	--						Fetch The data based on the input values 
	--==================================================================================================================================--
	DECLARE @UCIC TABLE(UCIC VARCHAR(20)) 

	IF @Request ='4P' AND (LEN(ISNULL(@PANNo,''))<> 0 OR LEN(ISNULL(@NCIF_Id,''))<>0 OR LEN(ISNULL(@Aadhar,''))<>0 OR LEN(ISNULL(@VoterId,''))<>0) 
	BEGIN 

		IF OBJECT_ID('Tempdb..#AadharVoterIDdata') IS NOT NULL
   		DROP TABLE #AadharVoterIDdata
		
		SELECT * 
		INTO #AadharVoterIDdata 
		FROM D2K_AADHAR_VOTER_ALL_NEW1 WITH (NOLOCK) WHERE UCIC=@NCIF_ID
		UNION ALL
		SELECT * FROM D2K_AADHAR_VOTER_ALL_NEW1 WITH (NOLOCK) WHERE AADHAR_NO=@AADHAR
		UNION ALL
		SELECT * FROM D2K_AADHAR_VOTER_ALL_NEW1 WITH (NOLOCK) WHERE KYCID=@VOTERID
		UNION ALL
		SELECT * FROM D2K_AADHAR_VOTER_ALL_NEW1 WITH (NOLOCK) WHERE PAN=@PANNO

		INSERT INTO @UCIC		
		SELECT DISTINCT UCIC FROM #AadharVoterIDdata

		IF OBJECT_ID('Tempdb..#NPA_IntegrationDetails_Curnt') IS NOT NULL 
		DROP TABLE #NPA_IntegrationDetails_Curnt

		SELECT NCIF_Id,CustomerId,CustomerACID,CustomerName,
			   IsARC_Sale,IsRestructured,IsOTS,IsFraud,IsTWO,ARC_SaleDate,WriteOffDate,PrincipleOutstanding,Balance,Segment,ProductCode,
			   FacilityType,AC_NPA_Date,NCIF_NPA_Date,NCIF_AssetClassAlt_Key,MaxDPD,IsSuitFiled,PAN,AccountEntityId,SrcSysAlt_Key,
			   EffectiveFromTimeKey,EffectiveToTimeKey
		INTO #NPA_IntegrationDetails_Curnt
		FROM NPA_IntegrationDetails_Curnt WITH (NOLOCK)
		WHERE (PAN=@PANNo OR NCIF_Id=@NCIF_Id OR NCIF_Id IN (SELECT * FROM @UCIC))

		INSERT INTO #TempAuditPAN_4P 
		SELECT
                 ROW_NUMBER() OVER(ORDER BY (SELECT 1))					AS CountPAN
                ,A.NCIF_Id												AS NCIF_ID
                ,D.SourceName											AS SourceName
                ,A.CustomerId											AS CustomerId
                ,A.CustomerACID											AS CustomerACID
                ,A.CustomerName											AS CustomerName
                ,A.IsARC_Sale											AS ARCFLAG
                ,A.IsRestructured										AS IsRestructured
                ,A.IsOTS												AS OTS
                ,A.IsFraud												AS fraud
                ,A.IsTWO												AS WriteOffFlag
                ,CONVERT(VARCHAR(10),A.ARC_SaleDate,103)				AS ARC_SaleDate
                ,CONVERT(VARCHAR(10),A.WriteOffDate,103)				AS Writeoffdate
                ,CONVERT(VARCHAR(10),C.RestructureDt,103)				AS RestructureDt
                ,ISNULL(A.PrincipleOutstanding,0.00)					AS PrincipleOutstanding
                ,ISNULL(A.Balance,0.00)									AS Balance
                ,A.Segment												AS Segment
                ,A.ProductCode											As ProductCode
                ,A.FacilityType											AS FacilityType
                ,CONVERT(VARCHAR(10),A.AC_NPA_Date,103)					AS AC_NPA_Date
                ,A.NCIF_AssetClassAlt_Key								AS NCIF_AssetClassAlt_Key
                ,CONVERT(VARCHAR(10),A.NCIF_NPA_Date,103)				AS NCIF_NPA_Date
                ,(CASE WHEN A.NCIF_AssetClassAlt_Key=1 
							THEN 'STD' 
				  ELSE 'NPA' END)										AS Status
                ,A.MaxDPD												AS MaxDPD
				,A.IsSuitFiled											AS IsSuitFiled 	
				,A.PAN													AS PAN
				,Av.KYCID												AS Voter_ID 
                ,Av.AADHAR_NO											AS AADHAR_ID 
                ,''														AS Matched_Criteria 
            FROM #NPA_IntegrationDetails_Curnt A
            LEFT JOIN CURDAT.AdvAcRestructureDetail_Curnt (nolock) C ON A.AccountEntityId=C.AccountEntityId
            LEFT JOIN DimSourceSystem D								 ON A.SrcSysAlt_Key=D.SourceAlt_Key        
            LEFT JOIN #AadharVoterIDdata AV							 ON A.NCIF_Id=AV.UCIC  
			
			UPDATE #TempAuditPAN_4P SET Matched_Criteria='NCIF_ID'								WHERE NCIF_Id=@NCIF_Id
			UPDATE #TempAuditPAN_4P SET Matched_Criteria=CONCAT(Matched_Criteria,' ,PAN')		WHERE PAN=@PANNo
			UPDATE #TempAuditPAN_4P SET Matched_Criteria=CONCAT(Matched_Criteria,' ,Aadhar')	WHERE AADHAR_ID=@Aadhar
			UPDATE #TempAuditPAN_4P SET Matched_Criteria=CONCAT(Matched_Criteria,' ,Voter_ID')	WHERE Voter_ID=@VoterId
			UPDATE #TempAuditPAN_4P SET Matched_Criteria= REPLACE(Matched_Criteria,' ,','')		WHERE Matched_Criteria LIKE ' ,%' 

			DECLARE @CountPAN INT=(SELECT COUNT(*) FROM #TempAuditPAN_4P)

			IF (@CountPAN>0)
            BEGIN
			
				SELECT * FROM #TempAuditPAN_4P 
				INSERT INTO Log_APIAudit (PAN,NCIF_Id,RecordCount,AADHAR,VOTERID,Date,Time,Remark)
				SELECT @PANNO						AS PANNO,
               		   @NCIF_Id						AS NCIF_Id,
               		   @CountPAN					AS RecordCount,
					   NULL							AS AADHAR,
					   NULL							AS VOTERID,
               		   CAST(GETDATE() AS DATE)		AS DATECUR,
               		   CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,
               		   'Successful'					AS Remark 
			END
			ELSE 
			BEGIN 
				IF (@PANNo <>'' AND @VoterId <>'' AND @Aadhar <>'' AND @NCIF_Id <>'')	
					SELECT 'No Record Available For All Parameters PAN / NCIF_Id / AadharID / VoterID' AS Remark
				ELSE IF @PANNo<>'' AND @NCIF_Id=''
					SELECT 'No Record Available For Pan' AS Remark
				ELSE IF @Aadhar<>'' And @NCIF_Id=''
					SELECT 'No Record Available For AadharID' AS Remark
				ELSE IF @VoterId <>'' And @NCIF_Id='' 
					SELECT 'No Record Available For VoterID' AS Remark
				ELSE 
					SELECT 'No Record Available...' AS Remark
			END	
		
		--Co Borrower Data Prepration 
		IF (@NCIF_Id<>'') AND (@CountPAN=0)
		BEGIN   
			IF OBJECT_ID('Tempdb..#CoBo_Check') IS NOT NULL 
			DROP TABLE #CoBo_Check
		
			SELECT 'ABCD'

			SELECT NCIFID_COBORROWER,NCIFID_PrimaryAccount,AcDegDate,AcDegFlg
			INTO #CoBo_Check 
			FROM  dbo.CoBorrowerData_curnt (nolock) 
			WHERE NCIFID_COBORROWER IN (@NCIF_Id) OR NCIFID_COBORROWER IN(SELECT UCIC FROM @UCIC)
			
			IF (SELECT 1 FROM #CoBo_Check)> 0
			BEGIN 

				IF OBJECT_ID('Tempdb..#NCIF_NIdata') IS NOT NULL 
				DROP TABLE #NCIF_NIdata
				SELECT DISTINCT NCIF_Id 
				INTO #NCIF_NIdata 
				FROM NPA_IntegrationDetails_Curnt
				WHERE NCIF_Id IN (SELECT NCIFID_PrimaryAccount FROM #CoBo_Check 
								  UNION
								  SELECT NCIFID_COBORROWER FROM #CoBo_Check
								 )
		
				IF OBJECT_ID('Tempdb..#Cobodata') IS NOT NULL 
				DROP TABLE #Cobodata
	
				SELECT DISTINCT a.NCIFID_COBORROWER,a.AcDegDate,a.AcDegFlg
				INTO #Cobodata 
				FROM dbo.CoBorrowerData_curnt (nolock) a 
				INNER JOIN #NCIF_NIdata (nolock) c on a.NCIFID_PrimaryAccount=c.NCIF_Id 
				LEFT JOIN #NCIF_NIdata (nolock) b  on a.NCIFID_COBORROWER=b.NCIF_Id 
				WHERE (a.NCIFID_COBORROWER=@NCIF_Id OR a.NCIFID_COBORROWER IN (SELECT UCIC FROM @UCIC))
				AND b.NCIF_Id IS NULL 
				
				IF OBJECT_ID('Tempdb..#SACOBO1') IS NOT NULL 
				DROP TABLE #SACOBO1
				SELECT 
                		ROW_NUMBER() OVER(ORDER BY (SELECT 1))								AS CountPAN  
						,A.NCIFID_COBORROWER												AS NCIF_Id
                		,NULL																AS SourceName  
                		,NULL																AS CustomerId  
                		,NULL																AS CustomerACID  
                		,NULL																AS CustomerName  
                		,NULL																AS ARCFLAG  
                		,NULL																AS IsRestructured  
                		,NULL																AS OTS  
                		,NULL																AS fraud  
                		,NULL																AS WriteOffFlag  
                		,NULL																AS ARC_SaleDate  
                		,NULL																AS Writeoffdate  
                		,NULL																AS RestructureDt  
                		,NULL																AS PrincipleOutstanding  
                		,NULL																AS Balance  
                		,NULL																AS Segment  
                		,NULL																AS ProductCode  
                		,NULL																AS FacilityType  
                		,NULL																AS AC_NPA_Date  
                		,NULL																AS NCIF_AssetClassAlt_Key  
                		,CONVERT(VARCHAR(10),A.AcDegDate,103)								AS NCIF_NPA_Date  
                		,(CASE WHEN ISNULL(A.AcDegFlg,'N')='N' 
									THEN 'STD' 
						  ELSE 'NPA' END)													AS Status  
                		,NULL																AS MaxDPD  
						,NULL																AS IsSuitFiled 
						,(CASE WHEN @PANNo <>'' THEN @PANNo ELSE Null END)					AS PAN
						,(CASE WHEN @VoterId <>'xxxx' THEN @VoterId ELSE Null END)			AS Voter_ID 
						,(CASE WHEN @Aadhar <>'xxxx' THEN @Aadhar ELSE Null END)			AS AADHAR_ID 
						,'Matched_Criteria Available In Data, PAN, Aadhar, Voter_ID, All'	AS Matched_Criteria   
				INTO #SACOBO1 
            	FROM #Cobodata A
 
				UPDATE #SACOBO1 SET Matched_Criteria=''
				UPDATE #SACOBO1 SET Matched_Criteria='NCIF_ID' 
				WHERE (NCIF_Id=@NCIF_Id 
					   AND ISNULL(NCIF_Id,'')=@NCIF_Id )
					   AND ( ISNULL(PAN,'')<>@PANNo OR ISNULL(AADHAR_ID,'')<>@Aadhar OR ISNULL(Voter_ID,'')<>@VoterId)
				UPDATE #SACOBO1 SET Matched_Criteria=CONCAT(Matched_Criteria,' ,PAN')		WHERE PAN=@PANNo
				UPDATE #SACOBO1 SET Matched_Criteria=CONCAT(Matched_Criteria,' ,Aadhar')	WHERE AADHAR_ID=@Aadhar
				UPDATE #SACOBO1 SET Matched_Criteria=CONCAT(Matched_Criteria,' ,Voter_ID')	WHERE Voter_ID=@VoterId
			  
				UPDATE A SET A.AADHAR_ID=B.AADHAR_NO 
							,A.Voter_ID=B.KYCID,A.PAN=B.PAN
				FROM #SACOBO1 A 
				INNER JOIN #AadharVoterIDdata B ON A.NCIF_Id=B.UCIC
				
				SELECT * FROM #SACOBO1 

				INSERT INTO Log_APIAudit (PAN,NCIF_Id,RecordCount,AADHAR,VOTERID,Date,Time,Remark)
				SELECT @PANNO						AS PANNO,
               		   @NCIF_Id						AS NCIF_Id,
               		   0							AS RecordCount,
					   NULL							AS AADHAR,
					   NULL							AS VOTERID,
               		   CAST(GETDATE() AS DATE)		AS DATECUR,
               		   CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,
               		   'Successful'					AS Remark 
			END
			ELSE
			BEGIN 
				SELECT 'No Record Available for PAN / NCIF_Id ' + isnull(@PANNo,'')+isnull(@NCIF_Id,'') AS Remark 
				INSERT INTO Log_APIAudit (PAN,NCIF_Id,RecordCount,AADHAR,VOTERID,Date,Time,Remark)
				SELECT @PANNO						AS PANNO,
               		   @NCIF_Id						AS NCIF_Id,
               		   0							AS RecordCount,
					   NULL							AS AADHAR,
					   NULL							AS VOTERID,
               		   CAST(GETDATE() AS DATE)		AS DATECUR,
               		   CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,
               		   'No Record Available for PAN / NCIF_Id'					AS Remark 
			END
		END
	END

	IF @Request ='2P' AND (LEN(ISNULL(@PANNo,''))>0 OR  LEN(ISNULL(@NCIF_Id,''))<>0 )
	BEGIN 
		IF OBJECT_ID ('TEMPDB..#NPA_IntegrationDetails_Curnt_2P') IS NOT NULL
		DROP TABLE #NPA_IntegrationDetails_Curnt_2P
		
        SELECT NCIF_Id,CustomerId,CustomerACID,CustomerName,  
			IsARC_Sale,IsRestructured,IsOTS,IsFraud,IsTWO,ARC_SaleDate,WriteOffDate,PrincipleOutstanding,Balance,Segment,ProductCode,  
			FacilityType,AC_NPA_Date,NCIF_NPA_Date,NCIF_AssetClassAlt_Key,MaxDPD,IsSuitFiled,PAN,SrcSysAlt_Key,EffectiveFromTimeKey,EffectiveToTimeKey  
		INTO #NPA_IntegrationDetails_Curnt_2P 
		FROM NPA_IntegrationDetails_Curnt WITH(NOLOCK) 
		WHERE (PAN=@PANNo OR NCIF_Id = @NCIF_Id)
		
		IF OBJECT_ID ('TEMPDB..#AdvAcRestructureDetail_Curnt_2P') IS NOT NULL
		DROP TABLE #AdvAcRestructureDetail_Curnt_2P
		
		SELECT RestructureDt,RefSystemAcId,EffectiveFromTimeKey,EffectiveToTimeKey 
		INTO #AdvAcRestructureDetail_Curnt_2P    
		FROM CURDAT.AdvAcRestructureDetail_Curnt (nolock)  
		WHERE RefSystemAcId IN (SELECT CustomerACID FROM #NPA_IntegrationDetails_Curnt_2P) 

		INSERT INTO #TempAuditPAN_2P   
        SELECT  
                ROW_NUMBER() OVER(ORDER BY (SELECT 1))			AS CountPAN  
               ,A.PAN											AS PAN
               ,A.NCIF_Id										AS NCIF_Id  
               ,D.SourceName									AS SourceName  
               ,A.CustomerId									AS CustomerId  
               ,A.CustomerACID									AS CustomerACID 	 
               ,A.CustomerName									AS CustomerName  
               ,A.IsARC_Sale									AS ARCFLAG  
               ,A.IsRestructured								AS IsRestructured  
               ,A.IsOTS											AS OTS  
               ,A.IsFraud										AS fraud  
               ,A.IsTWO											AS WriteOffFlag  
               ,CONVERT(VARCHAR(10),A.ARC_SaleDate,103)			AS ARC_SaleDate  
               ,CONVERT(VARCHAR(10),A.WriteOffDate,103)			AS Writeoffdate  
               ,CONVERT(VARCHAR(10),C.RestructureDt,103)		AS RestructureDt  
               ,ISNULL(A.PrincipleOutstanding,0.00)				AS PrincipleOutstanding  
               ,ISNULL(A.Balance,0.00)							AS Balance  
               ,A.Segment										AS Segment  
               ,A.ProductCode									As ProductCode  
               ,A.FacilityType									AS FacilityType  	
               ,CONVERT(VARCHAR(10),A.AC_NPA_Date,103)			AS AC_NPA_Date  
               ,A.NCIF_AssetClassAlt_Key						AS NCIF_AssetClassAlt_Key 	 
               ,CONVERT(VARCHAR(10),A.NCIF_NPA_Date,103)		AS NCIF_NPA_Date  
               ,(CASE WHEN A.NCIF_AssetClassAlt_Key=1 
						THEN 'STD' 
				ELSE 'NPA' END)									AS Status  
               ,A.MaxDPD										AS MaxDPD
			   ,A.IsSuitFiled									AS IsSuitFiled
            FROM #NPA_IntegrationDetails_Curnt_2P A  
            LEFT JOIN #AdvAcRestructureDetail_Curnt_2P C ON A.CustomerACID=C.RefSystemAcId     
            LEFT JOIN DimSourceSystem D ON A.SrcSysAlt_Key=D.SourceAlt_Key          

  		DECLARE @CountPAN_2P INT=(SELECT COUNT(*) FROM #TempAuditPAN_2P)  
		
		IF (@CountPAN_2P>0)  
        BEGIN  
        	SELECT * FROM #TempAuditPAN_2P   
            INSERT INTO Log_APIAudit(PAN,NCIF_Id,RecordCount,Date,Time,Remark)  
            SELECT  @PANNO AS PANNO,  
                    @NCIF_Id as NCIF_Id,  
                    @CountPAN AS RecordCount,  
                    CAST(GETDATE() AS DATE) AS DATECUR,  
                    CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,  
                    'Successful' as Remark  
        END 
		
		IF (@CountPAN_2P=0)  
        BEGIN  
				IF OBJECT_ID ('TEMPDB..#UCICDATA') IS NOT NULL
				DROP TABLE #UCICDATA
	
				CREATE TABLE #UCICDATA ( UCIC VARCHAR(50) NULL)
				CREATE INDEX Idx_UCIC on #UCICDATA(UCIC)

				select @NCIF_Id 

				INSERT INTO #UCICDATA ( UCIC)
				SELECT Distinct UCIC FROM D2K_AADHAR_VOTER_ALL_NEW1 WHERE PAN=@PANNo

				IF OBJECT_ID ('TEMPDB..#CoBo_Check_2P') IS NOT NULL
				DROP TABLE #CoBo_Check_2P

				SELECT NCIFID_COBORROWER,NCIFID_PrimaryAccount,AcDegDate,AcDegFlg
				INTO #CoBo_Check_2P 
				FROM dbo.CoBorrowerData_curnt (NOLOCK) 
				WHERE NCIFID_COBORROWER in (@NCIF_Id) OR NCIFID_COBORROWER IN (SELECT UCIC FROM #UCICDATA)
				
				select * from #CoBo_Check_2P

				IF OBJECT_ID ('TEMPDB..#NCIF_NIdata_2P') IS NOT NULL
				DROP TABLE #NCIF_NIdata_2P 

				SELECT DISTINCT NCIF_Id 
				INTO #NCIF_NIdata_2P 
				FROM NPA_IntegrationDetails_Curnt
				WHERE NCIF_Id IN (SELECT NCIFID_PrimaryAccount FROM #CoBo_Check_2P  
								  UNION
								  SELECT NCIFID_COBORROWER FROM #CoBo_Check_2P 
								 )
								
				IF OBJECT_ID ('TEMPDB..#Cobodata_2P') IS NOT NULL
				DROP TABLE #Cobodata_2P 			
								
				SELECT DISTINCT a.*
				INTO #Cobodata_2P 
				FROM #CoBo_Check_2P a 
				INNER JOIN #NCIF_NIdata_2P c ON a.NCIFID_PrimaryAccount=c.NCIF_Id
				LEFT JOIN #NCIF_NIdata_2P b  ON a.NCIFID_COBORROWER=b.NCIF_Id  
											 AND b.NCIF_Id IS NULL 

				SELECT 
                	 ROW_NUMBER() OVER(ORDER BY (SELECT 1))		AS CountPAN  
                	,@PANNo										AS PAN
					,A.NCIFID_COBORROWER						AS NCIF_Id
                	,NULL										AS SourceName  
                	,NULL										AS CustomerId  
                	,NULL										AS CustomerACID  
                	,NULL										AS CustomerName  
                	,NULL										AS ARCFLAG  
                	,NULL										AS IsRestructured  
                	,NULL										AS OTS  
                	,NULL										AS fraud  
                	,NULL										AS WriteOffFlag  
                	,NULL										AS ARC_SaleDate  
                	,NULL										AS Writeoffdate  
                	,NULL										AS RestructureDt  
                	,NULL										AS PrincipleOutstanding  
                	,NULL										AS Balance  
                	,NULL										AS Segment  
                	,NULL										AS ProductCode  
                	,NULL										AS FacilityType  
                	,NULL										AS AC_NPA_Date  
                	,NULL										AS NCIF_AssetClassAlt_Key  
                	,CONVERT(VARCHAR(10),A.AcDegDate,103)		AS NCIF_NPA_Date  
                	,(CASE WHEN ISNULL(A.AcDegFlg,'N')='N' 
							THEN 'STD' ELSE 'NPA' END)			AS Status  
                	,NULL										AS MaxDPD  
					,NULL										AS IsSuitFiled 
            	FROM #Cobodata_2P A
				
				IF (SELECT COUNT(*) FROM #Cobodata_2P) > 0
				BEGIN 
					INSERT INTO Log_APIAudit(PAN,NCIF_Id,RecordCount,Date,Time,Remark)  
                	SELECT  
                			@PANNO		AS PANNO,  
                			@NCIF_Id	as NCIF_Id,  
                			@CountPAN	AS RecordCount,  
                			CAST(GETDATE() AS DATE) AS DATECUR,  
                			CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,  
                			'Successful' AS Remark 
			    END
				ELSE 
				BEGIN
					SELECT 'No Record Available for PAN / NCIF_Id ' +  isnull(@PANNo,'') + isnull(@NCIF_Id,'') AS Remark  
                  	INSERT INTO Log_APIAudit(PAN,NCIF_Id,RecordCount,Date,Time,Remark)  
                  	SELECT  
                        	@PANNO		AS PANNO,  
                            @NCIF_Id	AS NCIF_Id,  
                        	@CountPAN	AS RecordCount,  
                        	CAST(GETDATE() AS DATE) AS DATECUR,  
                        	CONVERT(VARCHAR,GETDATE(),8) AS TIMECUR,  
                        	'No Record Available for PAN / NCIF_Id' AS Remark 
				END
   		END
	END
END
GO