# Interface to the DataPipeLIne April
# Note that this reuquires that the running virtual env is the conda env for
# the datapipeline April

using PyCall
using Pandas

# Took this from the example file. Unclear what this should be, or should be an argument
const DEFAULT_CONFIG = "../data_pipeline_api/examples/test_data_2/config.yaml"

function pycallinit()
    py"""
    import pandas as pd
    from pathlib import Path
    from data_pipeline_api.simple_network_sim_api import SimpleNetworkSimAPI
    from data_pipeline_api.standard_api import StandardAPI
    print(SimpleNetworkSimAPI)

    def read_estimate(api, data, component):
        print("[PYTHON]: Reading estimate")
        return api.read_estimate(data, component)

    def read_distribution(api, data, component):
        print("[PYTHON]: Reading distribution")
        return api.read_distribution(data)

    def read_array(api, data, component):
        print("[PYTHON]: Reading array")
        return api.read_array(data)

    def read_table(api, data, component):
        print("[PYTHON]: Reading table")
        return api.read_table(data)
    """
end

abstract type FileAPI end

struct StandardAPI <: FileAPI
    pyapi
end

struct SimpleNetworkSimAPI <: FileAPI
    pyapi
end

function StandardAPI(f::Function, config_filename)
    @pywith py"StandardAPI($config_filename)" as pyapi begin
        f(StandardAPI(pyapi))
    end
end

function SimpleNetworkSimAPI(f::Function, config_filename)
    @pywith py"SimpleNetworkSimAPI($config_filename)" as pyapi begin
        f(SimpleNetworkSimAPI(pyapi))
    end
end

function read_estimate(api::FileAPI, data_product, component)
    d = py"read_estimate($(api.pyapi), $data_product, $component)"
    return d
end

function read_distribution(api::FileAPI, data_product, component)
    d = py"read_distribution($(api.pyapi), $data_product, $component)"
    return d
end

function read_array(api::FileAPI, data_product, component)
    d = py"read_array($(api.pyapi), $data_product, $component)"
    return d
end

function read_table(api::FileAPI, data_product, component)
    d = py"read_table($(api.pyapi), $data_product, $component)"
    return DataFrames.DataFrame(Pandas.DataFrame(d))
end
