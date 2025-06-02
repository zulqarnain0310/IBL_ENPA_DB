SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO


CREATE proc [dbo].[ECS_Duplicate] 
as
Begin

insert into Duplicate_Records(
Row_num,
AccountNumber,
Sourcename)
select * from (
select row_number()over(partition by [ACCOUNT NUMBER] order by [CLIENT ID (SOURCE SYSTEM)] )as row_num,[ACCOUNT NUMBER],SYSTEM from Induslnd_Stg.dbo.ECS_Stg)a
where row_num > 1
End

GO