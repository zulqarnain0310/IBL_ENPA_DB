SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE proc [dbo].[Audit_Report]

as

begin
select * From InduslndStg.dbo.StgCount
end
GO