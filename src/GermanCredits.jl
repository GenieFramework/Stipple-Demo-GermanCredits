module GermanCredits

using Logging, LoggingExtras

function main()
  Base.eval(Main, :(const UserApp = GermanCredits))

  include(joinpath("..", "genie.jl"))

  Base.eval(Main, :(const Genie = GermanCredits.Genie))
  Base.eval(Main, :(using Genie))
end; main()

end
