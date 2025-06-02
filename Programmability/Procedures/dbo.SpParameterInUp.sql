SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
/* CREATED BY DF627 on 23-05-24 FOR STORING THE INPUT PARAMETER OF STORED PROCEDURES */

CREATE PROC [dbo].[SpParameterInUp]
AS
BEGIN
    INSERT INTO DBO.SpParameterDtls
    SELECT  
       @@SERVERNAME AS Server_Name,
       DB_NAME() AS Database_Name, -- You can use DB_NAME() if you want the current database name
	   p.object_id,
	   p.schema_id,
       s.name + '.' + p.name AS Stored_Procedure_Name,
       p.create_date AS Sp_Created_Date,
       p.modify_date AS Sp_Modified_Date,
       pa.name AS Parameter_name,
       TYPE_NAME(pa.user_type_id) AS Type,
       pa.max_length AS Length,
       CASE 
           WHEN TYPE_NAME(pa.system_type_id) = 'uniqueidentifier' THEN pa.precision
           ELSE OdbcPrec(pa.system_type_id, pa.max_length, pa.precision)
       END AS Prec,
       OdbcScale(pa.system_type_id, pa.scale) AS Scale,
       pa.parameter_id AS Param_order,
       CONVERT(sysname, 
               CASE 
                   WHEN pa.system_type_id IN (35, 99, 167, 175, 231, 239)  
                   THEN ServerProperty('collation')
               END) AS Collation,
       GETDATE() AS ProcessDate
    FROM sys.parameters AS pa
    INNER JOIN sys.procedures AS p ON pa.object_id = p.object_id
    INNER JOIN sys.schemas AS s ON s.schema_id = p.schema_id;
END
GO