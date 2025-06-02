CREATE TABLE [dbo].[MetaDynamicMasterFilter] (
  [MasterFilterKey] [smallint] NULL,
  [FilterMasterControlName] [varchar](50) NULL,
  [ExpectedValue] [varchar](50) NULL,
  [FilterByColumnName] [varchar](50) NULL,
  [MenuID] [smallint] NULL,
  [FilterByRemoveValue] [varchar](100) NULL,
  [EntityKey] [smallint] IDENTITY,
  [ControlID] [int] NULL,
  [RefColumnName] [varchar](50) NULL,
  [FilterBySelectValue] [varchar](1000) NULL,
  [MasterFilterGrpKey] [smallint] NULL
)
ON [PRIMARY]
GO