# Interface to the DataPipeLIne April
# Note that this reuquires that the running virtual env is the conda env for
# the datapipeline April

using PyCall
using Pandas

function pycallinit()
    py"""
    import pandas as pd
    import scipy.stats
    from pathlib import Path
    from data_pipeline_api.simple_network_sim_api import SimpleNetworkSimAPI
    from data_pipeline_api.standard_api import StandardAPI
    print(SimpleNetworkSimAPI)

    def read_estimate(api, data, component):
        print("[PYTHON]: Reading estimate")
        return api.read_estimate(data, component)

    def read_distribution(api, data, component):
        print("[PYTHON]: Reading distribution")
        return api.read_distribution(data, component)

    def read_sample(api, data, component):
        print("[PYTHON]: Reading sample")
        return api.read_sample(data, component)

    def read_array(api, data, component):
        print("[PYTHON]: Reading array")
        return api.read_array(data, component)

    def read_table(api, data, component):
        print("[PYTHON]: Reading table")
        return api.read_table(data, component)
    """
end

"""
    FileAPI

Wrapper around a `data_pipeline_api` python API
"""
abstract type FileAPI end

"""
    StandardAPI <: FileAPI

Wrapper around `data_pipeline_api.standard_api.StandardAPI`

Preferred use is:
```
StandardAPI(config_filename) do api
    df = read_table(api, ...)
    ...
end
```
"""
struct StandardAPI <: FileAPI
    pyapi::PyObject
end

"""
    SimpleNetworkSimAPI <: FileAPI

Wrapper around `data_pipeline_api.simple_network_sim_api.SimpleNetworkSimAPI`

Preferred use is:
```
SimpleNetworkSimAPI(config_filename) do api
    df = read_table(api, ...)
    ...
end
```
"""
struct SimpleNetworkSimAPI <: FileAPI
    pyapi::PyObject
end

"""
    StandardAPI(f::Function, config_filename)

Construct a `StandardAPI` using the config found in `config_filename`, and call `f` on it.
This will automatically take care of the API open/close methods.
The recommended way to use this is with a `do` block:
```
StandardAPI(config_filename) do api
    df = read_table(api, ...)
    ...
end
```

## Returns
- The value returned by `f`
"""
function StandardAPI(f::Function, config_filename)
    result = nothing
    # @pywith is from PyCall, it emulates a python "with" block.
    # We use this so that the appropriate __enter__ and __exit__ methods are called
    # automatically on the python API object.
    # Note that `StandardAPI` inside py"" refers to the class in the python library, while
    # `StandardAPI` inside the block refers to the `StandardAPI` Julia struct in this
    # module. (They are named the same for convenience)
    @pywith py"StandardAPI($config_filename)" as pyapi begin
        result = f(StandardAPI(pyapi))
    end
    return result
end

function SimpleNetworkSimAPI(f::Function, config_filename)
    result = nothing
    @pywith py"SimpleNetworkSimAPI($config_filename)" as pyapi begin
        result = f(SimpleNetworkSimAPI(pyapi))
    end
    return result
end

function read_estimate(api::FileAPI, data_product, component)
    d = py"read_estimate($(api.pyapi), $data_product, $component)"
    return d
end

function read_distribution(api::FileAPI, data_product, component)
    d = py"read_distribution($(api.pyapi), $data_product, $component)"
    return _parse_dist(d)
end

function read_sample(api::FileAPI, data_product, component)
    d = py"read_sample($(api.pyapi), $data_product, $component)"
    return convert(Float64, d)
end

function read_array(api::FileAPI, data_product, component)
    d = py"read_array($(api.pyapi), $data_product, $component)"
    return d
end

function read_table(api::FileAPI, data_product, component)
    d = py"read_table($(api.pyapi), $data_product, $component)"
    return DataFrames.DataFrame(Pandas.DataFrame(d))
end

function _parse_dist(d)
    if d.dist.name == "gamma"
        # Get mean and variance
        mv = py"$d.stats(moments='mv')"
        mean = mv[1][1]
        var = mv[2][1]
        # α = shape
        # θ = scale
        # mean = αθ
        # var = αθ^2
        θ = var / mean
        α = mean / θ
        return Gamma(α, θ)
    end
    error("Unable to parse $d as a distribution")
end
