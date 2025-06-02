CREATE TABLE [dbo].[MetaDynamicCallAuxSP] (
  [Entitykey] [smallint] IDENTITY,
  [MenuId] [int] NULL,
  [ControlID] [int] NULL,
  [SPName] [varchar](200) NULL,
  [ClientSideParams] [varchar](1000) NULL,
  [ServerSideParams] [varchar](1000) NULL
)
ON [PRIMARY]
GO