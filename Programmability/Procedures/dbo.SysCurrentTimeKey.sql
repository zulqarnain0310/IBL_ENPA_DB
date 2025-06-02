SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[SysCurrentTimeKey] 
AS 
SET DATEFORMAT DMY      
BEGIN        
DECLARE @TIMEKEY INT
SET @TIMEKEY=(SELECT TimeKey FROM SysDayMatrix WHERE CAST(Date AS DATE)=CAST(GETDATE() AS DATE))

PRINT @TIMEKEY

	SELECT         
		CONVERT(Char,MonthFirstDate ,103) AS MonthFirstDate        
		,CONVERT(Char,ExtDate,103) AS MonthLastDate        
		,CONVERT(Char,'01/01/1950',103) AS StartDate        
		,TimeKey       
		,MonthName        
		,CASE WHEN
			 MONTH(ExtDate)<=9 THEN 
			 '0'+CAST(month(ExtDate) AS VARCHAR)
			 ELSE
			 CAST(month(ExtDate) AS VARCHAR)
			 END+cast(Year(ExtDate) AS VARCHAR)  AS MonthYear    
		,[Year]        
		,Prev_Month_Key AS PrvTimeKey  
		,CurrentStatus      
		,TimeKey  AS EffectiveFromTimeKey
		,'49999' AS EffectiveToTimeKey
		,MonthLastDate
		,CONVERT(varchar(11),GETDATE(),103) AS CurrentDate
	FROM SysDataMatrix         
	WHERE  CurrentStatus = 'C'         
	 
END
BEGIN        
--DECLARE @TIMEKEY INT
SET @TIMEKEY=(SELECT TimeKey FROM SysDayMatrix WHERE CAST(Date AS DATE)=CAST(GETDATE() AS DATE))

PRINT @TIMEKEY
DECLARE @CurrentStatus_MOC char = 'C'
SET @CurrentStatus_MOC=(SELECT CurrentStatus_MOC FROM SysDataMatrix WHERE CurrentStatus_MOC = 'C')

	IF (@CurrentStatus_MOC = 'C')
	BEGIN
	SELECT         
		CONVERT(Char,MonthFirstDate ,103) AS MonthFirstDate        
		,CONVERT(Char,ExtDate,103) AS MonthLastDate        
		,CONVERT(Char,'01/01/1950',103) AS StartDate        
		,TimeKey       
		,MonthName        
		,CASE WHEN
			 MONTH(ExtDate)<=9 THEN 
			 '0'+CAST(month(ExtDate) AS VARCHAR)
			 ELSE
			 CAST(month(ExtDate) AS VARCHAR)
			 END+cast(Year(ExtDate) AS VARCHAR)  AS MonthYear    
		,[Year]        
		,Prev_Month_Key AS PrvTimeKey  
		,CurrentStatus_MOC      
		,TimeKey  AS EffectiveFromTimeKey
		,'49999' AS EffectiveToTimeKey
		,MonthLastDate
		,CONVERT(varchar(11),GETDATE(),103) AS CurrentDate
	FROM SysDataMatrix         
	WHERE  CurrentStatus_MOC = 'C'   
	END
 ELSE 
	BEGIN
	SELECT         
		CONVERT(Char,MonthFirstDate ,103) AS MonthFirstDate        
		,CONVERT(Char,ExtDate,103) AS MonthLastDate        
		,CONVERT(Char,'01/01/1950',103) AS StartDate        
		,TimeKey       
		,MonthName        
		,CASE WHEN
			 MONTH(ExtDate)<=9 THEN 
			 '0'+CAST(month(ExtDate) AS VARCHAR)
			 ELSE
			 CAST(month(ExtDate) AS VARCHAR)
			 END+cast(Year(ExtDate) AS VARCHAR)  AS MonthYear    
		,[Year]        
		,Prev_Month_Key AS PrvTimeKey  
		,CurrentStatus_MOC    = GETDATE()   
		,TimeKey  AS EffectiveFromTimeKey
		,'49999' AS EffectiveToTimeKey
		,MonthLastDate
		,CONVERT(varchar(11),GETDATE(),103) AS CurrentDate
	FROM SysDataMatrix         
	WHERE CurrentStatus = 'C'  
	END

	
	 
END

GO