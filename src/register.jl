function init(T::Type{ParameterBlock})

    for (name, v, loc, fname, desc, hash) in dependencies(T)
        loc = loc == DEFAULT ? PARAMETERBLOCK_DEFAULTLOC : loc
        register(
            DataDep(
                "ParameterBlock-$name-v$v",
                """
                Parameterblock name $name.
                $desc
                """,
                "$loc/$fname.toml", # Enforce standard around name encoding
                hash,
                fetch_method=DataDeps.fetch_http,
           )
       )
    end
end

function init(T::Type{DataBlock})

    for (name, v, loc, fname, desc, hash) in dependencies(T)
        loc = loc == DEFAULT ? DATABLOCK_DEFAULTLOC : loc
        register(
            DataDep(
                "DataBlock-$name-v$v",
                """
                Datablock name $name.
                $desc
                """,
                "$loc/$fname.h5", # Enforce standard around name encoding
                hash,
                fetch_method=DataDeps.fetch_http,
           )
       )
    end
end
