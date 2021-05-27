function init_loreco_model_sumsy(;
                        guaranteed_income::Real = 2000,
                        dem_free::Real = 25000,
                        dem::Real = 0.1,
                        interval::Integer = 30,
                        seed::Real = 5000,
                        consumers::Integer = 380,
                        bakers::Integer = 15,
                        tv_merchants::Integer = 5)
    # Create a standard Econo model.
    model = create_econo_model()

    sumsy::SuMSy = SuMSy(guaranteed_income, dem_free, dem, interval, seed = seed)
    # Add a sumsy property to the model to be used during simulation.
    model.properties[:sumsy] = sumsy

    # Add actors.
    add_consumers(model, consumers)
    add_bakers(model, bakers)
    add_tv_merchants(model, tv_merchants)
    add_governance(model, consumers + bakers + tv_merchants)

    return model
end


balance(a::Actor) = sumsy_balance(a.balance)
##alternative use  has_type(actor::Actor, type::Symbol) in actor.jl
consumer(a::Actor)::Bool = in(:consumer, getproperty(a, :types)) ? true : false
baker(a::Actor)::Bool = in(:baker, getproperty(a, :types)) ? true : false
tvmerchant(a::Actor)::Bool = in(:tv_merchant, getproperty(a, :types)) ? true : false
governance(a::Actor)::Bool = in(:governance, getproperty(a, :types)) ? true : false


function miss5thPercentile(values) return isempty(skipmissing(values)) ? NaN : quantile(skipmissing(values), 0.05) end
function miss95thPercentile(values) return isempty(skipmissing(values)) ? NaN : quantile(skipmissing(values), 0.95) end

function isDemurTransaction(comment::String, time::Integer)::Bool

    if startswith(comment, "Demurrage") & isequal(time, 31)
        print(time)
        return true
    else return false
    end
end

function sumsy_demurrage(balance)::Float64

    demurrages = filter(tuple-> let (time, type, entry, amount, comment)=tuple; isDemurTransaction(comment, time) end,
              collect(balance.transactions))
    return isempty(demurrages) ? 0 : sum(-y[4] for y in demurrages)
end

function demurrage(a::Actor)    
    sumsy_demurrage(a.balance)
end