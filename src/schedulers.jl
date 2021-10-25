baremodule Scheduler

using Base: @enum

@enum Choice begin
    # Use native task scheduler:
    default
    # Defined in TapirSchedulers:
    workstealing
    depthfirst
    constantpriority
    randompriority
end

function from end
function validate end

end  # baremodule Scheduler

Scheduler.from(name::AbstractString) = Scheduler.from(Symbol(name))
function Scheduler.from(name::Symbol)
    choice = try
        getfield(Scheduler, name)
    catch
        nothing
    end
    if choice isa Scheduler.Choice
        return choice
    else
        return nothing
    end
end

function Scheduler.validate(name::Union{Symbol,AbstractString}; warn = false)
    choice = Scheduler.from(name)
    if choice === nothing
        msg = string(
            "Invalid scheduler name: `$name`. Expected one of: ",
            join(instances(Scheduler.Choice), ", ", ", and "),
            ".",
        )
        if warn
            @warn "$msg"
            return Scheduler.default
        else
            error(msg)
        end
    end
    return choice
end

function NestedTasks.set_scheduler(name::Symbol)
    scheduler = string(Scheduler.validate(name))
    @set_preferences!("scheduler" => scheduler)
    @info "Scheduler is set to $name; please restart your Julia session"
end

function NestedTasks.unset_scheduler()
    @delete_preferences!("scheduler")
    @info "Scheduler is set to default; please restart your Julia session"
end

const SCHEDULER_CONFIG =
    Scheduler.validate(@load_preference("scheduler", "default"); warn = true)
# Note: Just warn, so that the package is still loadable (for recovery)

if SCHEDULER_CONFIG == Scheduler.default
    const var"@tapir_sync" = Tapir.var"@sync"
    const taskgroup = Tapir.taskgroup
else
    import TapirSchedulers
    if SCHEDULER_CONFIG == Scheduler.workstealing
        const var"@tapir_sync" = TapirSchedulers.var"@sync_ws"
        const taskgroup = TapirSchedulers.WorkStealingTaskGroup
    elseif SCHEDULER_CONFIG == Scheduler.depthfirst
        const var"@tapir_sync" = TapirSchedulers.var"@sync_df"
        const taskgroup = TapirSchedulers.DepthFirstTaskGroup
    elseif SCHEDULER_CONFIG == Scheduler.constantpriority
        const var"@tapir_sync" = TapirSchedulers.var"@sync_cp"
        const taskgroup = TapirSchedulers.ConstantPriorityTaskGroup
    elseif SCHEDULER_CONFIG == Scheduler.randompriority
        const var"@tapir_sync" = TapirSchedulers.var"@sync_rp"
        const taskgroup = TapirSchedulers.RandomPriorityTaskGroup
    else
        @error "unknown scheduler: $SCHEDULER_CONFIG"
        macro tapir_sync(_ignored...)
            :(error("unknown scheduler: $SCHEDULER_CONFIG"))
        end
        const taskgroup = nothing
    end
end
