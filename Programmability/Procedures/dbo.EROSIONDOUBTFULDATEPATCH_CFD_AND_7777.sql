SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[EROSIONDOUBTFULDATEPATCH_CFD_AND_7777]
AS
BEGIN
select * from cfd_and_7777--17060

SELECT * FROM NPA_IntegrationDetails A INNER JOIN cfd_and_7777 B 
	ON A.NCIF_Id=B.NCIF_ID

	SELECT * FROM 
	cfd_and_7777 WHERE Ncif_id IN ('22862866','32772784')

	--DELETE FROM 
	--cfd_and_7777 WHERE Ncif_id IN ('22862866','32772784') --deleted WRITE OFF CASE   32772784 , WRITE OFF 22862866



/*Querry to be fired while updating dbtdt*/


			;WITH CTE AS(
		SELECT A.NCIF_ID,MIN(A.AC_NPA_Date) NCIF_NPA_DATE FROM NPA_IntegrationDetails A WITH (NOLOCK) INNER JOIN [dbo].[CFD_AND_7777] B 
			ON A.NCIF_Id=B.NCIF_ID
			and A.EffectiveFromTimeKey=26935
			GROUP BY A.NCIF_ID
		),CTE_2
			AS
				(select NCIF_ID,NCIF_NPA_Date, IBL_ENPA_DB_LOCAL_DEV.[dbo].[GetLeapYearDate] ((NCIF_NPA_Date),1) DBT_DATE
			,DATEDIFF(DD,NCIF_NPA_Date,(IBL_ENPA_DB_LOCAL_DEV.[dbo].[GetLeapYearDate] ((NCIF_NPA_Date),1))) DIFF_DAYS
			FROM CTE
		)
	--	SELECT * from CTE_2 
	--ORDER BY DIFF_DAYS DESC
	 UPDATE A
		SET A.DbtDT=DBT_DATE
	 FROM NPA_IntegrationDetails A
		INNER JOIN CTE_2 B
			ON A.NCIF_Id=B.NCIF_Id
			where EffectiveFromTimeKey=26935


/* lossdt two cases update*/
			
				 UPDATE A
		SET LossDT=NULL,ErosionDT=NULL,FlgErosion=NULL
	 FROM NPA_IntegrationDetails A
		WHERE
		A.NCIF_Id in ('17232369','54068082')
			AND  EffectiveFromTimeKey=26935


END
GO