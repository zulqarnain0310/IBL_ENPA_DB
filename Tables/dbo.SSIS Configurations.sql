CREATE TABLE [dbo].[SSIS Configurations] (
  [ConfigurationFilter] [nvarchar](255) NOT NULL,
  [ConfiguredValue] [nvarchar](255) NULL,
  [PackagePath] [nvarchar](255) NOT NULL,
  [ConfiguredValueType] [nvarchar](20) NOT NULL
)
ON [PRIMARY]
GO