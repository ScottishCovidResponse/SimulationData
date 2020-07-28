using Pkg
ENV["PYTHON"] = ""
Pkg.build("PyCall")

using Conda

pip = joinpath(Conda.BINDIR, "pip")
run(`$pip install pyyaml setuptools-scm`)
run(`$pip install git+https://github.com/ScottishCovidResponse/data_pipeline_api#master`)
