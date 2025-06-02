SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

create proc [dbo].[Timekey]
(@date date,@Timekey int)
as
begin
if isnull(@date,'')<>''
begin
select TimeKey,date,* from SysDataMatrix where cast(date as date)=@date
end
else
begin
select TimeKey,date,* from SysDataMatrix where TimeKey=@Timekey
end
end
GO