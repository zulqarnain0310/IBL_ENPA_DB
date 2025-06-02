SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[Alert]
as

select PreProcessingFreeze,PreProcessingFreezeBy,PreProcessingFreezeDate,MOC_Freeze,MOC_FreezeBy,MOC_FreezeDate from SysDataMatrix where CurrentStatus='C'
GO