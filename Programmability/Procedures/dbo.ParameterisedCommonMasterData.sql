SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ParameterisedCommonMasterData] 
        @XMLMasterName AS VARCHAR(50)
AS

BEGIN
	PRINT 1
	PRINT @XMLMasterName

	DECLARE @Schema VARCHAR(10)

	
	 
	IF EXISTS(SELECT 1 FROM MetaParameterisedMasterTable WHERE XMLTableName=@XMLMasterName) 	
		BEGIN
			PRINT 2

			DECLARE @TableName VARCHAR(50)=''
					,@ColumnName VARCHAR(2000)=''
					,@InnerJoin VARCHAR(205)='' --- edited by shailesh on 20/07/2015 as inner join is used for metacerdescription is more than 200 char
					,@WhereCond VARCHAR(500)=''
					,@GroupBy VARCHAR(200)=''
					,@OrderBy VARCHAR(100)=''
					,@StrSql AS VARCHAR(MAX)=''

			SELECT @TableName=TableName 
					,@ColumnName= ColumnSelect 
					,@InnerJoin= InnerJoin 
					,@WhereCond=ISNULL(WhereCondition,'') 
					,@GroupBy=ISNULL(GroupBy,'')
					,@OrderBy=OrderBy
				FROM MetaParameterisedMasterTable 
				WHERE XMLTableName=@XMLMasterName
			
		SELECT  @Schema=SCHEMA_NAME(SCHEMA_ID)+'.'  FROM SYS.OBJECTS WHERE name=@TableName and SCHEMA_NAME(SCHEMA_ID)<>'ews'

			PRINT '@Schema'
			PRINT @Schema
			if isnull(@Schema,'')='' set @Schema=''



			PRINT @TableName
			print @ColumnName
			print @InnerJoin
			print @WhereCond
			print @OrderBy

			PRINT 11
			SET @StrSql='SELECT distinct '''+@XMLMasterName+ '''TableName,' +@ColumnName + ' FROM ' +@Schema+ @TableName
			
				     +' '+ISNULL(@InnerJoin,'')     			
						+' '+ISNULL(@WhereCond,'') 
					----	+ ' '+ISNULL(@GroupBy,'')
						+' '+ISNULL(@OrderBy,'')
		PRINT 12
			PRINT @StrSql
			PRINT 13
			EXECUTE (@StrSql) 
		END
END




GO