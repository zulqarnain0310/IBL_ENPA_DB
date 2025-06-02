SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[PanInUp]

 @xmlDocument	XML
,@CrModBy		VARCHAR(20)
,@Result		INT=0  OUTPUT
,@ReconcileFlag	CHAR(1)=0
,@TimeKey       INT

AS

BEGIN TRY
	BEGIN TRANSACTION

IF OBJECT_ID('TEMPDB..#Reconcile')IS NOT NULL
DROP TABLE #Reconcile

 SELECT
         c.value('./PAN[1]','varchar(20)')ENCIF
       
       INTO #Reconcile
       FROM @xmlDocument.nodes('/DataSet/GridData/XmlData') AS t(c) 


select * from #Reconcile

COMMIT TRANSACTION

END TRY
		BEGIN CATCH
				SELECT ERROR_MESSAGE()
				ROLLBACK 
		END CATCH


GO