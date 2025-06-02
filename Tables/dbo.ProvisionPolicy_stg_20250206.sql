CREATE TABLE [dbo].[ProvisionPolicy_stg_20250206] (
  [EntityKey] [int] IDENTITY,
  [SrNo] [varchar](max) NULL,
  [SourceSystem] [varchar](max) NULL,
  [SchemeCode] [varchar](max) NULL,
  [upto3months] [varchar](max) NULL,
  [From4monthsupto6months] [varchar](max) NULL,
  [From7monthsupto9months] [varchar](max) NULL,
  [From10monthsupto12months] [varchar](max) NULL,
  [Doubtful1] [varchar](max) NULL,
  [Doubtful2] [varchar](max) NULL,
  [Doubtful3] [varchar](max) NULL,
  [Loss] [varchar](max) NULL,
  [ProvisionUnSecured] [varchar](max) NULL,
  [filname] [varchar](max) NULL,
  [Action] [char](1) NULL,
  [Srnooferroneousrowsvarchar] [varchar](max) NULL
)
ON [PRIMARY]
TEXTIMAGE_ON [PRIMARY]
GO