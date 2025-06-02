SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[PAN_ENCIF_MismatchSelect]
 @TimeKey			INT=24745
,@UserId			VARCHAR(20)=''
,@DashboradFlag		CHAR(1)=''
,@SearchFor			VARCHAR(20)=''    
,@Result			SMALLINT   =0  OUTPUT
,@PageNo			INT=0

AS 

--DECLARE
-- @TimeKey			INT=0
--,@UserId			VARCHAR(20)=''
--,@DashboradFlag		CHAR(1)='N'
--,@SearchFor			VARCHAR(20)=''

IF OBJECT_ID('TEMPDB..#PanMismatchRecords')IS NOT NULL
DROP TABLE #PanMismatchRecords

IF @DashboradFlag='N'
	BEGIN

			SELECT 
			 PAN				AS PAN
			,NCIF				AS ENCIF  
			,CustomerID			AS ClientID
			,CustomerName		AS Name
			,A.SrcSysAlt_Key	
			,B.SourceName		AS SourceSystem
			,case when A.Reconciled<>'Y' THEN cast((0) as bit)  ELSE cast((1) as bit) END	AS Done
			,case when A.Reconciled<>'Y' THEN 0 ELSE 1 END	As IsDisable
			,A.ModifiedBy AS UserID
			,'TblSelect' AS TableName 
			
			FROM NCIF_MismatchDetails  A
			LEFT JOIN DimSourceSystem    B  ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
												AND B.SourceAlt_Key=A.SrcSysAlt_Key
			WHERE    TimeKey=@TimeKey
				 AND PAN=CASE WHEN @SearchFor<>'' THEN @SearchFor  ELSE PAN END
				 --AND  ISNULL(PAN,'')<>''    ---SHISHIR SIR	
				 --AND  LEN(PAN)=10 
				 --AND  PAN LIKE'%[A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]%'

	END				
		
