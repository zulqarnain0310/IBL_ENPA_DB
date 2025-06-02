CREATE TABLE [dbo].[SpBlock] (
  [EntityKey] [int] IDENTITY,
  [StartTime] [datetime] NOT NULL,
  [SPID] [smallint] NOT NULL,
  [Database] [nvarchar](128) NULL,
  [QueryName] [nvarchar](max) NULL,
  [Executing SQL] [nvarchar](max) NULL,
  [Status] [nvarchar](30) NOT NULL,
  [command] [nvarchar](32) NOT NULL,
  [wait_type] [nvarchar](60) NULL,
  [wait_time] [int] NOT NULL,
  [wait_resource] [nvarchar](256) NOT NULL,
  [last_wait_type] [nvarchar](60) NOT NULL,
  [program_name] [nvarchar](128) NULL,
  [login_name] [nvarchar](128) NULL,
  [host_name] [nvarchar](128) NULL,
  [SpName] [nvarchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO