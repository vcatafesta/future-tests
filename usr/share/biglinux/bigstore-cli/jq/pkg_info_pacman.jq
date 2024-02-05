del(.end) |
      .Groups |= if . == [""] then null else . end |
      .Provides |= if . == [""] then null else . end |
      .["Depends On"] |= if . == [""] then null else . end |
      .["Optional Deps"] |= if . == [""] then null else . end |
      .["Required By"] |= if . == [""] then null else . end |
      .["Optional For"] |= if . == [""] then null else . end |
      .["Conflicts With"] |= if . == [""] then null else . end |
      .Replaces |= if . == [""] then null else . end
