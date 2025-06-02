SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
create proc [dbo].[CLASSIFICATIONISNULL]
 @Syatem varchar(20)

as
--Declare @Syatem varchar(20)='fINACLE'

begin
select * from  IndusIndDev.dbo.ETL_Validation_Details where  CLASSIFICATION is null and SYSTEM=@Syatem
union all
select * from  IndusIndDev.dbo.ETL_Validation_Details where  CLASSIFICATION='' and SYSTEM=@Syatem
end
GO