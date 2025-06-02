SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO

CREATE Proc [dbo].[Main_DimProduct_Updation]
As

Begin

Exec Dimproduct_Finacle_Insert
print 1
Exec Dimproduct_ECS_Insert
print 2
Exec Dimproduct_Prolendz_Insert
print 3
Exec Dimproduct_Ganseva_Insert
print 4
end 
GO