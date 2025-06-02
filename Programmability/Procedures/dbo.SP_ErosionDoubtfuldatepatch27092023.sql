SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[SP_ErosionDoubtfuldatepatch27092023] AS 
BEGIN

/* CHECK HOW MANY CASES HAS BEE CLOSED FROM CURRENT CLOSED ACCOUNT DETAILS*/
	select * INTO Closed_Account_Details_ErosionDoubtfuldatepatch27092023 from Closed_Account_Details where CustomerACID in (select CustomerACID from ErosionDoubtfuldatepatch27092023)--2540

/*TAKING BACKUP OF THE NCASES FROM CURRENT PRODUCTION TABLE BEFORE UPDATING RECORDS IN MAIN TABLE*/
	SELECT * INTO NPA_IntegrationDetails_ErosionDoubtfuldatepatch27092023 from NPA_IntegrationDetails with (nolock)
	where CustomerACID in (select CustomerACID from ErosionDoubtfuldatepatch27092023)
	and effectivefromtimekey<=26932 and EffectiveToTimeKey>=26932 and AC_AssetClassAlt_Key not in (1,6,7)
	--total 65410,TO BE UPDATING 63721 EXCLUDING SOURCE STD AND WRITEOFF,EXCLUDING SOURCE LOSS ,EXCLUDING SOURCE STD AND WRITEOFF 63679


/*UPDATING DATA IN MAIN TABLE AFTER TABLE BACK UP */

	--UPDATE  SET A.DBTDT=B.DBTDT,erosiondt=null,lossdt=null
	--FROM NPA_IntegrationDetails A INNER JOIN ErosionDoubtfuldatepatch27092023 N ON A.CustomerACID=B.CustomerACID
	--WHERE A.effectivefromtimekey<=26932 and A.EffectiveToTimeKey>=26932 and A.AC_AssetClassAlt_Key not in (1,6,7)


END
GO