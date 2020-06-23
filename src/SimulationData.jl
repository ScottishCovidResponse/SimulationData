module SimulationData

using DataDeps
using HDF5
import Pkg

include("units.jl")

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
end





end
