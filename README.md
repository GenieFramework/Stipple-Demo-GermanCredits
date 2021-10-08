# NOTE: This repository is deprecated. For new Stipple examples check [this Repository](https://github.com/GenieFramework/StippleDemos)

# German Credits visualization dashboard

Demo data dashboard built with
[Stipple.jl](https://github.com/GenieFramework/Stipple.jl),
[StippleUI.jl](https://github.com/GenieFramework/StippleUI.jl),
[StippleCharts.jl](https://github.com/GenieFramework/StippleCharts.jl), and
[Genie.jl](https://github.com/GenieFramework/Genie.jl)

## Installation

Clone/download repo.

Open a Julia REPL and `cd` to the app's dir.

```julia
julia> cd(...the app folder...)
```

Install dependencies

```julia
pkg> activate .

pkg> instantiate
```

Load app

```julia
julia> using Genie

julia> Genie.loadapp()
```

The application will start on port 9000. Open your web browser and navigate to <http://localhost:9000>.

Use the age range to visualize the data.

<img src="https://genieframework.com/githubimg/Screenshot_German_Credits.png" width=800>

