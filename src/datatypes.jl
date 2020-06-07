abstract type DataDependency end

struct DataBlock <: DataDependency end

struct ParameterBlock <: DataDependency end
