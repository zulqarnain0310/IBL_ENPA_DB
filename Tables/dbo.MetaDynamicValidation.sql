CREATE TABLE [dbo].[MetaDynamicValidation] (
  [Entitykey] [smallint] IDENTITY,
  [ValidationGrpKey] [int] NULL,
  [ValidationKey] [int] NULL,
  [ControlID] [int] NULL,
  [CurrExpectedValue] [varchar](200) NULL,
  [CurrExpectedKey] [int] NULL,
  [ExpControlID] [varchar](300) NULL,
  [ExpKey] [int] NULL,
  [ExpControlValue] [varchar](200) NULL,
  [Operator] [varchar](100) NULL,
  [Message] [varchar](500) NULL
)
ON [PRIMARY]
GO