SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
create proc [dbo].[sysdtme]
as

declare @dt date =(select eomonth(dateadd(month,-1,Date)) from SysDataMatrix where CurrentStatus='c')

select TimeKey,Date,* from SysDataMatrix where Date=@dt
GO