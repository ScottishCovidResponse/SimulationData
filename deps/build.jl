using Pkg
ENV["PYTHON"] = ""
Pkg.build("PyCall")

using Conda

Conda.add("pip")

pip = joinpath(Conda.BINDIR, "pip")
run(`$pip install scipy pyyaml setuptools-scm aiohttp`)
run(`$pip install git+https://github.com/ScottishCovidResponse/data_pipeline_api@0.7.0`)
