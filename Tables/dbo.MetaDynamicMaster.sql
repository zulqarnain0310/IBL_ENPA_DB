CREATE TABLE [dbo].[MetaDynamicMaster] (
  [MasterColumnName] [varchar](50) NULL,
  [Condition] [varchar](200) NULL,
  [MasterTable] [varchar](50) NULL,
  [NameColumn] [varchar](50) NULL,
  [Entitykey] [smallint] IDENTITY,
  [ControlID] [int] NULL,
  [CodeColumn] [varchar](50) NULL,
  [DisplayColumnName] [varchar](50) NULL
)
ON [PRIMARY]
GO