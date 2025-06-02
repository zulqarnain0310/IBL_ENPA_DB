SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


create proc [dbo].[FileExistornot_ve]
@PDate date


AS



--declare
--@PDate VARCHAR(25)='2017-09-30'


Begin



IF (OBJECT_ID('tempdb..#temptable') IS NOT NULL)
					DROP TABLE #temptable
				
--select ParameterAlt_Key,ParameterValue,identity(int,1,1) id into #temptable from SysSolutionParameter
--where ParameterAlt_Key in(358,359,360,361,362,363,364,365)




declare @processdate varchar(20)= format(eomonth(@PDate),'yyyyMMdd')
PRINT @PROCESSDATE
select * into #temptable

from 
(
select ParameterAlt_Key,ROW_NUMBER() OVER( ORDER BY (SELECT 1))ID  ,case when ParameterAlt_Key=362
											   then ParameterValue  
											   else ParameterValue+  @PROCESSDATE + '.txt' 
											   end
											   ParameterValue
											   --identity(int,1,1)id
 from SysSolutionParameter
where ParameterAlt_Key in(358,359,360,361,363,364,365,362 )

) a
--select * from #temptable
--drop table #temp
update #temptable
set ParameterValue=ParameterValue + @PROCESSDATE + '.csv' 
where ParameterAlt_Key=362

declare @start int =1 , @totalcount int=(select count(1) from #temptable),@path varchar(255),@ParameterAlt_Key int,@true bit

while(@start<=@totalcount)
begin

  --set @path=(select replace(ParameterValue,'@Date',@processdate) from #temptable where id=@start)+''+@processdate+'.txt'
  SET @path=(SELECT ParameterValue FROM #temptable WHERE ID=@start)
  set @ParameterAlt_Key=(select ParameterAlt_Key from #temptable where id=@start)
  pRINT @PATH
 set @true=(select dbo.fn_FileExists(@path))
  
  update SysSolutionParameter set FileExist=@true where ParameterAlt_Key=@ParameterAlt_Key

 set @start=@start+1
end

if (select count(1) from SysSolutionParameter)=8

begin 
 print''
end 

else


 ---update SysSolutionParameter set FileExist=(select  (case when count(Customer_Code) >'0' then 1 else 0 end)  as fileexist   
 ---from InduslndStg.dbo.Prolendz_Stg_13022018 where EDate=@PDate) where ParameterAlt_Key=360 

begin
   select ParameterName,FileExist from SysSolutionParameter where FileExist is not null --and FileExist='0'
end


----CREATE FUNCTION dbo.fn_FileExists(@path varchar(512))
----RETURNS BIT
----AS
----BEGIN
----     DECLARE @result INT
----     EXEC master.dbo.xp_fileexist @path, @result OUTPUT
----     RETURN cast(@result as bit)
----END;


----select dbo.fn_FileExists('C:\D2K_Files\Dedup\Dedup_20180131.txt')

----drop table #temptable
 ---alter table SysSolutionParameter
 ---add FileExist char(1)


End
GO