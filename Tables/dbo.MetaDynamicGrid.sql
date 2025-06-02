CREATE TABLE [dbo].[MetaDynamicGrid] (
  [EntityKey] [int] NOT NULL,
  [ControlId] [int] NULL,
  [Label] [varchar](50) NULL,
  [EnableColumnMenu] [bit] NULL,
  [HeaderToolTip] [varchar](20) NULL,
  [EnableColumnResizing] [bit] NULL,
  [Width] [smallint] NULL,
  [CellTemplate] [varchar](100) NULL
)
ON [PRIMARY]
GO