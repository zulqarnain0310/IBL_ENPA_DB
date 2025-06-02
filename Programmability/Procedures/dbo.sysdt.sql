SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
create proc [dbo].[sysdt]
as
select Date,TimeKey,* from SysDataMatrix where CurrentStatus='c'
GO