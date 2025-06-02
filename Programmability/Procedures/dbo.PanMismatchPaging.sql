SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
create PROC [dbo].[PanMismatchPaging]
 @SearchForNCIF VARCHAR(20)=''
,@TimeKey   INT=24745
,@PageNo    INT=0
,@UserLoginID VARCHAR(20)='SONALI'

AS 

--DECLARE
-- @SearchForNCIF VARCHAR(20)=''
--,@TimeKey   INT=24745
--,@PageNo    INT=0E
--,@UserLoginID VARCHAR(20)='SONALI'

DECLARE
@TableName   VARCHAR(50)='PanMismatchRecords'
,@SQL        NVARCHAR(MAX)


SET @TableName=@TableName+'_'+@UserLoginID


IF OBJECT_ID('TEMPDB..#PanMismatchRecords')IS NOT NULL
DROP TABLE #PanMismatchRecords


IF @PageNo=0
	BEGIN
			/* Dynmaic Create table user wise */	

			IF OBJECT_ID(@TableName,'U')IS NOT NULL
				BEGIN
					SET @SQL='DROP TABLE '+@TableName+''
					EXEC(@SQL)

					SET @SQL='DROP TABLE IF EXISTS '+@TableName+''
					EXEC(@SQL)												----2016 FEATUE

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

				--IF ISNULL(@SearchForNCIF,'')=''
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
								--INSERT INTO #PanMismatchRecords 
								SELECT 
								 ROW_NUMBER()OVER(ORDER BY NCIF)AS Row_Num
								,NCIF,CustomerID,CustomerName,PAN,NSDL_FirstName,NSDL_MiddleName,NSDL_LastName,Reconciled,
								TimeKey,CreatedBy,DateCreated,ModifiedBy,ApprovedBy,DateApproved,PAN_Status,InsertFlag,SrcSysAlt_Key
								INTO #PanMismatchRecords 
								FROM PAN_MismatchDetails
								WHERE (TimeKey=@TimeKey) AND NCIF=CASE WHEN @SearchForNCIF<>'' THEN @SearchForNCIF ELSE NCIF END			
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
 @RecPerPage SMALLINT=10      --set per page records
,@SNoFrom SMALLINT=0
,@SNoTo SMALLINT=0


IF @PageNo=0
	BEGIN 
		SET @PageNo=1
	END


				SET @SNoTo=@PageNo*@RecPerPage
				SET @SNoFrom=(@SNoTo-@RecPerPage)+1

				DECLARE @value  VARCHAR(MAX)
				
				SET @SQL='SELECT @value=COUNT(*) FROM '+@TableName+''

				EXECUTE sp_executesql @SQL, N'@value int OUTPUT',@value output
				
				SELECT @value,@RecPerPage 

				IF @PageNo<>0
					BEGIN
							/*UPDATE THE RECORDS WHICH ARE RECONCILED*/
							SET @SQL='UPDATE A
									  SET A.Reconciled=B.Reconciled
									  FROM '+@TableName+' A
									  INNER JOIN PAN_MismatchDetails B  ON (A.PAN=B.PAN)
																			AND B.TIMEKEY='+CAST(@TimeKey AS VARCHAR(MAX))+'
									  '
							EXEC(@SQL)			
				   END

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
				WHERE Row_Num BETWEEN '+CAST(@SNoFrom AS VARCHAR(100))+' AND '+CAST(@SNoTo AS VARCHAR(100))+' ORDER BY ROW_NUM'
				EXEC (@SQL);






	







GO