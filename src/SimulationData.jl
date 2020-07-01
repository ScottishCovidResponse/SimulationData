module SimulationData

using DataDeps
using DataFrames
using Distributions
using HDF5
import Pkg

export
    FileAPI,
    StandardAPI,
    SimpleNetworkSimAPI,
    read_estimate,
    read_distribution,
    read_sample,
    read_array,
    read_table


include("units.jl")
include("pyapi.jl")

const DEFAULT = ""
const DATABLOCK_DEFAULTLOC = "https://www.gla.ac.uk/media" # TODO: Replace
const PARAMETERBLOCK_DEFAULTLOC = "https://www.gla.ac.uk/media" # TODO: Replace

#ENV["DATADEPS_LOAD_PATH"] = joinpath(first(Base.DEPOT_PATH), "datadeps", "SimulationData")

include("datatypes.jl")
include("./RegistrationBlocks/data.jl")
include("./RegistrationBlocks/parameters.jl")
include("datautils.jl")
include("register.jl")

function __init__()
    init(DataBlock)
    init(ParameterBlock)
    pycallinit()
end





end
