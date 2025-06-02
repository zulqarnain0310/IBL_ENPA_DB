CREATE TABLE [dbo].[DimDepttoBacid] (
  [EntityKey] [int] IDENTITY,
  [BACID] [varchar](max) NULL,
  [DepartmentAlt_Key] [int] NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO