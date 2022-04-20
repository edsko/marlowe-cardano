{ name = "marlowe-dashboard-client"
, dependencies =
  [ "aff"
  , "aff-promise"
  , "affjax"
  , "ansi"
  , "argonaut"
  , "argonaut-codecs"
  , "argonaut-core"
  , "argonaut-generic"
  , "arrays"
  , "avar"
  , "bifunctors"
  , "bigints"
  , "concurrent-queues"
  , "console"
  , "contravariant"
  , "control"
  , "datetime"
  , "debug"
  , "distributive"
  , "dom-indexed"
  , "effect"
  , "either"
  , "enums"
  , "exceptions"
  , "filterable"
  , "foldable-traversable"
  , "foreign"
  , "foreign-generic"
  , "foreign-object"
  , "fork"
  , "formatters"
  , "free"
  , "functions"
  , "functors"
  , "gen"
  , "halogen"
  , "halogen-nselect"
  , "halogen-store"
  , "halogen-subscriptions"
  , "heterogeneous"
  , "http-methods"
  , "identity"
  , "integers"
  , "json-helpers"
  , "lazy"
  , "lists"
  , "logging"
  , "maybe"
  , "monad-control"
  , "newtype"
  , "now"
  , "nullable"
  , "ordered-collections"
  , "parallel"
  , "partial"
  , "prelude"
  , "profunctor"
  , "profunctor-lenses"
  , "quickcheck"
  , "quickcheck-laws"
  , "random"
  , "record"
  , "refs"
  , "remotedata"
  , "safe-coerce"
  , "servant-support"
  , "spec"
  , "spec-quickcheck"
  , "strings"
  , "tailrec"
  , "these"
  , "transformers"
  , "tuples"
  , "typelevel-prelude"
  , "undefinable"
  , "unfoldable"
  , "unicode"
  , "unlift"
  , "unsafe-coerce"
  , "uri"
  , "validation"
  , "variant"
  , "web-clipboard"
  , "web-common"
  , "web-dom"
  , "web-events"
  , "web-file"
  , "web-html"
  , "web-socket"
  , "web-storage"
  , "web-touchevents"
  , "web-uievents"
  , "web-xhr"
  ]
, packages = ../packages.dhall
, sources =
  [ "src/**/*.purs"
  , "test/**/*.purs"
  , "generated/**/*.purs"
  , "../web-common-marlowe/src/**/*.purs"
  ]
}
