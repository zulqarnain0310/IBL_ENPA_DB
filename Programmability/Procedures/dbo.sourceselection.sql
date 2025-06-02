SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE proc [dbo].[sourceselection]
as

select SourceName as label,SourceName as value from DimSourceSystem
GO