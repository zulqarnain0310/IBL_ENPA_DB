SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


create PROCEDURE [dbo].[SelectMetaScreenResource] 
    @ScreenName VARCHAR(100) = 'Professionals'
		
	AS
	BEGIN
		DECLARE @MenuId INT , @LoopCount TINYINT =1 , @LangName VARCHAR(20)
		SELECT @MenuId = MenuId FROM SysCRisMacMenu WHERE REPLACE(MenuCaption,' ','') = @ScreenName
			--select @MenuId
			IF	OBJECT_ID('tempdb..#LanguageTmp') IS NOT NULL
				DROP TABLE #LanguageTmp

				PRINT '@MenuId'
				PRINT @MenuId
					--SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) RowId,ParameterName 
					--INTO #LanguageTmp 
					--FROM DimParameter 
					--WHERE DimParameterName = 'Language'

					SELECT ROW_NUMBER() OVER (ORDER BY (SELECT 1)) RowId , RC.LanguageKey ParameterName 
								INTO #LanguageTmp 
							FROM MetaScreenLableResource RC 
									INNER JOIN MetaDynamicScreenField MSF
										ON RC.ControlID = MSF.ControlID --AND MSF.MenuID = RC.MenuID
									WHERE RC.MenuID = @MenuId  
									GROUP BY RC.LanguageKey

					WHILE	@LoopCount <= (SELECT COUNT(1) FROM #LanguageTmp)
					BEGIN
						
							SELECT @LangName = ParameterName 
							FROM #LanguageTmp 
							WHERE RowId = @LoopCount
			
							DECLARE @ColName NVARCHAR(MAX), @ColData NVARCHAR(MAX), @SQL NVARCHAR(MAX)

							IF  OBJECT_ID('Tempdb..#TmmpResource') IS NOT NULL
							DROP TABLE #TmmpResource		
	
							SELECT RC.ControlID,	RC.Lable,	RC.LanguageKey TableName 
								INTO #TmmpResource
							FROM MetaScreenLableResource RC 
									INNER JOIN MetaDynamicScreenField MSF
										ON RC.ControlID = MSF.ControlID --AND MSF.MenuID = RC.MenuID
									WHERE RC.MenuID = @MenuId AND RC.LanguageKey = @LangName
								GROUP BY RC.ControlID,	RC.Lable,	RC.LanguageKey

							SELECT @ColName=STUFF((SELECT ', ['+CAST(ControlID AS VARCHAR(10))+'] NVARCHAR(2000)'
												FROM #TmmpResource M1
												FOR XML PATH('')),1,1,'')   
										FROM #TmmpResource M2

							SELECT @ColData=STUFF((SELECT ', N'''+Lable +''''
										FROM #TmmpResource M1
										FOR XML PATH('')),1,1,'')   
								FROM #TmmpResource M2

								print '@ColName	'
								print @ColName				

							--IF  OBJECT_ID('Tempdb..#TmmpResSelect') IS NOT NULL
							--	DROP TABLE #TmmpResSelect
							SET @ColName=RIGHT(@ColName,LEN(@ColName)-1)
							SET @ColData=''''+RIGHT(@ColData,LEN(@ColData)-1)
	
							SET @ColData=''+RIGHT(@ColData,LEN(@ColData)-1)
							IF OBJECT_ID('Tempdb..#ResSelect') IS NOT NULL
									DROP TABLE #ResSelect
							
							CREATE TABLE #ResSelect (EntityKey int)
	
							--PRINT @ColName
							--print @ColData

							SET @SQL=REPLACE(@SQL,'&amp;','&')
							SET @SQL='ALTER TABLE #ResSelect ADD '+@ColName
							PRINT @SQL
							exec (@SQL)
							ALTER TABLE #ResSelect DROP COLUMN EntityKey

							SET @SQL='INSERT INTO #ResSelect '
							SET @SQL=@SQL+'SELECT '+@ColData
							SET @SQL=REPLACE(@SQL,'&amp;','&')
							EXEC(@SQL)

							SELECT @LangName TableName, * FROM #ResSelect


						SET @LoopCount=@LoopCount +1

					END		

		
END


GO