ELSE IF @DashboradFlag='P'
    BEGIN
	
			--SELECT top 100
			-- NCIF				AS ENCIF  
			--,A.SrcSysAlt_Key	
			--,B.SourceName		AS Sourcesystem
			--,CustomerID			AS ClientID
			--,PAN				AS PAN
			--,CustomerName		AS Name
			----,B.SourceName		AS Sourcesystem
			--,A.NSDL_FirstName	AS FirstName
			--,A.NSDL_MiddleName	AS MiddleName
			--,A.NSDL_LastName	AS LastName
			--,case when A.Reconciled<>'Y' THEN cast((0) as bit)  ELSE cast((1) as bit) END	AS Done
			--,case when A.Reconciled<>'Y' THEN 0 ELSE 1 END	As IsDisable
			--,A.ModifiedBy AS UserID
			--,'TblSelect' AS TableName 
			--FROM PAN_MismatchDetails A
			--LEFT JOIN DimSourceSystem    B  ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
			--									AND B.SourceAlt_Key=A.SrcSysAlt_Key
			--WHERE    TimeKey=@TimeKey
			--	 AND PAN=CASE WHEN @SearchFor<>'' THEN @SearchFor ELSE PAN END

			DECLARE
			 @TableName   VARCHAR(50)='PanMismatchRecords'
			,@SQL        NVARCHAR(MAX)


			SET @TableName=@TableName+'_'+@UserId

			IF @PageNo =0
				BEGIN
							/* Dynmaic Create table user wise */	

							IF OBJECT_ID(@TableName,'U')IS NOT NULL
								BEGIN
											SET @SQL='DROP TABLE '+@TableName+''
											EXEC(@SQL)														

										--SET @SQL='DROP TABLE IF EXISTS '+@TableName+''
										--EXEC(@SQL)												----2016 FEATUE

								END

							IF OBJECT_ID(@TableName,'U')IS NULL
							    BEGIN
									 SET @SQL = 
			
									 N'CREATE TABLE ' + @TABLENAME + '
									 ('
									 + ' [Row_Num][INT]NULL,
											[NCIF] [varchar](20) NULL,
											[CustomerID] [varchar](20) NULL,
											[CustomerName] [varchar](80) NULL,
											[PAN] [varchar](20) NULL,
											[NSDL_FirstName] [varchar](80) NULL,
											[NSDL_MiddleName] [varchar](80) NULL,
											[NSDL_LastName] [varchar](80) NULL,
											[Reconciled] [char](1) NULL,
											[TimeKey] [int] NULL,
											[CreatedBy] [varchar](20) NULL,
											[DateCreated] [smalldatetime] NULL,
											[ModifiedBy] [varchar](20) NULL,
											[DateModified] [smalldatetime] NULL,
											[ApprovedBy] [varchar](20) NULL,
											[DateApproved] [smalldatetime] NULL,
											[PAN_Status] [char](1) NULL,
											[InsertFlag] [char](1) NULL,
											[SrcSysAlt_Key][TINYINT]NULL
									 
									 )';
			
									 EXEC (@sql)
	
								 END
								
							/* Dynmaic Create table user wise */	
								
							SET @SQL='TRUNCATE TABLE '+@TableName+''
							EXEC (@SQL);

								--IF ISNULL(@SearchFor,'')=''
								--	BEGIN
								--				--INSERT INTO  #PanMismatchRecords
								
								--				SELECT 
								--				 ROW_NUMBER()OVER(ORDER BY NCIF)AS Row_Num
								--				,NCIF,CustomerID,CustomerName,PAN,NSDL_FirstName,NSDL_MiddleName,NSDL_LastName,Reconciled,
								--				TimeKey,CreatedBy,DateCreated,ModifiedBy,ApprovedBy,DateApproved,PAN_Status,InsertFlag,SrcSysAlt_Key
								--				INTO #PanMismatchRecords
								--				FROM PAN_MismatchDetails
								--				WHERE (TimeKey=@TimeKey)
								
								--	END
								
								--ELSE
								--	 BEGIN
											
									SELECT  ROW_NUMBER()OVER(ORDER BY A.NCIF)AS Row_Num
									,A.NCIF,CustomerID,CustomerName,A.PAN,NSDL_FirstName,NSDL_MiddleName,NSDL_LastName,Reconciled,
									TimeKey,CreatedBy,DateCreated,ModifiedBy,ApprovedBy,DateApproved,PAN_Status,InsertFlag,SrcSysAlt_Key INTO #PanMismatchRecords 
									FROM PAN_MismatchDetails A
									WHERE A.TimeKey=@TimeKey 
									AND  A.NCIF=CASE WHEN @SearchFor<>''THEN @SearchFor ELSE A.NCIF END

								

									--INNER JOIN (SELECT COUNT(DISTINCT(PAN))PAN,NCIF FROM PAN_MismatchDetails
									--			WHERE (TimeKey=@TimeKey)AND NCIF=CASE WHEN @SearchFor<>'' THEN @SearchFor ELSE NCIF END		
									--				AND  ISNULL(PAN,'')<>''    ---SHISHIR SIR	
									--				AND  LEN(PAN)=10 
									--				AND  PAN LIKE'%[A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]%'
									--			GROUP BY NCIF		
									--			HAVING(COUNT(DISTINCT(PAN))>1)
									--			)B  ON (A.TimeKey=@TimeKey) AND A.NCIF=B.NCIF 
																							
									 --END
									 

								/*Insert the records in dynamic table */
								SET @SQL='INSERT INTO '+@TableName+'
								(
								Row_Num
							    ,NCIF,CustomerID,CustomerName,PAN,NSDL_FirstName,NSDL_MiddleName,NSDL_LastName,Reconciled,
								TimeKey,CreatedBy,DateCreated,ModifiedBy,ApprovedBy,DateApproved,PAN_Status,InsertFlag,SrcSysAlt_Key
								) 
								SELECT 
								Row_Num
								,NCIF,CustomerID,CustomerName,PAN,NSDL_FirstName,NSDL_MiddleName,NSDL_LastName,Reconciled,
								TimeKey,CreatedBy,DateCreated,ModifiedBy,ApprovedBy,DateApproved,PAN_Status,InsertFlag,SrcSysAlt_Key
								FROM #PanMismatchRecords'

								EXEC (@SQL);

				END					
					 	
			DECLARE
			 @RecPerPage INT=(SELECT ParameterValue FROM SysSolutionparameter  
							  WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
							  AND ParameterName='PanMismatchDashboardPerPageCnt'
							  )
			,@SNoFrom INT=0 
			,@SNoTo INT=0
			
			
			IF @PageNo=0
				BEGIN 
					SET @PageNo=1
				END
			
			
				SET @SNoTo=@PageNo*@RecPerPage
				SET @SNoFrom=(@SNoTo-@RecPerPage)+1


				DECLARE @value  VARCHAR(MAX)

				IF @PageNo<>0
					BEGIN
							/*UPDATE THE RECORDS WHICH ARE RECONCILED*/
							SET @SQL='UPDATE A
									  SET A.Reconciled=B.Reconciled,A.ModifiedBy=B.ModifiedBy
									  FROM '+@TableName+' A
									  INNER JOIN PAN_MismatchDetails B  ON (A.CustomerID=B.CustomerID)
																			AND B.TIMEKEY='+CAST(@TimeKey AS VARCHAR(MAX))+'
									  '
							EXEC(@SQL)			
				   END
				
				SET @SQL='SELECT @value=COUNT(*) FROM '+@TableName+''
				
				EXECUTE sp_executesql @SQL, N'@value int OUTPUT',@value output
				
				SELECT @value TotalCount,@RecPerPage RecPerPage,'TblPagination' AS TableName 

				SET @SQL='SELECT  
				 NCIF				AS ENCIF  
				,CAST(A.SrcSysAlt_Key AS VARCHAR(50))	 AS SrcSysAlt_Key
				,B.SourceName		AS Sourcesystem
				,CustomerID			AS ClientID
				,PAN				AS PAN
				,CustomerName		AS Name
				--,B.SourceName		AS Sourcesystem
				,A.NSDL_FirstName	AS FirstName
				,A.NSDL_MiddleName	AS MiddleName
				,A.NSDL_LastName	AS LastName
				,case when A.Reconciled<>''Y'' THEN cast((0) as bit)  ELSE cast((1) as bit) END	AS Done
				,case when A.Reconciled<>''Y'' THEN 0 ELSE 1 END	AS IsDisable
				,A.ModifiedBy AS UserID	
				,''TblSelect'' AS TableName 	
				FROM '+@TableName+' A
				LEFT JOIN DimSourceSystem B ON (B.EffectiveFromTimeKey<='+CAST(@TimeKey AS varchar(50))+' AND B.EffectiveToTimeKey>='+CAST(@TimeKey AS VARCHAR(50))+')
												AND B.SourceAlt_Key=A.SrcSysAlt_Key
				WHERE 
				Row_Num BETWEEN '+CAST(@SNoFrom AS VARCHAR(100))+' AND '+CAST(@SNoTo AS VARCHAR(100))+' 
				ORDER BY ROW_NUM'
				EXEC (@SQL);

				/*Count of records in user wise table*/
					
	END	

ELSE IF @DashboradFlag='C'
	BEGIN
				
			SELECT 
			 CustomerID			AS ClientID
			,CustomerName		AS Name
			,NCIF				AS ENCIF  
			,A.SrcSysAlt_Key	
			,B.SourceName		AS Sourcesystem
			,PAN				AS PAN
			,B.SourceName		AS Sourcesystem
			,case when A.Reconciled<>'Y' THEN cast((0) as bit)  ELSE cast((1) as bit) END	AS Done
			,case when A.Reconciled<>'Y' THEN 0 ELSE 1 END	As IsDisable
			,A.ModifiedBy AS UserID
			,'TblSelect' AS TableName 
			FROM ClientID_NCIF_MismatchDetails A
			LEFT JOIN DimSourceSystem    B  ON (B.EffectiveFromTimeKey<=@TimeKey AND B.EffectiveToTimeKey>=@TimeKey)
												AND B.SourceAlt_Key=A.SrcSysAlt_Key
			WHERE    TimeKey=@TimeKey
				 AND CustomerID=CASE WHEN @SearchFor<>'' THEN @SearchFor ELSE CustomerID END


	END
GO