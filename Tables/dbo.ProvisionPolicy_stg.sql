CREATE TABLE [dbo].[ProvisionPolicy_stg] (
  [EntityKey] [int] IDENTITY,
  [SrNo] [varchar](max) NULL,
  [SourceSystem] [varchar](max) NULL,
  [SchemeCode] [varchar](max) NULL,
  [upto3months] [varchar](max) NULL,
  [3monthsupto6months] [varchar](max) NULL,
  [6monthsupto9months] [varchar](max) NULL,
  [9monthsupto12months] [varchar](max) NULL,
  [Doubtful1] [varchar](max) NULL,
  [Doubtful2] [varchar](max) NULL,
  [Doubtful3] [varchar](max) NULL,
  [Loss] [varchar](max) NULL,
  [filname] [varchar](max) NULL,
  [Action] [char](1) NULL,
  [Srnooferroneousrowsvarchar] [varchar](max) NULL,
  [Effectivedate] [varchar](max) NULL,
  [Segment] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO