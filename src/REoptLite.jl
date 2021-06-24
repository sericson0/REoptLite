# *********************************************************************************
# REopt, Copyright (c) 2019-2020, Alliance for Sustainable Energy, LLC.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice, this list
# of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or other
# materials provided with the distribution.
#
# Neither the name of the copyright holder nor the names of its contributors may be
# used to endorse or promote products derived from this software without specific
# prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
# *********************************************************************************
module REoptLite

export
    Scenario,
    REoptInputs,
    run_reopt,
    build_reopt!,
    reopt_results,
    simulate_outages,
    # for docs:
    ElectricLoad,
    Financial,
    add_financial_results,
    ElectricUtility,
    Generator,
    Wind,
    sam_wind_prod_factors

import HTTP
import JSON
using JuMP
using JuMP.Containers: DenseAxisArray
using Logging
using DelimitedFiles
using Dates
using PyCall
const pyscc = PyNULL()

import MathOptInterface
import Dates: daysinmonth, Date, isleapyear
const MOI = MathOptInterface

include("keys.jl")
include("core/types.jl")
include("core/utils.jl")

include("core/site.jl")
include("core/financial.jl")
include("core/pv.jl")
include("core/storage.jl")
include("core/generator.jl")
include("core/wind.jl")
include("core/electric_load.jl")
include("core/electric_utility.jl")
include("core/prodfactor.jl")
include("core/wind_prodfactor.jl")
include("core/urdb.jl")
include("core/electric_tariff.jl")
include("core/scenario.jl")
include("core/reopt_inputs.jl")

include("constraints/outage_constraints.jl")
include("constraints/storage_constraints.jl")
include("constraints/load_balance.jl")
include("constraints/tech_constraints.jl")
include("constraints/electric_utility_constraints.jl")
include("constraints/generator_constraints.jl")

include("results/results.jl")
include("results/electric_tariff.jl")
include("results/electric_utility.jl")
include("results/financial.jl")
include("results/generator.jl")
include("results/pv.jl")
include("results/storage.jl")
include("results/outages.jl")
include("results/wind.jl")

include("core/reopt.jl")
include("core/reopt_multinode.jl")

include("outagesim/outage_simulator.jl")

end
