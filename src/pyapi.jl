# Interface to the DataPipeLIne April
# Note that this reuquires that the running virtual env is the conda env for
# the datapipeline April

using Conda
using PyCall
using Pandas

function pycallinit()
    py"""
    import scipy
    from data_pipeline_api.standard_api import StandardAPI
    """
    api_version = Conda.version("data-pipeline-api")
    @info "Found data-pipeline-api v$api_version"
end

"""
    DataPipelineAPI

Wrapper around a `data_pipeline_api` python API
"""
abstract type DataPipelineAPI end

"""
    StandardAPI <: DataPipelineAPI

Wrapper around `data_pipeline_api.standard_api.StandardAPI`

Preferred use is:
```
StandardAPI(config_filename, uri, git_sha) do api
    df = read_table(api, ...)
    ...
end
```

The following also works, but needs an explicit `close` call to write out the access file:
```
api = StandardAPI(config_filename, uri, git_sha)
read_table(api, ...)
...
close(api) # writes out the access file
```
"""
struct StandardAPI <: DataPipelineAPI
    pyapi::PyObject
end

function StandardAPI(config_filename::AbstractString, uri, git_sha)
    isfile(config_filename) || throw(ArgumentError("File $config_filename not found"))
    return StandardAPI(py"StandardAPI($config_filename, $uri, $git_sha)")
end

"""
    StandardAPI(f::Function, config_filename, uri, git_sha)

Construct a `StandardAPI` using the config found in `config_filename`, and call `f` on it.
This will automatically take care of the API open/close methods.
The recommended way to use this is with a `do` block:
```
StandardAPI(config_filename, uri, git_sha) do api
    df = read_table(api, ...)
    ...
end
```

## Returns
- The value returned by `f`
"""
function StandardAPI(f::Function, config_filename, uri, git_sha)
    result = nothing
    # @pywith is from PyCall, it emulates a python "with" block.
    # We use this so that the appropriate __enter__ and __exit__ methods are called
    # automatically on the python API object.
    # Note that `StandardAPI` inside py"" refers to the class in the python library, while
    # `StandardAPI` inside the block refers to the `StandardAPI` Julia struct in this
    # module. (They are named the same for convenience)
    @pywith py"StandardAPI($config_filename, $uri, $git_sha)" as pyapi begin
        result = f(StandardAPI(pyapi))
    end
    return result
end

"""
    DataPipelineIssue

An issue associated with a data product or component.

## Fields
- `description`
- `severity`
"""
struct DataPipelineIssue
    description::AbstractString
    severity::AbstractString
end

function Base.close(api::DataPipelineAPI)
    py"$(api.pyapi).file_api.close()"
end

function read_estimate(api::DataPipelineAPI, data_product, component)
    d = py"$(api.pyapi).read_estimate($data_product, $component)"
    return d
end

function read_distribution(api::DataPipelineAPI, data_product, component)
    d = py"$(api.pyapi).read_distribution($data_product, $component)"o
    return _dist_py_to_jl(d)
end

function read_sample(api::DataPipelineAPI, data_product, component)
    d = py"$(api.pyapi).read_sample($data_product, $component)"
    return convert(Float64, d)
end

"""
    read_array(api::DataPipelineAPI, data_product, component)

Read an array using `api`.

## Returns
`NamedTuple{(:data, :dimensions, :units)}`
"""
function read_array(api::DataPipelineAPI, data_product, component)
    # The python API returns Array(data=data, dimensions=dimensions, units=units)
    # Disable automatic conversion with 'o' at the end
    d = py"$(api.pyapi).read_array($data_product, $component)"o
    # Convert to NamedTuple
    return (data=d.data, dimensions=d.dimensions, units=d.units)
end

function read_table(api::DataPipelineAPI, data_product, component)
    d = py"$(api.pyapi).read_table($data_product, $component)"
    return DataFrames.DataFrame(Pandas.DataFrame(d))
end

function _dist_py_to_jl(d)
    name = d.dist.name
    kwds = d.kwds
    if name == "gamma"
        return Gamma(kwds["a"], kwds["scale"])
    end
    if name == "norm"
        return Normal(kwds["loc"], kwds["scale"])
    end
    error("Unable to parse $d as a distribution")
end

function _dist_jl_to_py(d::Normal)
    return py"scipy.stats.norm(loc=$(d.μ), scale=$(d.σ))"
end

function _dist_jl_to_py(d::Gamma)
    return py"scipy.stats.gamma($(d.α), scale=$(d.θ))"
end

function write_estimate(
    api::DataPipelineAPI, data_product, component, estimate;
    description=nothing, issues::AbstractVector{DataPipelineIssue}=DataPipelineIssue[]
)
    if isempty(issues)
        issues = nothing
    end
    return py"$(api.pyapi).write_estimate(
        $data_product, $component, $estimate,
        description=$description, issues=$issues
    )"
end

function write_distribution(
    api::DataPipelineAPI, data_product, component, distribution::Distribution;
    description=nothing, issues::AbstractVector{DataPipelineIssue}=DataPipelineIssue[]
)
    if isempty(issues)
        issues = nothing
    end
    return py"$(api.pyapi).write_distribution(
        $data_product, $component, $(_dist_jl_to_py(distribution)),
        description=$description, issues=$issues
    )"
end

function write_samples(
    api::DataPipelineAPI, data_product, component, samples;
    description=nothing, issues::AbstractVector{DataPipelineIssue}=DataPipelineIssue[]
)
    if isempty(issues)
        issues = nothing
    end
    return py"$(api.pyapi).write_samples(
        $data_product, $component, $samples,
        description=$description, issues=$issues
    )"
end

function write_array(
    api::DataPipelineAPI,
    data_product,
    component,
    array::NamedTuple{(:data, :dimensions, :units)};
    description=nothing,
    issues::AbstractVector{DataPipelineIssue}=DataPipelineIssue[]
)
    if isempty(issues)
        issues = nothing
    end
    return py"$(api.pyapi).write_array(
        $data_product, $component, $array,
        description=$description, issues=$issues
    )"
end

function write_array(
    api::DataPipelineAPI, data_product, component, array;
    description=nothing, issues::AbstractVector{DataPipelineIssue}=DataPipelineIssue[]
)
    array = (data=array, dimensions=nothing, units=nothing)
    return write_array(
        api, data_product, component, array;
        description=description, issues=issues
    )
end

function write_table(
    api::DataPipelineAPI, data_product, component, table;
    description=nothing, issues::AbstractVector{DataPipelineIssue}=DataPipelineIssue[]
)
    if isempty(issues)
        issues = nothing
    end
    table = Pandas.DataFrame(table)
    return py"$(api.pyapi).write_table(
        $data_product, $component, $table,
        description=$description, issues=$issues
    )"
end
