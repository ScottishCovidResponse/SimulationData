"""
    env_bool(key)

Checks for an enviroment variable and fuzzy converts it to a bool
"""
env_bool(key, default=false) = haskey(ENV, key) ? lowercase(ENV[key]) ∉ ["0","","false", "no"] : default


if !env_bool("TRAVIS_CI_BUILD")
    println("Downloading temporary data")
    run(`git clone --depth 1 https://github.com/ScottishCovidResponse/temporary_data`)
end
