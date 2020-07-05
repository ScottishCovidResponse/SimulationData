using Conda

"""
    env_bool(key)

Checks for an enviroment variable and fuzzy converts it to a bool
"""
env_bool(key, default=false) = haskey(ENV, key) ? lowercase(ENV[key]) ∉ ["0","","false", "no"] : default

# Clone the Python DATA API package
if !isdir("data_pipeline_api")
    @info "Downloading data_pipeline_api"
    #run(`git clone https://github.com/ScottishCovidResponse/data_pipeline_api`)
    pip = joinpath(Conda.BINDIR, "pip")
    run(`$pip install pyyaml`)
    run(`$pip install git+https://github.com/ScottishCovidResponse/data_pipeline_api`)
else
    @info "data_pipeline_api already found."
end
