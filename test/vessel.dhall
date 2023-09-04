let mainVessel = ../vessel.dhall

let additionalDependencies = [ "matchers" ] : List Text

in mainVessel
    with dependencies = mainVessel.dependencies # additionalDependencies