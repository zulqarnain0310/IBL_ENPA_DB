CREATE TABLE [dbo].[MetaScreenLableResource] (
  [Lable] [nvarchar](1000) NULL,
  [MenuID] [int] NULL,
  [ControlID] [int] NULL,
  [LanguageKey] [varchar](10) NULL,
  [EntityKey] [int] IDENTITY,
  [ControlName] [varchar](50) NULL
)
ON [PRIMARY]
GO