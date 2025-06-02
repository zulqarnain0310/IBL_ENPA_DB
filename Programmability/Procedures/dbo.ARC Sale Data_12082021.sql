SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[ARC Sale Data_12082021]
	@Cost AS float,
	@TimeKey AS int

	AS 
SET NOCOUNT ON;
SELECT
 EFFECTIVEFROMTIMEKEY 
,SrcSysAlt_Key
,NCIF_Id
,CustomerID
,AccountID
,DtofsaletoARC
,POS+InterestReceivable/@Cost [Total Sale Consideration]
,POS/@Cost
,InterestReceivable/@Cost
,Action
FROM  [DBO].[SaletoARCFinalACFlagging]	
WHERE EFFECTIVEFROMTIMEKEY=@TimeKey
GO