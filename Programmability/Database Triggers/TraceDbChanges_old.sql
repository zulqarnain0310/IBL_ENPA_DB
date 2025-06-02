SET QUOTED_IDENTIFIER, ANSI_NULLS ON
GO
CREATE trigger [TraceDbChanges_old]
on database
for  
create_procedure, alter_procedure, drop_procedure,
create_table, alter_table, drop_table,
create_function, alter_function, drop_function , 
create_trigger , alter_trigger , drop_trigger  ,
Create_Index,ALter_Index,Drop_Index,
Create_PARTITION_FUNCTION,ALTER_PARTITION_FUNCTION,Drop_PARTITION_FUNCTION,
Create_PARTITION_Scheme,ALTER_PARTITION_Scheme,Drop_PARTITION_Scheme,
CREATE_STATISTICS,DROP_STATISTICS,UPDATE_STATISTICS,
CREATE_SYNONYM,DROP_SYNONYM,
CREATE_USER ,Alter_USER ,Drop_USER

as

set nocount on

declare @data xml
set @data = EVENTDATA()
declare @DbVersion varchar(20)
set @DbVersion ='1.0.0'--(select ga.GetDbVersion())
declare @DbType varchar(50)
set @DbType ='Prod'--(select ga.GetDbType())
declare @DbName varchar(256)
set @DbName =@data.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'varchar(256)')
declare @LoginName varchar(256) 
set @LoginName = @data.value('(/EVENT_INSTANCE/LoginName)[1]', 'varchar(256)')
declare @EventType varchar(Max)
set @EventType =@data.value('(/EVENT_INSTANCE/EventType)[1]', 'varchar(50)')
declare @ObjectName varchar(256)
set @ObjectName  = @data.value('(/EVENT_INSTANCE/ObjectName)[1]', 'varchar(256)')
declare @ObjectType varchar(25)
set @ObjectType = @data.value('(/EVENT_INSTANCE/ObjectType)[1]', 'varchar(25)')
declare @TSQLCommand varchar(max)
set @TSQLCommand = @data.value('(/EVENT_INSTANCE/TSQLCommand)[1]', 'varchar(max)')
Declare @PostTime DateTime
set @PostTime = Convert(DateTime,@data.value('(/EVENT_INSTANCE/PostTime)[1]', 'varchar(50)'))
Declare @ServerName Varchar(50)
set @ServerName = @data.value('(/EVENT_INSTANCE/ServerName)[1]', 'varchar(50)')
Declare @SPID Varchar(10)
set @SPID = @data.value('(/EVENT_INSTANCE/SPID)[1]', 'varchar(50)')
Declare @HostName Varchar(100)
set @HostName = (Select HOSTName From sys.sysprocesses Where spid=@SPID And loginame=@LoginName)


declare @opentag varchar(4)
set @opentag= '&lt;'
declare @closetag varchar(4) 
set @closetag= '&gt;'
declare @newDataTxt varchar(max) 
set @newDataTxt= cast(@data as varchar(max))
set @newDataTxt = REPLACE ( REPLACE(@newDataTxt , @opentag , '<') , @closetag , '>')
-- print @newDataTxt
--declare @newDataXml xml 
--set @newDataXml = CONVERT ( xml , @newDataTxt)

--declare @Version varchar(50)
--set @Version = @newDataXml.value('(/EVENT_INSTANCE/TSQLCommand/CommandText/Version)[1]', 'varchar(50)')

-- if we are dropping take the version from the existing object 
--if  ( SUBSTRING(@EventType , 0 , 5)) = 'DROP'
--set @Version =Null--( select top 1 [Version]  from  DbObjChangeLog where ObjectName=@ObjectName order by [LogId] desc)
--if ( @Version is null)
--set @Version = '1.0.0'

--declare @Description varchar(max)
--set @Description = @newDataXml.value('(/EVENT_INSTANCE/TSQLCommand/CommandText/Description)[1]', 'varchar(max)')

--declare @ChangeDescription varchar(max)
--set @ChangeDescription = @newDataXml.value('(/EVENT_INSTANCE/TSQLCommand/CommandText/ChangeDescription)[1]', 'varchar(max)')


declare @UserName varchar(50)
set @UserName= Case When @LoginName Like '%App%' Then 'Badri'
					When @LoginName Like '%Rpt%' Then 'Vaibhav'
					When @LoginName Like '%SSIS%' Then 'Mala'
					Else Right(@LoginName,LEn(@LoginName)-PATINDEX('%[_]%',@LoginName)) End--(select NAme from sys.server_principals Where type='s'  And Name = @LoginName)
declare @SchemaName sysname 
set @SchemaName = @data.value('(/EVENT_INSTANCE/SchemaName)[1]', 'sysname');
--declare @Description xml 
--set @Description = @data.query('(/EVENT_INSTANCE/TSQLCommand/text())')




--print 'VERSION IS ' + @Version
--print @newDataTxt
--print cast(@data as varchar(max))


-- select column_name from information_schema.columns where table_name ='DbObjChangeLog'
insert into  [D2KMNTR].[DbObjChangeLog]
(
[DatabaseName] ,
[SchemaName],
--[DbVersion] ,
[DbType],
[EventType],
[ObjectName],
[ObjectType] ,
--[Version],
--[Description],
--[ChangeDescription],
[SqlCommand] ,
[LoginName] ,
--[UserName] ,
[HostName],
[TSql],
[PostTime],
[ServerName],
[SPID]
)

Values(

@DbName,
@SchemaName,
--@DbVersion,
@DbType,
@EventType, 
@ObjectName, 
@ObjectType , 
--@Version,
--@Description,
--@ChangeDescription,
@newDataTxt, 
@LoginName , 
--@UserName ,
@HostName,
@TSQLCommand,
@PostTime,
@ServerName,
@SPID
)









GO