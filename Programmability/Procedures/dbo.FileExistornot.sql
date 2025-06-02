SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE proc [dbo].[FileExistornot]
@PDate date


AS

--declare
--@PDate date='2017-09-30'


Begin

IF (OBJECT_ID('tempdb..#temptable') IS NOT NULL)
	DROP TABLE #temptable

select ParameterAlt_Key,ParameterValue,identity(int,1,1) id into #temptable from SysSolutionParameter
where ParameterAlt_Key in(358,359,360,361,362,363,364,365)

--select * from #temptable


declare @start int =1 , @totalcount int=(select count(1) from #temptable),@path varchar(255),@ParameterAlt_Key int,@true bit
declare @processdate varchar(20)= format(eomonth(@PDate),'ddMMyyyy')


while(@start<=@totalcount)
BEGIN

	IF EXISTS (SELECT 1 FROM #temptable WHERE ParameterAlt_Key=362 AND id=@start)	
		BEGIN
				SET @path=(select ParameterValue from #temptable where id=@start )+''+@processdate+'.csv'
        END	

		ELSE
			BEGIN
					
				  SET @path=(select ParameterValue from #temptable where id=@start )+''+@processdate+'.txt'	
			END

			SET @ParameterAlt_Key=(select ParameterAlt_Key from #temptable where id=@start )
						
			DECLARE @isExists INT
			exec master.dbo.xp_fileexist @path, 
			@isExists OUTPUT


			UPDATE SysSolutionParameter SET FileExist=@isExists 
			WHERE ParameterAlt_Key=@ParameterAlt_Key 



SET @start=@start+1

end

IF (SELECT COUNT(1) FROM SYSSOLUTIONPARAMETER)=8

BEGIN 
 PRINT''
END 

 ---update SysSolutionParameter set FileExist=(select  (case when count(Customer_Code) >'0' then 1 else 0 end)  as fileexist   
 ---from InduslndStg.dbo.Prolendz_Stg_13022018 where EDate=@PDate) where ParameterAlt_Key=360 

ELSE

BEGIN
      SELECT PARAMETERNAME,FILEEXIST FROM SYSSOLUTIONPARAMETER WHERE FILEEXIST IS NOT NULL --AND FILEEXIST='0'
END

end
GO