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

    def read_estimate(data, component):
        print("[PYTHON]: Reading estimate")
        with StandardAPI(
             $DEFAULT_CONFIG,
        ) as api:
            d = api.read_estimate(data, component)

        return d

    def read_distribution(data, component):
        print("[PYTHON]: Reading distribution")
        with SimpleNetworkSimAPI(
             $DEFAULT_CONFIG,
        ) as api:
            d = api.read_distribution(data)

        return d

    def read_array(data, component):
        print("[PYTHON]: Reading array")
        with SimpleNetworkSimAPI(
             $DEFAULT_CONFIG,
        ) as api:
            d = api.read_array(data)

        return d

    def read_table(data, component):
        print("[PYTHON]: Reading table")
        with SimpleNetworkSimAPI(
             $DEFAULT_CONFIG,
        ) as api:
            d = api.read_table(data)

        return d
    """

end


function read_estimate(data_product, component)
    d = py"read_estimate($data_product, $component)"
    return d
end

function read_distribution(data_product, component)
    d = py"read_distribution($data_product, $component)"
    return d
end

function read_array(data_product, component)
    d = py"read_array($data_product, $component)"
    return d
end

function read_table(data_product, component)
    d = py"read_table($data_product, $component)"
    return DataFrames.DataFrame(Pandas.DataFrame(d))
end
