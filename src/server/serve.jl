include("log.jl")
mutable struct Route
    path::String
    page::Any
    function Route(path::String = "", page::Any = "")
        new(path, page)
    end
end

mutable struct ServerTemplate
    ip::String
    port::Integer
    routes::AbstractVector
    logger::Logger
    remove::Function
    add::Function
    start::Function
    function ServerTemplate(ip::String, port::Int64, logger::Logger,
        routes::AbstractVector = [])
        add, remove, start = funcdefs(routes, ip, port, logger)
        new(ip, port, routes, logger, remove, add, start)
    end

    function ServerTemplate(logger = Logger())
        port = 8001
        ip = "127.0.0.1"
        ServerTemplate(ip, port, logger)
    end
end

function funcdefs(routes::AbstractVector, ip::String, port::Integer,
    logger::Logger)
    add(r::Route) = push!(routes, r)
    remove(i::Int64) = deleteat!(routes, i)
    start() = _start(routes, ip, port, logger)
    return(add, remove, start)
end

function _start(routes::AbstractVector, ip::String, port::Integer,
    logger::Logger)
    server = Sockets.listen(Sockets.InetAddr(parse(IPAddr, ip), port))
    logger.log(1, "Toolips Server starting on port " * string(port))
    routefunc = generate_router(routes, server, logger)
    @async HTTP.listen(routefunc, ip, port; server = server)
    logger.log(2, "Successfully started server on port " * string(port))
    logger.log(1,
    "You may visit it now at http://" * string(ip) * ":" * string(port))
    return(server)
end
function generate_router(routes::AbstractVector, server, logger::Logger)
    route_paths = Dict([route.path => route.page for route in routes])
    # CORE routing server lies here.
    # - Router itself is merely a function that gets called with the http
    #  stream. This trickles down the line all the way to the interface methods.
    routeserver = function serve(http)
    HTTP.setheader(http, "Content-Type" => "text/html")
    fullpath = http.message.target
    # Checks for argument data, because this is not in the route.
    if contains(http.message.target, '?')
         fullpath = split(http.message.target, '?')[1]
    end

     if fullpath in keys(route_paths)
         if typeof(route_paths[fullpath]) != Page
             write(http, route_paths[fullpath](http))
         else
             write(http, route_paths[fullpath].f(http))
         end
     else
         if typeof(route_paths["404"]) != Page
             write(http, route_paths["404"](http))
         else
            write(http, route_paths["404"].f(http))
        end
     end

 end # serve()
    return(routeserver)
end
function stop!(x::Any)
    close(x)
end
