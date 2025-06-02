SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[PanDataSelect]
@TimeKey INT=0

AS
	
	  
select PAN,* from PAN_MismatchDetails
GO