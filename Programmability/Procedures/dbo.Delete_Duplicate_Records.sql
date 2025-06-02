SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE proc [dbo].[Delete_Duplicate_Records]
As
Begin

delete a from (
select row_number()over(partition by ACCOUNT_NUMBER order by CLIENT_ID )as row_num,ACCOUNT_NUMBER,SYSTEM from Induslnd_Stg.dbo.Finacle_Stg)a
where row_num > 1



------------Duplicate----Delete---ECS-------
Delete a from (
select row_number()over(partition by [ACCOUNT NUMBER] order by [CLIENT ID (SOURCE SYSTEM)] )as row_num,[ACCOUNT NUMBER],SYSTEM from Induslnd_Stg.dbo.ECS_Stg)a
where row_num > 1


------------Duplicate----Delete--Prolendz----
Delete a from (
select row_number()over(partition by Deal_No order by Customer_Code )as row_num,Deal_No,SYSTEM from Induslnd_Stg.dbo.Prolendz_Stg)a
where row_num > 1

--------------Duplicate---Delete----Ganseva----
delete a from (
select row_number()over(partition by [ACCOUNT NUMBER] order by [CLIENT ID (SOURCE SYSTEM)] )as row_num,[ACCOUNT NUMBER],SYSTEM from Induslnd_Stg.dbo.Ganseva_Stg)a
where row_num > 1

END
GO