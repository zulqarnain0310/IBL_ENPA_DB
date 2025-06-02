SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
create procedure [dbo].[DailyProcess]
as
begin

declare @dt1 date=(select cast(Date as date) date from SysDataMatrix(nolock) where CurrentStatus='C')
select * from IBL_ENPA_STGDB..Procedure_Audit where EXT_DATE=@dt1 order by Start_Date_Time desc

select * from IBL_ENPA_STGDB..Package_AUDIT where Execution_date=@dt1 order by ExecutionStartTime desc
end
GO