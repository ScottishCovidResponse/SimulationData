using Pkg
ENV["PYTHON"] = ""
Pkg.build("PyCall")

using Conda

Conda.add("data_pipeline_api", channel="scottishcovidresponse")
Conda.add.(["scipy", "pyyaml", "setuptools-scm", "aiohttp"])
