SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO




CREATE FUNCTION [dbo].[DateConvert](@String varchar(max))
RETURNS @Results TABLE (RDATE Date)
AS
BEGIN
DECLARE @Date varchar(20)=@String,@MM varchar(2),@DD varchar(2),@YY varchar(4),
@RDate Date

SET @DD=LEFT(@Date,2)
SET @MM=right(LEFT(@Date,5),2)
SET @YY=right(@Date,4)
SET @RDate= CAST((@YY+'-'+ @MM+'-'+@DD) AS DATE)

INSERT INTO @Results(RDATE) VALUES(@RDate)

RETURN
END

GO