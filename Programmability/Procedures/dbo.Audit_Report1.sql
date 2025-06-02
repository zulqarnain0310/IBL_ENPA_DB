SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

create proc [dbo].[Audit_Report1]

as

begin
select * From TempCount
end
GO