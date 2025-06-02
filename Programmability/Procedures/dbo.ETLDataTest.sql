SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE procedure [dbo].[ETLDataTest]
 @MonthEndDate	VARCHAR(10)
,@TypeOfFreeze CHAR(1)='R'
,@UserID varchar(10)
,@TimeKey	INT=0
,@SourceAltKey INT=20
,@Result     SMALLINT=1 
as
begin
DECLARE @intFlag INT
SET @intFlag = (select COUNT(Status) from ETLTestProcess where Status=1)
WHILE (@intFlag <1)
BEGIN
    
   set @intFlag = (select COUNT(Status) from ETLTestProcess where Status=1)
    CONTINUE;
END
if @intFlag>=1
 begin
   return @intFlag
   end
end
GO