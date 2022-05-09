module Toolips
#==
Toolips.jl, a module created for light-weight interaction with Javascript via
bursts of HTML and Javascript working in tandem. There might be entirely new
intentions for this design, and dramatic changes. There are numerous features
coming to spruce up this code base to better facilitate things like
authentication.
~ TODO LIST ~ If you want to help out, you can try implementing the following:
=========================
- TODO Incoming user information would be nice.
- TODO Authentication. (UUID's would be nice)
- TODO improve default project files a tad.
- TODO Load environment in default files
- TODO Setup the Pkg environment with the given loaded files
- TODO Finish Servable 4.0 rework
- TODO Load directories using extensions.
==#
using Crayons
using Sockets, HTTP, Pkg
include("interface/Servables.jl")
# Core Server
export ServerTemplate, Logger, Files, stop!
# Function returns
export html, css, js, fn
# Servables
export File, Component, Container
export Input, TextArea, Button, P, Option, RadioInput, SliderInput
export Form, Link, MetaData, Header, Div, Animation, Style
# High-level api
export route, routes, route!, get_text, write!
# Methods
export getargs, getarg, getpost, write_file, lists

function create_serverdeps(name::String)
    Pkg.generate(name)
    Pkg.activate(name)
    #  Uncomment after 0.0.9 push:
    # Pkg.add("Toolips")
    dir = pwd() * "/"
    src = dir * name * "/src"
    logs = dir * name * "/logs"
    mkdir(logs)
    touch(name * "/dev.jl")
    touch(name * "/prod.jl")
    touch(logs * "/log.txt")
    rm(src * "/$name.jl")
    touch(src * "/$name.jl")
    open(src * "/$name.jl", "w") do io
        write(io, """
function main(routes::Vector{Route})
    server = ServerTemplate(IP, PORT, routes, extensions = [logger])
    TLSERVER = server.start()
    return(TLSERVER)
end
\n
                   #      vvv ?(Connection)
hello_world = route("/") do c
    write!(c, P("hello", text = "hello world!"))
end

fourofour = route("404", P("404", text = "404, not found!"))
rs = routes(hello_world, fourofour)
main(rs)
        """)
    end

end
function new_app(name::String = "ToolipsApp")
    create_serverdeps(name)
    open(name * "/dev.jl", "w") do io
        write(io, """
        using Toolips
        IP = "127.0.0.1"
        PORT = 8000
        logger = Logger()
        include("src/$name.jl")
        """)
    end
    open(name * "/prod.jl", "w") do io
        write(io, """
        using Toolips
        IP = "127.0.0.1"
        PORT = 8000
        logger = Logger()
        include("src/$name.jl")
        """)
    end
end

function new_webapp(name::String = "ToolipsApp")
    create_serverdeps(name)
    open(name * "/dev.jl", "w") do io
        write(io, """
        using Toolips
        IP = "127.0.0.1"
        PORT = 8000
        extensions = [Logger(), Files("public")]
        include("src/$name.jl")
        """)
    end
    open(name * "/prod.jl", "w") do io
        write(io, """
        using Toolips
        IP = "127.0.0.1"
        PORT = 8000
        extensions = [Logger(), Files("public")]
        include("src/$name.jl")
        """)
    end
    public = pwd() * "/$name/public"
    mkdir(public)
end
export new_webapp
# --

end
