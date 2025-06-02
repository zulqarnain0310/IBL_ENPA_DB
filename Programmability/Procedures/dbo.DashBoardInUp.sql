SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE PROC [dbo].[DashBoardInUp]

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
         c.value('./ENCIF[1]','varchar(20)')ENCIF
        ,c.value('./PAN[1]','varchar(20)')PAN
        ,c.value('./ClientID[1]','varchar(20)')ClientID
		,c.value('./UserId[1]','varchar(20)')UserId
        ,CASE WHEN c.value('./Done[1]','varchar(6)')='true' THEN 'Y' ELSE 'N' END  Done
       INTO #Reconcile
       FROM @xmlDocument.nodes('/DataSet/GridData/XmlData') AS t(c) 

--IF OBJECT_ID('TEMPDB..#NCIF_Reconcile')IS NOT NULL
--DROP TABLE #NCIF_Reconcile



IF @ReconcileFlag='N'
	BEGIN
	PRINT 'SAB'
	  --   SELECT
   --       c.value('./ENCIF[1]','varchar(20)')ENCIF
   --      ,c.value('./PAN[1]','varchar(20)')PAN
   --      ,c.value('./ClientID[1]','varchar(20)')ClientID
		 --,c.value('./UserId[1]','varchar(20)')UserId
   --      ,CASE WHEN c.value('./Done[1]','varchar(6)')='true' THEN 'Y' ELSE 'N' END  Done
   --     INTO #NCIF_Reconcile
   --     FROM @xmlDocument.nodes('/DataSet/GridData/XmlData') AS t(c) 

			UPDATE A
			SET A.Reconciled=B.Done
				,A.ModifiedBy=@CrModBy
				,A.DateModified=CAST(GETDATE() AS DATE)
			FROM NCIF_MismatchDetails  A
			INNER JOIN #Reconcile B  ON (A.TimeKey=@TimeKey)
											  AND A.NCIF=B.ENCIF
											  AND A.PAN=B.PAN
											  AND A.CustomerID=B.ClientID
			SET @Result=1
												
	END

--IF OBJECT_ID('TEMPDB..#PanReconcile')IS NOT NULL
--DROP TABLE #PanReconcile

ELSE IF @ReconcileFlag='P'
		BEGIN
							
			--SELECT
			--  c.value('./ENCIF[1]','varchar(20)')ENCIF
			-- ,c.value('./PAN[1]','varchar(20)')PAN
			-- ,c.value('./ClientID[1]','varchar(20)')ClientID
			-- ,c.value('./FirstName[1]','varchar(50)')FirstName
			-- ,c.value('./MiddleName[1]','varchar(50)')MiddleName
			-- ,c.value('./LastName[1]','varchar(50)')Lastname
			-- ,c.value('./UserId[1]','varchar(20)')UserId
			-- ,CASE WHEN c.value('./Done[1]','varchar(6)')='true' THEN 'Y' ELSE 'N' END  Done
			--INTO #PanReconcile
			--FROM @xmlDocument.nodes('/DataSet/GridData/XmlData') AS t(c) 

			UPDATE A
			SET A.Reconciled=B.Done
				--,A.NSDL_FirstName=B.FirstName
				--,A.NSDL_MiddleName=B.MiddleName
				--,A.NSDL_LastName=B.Lastname
				,A.ModifiedBy=@CrModBy
				,A.DateModified=CAST(GETDATE() AS DATE)
			FROM PAN_MismatchDetails  A
			INNER JOIN #Reconcile B  ON (A.TimeKey=@TimeKey)
											  AND A.NCIF=B.ENCIF
											  AND A.PAN=B.PAN
											  AND A.CustomerID=B.ClientID

			SET @Result=1
												

		END

--IF OBJECT_ID('TEMPDB..#ClientReconcile')IS NOT NULL
--DROP TABLE #ClientReconcile

ELSE IF @ReconcileFlag='C'
	 BEGIN
	 
			-- SELECT
			--  c.value('./ENCIF[1]','varchar(20)')ENCIF
			-- ,c.value('./PAN[1]','varchar(20)')PAN
			-- ,c.value('./ClientID[1]','varchar(20)')ClientID
			-- ,c.value('./UserId[1]','varchar(20)')UserId
			-- ,CASE WHEN c.value('./Done[1]','varchar(6)')='true' THEN 'Y' ELSE 'N' END  Done
			--INTO #ClientReconcile
			--FROM @xmlDocument.nodes('/DataSet/GridData/XmlData') AS t(c) 

			UPDATE A
			SET  A.Reconciled=B.Done
				,A.ModifiedBy=@CrModBy
				,A.DateModified=CAST(GETDATE() AS DATE)
			FROM ClientID_NCIF_MismatchDetails  A
			INNER JOIN #Reconcile B  ON (A.TimeKey=@TimeKey)
											  AND A.NCIF=B.ENCIF
											  AND A.CustomerID=B.ClientID
											  AND A.PAN=B.PAN

			SET @Result=1
												
	 END			

COMMIT TRANSACTION

END TRY
		BEGIN CATCH
				SELECT ERROR_MESSAGE()
				ROLLBACK 
		END CATCH

GO