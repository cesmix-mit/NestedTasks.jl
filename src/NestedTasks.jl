baremodule NestedTasks

module Internal

using ..NestedTasks: NestedTasks

include("internal.jl")

end  # module Internal

end  # baremodule NestedTasks
