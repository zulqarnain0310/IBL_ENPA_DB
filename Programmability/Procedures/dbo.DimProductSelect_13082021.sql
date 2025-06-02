SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author Triloki Kumar>
-- Create date: <Create 05/12/2017>
-- Description:	<Description Dim Product Select >
-- =============================================
CREATE PROCEDURE [dbo].[DimProductSelect_13082021]
@OperationFlag			INT
,@UserId				VARCHAR(30)
, @TimeKey INT
AS

--DECLARE
--	@OperationFlag			INT=2
--	,@UserId				VARCHAR(30)='npamaker'
--	,@TimeKey				INT=24745
BEGIN
	
	SET NOCOUNT ON;
		--DECLARE @TimeKey INT
		--select @TimeKey from SysDaymatrix WHERE Date=CONVERT(DATE,GETDATE(),103)
  

		IF @OperationFlag=2
			BEGIN
					select ProductAlt_Key,ProductCode,ProductName,CASE WHEN AgriFlag='N' THEN 'No' WHEN AgriFlag='Y' THEN 'Yes' END AgriFlag,'' ModifiedBy,'Y' IsMainTable,'TblFetchGrid' AS TableName 
					from DIMPRODUCT
					WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND ISNULL(AuthorisationStatus,'A')='A'

					UNION 
					select ProductAlt_Key,ProductCode,ProductName,CASE WHEN AgriFlag='N' THEN 'No' WHEN AgriFlag='Y' THEN 'Yes' END AgriFlag,ModifiedBy,'N' IsMainTable,'TblFetchGrid' AS TableName 
					from DIMPRODUCT_MOD 					
					WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND AuthorisationStatus IN('MP','RM')
					

			END
	

		ELSE
			BEGIN
				select ProductAlt_Key,ProductCode,ProductName,CASE WHEN AgriFlag='N' THEN 'No' WHEN AgriFlag='Y' THEN 'Yes' END AgriFlag,ModifiedBy,'TblFetchGrid' AS TableName 
					from DIMPRODUCT_MOD 					
					WHERE (EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
					AND AuthorisationStatus IN('MP','RM')
					AND ModifiedBy<>@UserId
			END

END
GO