baremodule NestedTasks

function set_scheduler end
function unset_scheduler end

module Internal

using ..NestedTasks: NestedTasks

using Preferences: @load_preference, @set_preferences!, @delete_preferences!

# TODO: non-Tapir shim?
using Base.Experimental: Tapir

include("schedulers.jl")

end  # module Internal

using .Internal: taskgroup
using Base.Experimental.Tapir: @spawn

# Workaround https://github.com/JuliaLang/julia/issues/42808
# using .Internal: @tapir_sync as @sync
const var"@sync" = Internal.var"@tapir_sync"

"""
    NestedTasks.Threads

A shim module to use `NestedTasks.@spawn` etc. for `Base.Threads.@spawn`.
"""
baremodule Threads
# module Threads
using ..NestedTasks: @spawn, @sync
using Base.Threads: nthreads

#=
function foreach(_args...; _kwargs...)
    error("not supported")
end

for n in names(Threads; all = true)
    n in [Symbol("@spawn"), Symbol("@sync"), Symbol("foreach")] && continue
    v = try
        getfield(Threads, n)
    catch
        continue
    end
    @eval const $n = $v
end
=#

end  # module Threads

end  # baremodule NestedTasks
