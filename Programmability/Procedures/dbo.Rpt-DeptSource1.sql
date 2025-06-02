SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE  proc [dbo].[Rpt-DeptSource1]
@UserId AS VARCHAR(25),
@DtEnter as varchar(20)
AS

--DECLARE 
--@UserId AS VARCHAR(25)='npachecker',
--@DtEnter as varchar(20)='31/03/2018'


DECLARE @DtEnter1 date ,@From1 date,@to1 date 


SET @DtEnter1=(SELECT Rdate FROM dbo.DateConvert(@DtEnter))
DECLARE @TimeKey as int=(select TimeKey from SysDayMatrix where date=@DtEnter1)

DECLARE @DeptGroupCode AS VARCHAR(10)

SET @UserId=(SELECT UserName FROM DimUserInfo WHERE UserName=@UserId AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
SET @DeptGroupCode=(SELECT DeptGroupCode FROM DimUserDeptGroup 
					WHERE DeptGroupId=(SELECT DeptGroupCode FROM DimUserInfo WHERE UserName=@UserId AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)
				    AND EffectiveFromTimeKey<=@TimeKey AND EffectiveToTimeKey>=@TimeKey)



IF(@DeptGroupCode IN ('FRR','SDG'))
BEGIN
SELECT '<ALL>' AS LABEL,0 AS VALUE
UNION ALL
SELECT 'Finacle' AS LABEL,10 AS VALUE
UNION ALL
SELECT 'ECS' AS LABEL,20 AS VALUE
UNION ALL
SELECT 'Prolendz' AS LABEL,60 AS VALUE
UNION ALL
SELECT 'Ganaseva' AS LABEL,70 AS VALUE

END


IF(@DeptGroupCode='CAD')
BEGIN
SELECT 'Finacle' AS LABEL,10 AS VALUE
END



IF(@DeptGroupCode='CFD')
BEGIN
SELECT 'Prolendz' AS LABEL,60 AS VALUE

END


IF(@DeptGroupCode='ECS')
BEGIN
SELECT 'ECS' AS LABEL,20 AS VALUE
END

IF(@DeptGroupCode='Prolendz')
BEGIN
SELECT 'Prolendz' AS LABEL,60 AS VALUE
END


IF(@DeptGroupCode='Ganaseva')
BEGIN
SELECT 'Ganaseva' AS LABEL,70 AS VALUE
END

GO