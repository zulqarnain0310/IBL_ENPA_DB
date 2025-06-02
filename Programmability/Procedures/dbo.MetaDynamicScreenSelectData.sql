SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

 
------ ====================================================================================================================
------ Author:			<Amar>
------ Create Date:		<30-11-2014>
------ Loading Master Data for Common Master Screen>
------ ====================================================================================================================
------- [MetaDynamicScreenSelectData]  @MenuId =6668, @TimeKey =24534, @Mode =2, @BaseColumnValue  = 1

CREATE PROCEDURE [dbo].[MetaDynamicScreenSelectData]
--declare
	 @MenuId			INT=610,
	 @TimeKey			INT=24860,
	 @Mode				TINYINT=2,
	 @BaseColumnValue	VARCHAR(50) = 1,
	 @ParentColumnValue VARCHAR(50) = NULL,
	 @TabId				INT=0
 AS 
BEGIN
	/*DECLARATION OF LOCAN VARIABLES FOR FURTHER USE*/
	DECLARE @SQL VARCHAR(MAX),
			@TableName varchar(500),
			@TableWithSchema varchar(50),
			@TableWithSchema_Mod varchar(50),
			@Schema varchar(5),
			@BaseColumn varchar(50),
			@EntityKey VARCHAR(50),
			@ChangeFields VARCHAR(200),
			@ParentColumn varchar(50)=''
	IF @Mode=1 SET @BaseColumnValue=0
	
	
	/*START FOR CREATE THE TEMP TABLE FOR SELECT THE DATA*/

		/*FIND THE TABLES USED IN MENU FOR GET THE COLUMN LIST TO CREATE TEMP TABLE  */
		SET @TableName=(SELECT ','+ SourceTable 
		FROM MetaDynamicScreenField WHERE MenuID=@MenuId 
			AND ISNULL(ParentcontrolID,0)= CASE WHEN @TabId > 0 THEN @TabId ELSE ISNULL(ParentcontrolID,0) END 
			AND SkipColumnInQuery='N' AND ValidCode='Y'
		GROUP BY SourceTable
		FOR XML PATH(''))

		print @TableName
	
		/*REMOVE COMM FROM DFIRST POSITION*/
		SET @TableName=RIGHT(@TableName,LEN(@TableName)-1)

		/*FIND THE LIST OF COLUMNS USED IN ABOBE @TableName  VARIABLES FOR FIND THE COLUMNS AND KEEP IN TEMP TABLE*/
		IF  OBJECT_ID('Tempdb..#TmmpQry') IS NOT NULL
			DROP TABLE #TmmpQry

		CREATE TABLE #TmmpQry ( ColDtl VARCHAR(100))
		
	
		INSERT INTO #TmmpQry

		SELECT  distinct A.NAME +  ' '+ B.NAME+ ''+
							(CASE 
								WHEN B.NAME IN ('VARCHAR','NVARCHAR','CHAR') 
									THEN  +'('+cast(A.max_length as varchar(4))+')'
								WHEN B.NAME IN ('decimal','numeric') 
									THEN  +'('+cast(A.precision as varchar(4))+','+CAST(A.scale as varchar(2))+')'
								ELSE '' END
							)
								AS ColDtl
			
				FROM SYS.COLUMNS  A
					INNER JOIN SYS.types B ON B.system_type_id=A.system_type_id
					INNER JOIN MetaDynamicScreenField C
							ON (C.ControlName=A.name)
							AND C.MenuID=@MenuId 
							AND SkipColumnInQuery='N'  AND ValidCode='Y'
						INNER JOIN SYS.objects D
							ON D.object_id=A.object_id
							AND SCHEMA_NAME(D.SCHEMA_ID) NOT IN ('LEGALVW','premoc')
				WHERE OBJECT_NAME(A.OBJECT_iD) 
						IN (SELECT SourceTable 
									FROM MetaDynamicScreenField WHERE MenuID=@MenuId 
										AND ISNULL(ParentcontrolID,0)= CASE WHEN @TabId > 0 THEN @TabId ELSE ISNULL(ParentcontrolID,0) END 
										AND SkipColumnInQuery='N' AND ValidCode='Y'
									GROUP BY SourceTable
							)
					AND  ISNULL(ParentcontrolID,0)= CASE WHEN @TabId > 0 THEN @TabId ELSE ISNULL(ParentcontrolID,0) END 
					AND A.NAME NOT IN('EntityKey','D2Ktimestamp' ,'AuthorisationStatus','EffectiveFromTimeKey','EffectiveToTimeKey','CreatedBy','DateCreated','ModifiedBy','DateModified','ApprovedBy')
					AND B.name <>'sysname'

         
		--SELECT * FROM #TmmpQry

		PRINT 2222222222
		DECLARE @ColName VARCHAR(MAX)
		/*MERGED ALL THE COLUMNS WITH COMMA(,) SEPARATED FOR FURTHER USE*/	
		SELECT @ColName=STUFF((SELECT ','+ColDtl 
						FROM #TmmpQry M1
							--where M1.MasterTable=M2.MasterTable
						FOR XML PATH('')),1,1,'')   
				FROM #TmmpQry M2
        PRINT 'VVVVVVVVVVVVV'
		PRINT @ColName

		/*CREATE TEMP TABLE FOR INSERT THE OUTPUT FOR SELECT DATA*/
			IF  OBJECT_ID('Tempdb..#TmpSelData') IS NOT NULL
				DROP TABLE #TmpSelData

		SET @ColName=REPLACE(@ColName,'(-1)','(MAX)')

		CREATE TABLE  #TmpSelData (EntityKey INT)
			SET @SQL= 'ALTER TABLE #TmpSelData ADD '+@ColName 	
		EXEC (@SQL)

		ALTER TABLE #TmpSelData ADD AuthorisationStatus varchar(2), IsMainTable cHAR(1),CreatedModifiedBy VARCHAR(20),ChangeFields  VARCHAR(200), D2Ktimestamp INT
	/*END OF CREATE TEMP TABLE FOR SELECT THE DATA*/
	--select * from #TmpSelData
		/* FIND THE FLAG FOR TAB USING IN SCREEN OR NOT*/
	DECLARE  @TabApplicable BIT=0
	SELECT @TabApplicable=1  FROM MetaDynamicScreenField WHERE MenuId= @MenuId AND isnull(ParentcontrolID,0)>0
	IF @TabApplicable=1 and @TabId=0
		BEGIN
			SELECT @TabId=MIN(ParentcontrolID)  FROM MetaDynamicScreenField WHERE MenuId= @MenuId AND isnull(ParentcontrolID,0)>0 AND ValidCode='Y'
		END


	/* FIND THE BASE COLUMN AND PARENT COLUMN */
	SELECT @TableName =SourceTable from  MetaDynamicScreenField where MenuId=@MenuID GROUP BY SourceTable
	SELECT @BaseColumn = ControlName from MetaDynamicScreenField where MenuId=@MenuID  AND ValidCode='Y'
			AND ISNULL(ParentcontrolID,0)= CASE WHEN @TabId > 0 THEN @TabId ELSE ISNULL(ParentcontrolID,0) END 
			AND BaseColumnType='BASE'
	SELECT  @ParentColumn= SourceColumn from MetaDynamicScreenField where MenuId=@MenuID  AND ValidCode='Y'
			AND ISNULL(ParentcontrolID,0)= CASE WHEN @TabId > 0 THEN @TabId ELSE ISNULL(ParentcontrolID,0) END 
			AND BaseColumnType='PARENT'

					
	/* FIND THE TABLE NAME WITH SCHEMA*/
	SELECT @TableWithSchema=SCHEMA_NAME(SCHEMA_ID)+'.'+@TableName , @Schema=SCHEMA_NAME(SCHEMA_ID)+'.'  FROM SYS.OBJECTS WHERE name=@TableName and SCHEMA_NAME(SCHEMA_ID)<>'premoc'
	PRINT 'TableName' +@TableName
	SELECT @EntityKey=NAME FROM SYS.columns WHERE OBJECT_NAME(OBJECT_ID)=@TableName AND IS_identity=1
	PRINT 'EntityKey'
	PRINT 'EntityKey'+@EntityKey
	print @TableWithSchema
	print @Schema


	/* CREATE TEMP TABLE FOR MAIN DATA SELECT*/
		IF OBJECT_ID('Tempdb..#TmpDataSelect') IS NOT NULL
			DROP TABLE #TmpDataSelect
	

	/* CREATE TEMP TABLE MAINTAIN THE ISAINTABLE, AUTH STATUS AND CREATED_MODIFIED BY */
		IF  OBJECT_ID('Tempdb..#TmpAuthStatus') IS NOT NULL
			DROP TABLE #TmpAuthStatus
		CREATE TABLE #TmpAuthStatus (IsMainTable CHAR(1), AuthorisationStatus VARCHAR(2), CreatedModifiedBy VARCHAR(20))
		
	/* CREATE TEMP TABLE KEEP THE UNIQUE SOURCE TABLE */
		IF OBJECT_ID('Tempdb..#TmpSrcTable') IS NOT NULL
			DROP TABLE #TmpSrcTable

		CREATE TABLE #TmpSrcTable
			(RowId TINYINT ,SourceTable varchar(50))

	/* FIRST INSERTING BASE TABLE ON FIRST (1) SEQUENCE */
	--INSERT INTO #TmpSrcTable
		--SELECT 1, SourceTable FROM MetaDynamicScreenField 
		--WHERE MenuID=@MenuId AND BaseColumnType='BASE'
		--		AND ISNULL(ParentcontrolID,0)= CASE WHEN @TabId > 0 THEN @TabId ELSE ISNULL(ParentcontrolID,0) END 


	INSERT INTO #TmpSrcTable
		SELECT 1, SourceTable 
		FROM MetaDynamicScreenField A
		INNER JOIN
			(SELECT MIN(ControlID) ControlID	FROM MetaDynamicScreenField  
					WHERE MenuID=@MenuID AND  BaseColumnType='BASE' 
					AND ISNULL(ParentcontrolID,0)= CASE WHEN @TabID > 0 THEN @TabID ELSE ISNULL(ParentcontrolID,0) END
					AND ValidCode='Y'
				 ) B
				ON A.ControlID=B.ControlID
				AND SkipColumnInQuery='N' AND ValidCode='Y'
			WHERE MenuID=@MenuID AND  BaseColumnType='BASE' 
				AND ISNULL(ParentcontrolID,0)= CASE WHEN @TabID > 0 THEN @TabID ELSE ISNULL(ParentcontrolID,0) END
				AND ValidCode='Y'
		--INSERT INTO #TmpSrcTable
		--SELECT 1+ROW_NUMBER() OVER (ORDER BY SourceTable),SourceTable  
		--FROM #TmmpQry WHERE SourceTable NOT IN (SELECT SourceTable FROM #TmpSrcTable)
		--	GROUP BY SourceTable

		--SELECT * FROM #TmpSrcTable

			
	/* INSERT UNIQUE SOURCE TABLE FOR LOOPING PURPOSE*/
		INSERT INTO #TmpSrcTable
		SELECT 1+ROW_NUMBER() OVER (ORDER BY SourceTable),SourceTable  
		FROM MetaDynamicScreenField WHERE SourceTable NOT IN (SELECT SourceTable FROM #TmpSrcTable)
			AND MenuID=@MenuId 
			AND ISNULL(ParentcontrolID,0)= CASE WHEN @TabId > 0 THEN @TabId ELSE ISNULL(ParentcontrolID,0) END 
			AND SkipColumnInQuery='N' AND ValidCode='Y'
		GROUP BY SourceTable
		
		--INSERT INTO #TmpSrcTable
		--SELECT 1+ROW_NUMBER() OVER (ORDER BY SourceTable),SourceTable  
		--FROM #TmmpQry WHERE SourceTable NOT IN (SELECT SourceTable FROM #TmpSrcTable)
		--	GROUP BY SourceTable
		DECLARE @OrgParentColumnVal VARCHAR(50)
		SET @OrgParentColumnVal = @ParentColumnValue

		DELETE  #TmpSrcTable WHERE SourceTable IS NULL

		/* STARTING OF LOOP FOR FOR PREPARING THE SELECT DATA*/
		 DELETE FROM #TmpSrcTable WHERE ISNULL(SourceTable,'') =''
		
		DECLARE @RowId TINYINT=1
		WHILE @RowId<=(SELECT COUNT(1) FROM #TmpSrcTable)
			BEGIN		

					set @ParentColumnValue= @OrgParentColumnVal
					SELECT @TableName=SourceTable from #TmpSrcTable WHERE RowId=@RowId
					SELECT @EntityKey=NAME FROM SYS.columns WHERE OBJECT_NAME(OBJECT_ID)=@TableName AND IS_identity=1

					SELECT @TableWithSchema=SCHEMA_NAME(SCHEMA_ID)+'.'+@TableName , @Schema=SCHEMA_NAME(SCHEMA_ID)+'.'  FROM SYS.OBJECTS WHERE name=@TableName and SCHEMA_NAME(SCHEMA_ID)<>'premoc'
					SELECT @TableWithSchema_Mod=SCHEMA_NAME(SCHEMA_ID)+'.'+@TableName+'_Mod' , @Schema=SCHEMA_NAME(SCHEMA_ID)+'.'  FROM SYS.OBJECTS WHERE name=@TableName+'_Mod'

					print 'Triloki'
					print @TableWithSchema
					print @Schema
					print @TableWithSchema_Mod

					TRUNCATE TABLE #TmmpQry

					INSERT INTO #TmmpQry

					SELECT distinct A.NAME  ColDtl
					FROM SYS.COLUMNS  A
						INNER JOIN SYS.types B ON B.system_type_id=A.system_type_id
						INNER JOIN MetaDynamicScreenField C
								ON A.name=C.ControlName
								AND C.MENUID=@MenuId
								AND ISNULL(ParentcontrolID,0)= CASE WHEN @TabId > 0 THEN @TabId ELSE ISNULL(ParentcontrolID,0) END 
								AND SkipColumnInQuery='N' AND ValidCode='Y'
		
					WHERE OBJECT_NAME(OBJECT_ID) =@TableName
						AND A.NAME NOT IN('D2Ktimestamp')
					

					--SELECT * FROM #TmmpQry
						--PRINT 1235468
					--SELECT @ColName
					IF NOT EXISTS(SELECT 1 FROM #TmmpQry WHERE ColDtl=@ParentColumn)
						BEGIN
						    PRINT 5555555555
							SET @ParentColumnValue='0'
						END

					IF @RowId=1
						BEGIN
						
							SELECT  @ColName=STUFF((
									SELECT  ' ,' +ColDtl
										FROM #TmmpQry  A1
											WHERE ColDtl<>@ParentColumn --AND ColDtl<>@BaseColumn --changes 19 jun 2017
									FOR XML PATH('')),1,1,'')  
								FROM #TmmpQry A2

   
						
						END					
					ELSE
						BEGIN
							PRINT 88888888
							set @ColName=''
							SELECT  @ColName=STUFF((
									SELECT  ' ,A.' +ColDtl +'=B.'+ColDtl
										FROM #TmmpQry  A1
											WHERE ColDtl<>@ParentColumn AND ColDtl<>@BaseColumn
									FOR XML PATH('')),1,1,'')  
								FROM #TmmpQry A2
							
						END
					
					--PRINT @ColName + 'ColName'
					SET @ColName=RIGHT(@ColName,LEN(@ColName)-1)
					--PRINT @ColName +'RIGHT'	
					IF @RowId=1
						BEGIN
						
							SET @SQL='INSERT INTO  #TmpSelData('+ @ColName +', AuthorisationStatus,IsMainTable,  CreatedModifiedBy, ChangeFields, D2Ktimestamp)'

							SET @ColName='A.'+@ColName

							

							--IF @Mode<>16 
							--	BEGIN			
								
									
										
										SET @SQL=@SQL+ ' SELECT '+ @ColName +', AuthorisationStatus,''Y'' AS IsMainTable, ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy, '''' ChangeFields, CAST(D2Ktimestamp AS INT) D2Ktimestamp FROM  '+@TableWithSchema +' A ' 
										SET @SQL=@SQL+' WHERE (EffectiveFromTimeKey<='+cast(@TimeKey AS VARCHAR(5)) +' AND EffectiveToTimeKey>=' +CAST(@TimeKey AS VARCHAR(5))+')'
										SET @SQL=@SQL+ CASE WHEN @ParentColumnValue<>'0' THEN ' AND '+ @ParentColumn +'= ' +@ParentColumnValue ELSE '' END
	
										SET @SQL=@SQL+' AND '+@BaseColumn+'='+@BaseColumnValue+' AND ISNULL(AuthorisationStatus,''A'')=''A'''									

										SET  @SQL=@SQL+ ' UNION '

										print 'MainTable'+@SQL
								   END
									print 'ModTable1'
									PRINT @TableWithSchema_Mod
									SET @SQL=@SQL+ ' SELECT '+ @ColName +', AuthorisationStatus,''N'' AS IsMainTable, ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy, ChangeFields ,CAST(D2Ktimestamp AS INT) D2Ktimestamp FROM  '+@TableWithSchema_Mod+' A' 
									PRINT 'ModTable2'+@SQL  
									---PRINT @EntityKey
									SET @SQL=@SQL+' INNER JOIN (SELECT MAX('+@EntityKey+') AS '+@EntityKey +' FROM ' +@TableWithSchema_Mod+' B WHERE ' + CASE WHEN @ParentColumnValue<>'0' THEN  @ParentColumn +'= ' +@ParentColumnValue +' AND '  ELSE ' ' END  +@BaseColumn+'='''+@BaseColumnValue+''' AND B.AuthorisationStatus IN(''NP'',''MP'',''DP'',''1A'',''1D'')) B ON A.'+@EntityKey +' = B.'+@EntityKey
									PRINT 'ModTable3'+@SQL
									SET @SQL=@SQL+' WHERE (EffectiveFromTimeKey<='+cast(@TimeKey AS VARCHAR(5)) +' AND EffectiveToTimeKey>=' +CAST(@TimeKey AS VARCHAR(5))+')'
									PRINT 'ModTable4'+@SQL
									SET @SQL=@SQL+ CASE WHEN @ParentColumnValue<>'0' THEN ' AND '+ @ParentColumn +'= ' +@ParentColumnValue ELSE '' END
									PRINT 'ModTable5'+@SQL
									SET @SQL=@SQL+' AND '+@BaseColumn+'='''+@BaseColumnValue+''' AND AuthorisationStatus IN (''NP'',''MP'',''DP'',''1A'',''1D'')'
									PRINT 'ModTable6'+@SQL							

									PRINT @SQL
							      EXEC (@SQL)
								 
							  --END
											
					   -- ELSE					  
						  --  BEGIN									 
								--	PRINT '99999999'
								--	SET @SQL='UPDATE A SET '+@ColName
								--	+' FROM #TmpSelData A '
								--	+' INNER JOIN '+ @TableWithSchema+ ' B ON (EffectiveFromTimeKey<='+cast(@TimeKey AS VARCHAR(5)) +' AND EffectiveToTimeKey>=' +CAST(@TimeKey AS VARCHAR(5))+')'
								--	+  CASE WHEN @ParentColumn<>'' THEN ' AND B.'+ @ParentColumn +'= ' +@ParentColumnValue ELSE '' END
								--	+' AND A.'+@BaseColumn+'=B.'+@BaseColumn
								--	+' AND ISNULL(B.AuthorisationStatus,''A'') =''A'''
								--	print 'A1'+@SQL
								--	EXEC (@SQL)

								--	SET @SQL='UPDATE A SET '+@ColName
								--	+' FROM #TmpSelData A '
								--	+' INNER JOIN '+ @TableWithSchema_Mod+' B ON (EffectiveFromTimeKey<='+cast(@TimeKey AS VARCHAR(5)) +' AND EffectiveToTimeKey>=' +CAST(@TimeKey AS VARCHAR(5))+')'
								--	+' INNER JOIN (SELECT MAX('+@EntityKey+') AS '+@EntityKey +' FROM ' +@TableWithSchema_Mod+' B WHERE ' 
								--	+  CASE WHEN @ParentColumnValue<>'0' THEN  @ParentColumn +'= ' +@ParentColumnValue ELSE '' END  
								--	+  case when @ParentColumnValue<>'0' then ' AND ' else '' end +  @BaseColumn+'='+@BaseColumnValue+ ' AND B.AuthorisationStatus IN(''NP'',''MP'',''DP'')) C ON B.'+@EntityKey +' = C.'+@EntityKey
								--	+  CASE WHEN @ParentColumnValue<>'0' THEN ' AND A.'+ @ParentColumn +'= B.' +@ParentColumn ELSE '' END
								--	+' AND A.'+@BaseColumn+'=B.'+@BaseColumn
							
							
							 --   EXEC (@SQL)
						  --END
								
									INSERT INTO #TmpAuthStatus
									SELECT  IsMainTable,AuthorisationStatus,CreatedModifiedBy FROM #TmpSelData 

									--IF  @RowId>1
									--	BEGIN
									--		SET @SQL='INSERT INTO  #TmpSelData('+ @ColName +
													
									--	END
			
									SET @RowId=@RowId+1
											
					END

				SELECT @ChangeFields=ChangeFields FROM #TmpSelData

				IF NOT EXISTS(SELECT 1 FROM #TmmpQry WHERE ColDtl LIKE 'CaseEntityID%')			
					BEGIN
						ALTER TABLE #TmpSelData ADD CaseEntityID INT
						
					END
				UPDATE #TmpSelData set CaseEntityID=@ParentColumnValue where isnull(CaseEntityID,0)=0

				IF NOT EXISTS(SELECT 1 FROM #TmmpQry WHERE ColDtl LIKE 'BranchCode%')			
					BEGIN
						ALTER TABLE #TmpSelData ADD BranchCode varchar(10)
					END

				declare @BrCode VARCHAR(10)
				
				
				
			IF EXISTS(SELECT 1 FROM  #TmpAuthStatus WHERE IsMainTable='N')
				BEGIN
					UPDATE T 
						SET IsMainTable='N'
						,AuthorisationStatus=(SELECT top(1) AuthorisationStatus FROM #TmpAuthStatus)
						,CreatedModifiedBy=(SELECT top(1) CreatedModifiedBy FROM #TmpAuthStatus)
					FROM #TmpSelData T
				END 
				

			DECLARE @CreatedModifiedBy varchar(50),	@UserLocation	varchar(5),	@UserLocationCode varchar(10)
			SELECT @CreatedModifiedBy = CreatedModifiedBy FROM #TmpSelData 

			/*FIND CHANGE FIELDS*/
			DECLARE
			@SQL1 NVARCHAR(MAX)
			print 'change1234'
			SET @SQL1 =' SELECT @ChangeFields=ChangeFields
			 FROM '+@TableWithSchema_Mod+'

						WHERE '+@EntityKey+'=(SELECT MAX('+@EntityKey+') AS '+@EntityKey+' FROM '+@TableWithSchema_Mod+' WHERE (EffectiveFromTimeKey<='+CAST(@TimeKey as varchar(6))+' AND EffectiveToTimeKey>='+CAST(@TimeKey as varchar(6))+') 
												   AND ISNULL(AuthorisationStatus,''A'')=''A''
													AND  '+@BaseColumn+'='+@BaseColumnValue+'	
													
						)'					 
						 
			--SET @SQL1=@SQL1+'AND'+CASE WHEN @ParentColumnValue<>'0' THEN ' AND '+ @ParentColumn +'= ' +@ParentColumnValue ELSE '' END				

			--SELECT @SQL1
			EXECUTE sp_executesql @SQL1,N'@ChangeFields varchar(max) output',@ChangeFields OUTPUT

		--	select @ChangeFields

			--ADDED ON 22 FEB 2018 BY HAMID
			UPDATE #TmpSelData
			SET AuthorisationStatus = 'A'
			WHERE ISNULL(AuthorisationStatus,'')=''

			--ADDED ON 23 FEB 2018 BY HAMID 
			---FOR REMOVING A 5
			UPDATE #TmpSelData
			SET AuthorisationStatus = LTRIM(RTRIM(AuthorisationStatus))


			

			IF @MenuId =610
			BEGIN

				SELECT 'SelectData' TableName,	@UserLocation CreatedModifiedByLoc, @UserLocationCode CreatedModifiedByLocCode
				, EntityKey, ApprovalDate, BLOTP_Date, ClubEntityId, ClubName, CurrentStatusAlt_Key, DormantInLast, LaunchDate
				,'JAMMU & KASHMIR' AS [StateName]
				, Dl.District_Code as District,
				--,DL.LocationName LocationAlt_key,
			--	DL.DISTRICT District,
				--SUB_DISTRICT as Taluka,
				Dl.Sub_District_Code as Taluka,DL.LocationAlt_key as LocationAlt_key
				,A.NABARD_Code, A.Revived, A.RevivedDate,A.AuthorisationStatus, A.IsMainTable, 
				A.CreatedModifiedBy, A.ChangeFields, A.D2Ktimestamp, A.CaseEntityID, A.BranchCode
				 FROM #TmpSelData A --WHERE MENUID=@MenuId
				 LEFT JOIN DimLocation DL
				 ON (DL.EffectiveFromTimeKey <= @TimeKey AND DL.EffectiveToTimeKey >= @TimeKey)
				 AND DL.LocationAlt_key = A.LocationAlt_key

				 DECLARE  @DistrictCode VARCHAR(8), @Taluka VARCHAR(8)
				 SELECT   @DistrictCode	= DL.DISTRICT_CODE
				         ,@Taluka		=SUB_DISTRICT_CODE
				 FROM #TmpSelData A --WHERE MENUID=@MenuId
				 LEFT JOIN DimLocation DL
				 ON (DL.EffectiveFromTimeKey <= @TimeKey AND DL.EffectiveToTimeKey >= @TimeKey)
				 AND DL.LocationAlt_key = A.LocationAlt_key
				 

	
				select 
				--'TalukaDataFetch' TableName,
				Distinct(Sub_District_Code) as Code,Sub_District as Description
				 from 
				 DimLocation
				 where 
				 District_Code=@DistrictCode and Sub_District Is NOT NULL


				 	select 
					--'VillageDataFetch' TableName,
				LocationCode as Code ,LocationName As Description
				 from 
				 DimLocation 
				 where Sub_District_Code=@Taluka and LocationCode Is NOT NULL

	


			END


			IF @MenuId = 605
			BEGIN
				
					PRINT '605'

					
					SELECT 'SelectData' TableName,	@UserLocation CreatedModifiedByLoc, @UserLocationCode CreatedModifiedByLocCode
					, A.EntityKey, A.BusiCorresEntityId, A.BusiCorresVillEntityId
					,Dl.District_Code as District
					,Dl.Sub_District_Code as Taluka
					, DL.LocationAlt_key as LocationAlt_Key
					--, A.LocationAlt_Key
					, A.Population, A.AuthorisationStatus
					, A.IsMainTable, A.CreatedModifiedBy, A.ChangeFields, A.D2Ktimestamp, A.CaseEntityID, A.BranchCode
					FROM #TmpSelData A--WHERE MENUID=@MenuId
						LEFT JOIN DimLocation DL
							ON (DL.EffectiveFromTimeKey <= @TimeKey AND DL.EffectiveToTimeKey >= @TimeKey)
							AND DL.LocationAlt_key = A.LocationAlt_key
			END

			ELSE IF @MenuId = 613
			BEGIN
				SELECT 'SelectData' TableName,	@UserLocation CreatedModifiedByLoc, @UserLocationCode CreatedModifiedByLocCode, * 
				, 'JAMMU & KASHMIR' AS [State]
				FROM #TmpSelData --WHERE MENUID=@MenuId
			END

			ELSE IF @MenuId = 614
			BEGIN
				SELECT 'SelectData' TableName,	@UserLocation CreatedModifiedByLoc, @UserLocationCode CreatedModifiedByLocCode
				,A.EntityKey,	A.AcHolderNo,	A.CampConductedByAlt_Key,	A.CampDate,	A.CampTypeAlt_Key,	A.CampTypeOthers,	A.FinLitCampEntityId
				,	A.FinLitEntityId,	A.FLC_BranchCode
				,Dl.District_Code as District
				,Dl.Sub_District_Code as Taluka
				,	A.LocationAlt_Key
				,'JAMMU & KASHMIR' AS [State]
				,	A.OpenAcAfterCamp, 	A.ParticipantsNo,
					A.Remarks,	A.StakeHolderAlt_Key,	A.StakeHolderOthers,	A.TargetGroupAlt_Key,	
					A.TargetGroupOthers
					,	A.UserLocation
					,	A.UserLocationCode
					,CASE WHEN A.UserLocation = 'HO' THEN 'Head Office'  --HO 
						  WHEN A.UserLocation = 'ZO' THEN 
							 (
								SELECT BranchZone 
								FROM DimBranch BR 
								WHERE EffectiveFromTimeKey <= @TimeKey
									AND EffectiveToTimeKey >= @TimeKey 
									AND BR.BranchZoneAlt_Key = A.UserLocationCode
								GROUP BY BranchZone
							 )		--ZO
						   WHEN A.UserLocation = 'RO' THEN 
						   (
								SELECT BranchRegion
								FROM DimBranch BR 
								WHERE EffectiveFromTimeKey <= @TimeKey
									AND EffectiveToTimeKey >= @TimeKey 
									AND BR.BranchRegionAlt_Key = A.UserLocationCode
								GROUP BY BranchRegion
						   )
						   WHEN A.UserLocation = 'BO' THEN 
						   (
								SELECT BranchName
								FROM DimBranch BR 
								WHERE EffectiveFromTimeKey <= @TimeKey
									AND EffectiveToTimeKey >= @TimeKey 
									AND BR.BranchCode = A.UserLocationCode
								GROUP BY BranchName
						   )
					 END AS UserLocationName
					,	A.AuthorisationStatus,	A.IsMainTable
					,	A.CreatedModifiedBy,	A.ChangeFields,	A.D2Ktimestamp,	A.CaseEntityID,	A.BranchCode
					
				--, A.* 
				FROM #TmpSelData A--WHERE MENUID=@MenuId
				LEFT JOIN DimLocation DL
							ON (DL.EffectiveFromTimeKey <= @TimeKey AND DL.EffectiveToTimeKey >= @TimeKey)
							AND DL.LocationAlt_key = A.LocationAlt_key
			END 
			
			ELSE IF @MenuId = 901
			BEGIN
				
					PRINT '901'

					
					SELECT 'SelectData' TableName,	A.EntityKey	,A.Currency	,A.DataExtractionMode	,A.DateFormat	,A.monetaryItemType		,A.NegativeDecimal	,A.OutputFileName	,A.ReportEntityId	,A.ReportId	,A.ReportName	,A.reporttype	,A.SequenceType	,
					--RIGHT(A.TaxonomyPath, CHARINDEX('\', REVERSE(A.TaxonomyPath)) - 1)	TaxonomyPath	,
					A.TaxonomyPath --AS 'TaxonomyPathPath',
					,A.Output_HTML
					,A.Output_Pdf
					,A.Output_Text
					,A.Output_Excel
					,A.AuthorisationStatus	,A.IsMainTable	,A.CreatedModifiedBy	,A.ChangeFields	,A.D2Ktimestamp	,A.CaseEntityID	,A.BranchCode	,CASE WHEN A.MultiCurrencyAllow=1 THEN '1' ELSE '0' END AS MultiCurrencyAllow
					FROM #TmpSelData A
			END
			ELSE IF @MenuId = 906
			BEGIN
				
					PRINT '901'

					
					SELECT 'SelectData' TableName
					
					,A.EntityKey	
					,A.DimensionName	
					,A.DimensionNameDomainMember	
					,A.DimensionNameDomainMemberSequence	
					,A.DimensionNameSequence	
					,A.DimentionEntityId	
					,A.HyperCubeId	
					,A.ReportId	
					,CASE WHEN A.SortingAllow=1 then '1' else '0' END AS SortingAllow
					,A.AuthorisationStatus	
					,A.IsMainTable	
					,A.CreatedModifiedBy	
					,A.ChangeFields	
					,A.D2Ktimestamp	
					,A.CaseEntityID	
					,A.BranchCode
					FROM #TmpSelData A
			END
			ELSE IF @MenuId = 801
			BEGIN
				
					PRINT '901'

					declare @CustomerId varchar(50)
					,@AccountId	Varchar(50)
					
					select @CustomerId=a.CustomerId,@AccountId=b.CustomerACID from curdat.CustomerBasicDetail a
						inner join curdat.AdvAcBasicDetail b
							on (a.EffectiveFromTimeKey<=@TimeKey and a.EffectiveToTimeKey>=@TimeKey)
							and(b.EffectiveFromTimeKey<=@TimeKey and b.EffectiveToTimeKey>=@TimeKey)
							and a.CustomerEntityId=b.CustomerEntityId
						inner join curdat.AdvSecurityValueDetail c
							on (c.EffectiveFromTimeKey<=@TimeKey and c.EffectiveToTimeKey>=@TimeKey)
							and c.AccountEntityId=b.AccountEntityId
						where c.SecurityEntityID=@OrgParentColumnVal
					
					print 'insurance'
					print @CustomerId
					print @AccountId
					print @ParentColumnValue
					SELECT 
					--@CustomerId CustomerId,@AccountId AccountId
					--@OrgParentColumnVal SecurityEntityID,
					* 
					FROM #TmpSelData A 
						
			END

			ELSE IF @MenuId=1035
			BEGIN
				PRINT 'MenuId = 1035'

				DECLARE @Date DATE,@MonthFirstDate DATE
				SELECT @Date=CONVERT(DATE,B.DATE,103),@MonthFirstDate=A.MonthFirstDate FROM SysDataMatrix A INNER JOIN SysDayMatrix B ON A.TimeKey=B.TimeKey WHERE A.CurrentStatus='C'
				--SELECT @Date=CONVERT(VARCHAR(10),DATE,103) FROM SysDataMatrix WHERE CurrentStatus='C'
				--PRINT @Date

				


				IF @Date > CONVERT(DATE,CAST(GETDATE() AS DATE),103)
				BEGIN
					SET @Date=CONVERT(DATE,CAST(GETDATE() AS DATE),103)
				END 

				PRINT @Date
				PRINT @MonthFirstDate
				
				SELECT 'SelectData' TableName, @UserLocation CreatedModifiedByLoc, @UserLocationCode CreatedModifiedByLocCode
				,CONVERT(VARCHAR(10),@MonthFirstDate,103) MonthFirstDate, CONVERT(VARCHAR(10),@Date,103) SystemDate,* FROM #TmpSelData

				SELECT 'MonthDate' TableName,CONVERT(VARCHAR(10),MonthFirstDate,103) MonthFirstDate,CONVERT(VARCHAR(10),MonthLastDate,103) MonthLastDate FROM SysDataMatrix WHERE CurrentStatus='C'

				--SELECT 'SelectData' TableName, @UserLocation CreatedModifiedByLoc, @UserLocationCode CreatedModifiedByLocCode, CONVERT(VARCHAR(10),@Date,103) MonthEndDate					
				--,A.EntityKey,A.AccountEntityId,A.ApprovingAuthAlt_Key,A.BankApprovalDt,A.CDRFlg,A.CutOffDate,A.DiminutionAmount,A.ExitCDRFlg,A.ForwardDt,A.MocDate,A.MocStatus	
				--,A.MocTypeAlt_Key,A.OverDueSinceDt,A.RefCustomerId,A.RefSystemAcId,A.Remark,A.RepaymentStartDate,B.Balance RestructureAmt,A.RestructureApprovalDt,A.RestructureByAlt_Key	
				--,A.RestructureCatgAlt_Key,A.RestructureDt,A.RestructureProposalDt,A.RestructureReason,A.RestructureSequenceRefNo,A.RestructureTypeAlt_Key,A.SDR_INVOKED,A.SDR_REFER_DATE	
				--,A.AuthorisationStatus,A.IsMainTable,A.CreatedModifiedBy,A.ChangeFields,A.D2Ktimestamp,A.CaseEntityID,A.BranchCode					
				
				--FROM #TmpSelData A
				--INNER JOIN AdvAcBalanceDetail B
				--ON A.AccountEntityId=B.AccountEntityId
				--WHERE (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
					


				--IF @Date<CONVERT(VARCHAR(10),GETDATE(),103)
				--BEGIN
				--	SELECT 'SelectData' TableName, @UserLocation CreatedModifiedByLoc, @UserLocationCode CreatedModifiedByLocCode, CONVERT(VARCHAR(10),@Date,103) MonthEndDate
				--	,* FROM #TmpSelData
				--END
				--ELSE
				--BEGIN
				--	SELECT 'SelectData' TableName, @UserLocation CreatedModifiedByLoc, @UserLocationCode CreatedModifiedByLocCode, CONVERT(VARCHAR(10),GETDATE(),103) MonthEndDate
				--	, * FROM #TmpSelData
				--END
			END

			---- ADD Additional Logic to Load Master Data for MOC Reason Master Table BY SATWAJI AS ON 04/07/2022
			ELSE IF @MenuId=2002
			BEGIN
				--SELECT * FROM #TmpSelData
				IF @Mode IN(0,1,2,3)
				BEGIN
					SELECT 
						'SelectData' TableName
						,MocReasonAlt_Key
						,MocReasonName
						,MocReasonShortName
						,MocReasonShortNameEnum
						,MocReasonGroup
						,MocReasonSubGroup
						,MocReasonSegment
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						 ,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						  ELSE NULL END AS AuthorisationStatus
						,'Y' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM DimMOCReason WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND MocReasonAlt_Key = Cast(@BaseColumnValue AS INT) AND ISNULL(AuthorisationStatus,'A')='A' 
					--AND (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey) 
					--AND MOCReasonAlt_Key=@ParentColumnValue
					UNION
					SELECT 
						'SelectData' TableName
						,MocReasonAlt_Key
						,MocReasonName
						,MocReasonShortName
						,MocReasonShortNameEnum
						,MocReasonGroup
						,MocReasonSubGroup
						,MocReasonSegment
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						 ELSE NULL END AS AuthorisationStatus
						,'N' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM DimMOCReason_Mod WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND MocReasonAlt_Key = Cast(@BaseColumnValue AS INT) AND AuthorisationStatus IN('NP','MP','DP','RM')
					AND MocReason_Key IN(
							SELECT MAX(MocReason_Key)MocReason_Key FROM DimMOCReason_Mod 
							where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
							AND AuthorisationStatus IN('NP','MP','DP','RM')
							group by MocReasonAlt_Key
						 )
					
				END
				ELSE
				BEGIN
					SELECT 
						'SelectData' TableName
						,MocReasonAlt_Key
						,MocReasonName
						,MocReasonShortName
						,MocReasonShortNameEnum
						,MocReasonGroup
						,MocReasonSubGroup
						,MocReasonSegment
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						 ELSE NULL END AS AuthorisationStatus
						,'N' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM DimMOCReason_Mod WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND MocReasonAlt_Key = Cast(@BaseColumnValue AS INT) AND AuthorisationStatus IN('NP','MP','DP','RM')
					AND MocReason_Key IN(
							SELECT MAX(MocReason_Key)MocReason_Key FROM DimMOCReason_Mod 
							where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
							AND AuthorisationStatus IN('NP','MP','DP','RM')
							group by MocReasonAlt_Key
						 )
				END
				--SELECT
				--	'SelectData' TableName
				--	,@UserLocation CreatedModifiedByLoc
				--	,@UserLocationCode CreatedModifiedByLocCode
				--	,CONVERT(VARCHAR(10),@MonthFirstDate,103) MonthFirstDate
				--	,CONVERT(VARCHAR(10),@Date,103) SystemDate
			END

			---- ADD Additional Logic to Load Master Data for Asset Class Master Table BY SATWAJI AS ON 04/07/2022
			ELSE IF @MenuId=2003
			BEGIN
				IF @Mode IN(0,1,2,3)
				BEGIN
					SELECT 
						'SelectData' TableName
						,AssetClassAlt_Key
						,AssetClassName
						,AssetClassShortName
						,AssetClassShortNameEnum
						,AssetClassGroup
						,AssetClassSubGroup
						,AssetClassSegment
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						  ELSE NULL END AS AuthorisationStatus
						,'Y' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM DimAssetClass WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND AssetClassAlt_Key = Cast(@BaseColumnValue AS INT) AND ISNULL(AuthorisationStatus,'A')='A' 
					UNION
					SELECT 
						'SelectData' TableName
						,AssetClassAlt_Key
						,AssetClassName
						,AssetClassShortName
						,AssetClassShortNameEnum
						,AssetClassGroup
						,AssetClassSubGroup
						,AssetClassSegment
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						 ELSE NULL END AS AuthorisationStatus
						,'N' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM DimAssetClass_Mod WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND AssetClassAlt_Key = Cast(@BaseColumnValue AS INT) AND AuthorisationStatus IN('NP','MP','DP','RM')
					AND AssetClass_Key IN(
							SELECT MAX(AssetClass_Key)AssetClass_Key FROM DimAssetClass_Mod 
							where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
							AND AuthorisationStatus IN('NP','MP','DP','RM')
							group by AssetClassAlt_Key
						 )
					
				END
				ELSE
				BEGIN
					SELECT 
						'SelectData' TableName
						,AssetClassAlt_Key
						,AssetClassName
						,AssetClassShortName
						,AssetClassShortNameEnum
						,AssetClassGroup
						,AssetClassSubGroup
						,AssetClassSegment
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						 ELSE NULL END AS AuthorisationStatus
						,'N' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM DimAssetClass_Mod WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND AssetClassAlt_Key = Cast(@BaseColumnValue AS INT) AND AuthorisationStatus IN('NP','MP','DP','RM')
					AND AssetClass_Key IN(
							SELECT MAX(AssetClass_Key)AssetClass_Key FROM DimAssetClass_Mod 
							where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
							AND AuthorisationStatus IN('NP','MP','DP','RM')
							group by AssetClassAlt_Key
						 )
				END
			END

			---- ADD Additional Logic to Load Master Data for Provision Master Table BY SATWAJI AS ON 05/07/2022
			ELSE IF @MenuId=2004
			BEGIN
				IF @Mode IN(0,1,2,3)
				BEGIN
					SELECT 
						'SelectData' TableName
						,ProvisionAlt_key
						,ProvisionName
						,ProvisionShortName
						,ProvisionShortNameEnum
						,ProvisionGroup
						,ProvisionSubGroup
						,ProvisionSegment
						,ProvisionSecured
						,ProvisionUnSecured
						,AssetClassDuration
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						  ELSE NULL END AS AuthorisationStatus
						,'Y' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM DimProvision WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND ProvisionAlt_Key = Cast(@BaseColumnValue AS INT) AND ISNULL(AuthorisationStatus,'A')='A' 
					UNION
					SELECT 
						'SelectData' TableName
						,ProvisionAlt_key
						,ProvisionName
						,ProvisionShortName
						,ProvisionShortNameEnum
						,ProvisionGroup
						,ProvisionSubGroup
						,ProvisionSegment
						,ProvisionSecured
						,ProvisionUnSecured
						,AssetClassDuration
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						 ELSE NULL END AS AuthorisationStatus
						,'N' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM DimProvision_Mod WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND ProvisionAlt_Key = Cast(@BaseColumnValue AS INT) AND AuthorisationStatus IN('NP','MP','DP','RM')
					AND Provision_Key IN(
							SELECT MAX(Provision_Key)Provision_Key FROM DimProvision_Mod 
							where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
							AND AuthorisationStatus IN('NP','MP','DP','RM')
							group by ProvisionAlt_Key
						 )
					
				END
				ELSE
				BEGIN
					SELECT 
						'SelectData' TableName
						,ProvisionAlt_key
						,ProvisionName
						,ProvisionShortName
						,ProvisionShortNameEnum
						,ProvisionGroup
						,ProvisionSubGroup
						,ProvisionSegment
						,ProvisionSecured
						,ProvisionUnSecured
						,AssetClassDuration
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						 ELSE NULL END AS AuthorisationStatus
						,'N' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM DimProvision_Mod WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND ProvisionAlt_Key = Cast(@BaseColumnValue AS INT) AND AuthorisationStatus IN('NP','MP','DP','RM')
					AND Provision_Key IN(
							SELECT MAX(Provision_Key)Provision_Key FROM DimProvision_Mod 
							where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
							AND AuthorisationStatus IN('NP','MP','DP','RM')
							group by ProvisionAlt_Key
						 )
				END
			END

			---- ADD Additional Logic to Load Master Data for Source System Master Table BY SATWAJI AS ON 05/07/2022
			ELSE IF @MenuId=2005
			BEGIN
				PRINT 'Source System Call'
				IF @Mode IN(0,1,2,3)
				BEGIN
					SELECT 
						'SelectData' TableName
						,SourceAlt_Key
						,SourceName
						,SourceShortName
						,SourceShortNameEnum
						,SourceGroup
						,SourceSubGroup
						,SourceSegment
						,SourceFilePath
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						  ELSE NULL END AS AuthorisationStatus
						,'Y' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM DimSourceSystem WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND SourceAlt_Key = Cast(@BaseColumnValue AS INT) AND ISNULL(AuthorisationStatus,'A')='A' 
					UNION
					SELECT 
						'SelectData' TableName
						,SourceAlt_Key
						,SourceName
						,SourceShortName
						,SourceShortNameEnum
						,SourceGroup
						,SourceSubGroup
						,SourceSegment
						,SourceFilePath
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						 ELSE NULL END AS AuthorisationStatus
						,'N' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM DimSourceSystem_Mod WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND SourceAlt_Key = Cast(@BaseColumnValue AS INT) AND AuthorisationStatus IN('NP','MP','DP','RM')
					AND Source_Key IN(
										SELECT MAX(Source_Key)Source_Key FROM DimSourceSystem_Mod 
										where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
										AND AuthorisationStatus IN('NP','MP','DP','RM')
										GROUP BY SourceAlt_Key
									 )
					
				END
				ELSE
				BEGIN
					SELECT 
						'SelectData' TableName
						,SourceAlt_Key
						,SourceName
						,SourceShortName
						,SourceShortNameEnum
						,SourceGroup
						,SourceSubGroup
						,SourceSegment
						,SourceFilePath
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						 ELSE NULL END AS AuthorisationStatus
						,'N' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM DimSourceSystem_Mod WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND SourceAlt_Key = Cast(@BaseColumnValue AS INT) AND AuthorisationStatus IN('NP','MP','DP','RM')
					AND Source_Key IN(
										SELECT MAX(Source_Key)Source_Key FROM DimSourceSystem_Mod 
										where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
										AND AuthorisationStatus IN('NP','MP','DP','RM')
										GROUP BY SourceAlt_Key
									 )
				END
			END

			---- ADD Additional Logic to Load Master Data for Reference Period Master Table BY SATWAJI AS ON 07/07/2022
			ELSE IF @MenuId=2006
			BEGIN
				IF @Mode IN(0,1,2,3)
				BEGIN
					SELECT 
						'SelectData' TableName
						,RuleAlt_Key
						,RuleType
						,BusinessRule
						,BusienssRuleName
						,ColumnName
						,RefValue
						,RefUnit
						,LogicSql
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						  ELSE NULL END AS AuthorisationStatus
						,'Y' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM RefPeriod WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND RuleAlt_Key = Cast(@BaseColumnValue AS INT) AND ISNULL(AuthorisationStatus,'A')='A' 
					UNION
					SELECT 
						'SelectData' TableName
						,RuleAlt_Key
						,RuleType
						,BusinessRule
						,BusienssRuleName
						,ColumnName
						,RefValue
						,RefUnit
						,LogicSql
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						 ELSE NULL END AS AuthorisationStatus
						,'N' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM RefPeriod_Mod WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND RuleAlt_Key = Cast(@BaseColumnValue AS INT) AND AuthorisationStatus IN('NP','MP','DP','RM')
					AND Rule_Key IN(
										SELECT MAX(Rule_Key)Rule_Key FROM RefPeriod_Mod 
										where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
										AND AuthorisationStatus IN('NP','MP','DP','RM')
										GROUP BY RuleAlt_Key
									 )
					
				END
				ELSE
				BEGIN
					SELECT 
						'SelectData' TableName
						,RuleAlt_Key
						,RuleType
						,BusinessRule
						,BusienssRuleName
						,ColumnName
						,RefValue
						,RefUnit
						,LogicSql
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						 ELSE NULL END AS AuthorisationStatus
						,'N' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM RefPeriod_Mod WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND RuleAlt_Key = Cast(@BaseColumnValue AS INT) AND AuthorisationStatus IN('NP','MP','DP','RM')
					AND Rule_Key IN(
										SELECT MAX(Rule_Key)Rule_Key FROM RefPeriod_Mod 
										where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
										AND AuthorisationStatus IN('NP','MP','DP','RM')
										GROUP BY RuleAlt_Key
									 )
				END
			END

			---- ADD Additional Logic to Load Master Data for User Role Master Table BY SATWAJI AS ON 07/07/2022
			ELSE IF @MenuId=2007
			BEGIN
				IF @Mode IN(0,1,2,3)
				BEGIN
					SELECT 
						'SelectData' TableName
						,UserRoleAlt_Key
						,UserRoleName
						,UserRoleShortName
						,UserRoleShortNameEnum
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						  ELSE NULL END AS AuthorisationStatus
						,'Y' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM DimUserRole WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND UserRoleAlt_Key = Cast(@BaseColumnValue AS INT) AND ISNULL(AuthorisationStatus,'A')='A' 
					UNION
					SELECT 
						'SelectData' TableName
						,UserRoleAlt_Key
						,UserRoleName
						,UserRoleShortName
						,UserRoleShortNameEnum
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						 ELSE NULL END AS AuthorisationStatus
						,'N' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM DimUserRole_Mod WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND UserRoleAlt_Key = Cast(@BaseColumnValue AS INT) AND AuthorisationStatus IN('NP','MP','DP','RM')
					AND UserRole_Key IN(
										SELECT MAX(UserRole_Key)UserRole_Key FROM DimUserRole_Mod 
										where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
										AND AuthorisationStatus IN('NP','MP','DP','RM')
										GROUP BY UserRoleAlt_Key
									 )
					
				END
				ELSE
				BEGIN
					SELECT 
						'SelectData' TableName
						,UserRoleAlt_Key
						,UserRoleName
						,UserRoleShortName
						,UserRoleShortNameEnum
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						 ELSE NULL END AS AuthorisationStatus
						,'N' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM DimUserRole_Mod WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND UserRoleAlt_Key = Cast(@BaseColumnValue AS INT) AND AuthorisationStatus IN('NP','MP','DP','RM')
					AND UserRole_Key IN(
										SELECT MAX(UserRole_Key)UserRole_Key FROM DimUserRole_Mod 
										where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
										AND AuthorisationStatus IN('NP','MP','DP','RM')
										GROUP BY UserRoleAlt_Key
									 )
				END
			END

			---- ADD Additional Logic to Load Master Data for Parameter Master Table BY SATWAJI AS ON 11/07/2022
			ELSE IF @MenuId=2008
			BEGIN
				IF @Mode IN(0,1,2,3)
				BEGIN
					SELECT 
						'SelectData' TableName
						,DimParameterName
						,ParameterAlt_Key
						,ParameterName
						,ParameterShortName
						,ParameterShortNameEnum
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						  ELSE NULL END AS AuthorisationStatus
						,'Y' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM DimParameter WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND ParameterAlt_Key = Cast(@BaseColumnValue AS INT) AND ISNULL(AuthorisationStatus,'A')='A' 
					UNION
					SELECT 
						'SelectData' TableName
						,DimParameterName
						,ParameterAlt_Key
						,ParameterName
						,ParameterShortName
						,ParameterShortNameEnum
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						 ELSE NULL END AS AuthorisationStatus
						,'N' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM DimParameter_Mod WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND ParameterAlt_Key = Cast(@BaseColumnValue AS INT) AND AuthorisationStatus IN('NP','MP','DP','RM')
					AND Parameter_Key IN(
										SELECT MAX(Parameter_Key)Parameter_Key FROM DimParameter_Mod 
										where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
										AND AuthorisationStatus IN('NP','MP','DP','RM')
										GROUP BY ParameterAlt_Key
									 )
					
				END
				ELSE
				BEGIN
					SELECT 
						'SelectData' TableName
						,DimParameterName
						,ParameterAlt_Key
						,ParameterName
						,ParameterShortName
						,ParameterShortNameEnum
						,ISNULL(ModifiedBy,CreatedBy) AS CreatedModifiedBy
						,CASE	WHEN  ISNULL(AuthorisationStatus,'')='' OR AuthorisationStatus='A' THEN 'Authorized'
						 		WHEN  AuthorisationStatus='R' THEN 'Rejected'
						 		WHEN  AuthorisationStatus IN('NP','MP','DP','RM') THEN 'Pending' 
						 ELSE NULL END AS AuthorisationStatus
						,'N' AS IsMainTable
						,ISNULL(ModifiedBy,CreatedBy) AS OperationBy
						--,ISNULL(CONVERT(VARCHAR(10),DateModified,103),CONVERT(VARCHAR(10),DateCreated,103)) AS OperationDate
						,ISNULL(DateModified,DateCreated) AS OperationDate
					FROM DimParameter_Mod WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND ParameterAlt_Key = Cast(@BaseColumnValue AS INT) AND AuthorisationStatus IN('NP','MP','DP','RM')
					AND Parameter_Key IN(
										SELECT MAX(Parameter_Key)Parameter_Key FROM DimParameter_Mod 
										where (EffectiveFromTimeKey<=@TimeKey and EffectiveToTimeKey>=@TimeKey)
										AND AuthorisationStatus IN('NP','MP','DP','RM')
										GROUP BY ParameterAlt_Key
									 )
				END
			END
			ELSE
			BEGIN

				PRINT 'Else'


		
				SELECT 'SelectData' TableName,	@UserLocation CreatedModifiedByLoc, @UserLocationCode CreatedModifiedByLocCode, * FROM #TmpSelData --WHERE MENUID=@MenuId
			END
			
			
			--SELECT 'ChangeFields' TableName,  ChngFld ControlId  FROM 
			--		(SELECT Split.a.value('.', 'VARCHAR(100)') AS ChngFld  
			--			FROM  (SELECT  CAST ('<M>' + REPLACE(@ChangeFields, ',', '</M><M>') + '</M>' AS XML) AS ChngFld 
				
			--				) AS A CROSS APPLY ChngFld.nodes ('/M') AS Split(a) )A
	
	

			SELECT 'ChangeFields' TableName,  @ChangeFields ControlId
	
	
END








GO